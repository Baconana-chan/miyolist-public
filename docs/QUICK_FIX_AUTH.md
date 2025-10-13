# ⚡ Быстрое исправление - Авторизация на Windows

## Что нужно сделать ПРЯМО СЕЙЧАС:

### 1️⃣ Обновить настройки на AniList (2 минуты)

1. Откройте https://anilist.co/settings/developer
2. Найдите приложение с **Client ID: YOUR_CLIENT_ID**
3. В поле **"Redirect URI"** должно быть:
   ```
   http://localhost:8080/auth
   ```
   И/или добавьте второй URI для мобильных устройств:
   ```
   miyolist://auth
   ```
4. Нажмите **"Update"** или **"Save"**

### 2️⃣ Перезапустить приложение

```bash
flutter run -d windows
```

### 3️⃣ Проверить консоль

После нажатия кнопки "Login" вы должны увидеть:

```
🔐 Auth URL: https://anilist.co/api/v2/oauth/authorize?client_id=YOUR_CLIENT_ID...
📍 Redirect URI: http://localhost:8080/auth
🔗 Callback scheme: http
✅ Auth result: http://localhost:8080/auth?code=def5020...
```

## Что изменилось в коде:

- ✅ Автоматическое определение платформы (Windows = localhost, Android = miyolist://)
- ✅ Правильный callback scheme для каждой платформы
- ✅ Debug логи для отладки

## Если не работает:

### Проблема: "Invalid redirect_uri"
👉 URI на AniList не совпадает → Проверьте, точно ли там `http://localhost:8080/auth`

### Проблема: "Callback url scheme must start with http://localhost"
👉 URI на AniList не добавлен → Добавьте `http://localhost:8080/auth`

### Проблема: Браузер открылся, но не вернулся в приложение
👉 Порт 8080 занят → Закройте другие приложения на порту 8080

---

**Готово!** После обновления настроек на AniList всё заработает 🎉
