# 🎯 ФИНАЛЬНОЕ РЕШЕНИЕ - OAuth Authorization

## 🔴 Текущая проблема

```
📥 Token response status: 401
📥 Token response body: {"error":"invalid_client","message":"Client authentication failed"}
```

**Причина**: Отсутствует `client_secret` в запросе обмена кода на токен.

---

## ✅ Решение (3 простых шага)

### Шаг 1: Получить Client Secret

1. Откройте: **https://anilist.co/settings/developer**
2. Найдите приложение с **Client ID: 31113**
3. Вы увидите поле **"Client Secret"**
4. **Скопируйте значение** (например: `abc123xyz456...`)

**Скриншот (пример)**:
```
┌──────────────────────────────────────┐
│ Client ID: 31113                     │
│ Client Secret: abc123xyz456def789... │ ← Скопируйте это
└──────────────────────────────────────┘
```

---

### Шаг 2: Добавить в app_constants.dart

Откройте файл:
```
lib/core/constants/app_constants.dart
```

Найдите строку:
```dart
static const String anilistClientSecret = 'YOUR_CLIENT_SECRET_HERE';
```

Замените `'YOUR_CLIENT_SECRET_HERE'` на **ваш настоящий Client Secret**:
```dart
static const String anilistClientSecret = 'abc123xyz456def789...'; // Ваш секрет
```

**Полный пример**:
```dart
class AppConstants {
  // AniList OAuth2
  static const String anilistClientId = '31113';
  static const String anilistClientSecret = 'IyaRCVCB1234abcd...'; // ← Ваш секрет здесь
  
  static const String anilistAuthUrl = 'https://anilist.co/api/v2/oauth/authorize';
  static const String anilistTokenUrl = 'https://anilist.co/api/v2/oauth/token';
  // ... остальное
}
```

---

### Шаг 3: Перезапустить приложение

**Hot Reload НЕ сработает!** Нужен полный перезапуск:

```powershell
# Остановите текущее приложение (Ctrl+C в терминале)
# Затем запустите заново:
flutter run -d windows
```

Или в терминале Flutter нажмите:
- **`q`** - выход
- Затем `flutter run -d windows`

---

## 🎉 Ожидаемый результат

После перезапуска и попытки входа вы должны увидеть в консоли:

```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=31113...
📍 Redirect URI: http://localhost:8080/auth
🔗 Callback scheme: http://localhost:8080
✅ Auth result: http://localhost:8080/auth?code=def502008f5edaed...
🔄 Exchanging code for access token...
📥 Token response status: 200 ✅
📥 Token response body: {"token_type":"Bearer","expires_in":31536000,"access_token":"eyJ0eXAi..."}
✅ Access token received successfully! ✅
```

**Главное**: `Token response status: 200` вместо `401`!

---

## ⚠️ Важные замечания

### Безопасность

**Client Secret = секретная информация!**

1. ❌ **НЕ публикуйте** в GitHub
2. ❌ **НЕ делитесь** с другими
3. ✅ **Добавьте в .gitignore** (необязательно для личного проекта)

### Если делаете коммит в Git

Рекомендую добавить в `.gitignore`:
```
# Secrets
lib/core/constants/app_constants.dart
```

Затем используйте `app_constants.example.dart` как шаблон для других разработчиков.

---

## 🐛 Troubleshooting

### Всё ещё ошибка 401?

**Проверьте**:
1. Client Secret скопирован **полностью** (без пробелов в начале/конце)
2. Приложение **полностью перезапущено** (не Hot Reload)
3. Client Secret **правильный** (проверьте на AniList еще раз)

### Ошибка "invalid_request"?

Убедитесь, что в `auth_service.dart` есть строка:
```dart
'client_secret': AppConstants.anilistClientSecret,
```

### Не можете найти Client Secret на AniList?

1. Убедитесь, что вы вошли в аккаунт
2. Перейдите в Settings → Developer
3. Client Secret должен быть виден сразу под Client ID
4. Если не видно - создайте новое приложение

---

## 📝 Что было изменено

### 1. `app_constants.dart`
```dart
// Добавлено:
static const String anilistClientSecret = 'YOUR_CLIENT_SECRET_HERE';
```

### 2. `auth_service.dart`
```dart
body: {
  'grant_type': 'authorization_code',
  'client_id': AppConstants.anilistClientId,
  'client_secret': AppConstants.anilistClientSecret, // ← Добавлено
  'redirect_uri': redirectUri,
  'code': code,
},
```

### 3. Создан `app_constants.example.dart`
Шаблон для других разработчиков

---

## ✅ Контрольный список

- [ ] Открыл https://anilist.co/settings/developer
- [ ] Нашёл Client Secret
- [ ] Скопировал Client Secret
- [ ] Открыл `lib/core/constants/app_constants.dart`
- [ ] Вставил Client Secret вместо `YOUR_CLIENT_SECRET_HERE`
- [ ] Сохранил файл
- [ ] Остановил приложение (Ctrl+C или `q`)
- [ ] Запустил заново: `flutter run -d windows`
- [ ] Попробовал войти
- [ ] Увидел "Token response status: 200" ✅
- [ ] Приложение загрузило профиль ✅

---

**После выполнения всех шагов авторизация заработает на 100%!** 🚀

Если есть вопросы или что-то не работает - проверьте консоль и пришлите вывод.

---

**Дата**: October 10, 2025  
**Версия**: 1.1.0  
**Статус**: ✅ Готово к работе (нужен только Client Secret)
