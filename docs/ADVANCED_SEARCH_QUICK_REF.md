# Advanced Search - Quick Reference

## Что было реализовано

### ✅ Новые файлы
1. **`lib/core/models/search_filters.dart`** - Модель фильтров поиска
2. **`lib/core/services/search_history_service.dart`** - Сервис истории поиска
3. **`lib/features/search/presentation/widgets/advanced_search_filters_dialog.dart`** - UI диалог фильтров
4. **`docs/ADVANCED_SEARCH.md`** - Полная документация

### ✅ Обновленные файлы
1. **`lib/core/services/anilist_service.dart`** - Добавлен метод `advancedSearch()`
2. **`docs/TODO.md`** - Отмечена функция как завершенная

### 🎯 Основные возможности

#### Фильтры
- **Жанры** (мультивыбор): 18 жанров
- **Год**: Слайдер от 1940 до текущего года + 1
- **Сезон** (только аниме): Winter, Spring, Summer, Fall
- **Формат**: TV, Movie, Manga, Novel и т.д.
- **Статус**: Finished, Releasing, Not Yet Released, Cancelled, Hiatus
- **Оценка**: Диапазон от 0 до 100
- **Эпизоды/Главы**: Минимум и максимум

#### Сортировка
- По популярности (по умолчанию)
- По оценке
- Тренды
- Алфавит
- Дата обновления
- Дата выхода

#### История поиска
- Автосохранение последних 20 запросов
- Быстрый доступ через чипсы
- Кнопка очистки истории
- Сохранение в Hive

## Как использовать

### Для разработчиков

```dart
// Пример 1: Поиск аниме 2023 года с жанром Action
final results = await anilistService.advancedSearch(
  query: '',
  type: 'ANIME',
  genres: ['Action'],
  year: 2023,
  sortBy: 'SCORE_DESC',
);

// Пример 2: Поиск высокорейтинговой манги
final results = await anilistService.advancedSearch(
  query: 'one piece',
  type: 'MANGA',
  scoreMin: 80,
  sortBy: 'POPULARITY_DESC',
);
```

### Для пользователей

1. Откройте страницу глобального поиска
2. Выберите тип контента (All, Anime, Manga, Character, Staff, Studio)
3. Введите поисковый запрос (необязательно)
4. Нажмите "Advanced Filters" для открытия диалога фильтров
5. Выберите нужные фильтры:
   - Жанры (множественный выбор)
   - Год (слайдер)
   - Сезон (для аниме)
   - Формат
   - Статус
   - Диапазон оценок
   - Диапазон эпизодов/глав
6. Нажмите "Apply Filters"
7. Используйте меню сортировки в AppBar для изменения порядка
8. Нажмите "Search"

## Следующие шаги

### Интеграция с GlobalSearchPage
Файл `global_search_page.dart` нужно обновить для использования новых возможностей:

1. Добавить импорты:
   ```dart
   import '../../../../core/models/search_filters.dart';
   import '../../../../core/services/search_history_service.dart';
   import '../widgets/advanced_search_filters_dialog.dart';
   ```

2. Добавить состояние:
   ```dart
   SearchFilters _filters = SearchFilters();
   SearchHistoryService _searchHistory = SearchHistoryService();
   List<String> _recentSearches = [];
   ```

3. Заменить `_performSearch()` на использование `advancedSearch()`

4. Добавить кнопку "Advanced Filters"

5. Добавить меню сортировки

6. Добавить отображение истории поиска

## Архитектура

```
lib/
├── core/
│   ├── models/
│   │   └── search_filters.dart          (NEW)
│   └── services/
│       ├── anilist_service.dart         (UPDATED)
│       └── search_history_service.dart  (NEW)
└── features/
    └── search/
        └── presentation/
            ├── pages/
            │   └── global_search_page.dart    (TO UPDATE)
            └── widgets/
                └── advanced_search_filters_dialog.dart  (NEW)
```

## GraphQL Query

Метод `advancedSearch()` использует следующий GraphQL запрос:

```graphql
query(
  $search: String,
  $type: MediaType,
  $genre_in: [String],
  $seasonYear: Int,
  $season: MediaSeason,
  $format: MediaFormat,
  $status: MediaStatus,
  $averageScore_greater: Int,
  $averageScore_lesser: Int,
  $episodes_greater: Int,
  $episodes_lesser: Int,
  $chapters_greater: Int,
  $chapters_lesser: Int,
  $sort: [MediaSort]
) {
  Page(perPage: 50) {
    media(...) {
      # Полная информация о медиа
    }
  }
}
```

## Тестирование

Используйте следующие сценарии для тестирования:

1. ✅ Поиск без фильтров
2. ✅ Поиск с одним жанром
3. ✅ Поиск с несколькими жанрами
4. ✅ Поиск с фильтром года
5. ✅ Поиск с фильтром сезона
6. ✅ Поиск с диапазоном оценок
7. ✅ Поиск с диапазоном эпизодов
8. ✅ Комбинированные фильтры
9. ✅ Все варианты сортировки
10. ✅ История поиска (сохранение/загрузка/очистка)

## Известные ограничения

1. Максимум 50 результатов за запрос (ограничение AniList API)
2. История поиска ограничена 20 записями
3. Фильтры недоступны для Character, Staff, Studio (ожидаемое поведение)

## Поддержка

Для вопросов и предложений см.:
- [ADVANCED_SEARCH.md](./ADVANCED_SEARCH.md) - Полная документация
- [TODO.md](./TODO.md) - Дорожная карта функций
