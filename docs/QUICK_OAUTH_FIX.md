# ⚡ Быстрое исправление OAuth

## Проблема: 401 "invalid_client"

## Решение за 60 секунд:

### 1️⃣ Получить секрет (30 сек)
https://anilist.co/settings/developer → Скопировать **Client Secret**

### 2️⃣ Вставить в код (20 сек)
Файл: `lib/core/constants/app_constants.dart`

Найти:
```dart
static const String anilistClientSecret = 'YOUR_CLIENT_SECRET_HERE';
```

Заменить на:
```dart
static const String anilistClientSecret = 'ваш_секрет_здесь';
```

### 3️⃣ Перезапустить (10 сек)
```powershell
# Остановить (Ctrl+C)
flutter run -d windows
```

## ✅ Готово!

Теперь в консоли будет:
```
📥 Token response status: 200 ✅
✅ Access token received successfully!
```

---

**P.S.** Полная инструкция: `docs/FINAL_OAUTH_SOLUTION.md`
