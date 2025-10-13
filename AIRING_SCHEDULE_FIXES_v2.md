# Исправления в Airing Schedule v2

## Все изменения (12 октября 2025)

### 1. ✅ Удалена кнопка профиля из списков
**Файл:** `lib/features/anime_list/presentation/pages/anime_list_page.dart`

**Проблема:**  
Кнопка профиля в AppBar списка дублировалась с новой Bottom Navigation.

**Решение:**
- Удалена кнопка `IconButton(Icons.person)` из AppBar
- Удалён импорт ProfilePage
- Теперь профиль доступен только через Bottom Navigation

---

### 2. ✅ Исправлен запрос расписания эпизодов
**Файл:** `lib/core/services/airing_schedule_service.dart`

**Проблема #1:** Empty schedule  
API требовал явного указания `userId` в запросе `MediaListCollection`.

**Решение:**
```graphql
query {
  Viewer { id }  # Получаем userId
  watching: MediaListCollection(userId: $userId, type: ANIME, status: CURRENT) {
    lists {
      entries {
        media {
          nextAiringEpisode { airingAt episode }
        }
      }
    }
  }
}
```

**Проблема #2:** Duplicate titles  
В расписании появлялись дубликаты одного и того же аниме.

**Решение:**  
Добавлена дедупликация по `mediaId`:
```dart
final seenIds = <int>{};
for (var entry in allEntries) {
  final mediaId = entry['media']['id'];
  if (seenIds.contains(mediaId)) continue;
  seenIds.add(mediaId);
  // Process episode...
}
```

---

### 3. ✅ Исправлен краш при открытии деталей аниме
**Файл:** `lib/core/models/media_details.dart`

**Проблема:**  
```
type 'String' is not a subtype of type 'MediaStudio' in type cast
```

**Причина:**  
Кэшированные данные содержали студии в разных форматах (строки, Map'ы, объекты).

**Решение:**  
Добавлен универсальный метод `_parseStudios()`:
```dart
static List<MediaStudio>? _parseStudios(dynamic studiosData) {
  // Handle GraphQL format: { nodes: [...] }
  // Handle direct list: [...]
  // Handle mixed types
  // Filter invalid items
}
```

**Преимущества:**
- ✅ Поддержка нескольких форматов
- ✅ Безопасный парсинг без краша
- ✅ Фильтрация невалидных элементов

---

## Тестирование

**Запустите Hot Restart:**
```bash
flutter run -d windows
```
или нажмите `R` в терминале.

**Проверьте:**
1. ✅ Activity tab показывает аниме без дубликатов
2. ✅ Открытие деталей аниме работает без ошибок
3. ✅ Профиль доступен только через Bottom Navigation

---

**Дата:** 12 октября 2025  
**Версия:** v1.5.0 (hotfix)  
**Статус:** ✅ Все исправления применены
