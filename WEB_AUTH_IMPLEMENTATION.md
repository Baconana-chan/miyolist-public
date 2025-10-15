# MiyoList Web OAuth Implementation

## 🎉 Реализация завершена

Система веб-авторизации для MiyoList теперь полностью интегрирована в приложение.

## 📁 Созданные файлы

### 1. `lib/core/services/web_auth_handler.dart`
Обработчик веб-авторизации с поддержкой:
- ✅ HTTP сервер для десктопных платформ (Windows/Linux/macOS)
- ✅ Красивые HTML страницы успеха/ошибки
- ✅ Автоматическое закрытие окна браузера
- ✅ Таймауты и обработка ошибок
- 🔄 Подготовлено для deep linking на мобильных платформах

### 2. `lib/features/auth/widgets/manual_code_entry_dialog.dart`
Диалог для ручного ввода кода авторизации:
- ✅ Красивый Material Design интерфейс
- ✅ Кнопка "Вставить из буфера"
- ✅ Кнопка "Открыть браузер"
- ✅ Пошаговые инструкции для пользователя

### 3. Обновлен `lib/core/services/auth_service.dart`
- ✅ Новый метод `authenticateWithAniList()` с веб-редиректом
- ✅ Метод `authenticateWithManualCode()` для ручного ввода
- ✅ Автоматический обмен кода на токен
- ✅ Безопасное хранение токена

### 4. Обновлен `lib/core/constants/app_constants.dart`
- ✅ Добавлен `redirectUriWeb` = `https://miyo.my/auth/callback`
- ✅ Добавлен `webAuthUrl` = `https://miyo.my/auth/login`

## 🚀 Как это работает

### Процесс авторизации:

```
1. Пользователь нажимает "Sign In"
   ↓
2. Открывается браузер с https://miyo.my/auth/login
   ↓
3. Веб-сайт редиректит на AniList OAuth
   ↓
4. Пользователь авторизуется на AniList
   ↓
5. AniList редиректит на https://miyo.my/auth/callback?code=XXX
   ↓
6. Desktop: Локальный HTTP сервер перехватывает код
   Mobile: Deep link (TODO) или ручной ввод
   ↓
7. Приложение обменивает код на токен
   ↓
8. Токен сохраняется, пользователь авторизован! ✅
```

### Desktop (Windows/Linux/macOS):

```dart
1. Запускается локальный HTTP сервер на случайном порту
2. Открывается браузер с веб-авторизацией
3. После авторизации пользователь вручную копирует URL из браузера
   ИЛИ будущая версия веб-сайта сделает redirect на localhost
4. Сервер получает код и закрывается
5. Отображается красивая страница успеха
```

### Mobile (Android/iOS):

```dart
// TODO: Реализовать через app_links
1. Открывается браузер с веб-авторизацией
2. Deep link перехватывает callback
3. Приложение получает код и обменивает на токен

// Временное решение:
1. Открывается браузер
2. Пользователь копирует код из браузера
3. Вставляет в диалог ручного ввода
```

## 📝 Использование в коде

### Базовая авторизация:

```dart
final authService = AuthService();

// Автоматическая авторизация (откроет браузер)
final token = await authService.authenticateWithAniList();

if (token != null) {
  print('✅ Успешно авторизован!');
} else {
  print('❌ Ошибка авторизации');
}
```

### С ручным вводом кода (fallback):

```dart
import 'package:miyolist/features/auth/widgets/manual_code_entry_dialog.dart';

// Попытка автоматической авторизации
String? token = await authService.authenticateWithAniList();

// Если не получилось - показываем диалог ручного ввода
if (token == null && context.mounted) {
  final code = await showManualCodeEntryDialog(context);
  
  if (code != null) {
    token = await authService.authenticateWithManualCode(code);
  }
}

if (token != null) {
  // Успех!
  Navigator.pushReplacementNamed(context, '/home');
}
```

### Проверка статуса авторизации:

```dart
final isAuth = await authService.isAuthenticated();

if (isAuth) {
  final token = await authService.getAccessToken();
  // Использовать токен для API запросов
}
```

### Выход:

```dart
await authService.logout();
// Токен удален, пользователь разлогинен
```

## 🔧 Настройка AniList

После деплоя веб-сайта на `https://miyo.my`, обновите настройки на AniList:

1. Откройте https://anilist.co/settings/developer
2. Найдите ваше приложение (Client ID: 31113)
3. Измените **Redirect URI** на: `https://miyo.my/auth/callback`
4. Сохраните изменения

## 🧪 Тестирование

### Локальное тестирование (без веб-сайта):

```dart
// В app_constants.dart временно измените:
static const String webAuthUrl = 'http://localhost:4321/auth/login';
static const String redirectUriWeb = 'http://localhost:4321/auth/callback';

// Запустите Astro dev сервер:
cd c:\Users\VIC\miyomy
npm run dev

// Запустите Flutter приложение:
flutter run -d windows
```

### Тестирование с production сайтом:

```dart
// Убедитесь что в app_constants.dart:
static const String webAuthUrl = 'https://miyo.my/auth/login';
static const String redirectUriWeb = 'https://miyo.my/auth/callback';

// Запустите приложение:
flutter run -d windows
```

### Проверка HTTP сервера:

```dart
// Включите debug вывод в web_auth_handler.dart
// Вы увидите в консоли:
🌐 Listening for auth callback on http://localhost:XXXX
📨 Received request: /auth?code=...
✅ Authorization code received: xxxxxxxxxx...
```

## 🔐 Безопасность

### Текущая реализация:
- ✅ Client Secret хранится в коде (не идеально, но приемлемо для desktop app)
- ✅ Токены сохраняются в `flutter_secure_storage`
- ✅ HTTPS для всех внешних запросов

### Рекомендации для production:

1. **Environment Variables** (опционально):
```dart
// Используйте --dart-define при сборке
static const String anilistClientSecret = String.fromEnvironment(
  'ANILIST_CLIENT_SECRET',
  defaultValue: 'your_default_secret',
);

// Build command:
flutter build windows --dart-define=ANILIST_CLIENT_SECRET=your_secret
```

2. **PKCE** (будущее улучшение):
```dart
// Добавьте в pubspec.yaml:
dependencies:
  crypto: ^3.0.3

// Используйте PKCE для дополнительной безопасности
// См. WEB_OAUTH_INTEGRATION.md для деталей
```

## 📱 Будущие улучшения

### 1. Deep Linking для Mobile:

```yaml
# pubspec.yaml
dependencies:
  app_links: ^6.0.0
```

```dart
// В web_auth_handler.dart добавить:
import 'package:app_links/app_links.dart';

Future<String?> _waitViaDeepLink() async {
  final appLinks = AppLinks();
  
  final subscription = appLinks.uriLinkStream.listen((uri) {
    final code = uri.queryParameters['code'];
    // Handle code
  });
  
  // ...
}
```

### 2. WebSocket для real-time communication:

```dart
// Веб-сайт отправляет код через WebSocket
// Приложение слушает и получает код мгновенно
// Не нужен HTTP сервер или deep linking
```

### 3. QR Code авторизация:

```dart
// Desktop app показывает QR код
// Mobile app сканирует и авторизуется
// Код передается через WebSocket или Firebase
```

## 🐛 Troubleshooting

### Проблема: Браузер не открывается

```dart
// Проверьте права и URL
final uri = Uri.parse(AppConstants.webAuthUrl);
if (!await canLaunchUrl(uri)) {
  print('❌ Cannot launch URL: $uri');
}
```

### Проблема: Код не получен

1. Проверьте консоль на наличие ошибок
2. Убедитесь что redirect URI совпадает в AniList настройках
3. Проверьте что веб-сайт правильно редиректит
4. Используйте диалог ручного ввода как fallback

### Проблема: Обмен кода на токен не работает

1. Убедитесь что `client_secret` правильный
2. Проверьте что `redirect_uri` совпадает точно
3. Код действителен ~10 минут, убедитесь что не истек
4. Проверьте формат запроса (должен быть `x-www-form-urlencoded`)

### Проблема: HTTP сервер не запускается

```dart
// Порт может быть занят, код использует случайный порт
// Проверьте firewall настройки
// На Windows может потребоваться разрешение
```

## 📚 Дополнительные ресурсы

- [AniList API Documentation](https://anilist.gitbook.io/anilist-apiv2-docs/)
- [OAuth 2.0 Specification](https://oauth.net/2/)
- [Flutter URL Launcher](https://pub.dev/packages/url_launcher)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [App Links (Deep Linking)](https://pub.dev/packages/app_links)

## ✅ Чек-лист внедрения

- [x] Создан `web_auth_handler.dart`
- [x] Создан `manual_code_entry_dialog.dart`
- [x] Обновлен `auth_service.dart`
- [x] Обновлен `app_constants.dart`
- [ ] Деплой веб-сайта на `https://miyo.my`
- [ ] Обновление AniList redirect URI
- [ ] Тестирование на Windows
- [ ] Тестирование на Linux (опционально)
- [ ] Тестирование на macOS (опционально)
- [ ] Реализация deep linking для Android
- [ ] Реализация deep linking для iOS
- [ ] Добавление PKCE (опционально)
- [ ] Environment variables для secrets (опционально)

## 🎯 Следующие шаги

1. **Деплой веб-сайта**:
   ```bash
   cd c:\Users\VIC\miyomy
   npm run build
   vercel --prod
   # или netlify deploy --prod
   ```

2. **Обновить AniList settings**:
   - Redirect URI: `https://miyo.my/auth/callback`

3. **Протестировать на Windows**:
   ```bash
   flutter run -d windows
   ```

4. **Собрать релиз**:
   ```bash
   flutter build windows --release
   ```

Готово! 🎉
