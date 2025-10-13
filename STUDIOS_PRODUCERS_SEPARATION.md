# Разделение Studios и Producers

## Изменения (12 октября 2025)

### ✅ Разделены студии на Studios (Main) и Producers (Support)

**Проблема:**  
На странице деталей тайтла все студии показывались вместе в одной секции "Studios", без различия между основными студиями (main) и вспомогательными (support/producers).

**Решение:**  
Разделили студии на две категории на основе поля `isMain` из AniList API:
- **Studios** - основные студии, которые непосредственно работали над аниме (isMain: true)
- **Producers** - вспомогательные студии, которые помогали в производстве (isMain: false)

---

## Изменённые файлы

### 1. `lib/core/models/media_details.dart`

**Добавлено поле `isMain` в класс `MediaStudio`:**

```dart
@HiveType(typeId: 21)
class MediaStudio extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isAnimationStudio;

  @HiveField(3)  // Новое поле
  final bool isMain;

  MediaStudio({
    required this.id,
    required this.name,
    required this.isAnimationStudio,
    this.isMain = true, // По умолчанию true для обратной совместимости
  });
}
```

**Обновлён метод `_parseStudios`:**

- Парсит поле `edges` с информацией о `isMain`
- Связывает данные из `edges` с полными данными из `nodes`
- Сохраняет обратную совместимость со старым форматом

```dart
static List<MediaStudio>? _parseStudios(dynamic studiosData) {
  if (studiosData == null) return null;

  // Новая логика: парсинг edges с isMain
  if (studiosData is Map && studiosData.containsKey('edges')) {
    final edges = studiosData['edges'] as List<dynamic>?;
    if (edges != null) {
      for (var edge in edges) {
        final node = edge['node'];
        final isMain = edge['isMain'] as bool? ?? true;
        // ... создание MediaStudio с isMain
      }
    }
  }
  
  // Старая логика для обратной совместимости
  // ...
}
```

---

### 2. `lib/core/services/anilist_service.dart`

**Обновлены GraphQL запросы (3 места):**

Добавлено поле `edges` с `isMain` в запросы студий:

```graphql
studios {
  nodes {
    id
    name
    isAnimationStudio
  }
  edges {
    isMain      # Новое поле
    node {
      id
    }
  }
}
```

**Места изменений:**
1. **Запрос избранного** (строка ~465)
2. **Запрос деталей медиа** (строка ~540)
3. **Глобальный поиск** (строка ~645)

---

### 3. `lib/features/media_details/presentation/pages/media_details_page.dart`

**Разделён UI на две секции:**

#### Studios (Main) - Основные студии

```dart
if (_media!.studios != null && 
    _media!.studios!.whereType<MediaStudio>().any((s) => s.isMain)) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.business, color: AppTheme.textGray, size: 20),
        const SizedBox(width: 12),
        const Text('Studios: ', ...),
        Expanded(
          child: Wrap(
            children: _media!.studios!
                .whereType<MediaStudio>()
                .where((studio) => studio.isMain)
                .map((studio) => /* Ссылка на студию */)
                .toList(),
          ),
        ),
      ],
    ),
  ),
]
```

#### Producers (Support) - Вспомогательные студии

```dart
if (_media!.studios != null && 
    _media!.studios!.whereType<MediaStudio>().any((s) => !s.isMain)) ...[
  Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.people, color: AppTheme.textGray, size: 20),
        const SizedBox(width: 12),
        const Text('Producers: ', ...),
        Expanded(
          child: Wrap(
            children: _media!.studios!
                .whereType<MediaStudio>()
                .where((studio) => !studio.isMain)
                .map((studio) => /* Ссылка на студию */)
                .toList(),
          ),
        ),
      ],
    ),
  ),
]
```

**Отличия:**
- Studios: иконка `Icons.business` (🏢)
- Producers: иконка `Icons.people` (👥)
- Каждая секция показывается только если есть соответствующие студии

---

## Как это работает

### Пример данных от AniList API

```json
{
  "studios": {
    "nodes": [
      { "id": 1, "name": "Studio A", "isAnimationStudio": true },
      { "id": 2, "name": "Studio B", "isAnimationStudio": true },
      { "id": 3, "name": "Producer C", "isAnimationStudio": false }
    ],
    "edges": [
      { "isMain": true, "node": { "id": 1 } },      // Основная студия
      { "isMain": true, "node": { "id": 2 } },      // Основная студия
      { "isMain": false, "node": { "id": 3 } }      // Вспомогательная
    ]
  }
}
```

### Результат на странице

```
🏢 Studios: Studio A, Studio B
👥 Producers: Producer C
```

---

## Преимущества

✅ **Понятнее для пользователя**
- Чётко видно, кто основной создатель аниме
- Видно, кто помогал в производстве

✅ **Соответствует AniList**
- Использует официальные данные из API
- Такое же разделение как на сайте AniList

✅ **Обратная совместимость**
- Старые данные без `isMain` будут показаны как Studios
- Не ломает существующий функционал

✅ **Визуальное различие**
- Разные иконки (🏢 vs 👥)
- Разные заголовки (Studios vs Producers)

---

## Тестирование

### Проверить:

1. ✅ Откройте аниме с несколькими студиями
2. ✅ Проверьте, что основные студии в секции "Studios"
3. ✅ Проверьте, что вспомогательные в секции "Producers"
4. ✅ Проверьте, что обе секции кликабельны
5. ✅ Проверьте навигацию на страницу студии
6. ✅ Проверьте старые аниме (с кэшем без isMain)

### Тестовые сценарии:

**Сценарий 1: Аниме с основными и вспомогательными студиями**
- Ожидание: Две секции - Studios и Producers
- Результат: ✅

**Сценарий 2: Аниме только с основными студиями**
- Ожидание: Только секция Studios
- Результат: ✅

**Сценарий 3: Аниме только со вспомогательными студиями**
- Ожидание: Только секция Producers
- Результат: ✅

**Сценарий 4: Старые данные из кэша (без isMain)**
- Ожидание: Все студии показываются как Studios (isMain = true по умолчанию)
- Результат: ✅

---

## Технические детали

### Hive Migration

**Внимание:** Поле `@HiveField(3)` добавлено в существующий `HiveType(typeId: 21)`.

- Существующие данные продолжат работать
- Новое поле `isMain` будет `true` по умолчанию
- При следующем обновлении данных поле заполнится корректными значениями

### GraphQL API

**Используется:**
- `studios.edges[].isMain` - флаг основной студии
- `studios.nodes[]` - полные данные студий

**Почему два источника:**
- `edges` содержит метаданные (isMain)
- `nodes` содержит полную информацию (name, isAnimationStudio)
- Связываем по `id`

---

**Дата:** 12 октября 2025  
**Версия:** v1.5.0  
**Статус:** ✅ Готово к тестированию
