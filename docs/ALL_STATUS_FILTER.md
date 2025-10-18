# All Status Filter Feature

## Overview

Фильтр "All" позволяет просматривать все записи независимо от их статуса просмотра/чтения в едином списке. Это удобно для получения полного обзора всей коллекции пользователя.

## Features

### 1. Фильтр "All"
- **Позиция**: Первый в списке статусов (слева)
- **Функция**: Показывает все записи (Watching, Planning, Completed, Paused, Dropped, Repeating)
- **По умолчанию**: Выбран при открытии страницы

### 2. Визуальное выделение

#### Кнопка фильтра "All"
Когда выбран фильтр "All", кнопка имеет специальное оформление:
- **Градиент**: Синий → Красный (accentBlue → accentRed)
- **Иконка**: `Icons.grid_view` (сетка)
- **Тень**: Синее свечение для акцента
- **Текст**: "All" белым цветом с жирным шрифтом

В невыбранном состоянии:
- **Цвет**: Серый фон (cardGray)
- **Иконка**: Та же иконка сетки
- **Текст**: Серый цвет

#### Индикаторы статусов на карточках
При выбранном фильтре "All" каждая карточка медиа получает **цветную полоску** слева:
- **CURRENT** (Watching/Reading): 🟢 Зелёный (#4CAF50)
- **PLANNING** (Plan to Watch/Read): 🔵 Синий (#2196F3)
- **COMPLETED**: 🟣 Фиолетовый (#9C27B0)
- **PAUSED**: 🟠 Оранжевый (#FF9800)
- **DROPPED**: 🔴 Красный (#F44336)
- **REPEATING** (Rewatching/Rereading): 🩵 Циан (#00BCD4)

Полоска имеет:
- **Ширина**: 4px
- **Высота**: Полная высота карточки
- **Позиция**: Левый край
- **Скругление**: Соответствует скруглению карточки (12px слева)

## Implementation Details

### Changes in anime_list_page.dart

#### 1. Добавлен статус "ALL" в список
```dart
final List<String> _statusList = [
  'ALL',           // Новый статус
  'CURRENT',
  'PLANNING',
  'COMPLETED',
  'PAUSED',
  'DROPPED',
  'REPEATING',
];
```

#### 2. Изменены начальные значения фильтров
```dart
String _selectedAnimeStatus = 'ALL';  // Было 'CURRENT'
String _selectedMangaStatus = 'ALL';  // Было 'CURRENT'
String _selectedNovelStatus = 'ALL';  // Было 'CURRENT'
```

#### 3. Обновлён метод _filterByStatus
```dart
List<MediaListEntry> _filterByStatus(List<MediaListEntry> list, String status) {
  // Если выбран "ALL", не фильтруем по статусу
  var filtered = status == 'ALL' 
      ? list 
      : list.where((entry) => entry.status == status).toList();
  
  // Остальная фильтрация (adult content, search) остаётся
  // ...
}
```

#### 4. Добавлена локализация в _formatStatus
```dart
String _formatStatus(String status, bool isAnime) {
  switch (status) {
    case 'ALL':
      return 'All';  // Новый case
    // ...
  }
}
```

#### 5. Создан метод _buildAllStatusChip
```dart
Widget _buildAllStatusChip(bool isAnime) {
  return GestureDetector(
    onTap: () {
      // Уже выбран, действие не требуется
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.accentBlue, AppTheme.accentRed],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentBlue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grid_view, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          const Text('All', style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          )),
        ],
      ),
    ),
  );
}
```

#### 6. Обновлён itemBuilder для статусов
```dart
itemBuilder: (context, index) {
  final status = _statusList[index];
  final isSelected = status == selectedStatus;
  final isAllStatus = status == 'ALL';
  
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: isAllStatus && isSelected
        ? _buildAllStatusChip(isAnime)  // Специальный виджет для "All"
        : FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAllStatus) ...[
                  const Icon(Icons.grid_view, size: 16),
                  const SizedBox(width: 4),
                ],
                Text(_formatStatus(status, isAnime)),
              ],
            ),
            // ... остальные параметры
            selectedColor: isAllStatus 
                ? AppTheme.accentBlue 
                : AppTheme.accentRed,
          ),
  );
}
```

#### 7. Передача флага showStatusIndicator
```dart
_buildMediaGrid(
  _applyFiltersAndSort(list, selectedStatus, filters),
  isAnime,
  selectedStatus == 'ALL',  // Показывать индикаторы только для "All"
)
```

### Changes in media_list_card.dart

#### 1. Добавлен параметр showStatusIndicator
```dart
class MediaListCard extends StatelessWidget {
  final MediaListEntry entry;
  final VoidCallback onTap;
  final bool showStatusIndicator;  // Новый параметр

  const MediaListCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showStatusIndicator = false,  // По умолчанию false
  });
```

#### 2. Создан метод _getStatusColor
```dart
Color _getStatusColor() {
  switch (entry.status) {
    case 'CURRENT':
      return const Color(0xFF4CAF50); // Green
    case 'PLANNING':
      return const Color(0xFF2196F3); // Blue
    case 'COMPLETED':
      return const Color(0xFF9C27B0); // Purple
    case 'PAUSED':
      return const Color(0xFFFF9800); // Orange
    case 'DROPPED':
      return const Color(0xFFF44336); // Red
    case 'REPEATING':
      return const Color(0xFF00BCD4); // Cyan
    default:
      return AppTheme.textGray;
  }
}
```

#### 3. Добавлен Stack и Positioned индикатор
```dart
child: Stack(
  children: [
    Column(
      // Основное содержимое карточки
      // ...
    ),
    
    // Status indicator (colored strip on the left)
    if (showStatusIndicator)
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: Container(
          width: 4,
          decoration: BoxDecoration(
            color: _getStatusColor(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ),
      ),
  ],
)
```

## User Experience

### Сценарий 1: Просмотр всей коллекции
1. Пользователь открывает страницу списков
2. По умолчанию выбран фильтр "All" с градиентом
3. Видны ВСЕ записи с цветными индикаторами слева
4. Можно быстро оценить распределение по статусам

### Сценарий 2: Переключение на конкретный статус
1. Пользователь нажимает на "Watching"
2. Кнопка "All" теряет градиент, становится серой
3. "Watching" подсвечивается красным
4. Индикаторы статусов исчезают (все записи одного типа)

### Сценарий 3: Возврат к "All"
1. Пользователь нажимает на кнопку "All"
2. Кнопка получает градиент и иконку
3. Показываются все записи
4. Появляются цветные индикаторы

## Visual Design

### Color Palette
- **All Gradient**: Blue (#2196F3) → Red (#F44336)
- **Status Colors**:
  - Green: Active/Current state
  - Blue: Planning/Future
  - Purple: Completed/Finished
  - Orange: Paused/On hold
  - Red: Dropped/Abandoned
  - Cyan: Repeating/Rewatching

### UI Hierarchy
1. **Фильтр "All"** — самый заметный (градиент + тень)
2. **Статусы** — стандартные чипы
3. **Индикаторы** — тонкие, не отвлекают от контента

## Benefits

### Для пользователей
- ✅ **Полный обзор**: Вся коллекция на одном экране
- ✅ **Визуальная навигация**: Цвета помогают быстро находить нужный статус
- ✅ **Гибкость**: Можно быстро переключаться между "All" и конкретными статусами
- ✅ **Интуитивность**: Градиент и иконка делают "All" узнаваемым

### Для разработчиков
- ✅ **Минимальные изменения**: Только фильтрация и визуализация
- ✅ **Переиспользуемость**: `showStatusIndicator` можно использовать в других местах
- ✅ **Читаемость**: Чёткая цветовая схема
- ✅ **Производительность**: Индикаторы рендерятся только при "All"

## Testing

### Test Case 1: Выбор "All"
**Steps:**
1. Открыть страницу списков
2. Убедиться, что выбран "All"
3. Проверить наличие градиента на кнопке
4. Проверить цветные полоски на карточках

**Expected:**
- ✅ Кнопка "All" с градиентом и иконкой
- ✅ Все записи видны
- ✅ Каждая карточка имеет цветной индикатор слева

### Test Case 2: Переключение статусов
**Steps:**
1. Выбрать "Watching"
2. Проверить, что "All" стал серым
3. Проверить отсутствие индикаторов
4. Вернуться к "All"

**Expected:**
- ✅ "Watching" активен (красный)
- ✅ "All" неактивен (серый)
- ✅ Индикаторов нет
- ✅ При возврате к "All" индикаторы появляются

### Test Case 3: Разные вкладки
**Steps:**
1. Проверить "All" на вкладке Anime
2. Переключиться на Manga
3. Проверить "All" на Manga

**Expected:**
- ✅ "All" работает независимо на каждой вкладке
- ✅ Индикаторы соответствуют статусам

## Future Improvements

### 1. Легенда статусов
Добавить легенду с расшифровкой цветов:
```dart
Widget _buildStatusLegend() {
  return Container(
    padding: const EdgeInsets.all(8),
    child: Wrap(
      spacing: 8,
      children: [
        _buildLegendItem('Watching', Colors.green),
        _buildLegendItem('Planning', Colors.blue),
        // ...
      ],
    ),
  );
}
```

### 2. Сортировка по статусу
При выбранном "All" добавить опцию группировки:
- Watching
- Planning
- Completed
- ...

### 3. Статистика
Показывать количество записей каждого статуса:
```
All (245)
Watching (12) | Planning (45) | Completed (180) | ...
```

### 4. Кастомизация цветов
Позволить пользователям выбирать цвета для статусов в настройках.

### 5. Анимация
Добавить плавный переход при появлении/исчезновении индикаторов.

## Related Features

- **Tab Visibility**: Работает независимо
- **Search**: Применяется к отфильтрованным записям
- **Filters**: Применяются после фильтрации по статусу
- **Sort**: Работает с результатами "All"

## Changelog

### v1.4.0 (Current)
- ✨ **NEW**: Добавлен фильтр "All" для просмотра всех статусов
- ✨ **NEW**: Градиентная кнопка для "All"
- ✨ **NEW**: Цветные индикаторы статусов на карточках
- 🎨 **IMPROVED**: Улучшена визуальная навигация
- 🎨 **IMPROVED**: Добавлена иконка сетки для "All"

## Conclusion

Фильтр "All" предоставляет пользователям удобный способ просматривать всю коллекцию с визуальной индикацией статусов. Градиентное оформление и цветные полоски делают навигацию интуитивной и эффективной.
