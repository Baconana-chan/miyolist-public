# 🔧 OAuth Fix - Final Solution

## Проблемы и решения

### ❌ Проблема 1: "Callback url scheme must start with http://localhost:{port}"

**Причина**: Неправильный `callbackUrlScheme` для Windows

**Было**:
```dart
String get callbackUrlScheme {
  if (Platform.isWindows) {
    return 'http';  // ❌ Неправильно
  }
}
```

**Стало**:
```dart
String get callbackUrlScheme {
  if (Platform.isWindows) {
    return 'http://localhost:8080';  // ✅ Правильно
  }
}
```

---

### ❌ Проблема 2: "invalid_client" при обмене кода на токен

**Причина**: AniList ожидает `application/x-www-form-urlencoded`, а не JSON

**Было**:
```dart
final tokenResponse = await http.post(
  Uri.parse(AppConstants.anilistTokenUrl),
  headers: {
    'Content-Type': 'application/json',  // ❌ Неправильно
    'Accept': 'application/json',
  },
  body: json.encode({  // ❌ JSON
    'grant_type': 'authorization_code',
    'client_id': AppConstants.anilistClientId,
    'redirect_uri': redirectUri,
    'code': code,
  }),
);
```

**Стало**:
```dart
final tokenResponse = await http.post(
  Uri.parse(AppConstants.anilistTokenUrl),
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',  // ✅ Правильно
    'Accept': 'application/json',
  },
  body: {  // ✅ Form data
    'grant_type': 'authorization_code',
    'client_id': AppConstants.anilistClientId,
    'redirect_uri': redirectUri,
    'code': code,
  },
);
```

---

## 🎯 Итоговая конфигурация

### 1. AniList Settings

**URL**: https://anilist.co/settings/developer

**Redirect URIs**:
```
http://localhost:8080/auth    ← Для Windows/Desktop
miyolist://auth               ← Для Android/iOS
```

### 2. app_constants.dart

```dart
class AppConstants {
  static const String anilistClientId = '31113';
  static const String redirectUriMobile = 'miyolist://auth';
  static const String redirectUriDesktop = 'http://localhost:8080/auth';
}
```

### 3. auth_service.dart

```dart
String get redirectUri {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return AppConstants.redirectUriDesktop;
  } else {
    return AppConstants.redirectUriMobile;
  }
}

String get callbackUrlScheme {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return 'http://localhost:8080';  // ✅ Полный URL
  } else {
    return 'miyolist';
  }
}
```

---

## 🧪 Тестирование

Запустите приложение:

```powershell
flutter run -d windows
```

### Ожидаемый вывод консоли:

```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=31113&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fauth&response_type=code
📍 Redirect URI: http://localhost:8080/auth
🔗 Callback scheme: http://localhost:8080
✅ Auth result: http://localhost:8080/auth?code=def502002dc704d877...
🔄 Exchanging code for access token...
📥 Token response status: 200
📥 Token response body: {"token_type":"Bearer","expires_in":31536000,"access_token":"eyJ0..."}
✅ Access token received successfully!
```

---

## ✅ Контрольный список

- [x] `callbackUrlScheme` = `'http://localhost:8080'` для Windows
- [x] `Content-Type` = `'application/x-www-form-urlencoded'`
- [x] Данные отправляются как `Map<String, String>`, не JSON
- [x] На AniList добавлен `http://localhost:8080/auth`
- [x] Debug логи добавлены для отладки

---

## 🐛 Если не работает:

### Проверьте консоль

1. **"Callback url scheme must start..."** → Проверьте `callbackUrlScheme`
2. **"invalid_client"** → Проверьте Content-Type и формат данных
3. **"invalid_redirect_uri"** → Проверьте настройки на AniList
4. **Code 400/401** → Проверьте формат тела запроса

### Проверьте Network logs

Если нужно, добавьте:
```dart
print('Request headers: ${tokenResponse.request?.headers}');
print('Request body type: ${tokenResponse.request?.body.runtimeType}');
```

---

**Дата**: October 10, 2025  
**Версия**: 1.1.0  
**Статус**: ✅ Полностью исправлено
