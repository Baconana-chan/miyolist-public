# 🔧 Исправление ошибки авторизации на Windows

## Проблема

```
Authentication error: Invalid argument(s): 
Callback url scheme must start with http://localhost:{port}
```

## Причина

Библиотека `flutter_web_auth_2` на **Windows, Linux и macOS** требует использовать `http://localhost:{port}` вместо custom scheme типа `miyolist://auth`.

Custom schemes (`miyolist://auth`) работают **только на Android/iOS**.

## Решение

### ✅ Что было сделано:

1. **Обновлен `app_constants.dart`**: Добавлены отдельные URI для desktop и mobile
2. **Обновлен `auth_service.dart`**: Автоматическое определение платформы
3. **Добавлены debug логи**: Для отладки процесса авторизации

### 📝 Настройка на AniList

**ОБЯЗАТЕЛЬНО**: Добавьте оба redirect URI в настройках приложения на AniList:

1. Откройте https://anilist.co/settings/developer
2. Выберите ваше приложение (Client ID: YOUR_CLIENT_ID)
3. В поле **"Redirect URI"** добавьте:
   ```
   http://localhost:8080/auth
   miyolist://auth
   ```
4. Нажмите **"Save"**

### 🎯 Как это работает теперь:

```dart
// Автоматическое определение платформы
String get redirectUri {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return 'http://localhost:8080/auth';  // Desktop
  } else {
    return 'miyolist://auth';              // Mobile
  }
}

String get callbackUrlScheme {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return 'http';      // Только 'http', не полный URL!
  } else {
    return 'miyolist';  // Scheme без '://'
  }
}
```

## Тестирование

### Windows

```bash
flutter run -d windows
```

**Ожидаемый вывод в консоли**:
```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=YOUR_CLIENT_ID...
📍 Redirect URI: http://localhost:8080/auth
🔗 Callback scheme: http
✅ Auth result: http://localhost:8080/auth?code=def5020...
```

### Android

```bash
flutter run -d android
```

**Ожидаемый вывод в консоли**:
```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=YOUR_CLIENT_ID...
📍 Redirect URI: miyolist://auth
🔗 Callback scheme: miyolist
✅ Auth result: miyolist://auth?code=def5020...
```

## Частые ошибки

### ❌ "Invalid redirect_uri"

**Причина**: URI в настройках AniList не совпадает с URI в приложении

**Решение**:
1. Проверьте AniList Developer page
2. Убедитесь, что там есть `http://localhost:8080/auth`
3. Перезапустите приложение

### ❌ "Callback url scheme must start with http://localhost"

**Причина**: В настройках AniList указан только `miyolist://auth`

**Решение**:
1. Добавьте `http://localhost:8080/auth` на AniList
2. Сохраните изменения
3. Попробуйте снова

### ❌ Открывается браузер, но не возвращается в приложение

**Причина**: Порт занят или неправильный callback scheme

**Решение**:
1. Проверьте, что порт 8080 свободен
2. Убедитесь, что `callbackUrlScheme = 'http'` (не `'http://localhost:8080'`)
3. Перезапустите приложение

## Изменённые файлы

- ✅ `lib/core/constants/app_constants.dart` - Добавлены `redirectUriDesktop` и `redirectUriMobile`
- ✅ `lib/core/services/auth_service.dart` - Добавлена логика определения платформы
- ✅ `OAUTH_SETUP.md` - Обновлена документация
- ✅ `docs/AUTH_FIX_WINDOWS.md` - Создан этот гайд

## Следующие шаги

1. **Обновите настройки на AniList** (добавьте оба URI)
2. **Перезапустите приложение**
3. **Попробуйте авторизоваться**
4. **Проверьте консоль** на наличие debug сообщений (🔐📍🔗✅)

---

**Версия**: 1.1.0
**Дата**: October 10, 2025
**Статус**: ✅ Исправлено
