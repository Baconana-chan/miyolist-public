# Manga Status Labels Fix

## Проблема
В разделе Manga использовались те же названия статусов, что и для Anime:
- ❌ "Watching" вместо "Reading"
- ❌ "Plan to Watch" вместо "Plan to Read"
- ❌ "Rewatching" вместо "Rereading"

## Решение

Обновлён метод `_formatStatus()` для учёта типа медиа (Anime/Manga).

### Изменения в коде

**Файл:** `lib/features/anime_list/presentation/pages/anime_list_page.dart`

```dart
// Было:
String _formatStatus(String status) {
  switch (status) {
    case 'CURRENT':
      return 'Watching';
    case 'PLANNING':
      return 'Plan to Watch';
    case 'REPEATING':
      return 'Rewatching';
    // ...
  }
}

// Стало:
String _formatStatus(String status, bool isAnime) {
  switch (status) {
    case 'CURRENT':
      return isAnime ? 'Watching' : 'Reading';
    case 'PLANNING':
      return isAnime ? 'Plan to Watch' : 'Plan to Read';
    case 'REPEATING':
      return isAnime ? 'Rewatching' : 'Rereading';
    // ...
  }
}
```

## Соответствие статусов

### Anime Tab
| Status      | Label           |
|-------------|-----------------|
| CURRENT     | Watching        |
| PLANNING    | Plan to Watch   |
| COMPLETED   | Completed       |
| PAUSED      | Paused          |
| DROPPED     | Dropped         |
| REPEATING   | Rewatching      |

### Manga Tab
| Status      | Label           |
|-------------|-----------------|
| CURRENT     | **Reading**     |
| PLANNING    | **Plan to Read**|
| COMPLETED   | Completed       |
| PAUSED      | Paused          |
| DROPPED     | Dropped         |
| REPEATING   | **Rereading**   |

## Результат

✅ Anime статусы: Watching, Plan to Watch, Rewatching  
✅ Manga статусы: Reading, Plan to Read, Rereading  
✅ Универсальные: Completed, Paused, Dropped (одинаковые для обоих)

## Версия
- Исправлено в v1.1.1
- Дата: 10 октября 2025
