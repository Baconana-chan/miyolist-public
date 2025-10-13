# 🚨 КРИТИЧЕСКАЯ ПРОБЛЕМА: Client Secret Required

## Проблема

```
📥 Token response status: 401
📥 Token response body: {"error":"invalid_client","message":"Client authentication failed"}
```

## Причина

AniList требует **client_secret** для обмена authorization code на access token. Это стандартный OAuth2 Authorization Code flow.

## Решение

### Шаг 1: Получить Client Secret

1. Откройте: https://anilist.co/settings/developer
2. Найдите приложение с **Client ID: YOUR_CLIENT_ID**
3. Найдите поле **"Client Secret"** (должно быть видно)
4. **Скопируйте Client Secret**

⚠️ **ВАЖНО**: Client Secret должен храниться **в секрете**! Не публикуйте его в GitHub!

### Шаг 2: Добавить в app_constants.dart

```dart
class AppConstants {
  // AniList OAuth2
  static const String anilistClientId = 'YOUR_CLIENT_ID';
  
  // ⚠️ СЕКРЕТНО! Не коммитить в публичный репозиторий!
  static const String anilistClientSecret = 'YOUR_CLIENT_SECRET_HERE';
  
  static const String anilistAuthUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String anilistTokenUrl = 'https://anilist.co/api/v2/oauth/token';
  static const String anilistGraphQLUrl = 'https://graphql.anilist.co';
  
  // ... rest of constants
}
```

### Шаг 3: Обновить auth_service.dart

Нужно добавить `client_secret` в запрос обмена токена:

```dart
final tokenResponse = await http.post(
  Uri.parse(AppConstants.anilistTokenUrl),
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
    'Accept': 'application/json',
  },
  body: {
    'grant_type': 'authorization_code',
    'client_id': AppConstants.anilistClientId,
    'client_secret': AppConstants.anilistClientSecret,  // ← Добавить это
    'redirect_uri': redirectUri,
    'code': code,
  },
);
```

---

## ⚠️ БЕЗОПАСНОСТЬ

### Проблема хранения секретов

**Client Secret в мобильном/десктоп приложении = небезопасно!**

Любой может декомпилировать приложение и извлечь секрет.

### Решения:

#### Вариант 1: Backend Proxy (Рекомендуется)

```
[Flutter App] → [Your Backend] → [AniList API]
                    ↑
              Хранит client_secret
```

**Плюсы**: Секрет в безопасности
**Минусы**: Нужен backend

#### Вариант 2: Implicit Flow (Не рекомендуется AniList)

Некоторые OAuth2 провайдеры поддерживают Implicit Flow без client_secret, но AniList требует Authorization Code flow.

#### Вариант 3: Хранить секрет в приложении (Текущий подход)

**Плюсы**: Просто
**Минусы**: 
- Секрет может быть извлечен
- Нарушает best practices OAuth2
- Но для личного/некоммерческого проекта приемлемо

---

## Быстрое решение (для тестирования)

Если это личный проект и не планируется публикация:

1. Получите Client Secret с AniList
2. Добавьте в `app_constants.dart`
3. Добавьте в `.gitignore`:
   ```
   lib/core/constants/app_constants.dart
   ```
4. Создайте `app_constants.example.dart` с placeholder:
   ```dart
   // Скопируйте в app_constants.dart и заполните реальными значениями
   static const String anilistClientId = 'YOUR_CLIENT_ID';
   static const String anilistClientSecret = 'YOUR_CLIENT_SECRET';
   ```

---

## Для публичного приложения

Если планируете публиковать приложение:

### Вариант A: Flutter Environment Variables

```dart
class AppConstants {
  static const String anilistClientSecret = String.fromEnvironment(
    'ANILIST_CLIENT_SECRET',
    defaultValue: '',
  );
}
```

Компиляция:
```bash
flutter build windows --dart-define=ANILIST_CLIENT_SECRET=your_secret_here
```

### Вариант B: Отдельный конфиг файл

1. Создайте `lib/core/constants/secrets.dart`:
```dart
class Secrets {
  static const String clientSecret = 'YOUR_SECRET';
}
```

2. Добавьте в `.gitignore`:
```
lib/core/constants/secrets.dart
```

3. Создайте `secrets.example.dart`:
```dart
class Secrets {
  static const String clientSecret = 'REPLACE_ME';
}
```

---

## Следующие шаги

1. ✅ Получите Client Secret с AniList
2. ✅ Добавьте в `app_constants.dart`
3. ✅ Обновите `auth_service.dart` (добавьте `client_secret` в body)
4. ✅ Перезапустите приложение
5. ✅ Протестируйте авторизацию

**После этого авторизация должна заработать!**

---

**Нужна помощь с добавлением Client Secret?** Пришлите его мне, и я обновлю код.
