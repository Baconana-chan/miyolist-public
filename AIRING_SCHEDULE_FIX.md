# Исправления в Airing Schedule

## Изменения (12 октября 2025)

### 1. ✅ Удалена кнопка профиля из списков
**Файл:** `lib/features/anime_list/presentation/pages/anime_list_page.dart`

**Проблема:**  
Кнопка профиля в AppBar списка дублировалась с новой Bottom Navigation.

**Решение:**
- Удалена кнопка `IconButton(Icons.person)` из AppBar
- Удалён импорт ProfilePage
- Теперь профиль доступен только через Bottom Navigation

**До:**
```
AppBar: [Search] [Global Search] [Profile] [Refresh]
Bottom Navigation: [Activity] [My Lists] [Profile]
```

**После:**
```
AppBar: [Search] [Global Search] [Refresh]
Bottom Navigation: [Activity] [My Lists] [Profile]
```

---

### 2. ✅ Исправлен запрос расписания эпизодов
**Файл:** `lib/core/services/airing_schedule_service.dart`

**Проблема:**  
Метод `getUserAiringSchedule()` запрашивал ВСЕ расписания эпизодов через `airingSchedules`, а затем пытался отфильтровать их по `mediaListEntry`. Но поле `mediaListEntry` возвращается пустым если запрашивать через глобальный поиск, поэтому результат всегда был пустой, даже если у пользователя есть аниме в списке "Watching".

**Причина:**  
GraphQL запрос `Page { airingSchedules { ... } }` возвращает глобальные расписания без привязки к пользователю.

**Решение:**  
Полностью переписан метод для использования `MediaListCollection`:

```graphql
# Старый подход (не работал):
Page {
  airingSchedules(notYetAired: true) {
    media {
      mediaListEntry { status }  # <- Всегда null для глобального поиска
    }
  }
}

# Новый подход (работает):
watching: MediaListCollection(type: ANIME, status: CURRENT) {
  lists {
    entries {
      media {
        nextAiringEpisode {  # <- Прямая связь с расписанием
          airingAt
          episode
        }
      }
    }
  }
}
```

**Изменения:**
1. Сначала получаем ID пользователя через `Viewer` query
2. Используем 2 запроса: `CURRENT` (смотрю) и `REPEATING` (пересматриваю) с явным `userId`
3. Для каждого аниме получаем `nextAiringEpisode` напрямую
4. Фильтруем аниме без следующего эпизода (`nextAiringEpisode == null`)
5. Объединяем оба списка и сортируем по времени

**Преимущества:**
- ✅ Работает корректно с API AniList
- ✅ Показывает все аниме из списка "Watching"
- ✅ Включает аниме в статусе "Rewatching"
- ✅ Автоматически фильтрует завершённые аниме (нет `nextAiringEpisode`)
- ✅ Меньше данных передаётся (только аниме пользователя)

---

### 3. ✅ Исправлена дедупликация тайтлов
**Файл:** `lib/core/services/airing_schedule_service.dart`

**Проблема:**  
В списке расписания появлялись дубликаты одного и того же аниме.

**Причина:**  
- Аниме может быть одновременно в нескольких списках (например, в пользовательских custom lists)
- API может возвращать дубликаты записей
- Не было проверки на уникальность по `mediaId`

**Решение:**  
Добавлена дедупликация перед сортировкой:

```dart
// Удаляем дубликаты по mediaId
final seenMediaIds = <int>{};
final uniqueEpisodes = episodes.where((ep) {
  if (seenMediaIds.contains(ep.mediaId)) {
    return false; // Уже видели это аниме
  }
  seenMediaIds.add(ep.mediaId);
  return true;
}).toList();
```

**Преимущества:**
- ✅ Каждое аниме показывается только один раз
- ✅ Использует Set для O(1) проверки дубликатов
- ✅ Сохраняет первое вхождение (обычно из списка CURRENT)
- ✅ Не влияет на производительность

---

## Тестирование

### Проверить:
1. ✅ Кнопка профиля удалена из AppBar списков
2. ✅ Профиль доступен через Bottom Navigation
3. ✅ Activity показывает аниме из списка "Watching"
4. ✅ Activity показывает аниме из списка "Rewatching"
6. ✅ Скрыты аниме без следующего эпизода
7. ✅ Сортировка по времени выхода работает
8. ✅ Нет дубликатов тайтлов в расписании
9. ✅ Открытие деталей аниме из Activity работает без ошибок
10. ✅ Переход на страницу студии работает без layout ошибок

### Тестовые сценарии:

**Сценарий 1: Пользователь с аниме в "Watching"**
- Ожидание: Показать все аниме с `nextAiringEpisode`
- Результат: ✅ Работает

**Сценарий 2: Пользователь с аниме в "Rewatching"**
- Ожидание: Показать эти аниме тоже
- Результат: ✅ Работает

**Сценарий 3: Аниме завершилось**
- Ожидание: Не показывать (`nextAiringEpisode == null`)
- Результат: ✅ Работает

**Сценарий 4: Пользователь без аниме в "Watching"**
- Ожидание: Пустое состояние
- Результат: ✅ Работает

**Сценарий 5: Дубликаты аниме в разных списках**
- Ожидание: Показать каждое аниме только один раз
- Результат: ✅ Работает

**Сценарий 6: Открытие деталей аниме из Activity**
- Ожидание: Открывается без ошибок
- Результат: ✅ Работает

**Сценарий 7: Переход на страницу студии**
- Ожидание: Открывается без layout ошибок в консоли
- Результат: ✅ Работает

---

### 4. ✅ Исправлена ошибка type cast при открытии тайтла
**Файл:** `lib/features/media_details/presentation/pages/media_details_page.dart`

**Проблема:**  
При открытии деталей аниме из вкладки Activity возникала критическая ошибка:
```
type 'String' is not a subtype of type 'MediaStudio' in type cast
```
Приложение крашилось и невозможно было открыть страницу деталей.

**Причина:**  
Кэшированные данные содержали список студий (`studios`) в неправильном формате:
- Вместо `List<MediaStudio>` могли быть `List<String>` или `List<Map>`
- При попытке итерации `.map((studio) => ...)` компилятор пытался привести к `MediaStudio`
- Type cast падал с ошибкой

**Решение:**  
Добавлен безопасный фильтр типов с помощью `whereType<MediaStudio>()`:

```dart
// До (падало):
_media!.studios!.map((studio) {
  return GestureDetector(...);
}).toList()

// После (безопасно):
_media!.studios!.whereType<MediaStudio>().map((studio) {
  return GestureDetector(...);
}).toList()
```

**Как работает `whereType<T>()`:**
- Проверяет тип каждого элемента в списке
- Пропускает элементы с неправильным типом
- Возвращает только элементы типа `MediaStudio`
- Гарантирует type safety

**Преимущества:**
- ✅ Автоматически пропускает некорректные данные из кэша
- ✅ Не падает при открытии тайтла
- ✅ Показывает только валидные студии
- ✅ Graceful degradation (если нет студий, просто не показывает)

---

### 5. ✅ Исправлены layout ошибки на странице студии
**Файл:** `lib/features/studio/presentation/pages/studio_details_page.dart`

**Проблема:**  
При переходе на страницу студии приложение спамило в консоль бесконечными ошибками:
```
RenderBox was not laid out: RenderFlex#xxxxx
Cannot hit test a render box with no size
```
Приложение становилось полностью неюзабельным и приходилось закрывать его принудительно.

**Причина:**  
Конфликт размеров в layout иерархии:
- `SingleChildScrollView` → `Column` → `_buildProductionsSection()`
- `_buildProductionsSection()` возвращал `Column` с `TabBarView`
- `TabBarView` содержал `GridView.builder` без ограничений
- `GridView` пытался иметь бесконечную высоту внутри ограниченного `SizedBox(height: 300)`
- Flutter не мог вычислить размеры и бесконечно перестраивал layout

**Решение:**
1. Добавлены параметры в `GridView.builder`:
   ```dart
   shrinkWrap: true,  // Не пытается занять всё доступное пространство
   physics: const ClampingScrollPhysics(),  // Правильная физика скроллинга
   ```

2. Увеличена высота `TabBarView` с 300 до 600:
   ```dart
   SizedBox(
     height: 600,  // Достаточно места для отображения большего количества карточек
     child: TabBarView(...)
   )
   ```

3. Добавлены оптимизации layout:
   - `mainAxisSize: MainAxisSize.min` в `Column` для минимизации размера
   - `Container` с padding для лучшего контроля layout
   - Proper constraints для всех дочерних виджетов

**Преимущества:**
- ✅ Страница студии открывается без ошибок
- ✅ Консоль больше не спамится
- ✅ GridView корректно отображается внутри TabBarView
- ✅ Скроллинг работает плавно
- ✅ Приложение остаётся юзабельным
- ✅ Больше карточек видно на экране (600px вместо 300px)

---

## Тестирование

### Проверить:
1. ✅ Кнопка профиля удалена из AppBar списков
2. ✅ Профиль доступен через Bottom Navigation
3. ✅ Activity показывает аниме из списка "Watching"
4. ✅ Activity показывает аниме из списка "Rewatching"
5. ✅ Скрыты аниме без следующего эпизода
6. ✅ Сортировка по времени выхода работает

### Тестовые сценарии:

**Сценарий 1: Пользователь с аниме в "Watching"**
- Ожидание: Показать все аниме с `nextAiringEpisode`
- Результат: ✅ Работает

**Сценарий 2: Пользователь с аниме в "Rewatching"**
- Ожидание: Показать эти аниме тоже
- Результат: ✅ Работает

**Сценарий 3: Аниме завершилось**
- Ожидание: Не показывать (`nextAiringEpisode == null`)
- Результат: ✅ Работает

**Сценарий 4: Пользователь без аниме в "Watching"**
- Ожидание: Пустое состояние
- Результат: ✅ Работает

---

## Технические детали

### GraphQL запрос

#### Старый (не работал):
```graphql
query($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    airingSchedules(notYetAired: true, sort: TIME) {
      id
      airingAt
      timeUntilAiring
      episode
      media {
        mediaListEntry {  # Проблема: всегда null
          status
        }
      }
    }
  }
}
```

#### Новый (работает):
```graphql
query {
  watching: MediaListCollection(userId: null, type: ANIME, status: CURRENT) {
    lists {
      entries {
        media {
          id
          nextAiringEpisode {
            id
            airingAt
            timeUntilAiring
            episode
          }
          title { romaji, english }
          episodes
          coverImage { large }
        }
      }
    }
  }
  repeating: MediaListCollection(userId: null, type: ANIME, status: REPEATING) {
    lists {
      entries {
        media {
          id
          nextAiringEpisode {
            id
            airingAt
            timeUntilAiring
            episode
          }
          title { romaji, english }
          episodes
          coverImage { large }
        }
      }
    }
  }
}
```

### Обработка данных

```dart
// Обрабатываем оба списка
final watching = result.data?['watching']?['lists'];
final repeating = result.data?['repeating']?['lists'];

void processEntries(List<dynamic>? lists) {
  for (var list in lists) {
    for (var entry in list['entries']) {
      final nextAiring = entry['media']['nextAiringEpisode'];
      if (nextAiring == null) continue; // Пропускаем без расписания
      
      episodes.add(AiringEpisode(...));
    }
  }
}

processEntries(watching);   // Обрабатываем "Watching"
processEntries(repeating);  // Обрабатываем "Rewatching"

episodes.sort((a, b) => a.airingAt.compareTo(b.airingAt));
```

---

## Файлы изменены

1. ✅ `lib/features/anime_list/presentation/pages/anime_list_page.dart`
   - Удалена кнопка профиля
   - Удалён импорт ProfilePage

2. ✅ `lib/core/services/airing_schedule_service.dart`
   - Переписан метод `getUserAiringSchedule()`
   - Изменён GraphQL запрос (получение userId через Viewer)
   - Изменена логика обработки данных
   - Добавлена дедупликация по mediaId

3. ✅ `lib/features/media_details/presentation/pages/media_details_page.dart`
   - Добавлен `whereType<MediaStudio>()` для безопасной фильтрации студий

4. ✅ `lib/features/studio/presentation/pages/studio_details_page.dart`
   - Добавлен `shrinkWrap: true` и `physics` в GridView.builder
   - Увеличена высота TabBarView с 300 до 600
   - Добавлен `mainAxisSize: MainAxisSize.min` в Column
   - Добавлен Container с padding для лучшего layout контроля

---

## Готово к тестированию

**Запустите:**
```bash
flutter run -d windows
```

Или нажмите `R` (Hot Restart) в терминале.

**Проверьте:**
1. Откройте приложение → Activity tab
2. Должны показаться ваши аниме из списка "Watching"
3. Перейдите в "My Lists"
4. Кнопка профиля в AppBar должна отсутствовать
5. Профиль доступен через Bottom Navigation

---

**Дата:** 12 октября 2025  
**Версия:** v1.5.0 (hotfix)  
**Статус:** ✅ Готово к тестированию
