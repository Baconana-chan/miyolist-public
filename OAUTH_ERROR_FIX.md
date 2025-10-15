# 🔧 Исправление OAuth ошибки "invalid_client"

## ❌ Проблема

При попытке авторизации по ссылке:
```
https://anilist.co/api/v2/oauth/authorize?client_id=31113&redirect_uri=http://localhost:4321/auth/callback&response_type=code
```

Получаете ошибку:
```json
{"error":"invalid_client","message":"Client authentication failed"}
```

## 🔍 Причина

AniList не разрешает redirect URI `http://localhost:4321/auth/callback`, потому что он не добавлен в настройки вашего приложения.

## ✅ Решение 1: Добавить localhost в AniList (для локального тестирования)

### Шаг 1: Откройте настройки AniList
1. Перейдите на https://anilist.co/settings/developer
2. Найдите ваше приложение (Client ID: 31113)
3. Нажмите "Edit"

### Шаг 2: Добавьте localhost redirect URI
В поле **Redirect URI** добавьте:
```
http://localhost:4321/auth/callback
```

**Важно**: Вы можете добавить несколько redirect URI, разделяя их запятой или новой строкой:
```
http://localhost:4321/auth/callback
https://miyo.my/auth/callback
```

### Шаг 3: Сохраните изменения

Теперь локальное тестирование будет работать! ✅

## ✅ Решение 2: Использовать production URL (рекомендуется)

Вместо локального тестирования, сразу используйте production URL:

### В вашем веб-сайте (Astro):

```typescript
// В auth/login.astro или где у вас OAuth
const CLIENT_ID = '31113';
const REDIRECT_URI = 'https://miyo.my/auth/callback';  // Production URL
const AUTH_URL = `https://anilist.co/api/v2/oauth/authorize
  ?client_id=${CLIENT_ID}
  &redirect_uri=${REDIRECT_URI}
  &response_type=code`;
```

### В настройках AniList:

Redirect URI:
```
https://miyo.my/auth/callback
```

## 🧪 Тестирование после исправления

### Локальное тестирование (если добавили localhost):

1. Запустите Astro dev server:
```bash
cd c:\Users\VIC\miyomy
npm run dev
```

2. Откройте в браузере:
```
http://localhost:4321/auth/login
```

3. Вы должны успешно авторизоваться и быть перенаправлены на:
```
http://localhost:4321/auth/callback?code=XXXXX
```

### Production тестирование:

1. Деплой сайта:
```bash
cd c:\Users\VIC\miyomy
npm run build
vercel --prod
```

2. Откройте в браузере:
```
https://miyo.my/auth/login
```

3. После авторизации:
```
https://miyo.my/auth/callback?code=XXXXX
```

## 🔐 Безопасность

### ⚠️ Важно для production:

**НЕ используйте localhost в production!**

Правильная конфигурация для production:
```
Redirect URI: https://miyo.my/auth/callback
```

Правильная конфигурация для development + production:
```
http://localhost:4321/auth/callback
https://miyo.my/auth/callback
```

## 📝 Проверка текущих настроек

### Проверьте в настройках AniList:

1. **Client ID**: 31113 ✅
2. **Client Secret**: (должен быть установлен) ✅
3. **Redirect URI**: 
   - Для dev: `http://localhost:4321/auth/callback`
   - Для prod: `https://miyo.my/auth/callback`

### Проверьте в коде:

#### Flutter (app_constants.dart):
```dart
static const String webAuthUrl = 'https://miyo.my/auth/login';
static const String redirectUriWeb = 'https://miyo.my/auth/callback';

// Для локального тестирования временно измените на:
// static const String webAuthUrl = 'http://localhost:4321/auth/login';
// static const String redirectUriWeb = 'http://localhost:4321/auth/callback';
```

#### Astro веб-сайт:
```typescript
const REDIRECT_URI = process.env.PUBLIC_REDIRECT_URI || 'https://miyo.my/auth/callback';
```

## 🎯 Рекомендуемый workflow

### Для разработки:

1. **Добавьте localhost в AniList settings**
2. **Используйте environment variables** в Astro:

```typescript
// .env.development
PUBLIC_REDIRECT_URI=http://localhost:4321/auth/callback

// .env.production
PUBLIC_REDIRECT_URI=https://miyo.my/auth/callback
```

3. **В Flutter используйте условие**:

```dart
class AppConstants {
  // Development mode
  static const bool isDevelopment = true; // Change to false for production
  
  static String get webAuthUrl => isDevelopment 
    ? 'http://localhost:4321/auth/login'
    : 'https://miyo.my/auth/login';
    
  static String get redirectUriWeb => isDevelopment
    ? 'http://localhost:4321/auth/callback'
    : 'https://miyo.my/auth/callback';
}
```

### Для production:

1. **Установите `isDevelopment = false`**
2. **Деплой сайта на miyo.my**
3. **Убедитесь что redirect URI в AniList правильный**

## ✅ Итоговый чеклист

- [ ] Открыл https://anilist.co/settings/developer
- [ ] Нашел приложение (Client ID: 31113)
- [ ] Добавил redirect URI:
  - [ ] `http://localhost:4321/auth/callback` (для dev)
  - [ ] `https://miyo.my/auth/callback` (для prod)
- [ ] Сохранил изменения
- [ ] Протестировал локально (если нужно)
- [ ] Задеплоил на production
- [ ] Протестировал на production

## 🆘 Если проблема осталась

### Дополнительные проверки:

1. **Проверьте Client ID**:
   ```
   Должен быть: 31113
   ```

2. **Проверьте формат URL**:
   ```
   ✅ Правильно: http://localhost:4321/auth/callback
   ❌ Неправильно: http://localhost:4321/auth/callback/
   ❌ Неправильно: http://localhost:4321/callback
   ```

3. **Проверьте протокол**:
   ```
   ✅ Development: http://localhost:4321
   ✅ Production: https://miyo.my
   ❌ Неправильно: http://miyo.my (должен быть https)
   ```

4. **Очистите кэш браузера** и попробуйте снова

5. **Подождите 1-2 минуты** после изменения настроек на AniList

---

**Готово!** После добавления правильного redirect URI ошибка должна исчезнуть. ✅
