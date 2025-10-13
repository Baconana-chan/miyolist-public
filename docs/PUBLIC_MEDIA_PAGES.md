# Публичные страницы медиа (Public Media Pages)

## Обзор

Реализована система публичных страниц для просмотра информации об аниме и манге с умным поиском и многоуровневым кешированием.

## Реализованные фичи (7/10)

### ✅ Backend (6/6)

1. **Модели данных** (`lib/core/models/media_details.dart`)
   - `MediaDetails` - полная информация о медиа (28 полей)
   - `MediaCharacter` - персонажи аниме/манги
   - `MediaRelation` - связанные медиа (сиквелы, приквелы и т.д.)
   - Hive typeId: 6, 7, 8 (было 3, 4, 5 - конфликт с UserSettings)

2. **LocalStorageService** - локальное кеширование
   - `saveMediaDetails()` - сохранение медиа в Hive
   - `getMediaDetails()` - получение из локального кеша
   - `getAllCachedMedia()` - все закешированные медиа
   - `clearExpiredCache()` - очистка устаревших (>7 дней)

3. **AniListService** - запросы к AniList API
   - `searchMedia(query, type)` - поиск по названию (до 20 результатов)
   - `getMediaDetails(mediaId)` - детальная информация с персонажами и связями
   - GraphQL запросы с rate limiting

4. **SupabaseService** - облачное кеширование
   - `cacheMediaDetails()` - сохранение в Supabase
   - `searchMedia()` - поиск в облачном кеше (полнотекстовый поиск)
   - `getMediaFromCache()` - получение из облака
   - SQL миграция `003_media_cache.sql` с индексами и RLS

5. **MediaSearchService** - умный трёхуровневый поиск
   - **Уровень 1**: Поиск в Hive (моментально, офлайн)
   - **Уровень 2**: Поиск в Supabase (быстро, онлайн)
   - **Уровень 3**: Запрос к AniList API (медленно, всегда актуально)
   - Автоматическое кеширование результатов на всех уровнях

6. **SQL миграция** (`supabase/migrations/003_media_cache.sql`)
   - Таблица `media_cache` с 28 колонками
   - Full-text search индекс для поиска по названиям
   - Индексы на type, cached_at, title_*
   - RLS политики: чтение всем, запись только авторизованным

### ✅ Frontend (3/4)

7. **SearchPage** (`lib/features/search/presentation/pages/search_page.dart`)
   - Поле поиска с автоочисткой
   - Фильтры по типу: All / Anime / Manga
   - Состояния: empty, loading, results, error
   - Список результатов с карточками
   - Навигация к детальной странице

8. **SearchResultCard** (`lib/features/search/presentation/widgets/search_result_card.dart`)
   - Обложка медиа (80x120)
   - Название (2 строки max)
   - Тип и формат (TV, Movie, Manga и т.д.)
   - Эпизоды/главы/тома
   - Рейтинг (звёзды) и популярность
   - Жанры (первые 3)
   - Адаптивная карточка с InkWell

9. **Кнопка поиска в навигации**
   - Иконка поиска добавлена в AppBar главной страницы
   - Расположена перед кнопкой профиля
   - Открывает SearchPage через Navigator.push

### 🔧 В разработке (1/4)

10. **MediaDetailsPage** (заглушка создана)
    - Сейчас: placeholder с "Coming soon..."
    - Нужно: полноценная страница с баннером, описанием, персонажами, связями

### ❌ Не реализовано (1/4)

11. **Add/Edit функциональность**
    - Добавление нового медиа в список с MediaDetailsPage
    - Редактирование существующей записи через EditEntryDialog
    - Интеграция с AniList API для создания/обновления записей

## Архитектура поиска

```
User Input → MediaSearchService
              ↓
         1. Hive Cache (fast, offline)
              ↓ (not found)
         2. Supabase Cache (medium, online)
              ↓ (not found)
         3. AniList API (slow, always fresh)
              ↓
         Auto-cache results (Hive + Supabase)
              ↓
         Return to UI
```

## Структура файлов

```
lib/
├── core/
│   ├── models/
│   │   ├── media_details.dart           # MediaDetails, MediaCharacter, MediaRelation
│   │   └── media_details.g.dart         # Generated Hive adapters
│   ├── services/
│   │   ├── media_search_service.dart    # 3-level search logic
│   │   ├── local_storage_service.dart   # + media cache methods
│   │   ├── anilist_service.dart         # + searchMedia, getMediaDetails
│   │   └── supabase_service.dart        # + cacheMediaDetails, searchMedia
│   └── constants/
│       └── app_constants.dart           # + mediaCacheBox
├── features/
│   ├── search/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── search_page.dart     # Search UI
│   │       └── widgets/
│   │           └── search_result_card.dart  # Result card
│   └── media_details/
│       └── presentation/
│           └── pages/
│               └── media_details_page.dart  # Placeholder (TODO)
└── supabase/
    └── migrations/
        └── 003_media_cache.sql          # Database schema
```

## Использование

### Поиск медиа

```dart
// В любом месте приложения
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const SearchPage()),
);
```

### Программный поиск

```dart
final searchService = MediaSearchService(
  localStorage: localStorageService,
  supabase: supabaseService,
  anilist: anilistService,
);

// Поиск
final results = await searchService.searchMedia(
  query: 'One Piece',
  type: 'ANIME', // или 'MANGA', или null для всех типов
);

// Получение детальной информации
final details = await searchService.getMediaDetails(21);
```

## База данных Supabase

### Создание таблицы

Выполните миграцию `003_media_cache.sql` в Supabase Dashboard:

```bash
# Или через CLI
supabase migration up
```

### Структура таблицы `media_cache`

| Колонка | Тип | Описание |
|---------|-----|----------|
| id | INTEGER PK | AniList media ID |
| type | TEXT | ANIME / MANGA |
| title_* | TEXT | Названия (romaji, english, native) |
| description | TEXT | Описание |
| cover_image, banner_image | TEXT | URL изображений |
| episodes, chapters, volumes | INTEGER | Количество |
| status | TEXT | FINISHED / RELEASING / etc |
| format | TEXT | TV / MOVIE / MANGA / etc |
| genres | TEXT[] | Массив жанров |
| average_score | NUMERIC | Средний балл (0-100) |
| popularity | INTEGER | Популярность |
| season, season_year | TEXT, INTEGER | Сезон выхода |
| source | TEXT | ORIGINAL / MANGA / etc |
| studios | TEXT[] | Массив студий |
| start_date, end_date | TIMESTAMPTZ | Даты |
| trailer | TEXT | YouTube ID |
| synonyms | TEXT[] | Альтернативные названия |
| duration | INTEGER | Длительность эпизода (мин) |
| cached_at, updated_at | TIMESTAMPTZ | Метаданные кеша |

## Кеширование

### Время жизни кеша
- **Hive**: бессрочно (до `clearExpiredCache()`)
- **Supabase**: 7 дней (проверка через `isCacheExpired()`)

### Очистка кеша

```dart
// Очистить устаревший локальный кеш
await localStorageService.clearExpiredCache(
  maxAge: Duration(days: 7),
);
```

## Следующие шаги

1. **MediaDetailsPage** - полноценная детальная страница
   - Баннер изображение (верх страницы)
   - Обложка и основная информация
   - Описание с HTML парсингом
   - Список персонажей (горизонтальный скролл)
   - Связанные медиа (сиквелы, приквелы)
   - Кнопки Add to List / Edit Entry

2. **Add/Edit интеграция**
   - Проверка: есть ли медиа в списке пользователя
   - Кнопка "Add to List" → диалог выбора статуса
   - Кнопка "Edit" → EditEntryDialog
   - Мутации AniList API для создания/обновления записей

3. **Улучшения поиска**
   - Фильтры по жанрам, году, сезону
   - Сортировка результатов
   - Бесконечная прокрутка (pagination)
   - Сохранение истории поиска

## Известные проблемы

- MediaDetailsPage - пока заглушка
- Нет функционала добавления медиа в список
- Нет обработки больших изображений (баннеры)
- Поиск не поддерживает продвинутые фильтры

## Производительность

- **Локальный кеш (Hive)**: ~1ms
- **Облачный кеш (Supabase)**: ~100-300ms
- **AniList API**: ~500-1500ms
- **Rate Limiting**: 90 запросов/минуту (AniList API)

## Версия

- MiyoList v1.1.2+3
- Добавлено: 2025-01-10
- Статус: В разработке (70% готово)
