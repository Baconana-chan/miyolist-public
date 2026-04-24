use std::{
    io::{Read, Write},
    net::{TcpListener, TcpStream},
    sync::{Mutex, OnceLock},
    thread,
    time::Instant,
};

use rusqlite::Connection;
use tauri::AppHandle;
use url::Url;
use uuid::Uuid;

use crate::models::{AuthRequestPlan, FoundationModule};

const CALLBACK_HOST: &str = "localhost";
const CALLBACK_BIND_HOST: &str = "127.0.0.1";
const CALLBACK_PORT: u16 = 43821;
const CALLBACK_PATH: &str = "/auth/callback";
const RESPONSE_TYPE: &str = "code";
const AUTH_TIMEOUT_SECS: u64 = 120;

static CALLBACK_LISTENER_STATE: OnceLock<Mutex<CallbackListenerState>> = OnceLock::new();

enum CallbackListenerState {
    NotStarted,
    Running { started_at: Instant },
    Completed,
    Failed(String),
}

pub fn get_auth_callback_status() -> String {
    match &*callback_listener_state().lock().unwrap() {
        CallbackListenerState::NotStarted => "idle".into(),
        CallbackListenerState::Running { started_at } => {
            if started_at.elapsed().as_secs() > AUTH_TIMEOUT_SECS {
                "timed_out".into()
            } else {
                "waiting".into()
            }
        }
        CallbackListenerState::Completed => "completed".into(),
        CallbackListenerState::Failed(msg) => format!("failed:{msg}"),
    }
}

pub fn reopen_auth_browser(app: &AppHandle, auth_url: &str) -> Result<(), String> {
    use tauri_plugin_opener::OpenerExt;
    app.opener()
        .open_url(auth_url, None::<&str>)
        .map_err(|e| e.to_string())
}

pub fn submit_auth_code_manually(app: &AppHandle, code: &str) -> Result<(), String> {
    crate::anilist::exchange_authorization_code(app, code)?;
    crate::anilist::fetch_viewer(app)?;
    *callback_listener_state().lock().unwrap() = CallbackListenerState::Completed;
    Ok(())
}

pub fn foundation_summary() -> FoundationModule {
    FoundationModule {
        name: "Auth".into(),
        summary: "Localhost-based AniList OAuth foundation replaces the old website bridge and persists pending auth state locally.".into(),
        status: "ready".into(),
    }
}

pub fn auth_strategy() -> Vec<String> {
    vec![
        "Use an external browser with a local localhost callback handled by Tauri.".into(),
        "Do not depend on a website bridge or Cloudflare Pages middleware for auth return flow."
            .into(),
        "Treat manual code paste as a fallback, not the main path.".into(),
        "Expose timeout, retry, and callback failures clearly in the UI and logs.".into(),
    ]
}

pub fn primary_platform() -> String {
    "Windows".into()
}

pub fn prepare_auth_request(app: &AppHandle) -> Result<AuthRequestPlan, String> {
    crate::db::initialize_database(app)?;
    ensure_callback_listener(app)?;

    let redirect_uri_value = redirect_uri();
    let state = Uuid::new_v4().simple().to_string();
    let auth_url = build_auth_url(&redirect_uri_value, &state)?;

    persist_pending_state(app, &state)?;

    Ok(AuthRequestPlan {
        auth_url,
        redirect_uri: redirect_uri_value.clone(),
        callback_host: CALLBACK_BIND_HOST.into(),
        callback_port: CALLBACK_PORT,
        callback_path: CALLBACK_PATH.into(),
        state,
        response_type: RESPONSE_TYPE.into(),
        uses_website_bridge: false,
        notes: vec![
            format!(
                "Register {} in AniList developer settings as the desktop redirect URI.",
                redirect_uri_value
            ),
            "The callback is handled locally by the app, not by a Cloudflare Pages or site middleware layer.".into(),
            "A fresh OAuth state is generated per request and stored locally in auth_session.".into(),
        ],
    })
}

pub fn redirect_uri() -> String {
    format!("http://{CALLBACK_HOST}:{CALLBACK_PORT}{CALLBACK_PATH}")
}

fn build_auth_url(redirect_uri: &str, state: &str) -> Result<String, String> {
    let config = crate::anilist::load_public_config()?;
    let mut url = Url::parse(&config.auth_url).map_err(|error| error.to_string())?;
    url.query_pairs_mut()
        .append_pair("client_id", &config.client_id)
        .append_pair("redirect_uri", redirect_uri)
        .append_pair("response_type", RESPONSE_TYPE)
        .append_pair("state", state);

    Ok(url.to_string())
}

fn persist_pending_state(app: &AppHandle, state: &str) -> Result<(), String> {
    let database_path = crate::db::database_path(app)?;
    let connection = Connection::open(database_path).map_err(|error| error.to_string())?;

    connection
        .execute(
            "
            INSERT INTO auth_session (
              id,
              auth_state,
              updated_at
            ) VALUES (1, ?1, CURRENT_TIMESTAMP)
            ON CONFLICT(id) DO UPDATE SET
              auth_state = excluded.auth_state,
              updated_at = CURRENT_TIMESTAMP
            ",
            [state],
        )
        .map_err(|error| error.to_string())?;

    Ok(())
}

fn callback_listener_state() -> &'static Mutex<CallbackListenerState> {
    CALLBACK_LISTENER_STATE.get_or_init(|| Mutex::new(CallbackListenerState::NotStarted))
}

fn ensure_callback_listener(app: &AppHandle) -> Result<(), String> {
    let state = callback_listener_state();
    let mut guard = state
        .lock()
        .map_err(|_| "Callback listener state is poisoned".to_string())?;

    match &*guard {
        CallbackListenerState::Running { .. } => return Ok(()),
        CallbackListenerState::Failed(message) => return Err(message.clone()),
        CallbackListenerState::NotStarted | CallbackListenerState::Completed => {}
    }

    let listener = TcpListener::bind((CALLBACK_BIND_HOST, CALLBACK_PORT)).map_err(|error| {
        let message = format!(
            "[LISTENER_BIND_ERROR] Failed to start localhost auth callback listener on {}:{}: {}",
            CALLBACK_BIND_HOST, CALLBACK_PORT, error
        );
        *guard = CallbackListenerState::Failed(message.clone());
        message
    })?;

    *guard = CallbackListenerState::Running {
        started_at: Instant::now(),
    };
    drop(guard);

    let app_handle = app.clone();
    thread::spawn(move || run_callback_listener(listener, app_handle));

    Ok(())
}

fn run_callback_listener(listener: TcpListener, app: AppHandle) {
    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                if let Err(error) = handle_callback_connection(stream, &app) {
                    eprintln!("Auth callback handling failed: {error}");
                }
            }
            Err(error) => {
                eprintln!("Auth callback listener connection failed: {error}");
            }
        }
    }
}

fn handle_callback_connection(mut stream: TcpStream, app: &AppHandle) -> Result<(), String> {
    let mut buffer = [0_u8; 8192];
    let bytes_read = stream
        .read(&mut buffer)
        .map_err(|error| error.to_string())?;
    if bytes_read == 0 {
        return Ok(());
    }

    let request = String::from_utf8_lossy(&buffer[..bytes_read]);
    let target = request_target(&request)?;
    let url = Url::parse(&format!("http://{CALLBACK_HOST}{target}"))
        .map_err(|error| error.to_string())?;

    let response = if url.path() != CALLBACK_PATH {
        html_response(
            "404 Not Found",
            "Unknown callback path",
            "The browser reached the local auth server, but the requested route is not supported.",
        )
    } else {
        match handle_callback(app, &url) {
            Ok(message) => html_response("200 OK", "AniList login completed", &message),
            Err(message) => {
                *callback_listener_state().lock().unwrap() =
                    CallbackListenerState::Failed(message.clone());
                html_response("400 Bad Request", "AniList login failed", &message)
            }
        }
    };

    stream
        .write_all(response.as_bytes())
        .map_err(|error| error.to_string())?;
    stream.flush().map_err(|error| error.to_string())?;

    Ok(())
}

fn request_target(request: &str) -> Result<&str, String> {
    let first_line = request
        .lines()
        .next()
        .ok_or_else(|| "Auth callback request was empty".to_string())?;
    let mut parts = first_line.split_whitespace();
    let method = parts.next().unwrap_or_default();
    let target = parts
        .next()
        .ok_or_else(|| "Auth callback request target was missing".to_string())?;

    if method != "GET" {
        return Err(format!("Unsupported callback request method: {method}"));
    }

    Ok(target)
}

fn handle_callback(app: &AppHandle, url: &Url) -> Result<String, String> {
    let query = url.query_pairs().into_owned().collect::<Vec<_>>();

    let error = query
        .iter()
        .find(|(key, _)| key == "error")
        .map(|(_, value)| value.clone());
    if let Some(error) = error {
        let description = query
            .iter()
            .find(|(key, _)| key == "error_description")
            .map(|(_, value)| value.clone())
            .unwrap_or_else(|| "AniList denied the request.".into());
        return Err(format!(
            "[CALLBACK_ANILIST_DENIED] AniList returned {error}: {description}"
        ));
    }

    let code = query
        .iter()
        .find(|(key, _)| key == "code")
        .map(|(_, value)| value.clone())
        .ok_or_else(|| {
            "[CALLBACK_MISSING_CODE] AniList callback did not include an authorization code."
                .to_string()
        })?;
    let state = query
        .iter()
        .find(|(key, _)| key == "state")
        .map(|(_, value)| value.clone())
        .ok_or_else(|| {
            "[CALLBACK_MISSING_STATE] AniList callback did not include an OAuth state.".to_string()
        })?;

    validate_state(app, &state)?;
    crate::anilist::exchange_authorization_code(app, &code)?;
    crate::anilist::fetch_viewer(app)?;
    *callback_listener_state().lock().unwrap() = CallbackListenerState::Completed;

    Ok("The AniList browser callback reached MiyoList successfully. You can close this tab and return to the app; the local session has been updated.".into())
}

fn validate_state(app: &AppHandle, state: &str) -> Result<(), String> {
    let database_path = crate::db::database_path(app)?;
    let connection = Connection::open(database_path).map_err(|error| error.to_string())?;
    let expected_state = connection
        .query_row(
            "SELECT auth_state FROM auth_session WHERE id = 1",
            [],
            |row| row.get::<_, Option<String>>(0),
        )
        .map_err(|error| error.to_string())?
        .ok_or_else(|| {
            "[STATE_NOT_FOUND] No pending OAuth state was stored locally.".to_string()
        })?;

    if expected_state != state {
        return Err("[CALLBACK_STATE_MISMATCH] OAuth state mismatch. The callback does not match the latest sign-in attempt.".into());
    }

    Ok(())
}

fn html_response(status: &str, title: &str, body: &str) -> String {
    let html = format!(
        "<!doctype html><html><head><meta charset=\"utf-8\"><title>{title}</title><style>body{{margin:0;font-family:Segoe UI,Trebuchet MS,sans-serif;background:#121314;color:#f1efe7;display:grid;place-items:center;min-height:100vh}}main{{max-width:42rem;padding:2rem;border:1px solid rgba(255,255,255,.08);border-radius:24px;background:rgba(24,27,30,.92);box-shadow:0 24px 60px rgba(0,0,0,.28)}}h1{{margin:0 0 .75rem;font-size:2rem}}p{{margin:0;color:#b5b0a5;line-height:1.6}}</style></head><body><main><h1>{title}</h1><p>{body}</p></main></body></html>"
    );

    format!(
        "HTTP/1.1 {status}\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}",
        html.len(),
        html
    )
}
