# 🎯 Итоговая инструкция - Исправление авторизации

## ✅ Что было исправлено:

### Проблема:
```
Authentication error: Invalid argument(s): 
Callback url scheme must start with http://localhost:{port}
```

### Причина:
- Библиотека `flutter_web_auth_2` на **Windows требует `http://localhost:{port}`**
- Custom schemes (`miyolist://`) работают **только на мобильных устройствах**
- В коде использовался неправильный callback scheme для Windows

### Решение:
1. ✅ Разделены URI для desktop и mobile в `app_constants.dart`
2. ✅ Добавлено автоопределение платформы в `auth_service.dart`
3. ✅ Добавлены debug логи для отладки

---

## 🔧 Что нужно сделать СЕЙЧАС:

### Шаг 1: Обновить настройки на AniList

**ОБЯЗАТЕЛЬНО!** Без этого авторизация не заработает.

1. Откройте: https://anilist.co/settings/developer
2. Найдите приложение с **Client ID: 31113**
3. В разделе **"Redirect URI"** добавьте:
   ```
   http://localhost:8080/auth
   ```
   
4. Если планируете поддержку Android/iOS, добавьте также:
   ```
   miyolist://auth
   ```

5. Нажмите **"Save"** или **"Update"**

**Скриншот того, как должно выглядеть:**
```
┌─────────────────────────────────────┐
│ Redirect URI:                       │
│ ┌─────────────────────────────────┐ │
│ │ http://localhost:8080/auth      │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ miyolist://auth                 │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Шаг 2: Перезапустить приложение

```powershell
# В PowerShell
flutter run -d windows
```

### Шаг 3: Тестирование

1. Откройте приложение
2. Нажмите кнопку **"Login with AniList"**
3. **Проверьте консоль** - должно появиться:

```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=31113&redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fauth&response_type=code
📍 Redirect URI: http://localhost:8080/auth
🔗 Callback scheme: http
```

4. **Откроется браузер** с авторизацией AniList
5. Нажмите **"Approve"**
6. **Консоль должна показать**:

```
✅ Auth result: http://localhost:8080/auth?code=def50200...
```

7. **Приложение должно вернуться** к главному экрану, залогинив вас

---

## 🐛 Частые проблемы:

### ❌ "Invalid redirect_uri"

**Консоль:**
```
Authentication error: invalid_request: The redirect_uri provided does not match the registered redirect_uri
```

**Решение:**
1. Проверьте AniList → Settings → Developer
2. Убедитесь, что там **точно** `http://localhost:8080/auth`
3. Нет лишних пробелов, правильный порт (8080)
4. Сохраните изменения
5. Перезапустите приложение

---

### ❌ "Callback url scheme must start with http://localhost"

**Консоль:**
```
Authentication error: Invalid argument(s): Callback url scheme must start with http://localhost:{port}
```

**Решение:**
1. На AniList должен быть добавлен `http://localhost:8080/auth`
2. Если его нет - добавьте прямо сейчас
3. Код уже исправлен, нужно только настроить AniList

---

### ❌ Браузер открылся, но приложение не вернулось

**Симптом:**
- Браузер показывает "You have been redirected"
- Приложение не реагирует
- В консоли нет `✅ Auth result`

**Решение:**
1. Проверьте, что порт 8080 свободен:
   ```powershell
   netstat -ano | findstr :8080
   ```
2. Если порт занят, закройте процесс или измените порт в `app_constants.dart`:
   ```dart
   static const String redirectUriDesktop = 'http://localhost:9999/auth';
   ```
   И обновите на AniList!

---

### ❌ Приложение вылетает при логине

**Консоль:**
```
Exception: Authorization code not found
```

**Решение:**
1. Убедитесь, что на AniList нажали **"Approve"**
2. Проверьте, что callback вернулся с параметром `?code=...`
3. Проверьте консоль на наличие `✅ Auth result`

---

## 📊 Техническая информация:

### Изменённые файлы:

**1. `lib/core/constants/app_constants.dart`**
```dart
// Было:
static const String redirectUri = 'miyolist://auth';

// Стало:
static const String redirectUriMobile = 'miyolist://auth';
static const String redirectUriDesktop = 'http://localhost:8080/auth';
```

**2. `lib/core/services/auth_service.dart`**
```dart
// Добавлено:
String get redirectUri {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return AppConstants.redirectUriDesktop;
  } else {
    return AppConstants.redirectUriMobile;
  }
}

String get callbackUrlScheme {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return 'http';  // НЕ 'http://localhost:8080'!
  } else {
    return 'miyolist';
  }
}
```

### Как это работает:

1. **Windows/Linux/macOS:**
   - Redirect URI: `http://localhost:8080/auth`
   - Callback scheme: `http` (только протокол!)
   - Библиотека запускает локальный HTTP сервер на порту 8080
   - Браузер перенаправляет на этот сервер с кодом авторизации

2. **Android/iOS:**
   - Redirect URI: `miyolist://auth`
   - Callback scheme: `miyolist` (без `://`)
   - ОС регистрирует custom scheme для приложения
   - Браузер перенаправляет напрямую в приложение

---

## ✅ Контрольный список:

Отметьте всё, что сделали:

- [ ] Открыл https://anilist.co/settings/developer
- [ ] Нашёл приложение с Client ID: 31113
- [ ] Добавил `http://localhost:8080/auth` в Redirect URI
- [ ] Сохранил изменения на AniList
- [ ] Перезапустил приложение (`flutter run -d windows`)
- [ ] Нажал кнопку логина
- [ ] Увидел debug логи в консоли (🔐📍🔗)
- [ ] Одобрил авторизацию в браузере
- [ ] Увидел `✅ Auth result` в консоли
- [ ] Приложение вернулось к главному экрану
- [ ] Профиль загрузился

---

## 🎉 Готово!

После выполнения всех шагов авторизация должна работать корректно на Windows.

**Для Android:** Код уже поддерживает оба варианта, просто убедитесь, что на AniList добавлен также `miyolist://auth`.

---

**Версия:** 1.1.0  
**Дата:** October 10, 2025  
**Платформа:** Windows (также поддерживается Linux, macOS, Android, iOS)

---

## 📚 Дополнительные материалы:

- `docs/AUTH_FIX_WINDOWS.md` - Подробное описание проблемы и решения
- `docs/QUICK_FIX_AUTH.md` - Краткая инструкция
- `OAUTH_SETUP.md` - Полное руководство по OAuth2 настройке

---

**Нужна помощь?** Проверьте консоль на наличие emoji-логов (🔐📍🔗✅) для диагностики проблемы.
