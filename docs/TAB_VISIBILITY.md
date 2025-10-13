# Tab Visibility Settings - MiyoList

**Version:** 1.3.0  
**Last Updated:** January 2025

---

## Overview

**Tab Visibility Settings** позволяет пользователям полностью настроить главный интерфейс приложения, скрывая ненужные вкладки. Это особенно полезно для пользователей, которые используют MiyoList только для отслеживания определенного типа контента.

### Настраиваемые вкладки:
- ✅ **Anime Tab** - Вкладка со списком аниме
- ✅ **Manga Tab** - Вкладка со списком манги
- ✅ **Novels Tab** - Вкладка со списком лайт-новелл

---

## Сценарии использования

### 1. **Только аниме**
```
Пользователь смотрит только аниме, не читает мангу/новеллы.
→ Скрыть вкладки "Manga" и "Novels"
→ Чистый интерфейс с одной вкладкой
```

### 2. **Аниме + Манга**
```
Пользователь смотрит аниме и читает мангу, но не интересуется новеллами.
→ Скрыть вкладку "Novels"
→ Две вкладки вместо трёх
```

### 3. **Только манга**
```
Пользователь читает только мангу.
→ Скрыть вкладки "Anime" и "Novels"
→ Фокус на манга-контенте
```

### 4. **Минималистичный интерфейс**
```
Пользователь хочет максимально простой интерфейс.
→ Оставить только одну нужную вкладку
→ Убрать переключение между вкладками
```

---

## Архитектура

### Модель данных

**Файл:** `lib/core/models/user_settings.dart`

```dart
@HiveType(typeId: 3)
class UserSettings {
  // ... существующие поля ...

  @HiveField(10)
  final bool showAnimeTab; // Показывать вкладку "Anime"

  @HiveField(11)
  final bool showMangaTab; // Показывать вкладку "Manga"

  @HiveField(12)
  final bool showNovelTab; // Показывать вкладку "Novels"

  UserSettings({
    // ... другие параметры ...
    this.showAnimeTab = true,  // По умолчанию: показывать
    this.showMangaTab = true,  // По умолчанию: показывать
    this.showNovelTab = true,  // По умолчанию: показывать
  });
}
```

**Поведение по умолчанию:**
- Все вкладки **видимы по умолчанию**
- Обратная совместимость с существующими установками
- Минимум одна вкладка всегда должна быть видна

---

## User Interface

### Расположение
**Profile → Privacy Settings → Tab Visibility**

### UI компоненты

```
┌─────────────────────────────────────────────┐
│ Privacy Settings                            │
├─────────────────────────────────────────────┤
│                                             │
│ ... (другие настройки) ...                 │
│                                             │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━    │
│                                             │
│ Tab Visibility                              │
│ Choose which tabs to show in the main view │
│                                             │
│ ☑ Anime Tab                                │
│   Show anime list tab                      │
│                                             │
│ ☑ Manga Tab                                │
│   Show manga list tab                      │
│                                             │
│ ☑ Novels Tab                               │
│   Show light novels list tab               │
│                                             │
│ [Cancel]                    [Save]         │
└─────────────────────────────────────────────┘
```

### Состояние предупреждения

Если **все** вкладки отключены (невозможно):

```
┌─────────────────────────────────────────────┐
│ ⚠️ Warning                                  │
│ At least one tab must be visible           │
└─────────────────────────────────────────────┘
```

### Валидация

```dart
Future<void> _saveSettings() async {
  // Проверка что хотя бы одна вкладка видна
  if (!_showAnimeTab && !_showMangaTab && !_showNovelTab) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('At least one tab must be visible'),
        backgroundColor: AppTheme.accentRed,
      ),
    );
    return; // Не сохраняем настройки
  }
  
  // ... продолжение сохранения ...
}
```

---

## Реализация

### Динамическое создание TabController

**Файл:** `lib/features/anime_list/presentation/pages/anime_list_page.dart`

```dart
void _initializeTabController() {
  final settings = widget.localStorageService.getUserSettings();
  int tabCount = 0;
  if (settings?.showAnimeTab ?? true) tabCount++;
  if (settings?.showMangaTab ?? true) tabCount++;
  if (settings?.showNovelTab ?? true) tabCount++;
  
  // Гарантируем минимум одну вкладку
  if (tabCount == 0) tabCount = 1;
  
  _tabController = TabController(length: tabCount, vsync: this);
}
```

### Генерация видимых вкладок

```dart
List<Tab> _getVisibleTabs() {
  final settings = widget.localStorageService.getUserSettings();
  final tabs = <Tab>[];
  
  if (settings?.showAnimeTab ?? true) {
    tabs.add(const Tab(text: 'Anime'));
  }
  if (settings?.showMangaTab ?? true) {
    tabs.add(const Tab(text: 'Manga'));
  }
  if (settings?.showNovelTab ?? true) {
    tabs.add(const Tab(text: 'Light Novels'));
  }
  
  // Гарантируем минимум одну вкладку
  if (tabs.isEmpty) {
    tabs.add(const Tab(text: 'Anime'));
  }
  
  return tabs;
}
```

### Генерация видимых представлений

```dart
List<Widget> _getVisibleTabViews() {
  final settings = widget.localStorageService.getUserSettings();
  final views = <Widget>[];
  
  if (settings?.showAnimeTab ?? true) {
    views.add(_buildListView(_animeList, _selectedAnimeStatus, true, 'anime', _animeFilters));
  }
  if (settings?.showMangaTab ?? true) {
    views.add(_buildListView(_mangaList, _selectedMangaStatus, false, 'manga', _mangaFilters));
  }
  if (settings?.showNovelTab ?? true) {
    views.add(_buildListView(_novelList, _selectedNovelStatus, false, 'novel', _novelFilters));
  }
  
  // Гарантируем минимум одно представление
  if (views.isEmpty) {
    views.add(_buildListView(_animeList, _selectedAnimeStatus, true, 'anime', _animeFilters));
  }
  
  return views;
}
```

### Определение текущего типа медиа

```dart
String _getCurrentMediaType() {
  final settings = widget.localStorageService.getUserSettings();
  final currentTab = _tabController.index;
  int tabIndex = 0;
  
  if (settings?.showAnimeTab ?? true) {
    if (currentTab == tabIndex) return 'anime';
    tabIndex++;
  }
  if (settings?.showMangaTab ?? true) {
    if (currentTab == tabIndex) return 'manga';
    tabIndex++;
  }
  if (settings?.showNovelTab ?? true) {
    if (currentTab == tabIndex) return 'novel';
    tabIndex++;
  }
  
  return 'anime'; // По умолчанию
}
```

---

## Применение изменений

### Уведомление пользователя

После сохранения настроек пользователь получает уведомление:

```dart
if (tabsChanged) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tab visibility updated. Please return to home to see changes.'),
      backgroundColor: AppTheme.accentBlue,
      duration: Duration(seconds: 3),
    ),
  );
}
```

### Перезагрузка интерфейса

Изменения видимости вкладок применяются при:
1. **Возврате на главную страницу** из профиля
2. **Перезапуске приложения**
3. **Переинициализации AnimeListPage**

---

## Примеры использования

### Пример 1: Скрыть манга и новеллы

```dart
// В Privacy Settings Dialog
setState(() {
  _showAnimeTab = true;   // ✅ Показывать
  _showMangaTab = false;  // ❌ Скрыть
  _showNovelTab = false;  // ❌ Скрыть
});

// Результат:
// TabBar будет содержать только одну вкладку "Anime"
```

### Пример 2: Только манга

```dart
setState(() {
  _showAnimeTab = false;  // ❌ Скрыть
  _showMangaTab = true;   // ✅ Показывать
  _showNovelTab = false;  // ❌ Скрыть
});

// Результат:
// TabBar будет содержать только одну вкладку "Manga"
```

### Пример 3: Аниме + Манга

```dart
setState(() {
  _showAnimeTab = true;   // ✅ Показывать
  _showMangaTab = true;   // ✅ Показывать
  _showNovelTab = false;  // ❌ Скрыть
});

// Результат:
// TabBar будет содержать две вкладки: "Anime" и "Manga"
```

---

## Тестовые сценарии

### Тест 1: Все вкладки видны (по умолчанию)
```
Настройка: Свежая установка
Ожидается: 3 вкладки (Anime, Manga, Novels)
Результат: ✅ Pass
```

### Тест 2: Скрыть вкладку Manga
```
Настройка: Снять галочку "Manga Tab"
Действие: Сохранить → Вернуться на главную
Ожидается: 2 вкладки (Anime, Novels)
Результат: ✅ Pass
```

### Тест 3: Только одна вкладка
```
Настройка: Оставить только "Anime Tab"
Действие: Сохранить → Вернуться на главную
Ожидается: 1 вкладка (Anime)
Результат: ✅ Pass
```

### Тест 4: Попытка скрыть все вкладки
```
Настройка: Снять все галочки
Действие: Нажать "Save"
Ожидается: Предупреждение "At least one tab must be visible"
Ожидается: Настройки не сохраняются
Результат: ✅ Pass
```

### Тест 5: Обратная совместимость
```
Настройка: Существующий пользователь обновляется до v1.3.0
Ожидается: Все вкладки видны по умолчанию
Ожидается: Поведение не изменилось
Результат: ✅ Pass
```

### Тест 6: Фильтры с разными вкладками
```
Настройка: Скрыть Manga, оставить Anime и Novels
Действие: Открыть фильтры на вкладке Anime (index 0)
Ожидается: Фильтры для аниме
Действие: Переключиться на Novels (теперь index 1)
Ожидается: Фильтры для новелл
Результат: ✅ Pass
```

---

## API Reference

### UserSettings

```dart
class UserSettings {
  final bool showAnimeTab;   // Показывать вкладку аниме
  final bool showMangaTab;   // Показывать вкладку манги
  final bool showNovelTab;   // Показывать вкладку новелл
  
  // Получить настройки
  final settings = localStorageService.getUserSettings();
  
  // Обновить настройки
  final newSettings = settings.copyWith(
    showAnimeTab: true,
    showMangaTab: false,
    showNovelTab: false,
  );
  await localStorageService.saveUserSettings(newSettings);
}
```

### AnimeListPage методы

```dart
// Инициализировать TabController с нужным количеством вкладок
void _initializeTabController()

// Получить список видимых вкладок
List<Tab> _getVisibleTabs()

// Получить список видимых представлений
List<Widget> _getVisibleTabViews()

// Определить тип медиа текущей вкладки
String _getCurrentMediaType() // returns: 'anime' | 'manga' | 'novel'
```

---

## Troubleshooting

### Проблема: Изменения не применяются

**Симптомы:**
- Изменил настройки, но вкладки не скрылись
- Все 3 вкладки всё ещё видны

**Решение:**
1. Вернитесь на главную страницу (AnimeListPage)
2. Или перезапустите приложение
3. TabController создается заново при инициализации страницы

---

### Проблема: Не могу сохранить настройки

**Симптомы:**
- Кнопка "Save" не работает
- Появляется предупреждение красного цвета

**Диагностика:**
- Проверьте что хотя бы одна вкладка выбрана
- Нельзя скрыть все вкладки одновременно

**Решение:**
- Оставьте минимум одну вкладку видимой
- Выберите главную вкладку которую используете

---

### Проблема: Фильтры открываются для неправильной вкладки

**Симптомы:**
- Открыл фильтры на Manga, но показываются фильтры Anime

**Диагностика:**
```dart
// Проверьте метод _getCurrentMediaType()
debugPrint('Current media type: ${_getCurrentMediaType()}');
```

**Решение:**
- Убедитесь что `_getCurrentMediaType()` правильно определяет тип
- Метод учитывает какие вкладки видны

---

## Преимущества функции

### Для пользователей
- ✅ **Персонализация интерфейса** - настроить под свои нужды
- ✅ **Упрощение навигации** - меньше вкладок = проще
- ✅ **Фокус на нужном контенте** - нет отвлекающих элементов
- ✅ **Чистый UI** - минималистичный дизайн

### Для разработчиков
- ✅ **Гибкая архитектура** - легко добавить новые вкладки
- ✅ **Динамическая генерация UI** - вкладки создаются на лету
- ✅ **Чистый код** - методы для видимости изолированы
- ✅ **Обратная совместимость** - работает с v1.0.0+

### Производительность
- ✅ **Меньше виджетов** - скрытые вкладки не создаются
- ✅ **Быстрее инициализация** - меньше TabView детей
- ✅ **Меньше памяти** - не хранятся неиспользуемые списки

---

## Связанная документация

- [Privacy Settings](./PRIVACY_IMPLEMENTATION_SUMMARY.md) - Система приватности
- [Selective Sync](./SELECTIVE_SYNC.md) - Выборочная синхронизация
- [User Settings](./USER_SETTINGS.md) - Настройки пользователя

---

## Changelog

### v1.3.0 (January 2025)
- ✨ Начальная реализация
- Добавлены 3 настройки видимости вкладок
- UI в Privacy Settings dialog
- Динамическое создание TabController
- Валидация (минимум 1 вкладка)
- Полная обратная совместимость

---

## Будущие улучшения

### Не реализовано (низкий приоритет)

1. **Переупорядочивание вкладок**
   - Drag-and-drop для изменения порядка
   - Сохранение пользовательского порядка
   - "Anime → Novels → Manga" вместо фиксированного

2. **Горячее обновление**
   - Применять изменения без возврата на главную
   - Пересоздавать TabController на лету
   - Сохранять текущую позицию

3. **Предустановки**
   - "Только аниме" - одна кнопка
   - "Аниме + Манга" - одна кнопка
   - "Всё" - одна кнопка

4. **Статистика использования**
   - Показывать какую вкладку чаще используют
   - Предлагать скрыть неиспользуемые вкладки

---

**Время реализации:** ~1.5 часа  
**Сложность:** Средняя  
**Тестовое покрытие:** Ручное тестирование (6 сценариев)  
**Документация:** Полная (TAB_VISIBILITY.md)
