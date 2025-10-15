# 🚀 Быстрый старт: Веб-авторизация MiyoList

## ✅ Что уже готово

1. ✅ **AuthService** - обновлен для веб-авторизации
2. ✅ **WebAuthHandler** - обработчик OAuth для desktop
3. ✅ **ManualCodeEntryDialog** - диалог для ручного ввода кода
4. ✅ **WebAuthLoginScreen** - пример экрана входа
5. ✅ **Зависимости** - обновлены (удален flutter_web_auth_2)

## 🎯 Как использовать

### Вариант 1: Быстрый тест (локально)

Если веб-сайт еще не задеплоен, можно протестировать локально:

```dart
// В app_constants.dart временно измените:
static const String webAuthUrl = 'http://localhost:4321/auth/login';
static const String redirectUriWeb = 'http://localhost:4321/auth/callback';

// Запустите Astro dev сервер в другом терминале:
cd c:\Users\VIC\miyomy
npm run dev

// Запустите Flutter приложение:
flutter run -d windows
```

### Вариант 2: Production (с деплоем)

После деплоя веб-сайта на `https://miyo.my`:

```dart
// app_constants.dart уже содержит правильные URL:
static const String webAuthUrl = 'https://miyo.my/auth/login';
static const String redirectUriWeb = 'https://miyo.my/auth/callback';

// Просто запустите приложение:
flutter run -d windows
```

## 📝 Интеграция в существующий код

### Шаг 1: Используйте новый экран входа

```dart
// В вашем роутинге или main.dart:
import 'package:miyolist/features/auth/screens/web_auth_login_screen.dart';

// Если пользователь не авторизован, покажите экран входа:
if (!isAuthenticated) {
  return MaterialApp(
    home: WebAuthLoginScreen(),
  );
}
```

### Шаг 2: Или используйте AuthService напрямую

```dart
import 'package:miyolist/core/services/auth_service.dart';

final authService = AuthService();

// Попытка авторизации
final token = await authService.authenticateWithAniList();

if (token != null) {
  // Успех! Пользователь авторизован
  print('Токен получен: $token');
} else {
  // Ошибка или отмена
  print('Авторизация не удалась');
}
```

### Шаг 3: Проверка статуса авторизации

```dart
// При старте приложения:
final isAuth = await authService.isAuthenticated();

if (isAuth) {
  // Пользователь уже авторизован
  navigateToHome();
} else {
  // Показать экран входа
  navigateToLogin();
}
```

## 🔧 Настройка AniList (важно!)

После деплоя веб-сайта обязательно обновите настройки:

1. Откройте https://anilist.co/settings/developer
2. Найдите ваше приложение (Client ID: 31113)
3. **Измените Redirect URI** на: `https://miyo.my/auth/callback`
4. Сохраните

**Без этого авторизация не будет работать!**

## 🧪 Тестирование

### Запуск на Windows:

```powershell
# В корне проекта:
flutter run -d windows
```

### Проверка логов:

При авторизации вы увидите в консоли:

```
🔐 Starting web-based OAuth authentication...
🌐 Opening browser: https://miyo.my/auth/login
🌐 Listening for auth callback on http://localhost:XXXXX
⏳ Waiting for authorization code...
📨 Received request: /auth?code=...
✅ Authorization code received: xxxxxxxxxx...
🔄 Exchanging code for access token...
📥 Token response status: 200
✅ Access token received successfully!
```

## 🎨 Кастомизация

### Изменение UI экрана входа:

```dart
// Отредактируйте:
lib/features/auth/screens/web_auth_login_screen.dart

// Измените иконку, цвета, текст и т.д.
```

### Добавление дополнительной логики:

```dart
// В auth_service.dart добавьте методы:

Future<UserProfile?> getUserProfile() async {
  final token = await getAccessToken();
  // Запрос профиля пользователя через GraphQL
}

Future<void> refreshToken() async {
  // Обновление токена если нужно
}
```

## 🐛 Решение проблем

### Проблема: "Could not launch auth URL"

**Решение**: Проверьте что URL правильный и доступен:

```dart
final url = Uri.parse(AppConstants.webAuthUrl);
if (!await canLaunchUrl(url)) {
  print('URL недоступен: $url');
}
```

### Проблема: "HTTP server timeout"

**Решение**: Используйте диалог ручного ввода:

```dart
// После неудачной автоматической авторизации:
if (token == null && context.mounted) {
  final code = await showManualCodeEntryDialog(context);
  if (code != null) {
    token = await authService.authenticateWithManualCode(code);
  }
}
```

### Проблема: "Token exchange failed"

**Решение**: Проверьте:
1. Client secret правильный
2. Redirect URI совпадает в AniList настройках
3. Код не истек (действителен ~10 минут)

## 📦 Сборка релиза

Когда все работает, соберите релиз:

```powershell
# Windows
flutter build windows --release

# Результат в:
build\windows\x64\runner\Release\
```

## 🎉 Готово!

Теперь у вас есть полностью рабочая веб-авторизация!

### Следующие шаги:

1. ✅ Протестировать на Windows
2. ⏳ Задеплоить веб-сайт
3. ⏳ Обновить AniList redirect URI
4. ⏳ Протестировать с production URL
5. ⏳ Собрать релиз
6. ⏳ Добавить deep linking для mobile (опционально)

---

**Нужна помощь?** Смотрите подробную документацию в `WEB_AUTH_IMPLEMENTATION.md`
