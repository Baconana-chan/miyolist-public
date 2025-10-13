# UI Improvements - v1.1.1

## Реализованные улучшения

### 1. Адаптивная сетка карточек аниме/манги 📐

**Проблема:** Карточки тайтлов были слишком большими (всего 2 в ряд), что выглядело неэффективно на больших экранах.

**Решение:**
- Изменён `GridView` с фиксированного количества колонок на адаптивную сетку
- Используется `SliverGridDelegateWithMaxCrossAxisExtent` вместо `SliverGridDelegateWithFixedCrossAxisCount`
- Максимальная ширина карточки: 200px (~6 карточек на Full HD 1920px)
- Соотношение сторон: 0.67 (соответствует формату постеров 460x690)

**Файлы:**
- `lib/features/anime_list/presentation/pages/anime_list_page.dart`

**Результат:**
```
До:  2 карточки в ряд (слишком большие)
После: ~6-7 карточек в ряд на Full HD (как на AniList)
```

---

### 2. Просмотр всех избранных 📱

**Проблема:** 
- В профиле избранное показывалось горизонтальным списком
- Максимум видно 12 элементов
- Если избранного больше, остальное скрыто без возможности просмотра

**Решение:**
- Добавлена кнопка "View All (N)" когда элементов больше 12
- Кнопка открывает диалоговое окно с адаптивной сеткой
- В диалоге карточки размером 150px, показываются все элементы
- Горизонтальный список ограничен 12 элементами для производительности

**Файлы:**
- `lib/features/profile/presentation/pages/profile_page.dart`

**Код:**
```dart
if (nodes.length > 12)
  TextButton(
    onPressed: () => _showAllFavorites(title, nodes),
    child: Text('View All (${nodes.length})'),
  ),
```

**Результат:**
- ✅ Favorite Anime (250) → View All button → диалог с полной сеткой
- ✅ Favorite Characters (187) → View All button → диалог с полной сеткой
- ✅ Меньше 12 элементов → кнопка не показывается

---

### 3. Markdown в описании профиля 📝

**Проблема:**
- Описание профиля отображалось как plain text
- HTML теги удалялись простым regex
- Ссылки не работали
- Форматирование терялось

**Решение:**
- Добавлен пакет `flutter_markdown: ^0.7.4+1`
- Добавлен пакет `url_launcher: ^6.3.1` (уже был)
- Создан метод `_convertAniListMarkdown()` для конвертации AniList markup
- Используется `MarkdownBody` вместо `Text`

**Файлы:**
- `lib/features/profile/presentation/pages/profile_page.dart`
- `pubspec.yaml`

**Поддерживаемые форматы:**
- ✅ **Ссылки:** `<a href="url">text</a>` → `[text](url)` (кликабельные)
- ✅ **Переносы строк:** `<br>` → `\n`
- ✅ **HTML entities:** `&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`, `&nbsp;`
- ✅ **Markdown:** Bold, italic, списки (нативная поддержка)
- ✅ **Спойлеры:** `~~~text~~~` → `||text||`

**Код:**
```dart
MarkdownBody(
  data: _convertAniListMarkdown(_user!.about!),
  styleSheet: MarkdownStyleSheet(
    p: Theme.of(context).textTheme.bodyMedium,
    a: Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppTheme.accentBlue,
      decoration: TextDecoration.underline,
    ),
  ),
  onTapLink: (text, href, title) {
    if (href != null) {
      launchUrl(Uri.parse(href));
    }
  },
),
```

**Результат:**
- ✅ Ссылки открываются в браузере
- ✅ Форматирование сохраняется
- ✅ Цвета ссылок (accentBlue) соответствуют темой приложения

---

## Технические детали

### Зависимости
```yaml
dependencies:
  flutter_markdown: ^0.7.4+1  # Поддержка Markdown
  url_launcher: ^6.3.1        # Открытие ссылок
```

### Адаптивность

#### Карточки списков (Anime/Manga)
```dart
SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 200,    // Макс. ширина
  childAspectRatio: 0.67,     // 460x690
  crossAxisSpacing: 12,
  mainAxisSpacing: 16,
)
```

**Расчёт на разных разрешениях:**
- 1920px (Full HD): ~9 карточек
- 1680px: ~8 карточек
- 1440px: ~7 карточек
- 1366px: ~6 карточек
- 1280px: ~6 карточек

#### Favorites Dialog
```dart
SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 150,    // Компактнее
  childAspectRatio: 0.67,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
)
```

### Производительность

**Оптимизации:**
1. Горизонтальный список избранного ограничен 12 элементами: `itemCount: nodes.length.clamp(0, 12)`
2. Полная сетка загружается только при открытии диалога (lazy loading)
3. `CachedNetworkImage` кэширует изображения

---

## Сравнение с AniList

### Размер карточек
- **AniList:** ~6 карточек в ряд на Full HD
- **MiyoList v1.1.1:** ~6-9 карточек (адаптивно) ✅

### Favorites
- **AniList:** Отдельная страница для каждой категории
- **MiyoList v1.1.1:** Диалог с сеткой для всех элементов ✅

### Описание профиля
- **AniList:** Полный Markdown + HTML
- **MiyoList v1.1.1:** Markdown + базовый HTML + ссылки ✅

---

## Будущие улучшения

### Средний приоритет
- [ ] Добавить настройку размера карточек (маленькие/средние/большие)
- [ ] Lazy loading для больших списков (виртуализация)
- [ ] Hover эффекты на карточках (Windows desktop)
- [ ] Анимация открытия favorites dialog

### Низкий приоритет
- [ ] Поддержка YouTube embed в описании
- [ ] Поддержка img tags в описании
- [ ] Custom spoiler tag визуализация
- [ ] Drag-to-reorder для favorites

---

## Changelog

### v1.1.1 - 2025-10-10

#### Added
- ✨ Адаптивная сетка для списков аниме/манги
- ✨ Диалог "View All" для избранного (>12 элементов)
- ✨ Поддержка Markdown в описании профиля
- ✨ Кликабельные ссылки в описании

#### Changed
- 🔄 GridView: фиксированные колонки → адаптивная ширина
- 🔄 Favorites: показываем max 12 → кнопка "View All" для остальных
- 🔄 About: plain text → MarkdownBody с поддержкой ссылок

#### Technical
- 📦 Добавлен пакет `flutter_markdown ^0.7.4+1`
- 📦 Используется `url_launcher ^6.3.1`
- 🔧 Создан метод `_convertAniListMarkdown()` для конвертации markup

---

**Версия:** 1.1.1  
**Дата:** 10 октября 2025  
**Статус:** ✅ Реализовано и протестировано
