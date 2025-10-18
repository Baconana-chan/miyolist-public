# Charts and Activity History - v1.1.0 "Botan (牡丹)"

**Status:** In Development  
**Target Release:** v1.1.0 "Botan" (Green - growth and progress)  
**Started:** October 15, 2025  
**Dependencies:** fl_chart ^0.68.0

---

## 📊 Overview

Добавление визуальной аналитики и истории активности для отслеживания прогресса пользователя. Включает интерактивные графики и GitHub-style contribution graph.

---

## 🎯 Features

### 1. Charts and Graphs

#### Genre Distribution Pie Chart
- **Цель:** Показать распределение просмотренного контента по жанрам
- **Тип графика:** Pie Chart (круговая диаграмма)
- **Данные:**
  - Топ-10 жанров из списка пользователя
  - Процентное соотношение
  - Количество тайтлов в жанре
- **Интерактивность:**
  - Hover tooltip с названием жанра и процентом
  - Tap на сектор для фильтрации списка по жанру
  - Легенда с цветами жанров
- **Цвета:** Разные цвета для каждого жанра

#### Score Distribution Histogram
- **Цель:** Показать как пользователь оценивает аниме/мангу
- **Тип графика:** Bar Chart (столбчатая диаграмма)
- **Данные:**
  - Ось X: Оценки от 0 до 10 (с шагом 0.5 или 1.0)
  - Ось Y: Количество тайтлов с данной оценкой
  - Отдельные графики для anime и manga
- **Интерактивность:**
  - Hover tooltip с точным количеством
  - Tap на столбец для списка тайтлов с этой оценкой
  - Средняя оценка линией
- **Цвета:** Градиент от красного (низкие оценки) до зеленого (высокие)

#### Watching History Timeline
- **Цель:** Показать активность просмотра по месяцам/годам
- **Тип графика:** Line Chart (линейный график)
- **Данные:**
  - Ось X: Месяцы/годы
  - Ось Y: Количество завершенных тайтлов
  - Отдельные линии для anime и manga
- **Интерактивность:**
  - Hover tooltip с датой и количеством
  - Zoom in/out по оси X
  - Switch между monthly и yearly view
- **Цвета:** Синий для anime, красный для manga

#### Monthly Activity Heatmap
- **Цель:** Показать активность по дням месяца
- **Тип графика:** Heatmap (тепловая карта)
- **Данные:**
  - 7 строк (дни недели: Mon-Sun)
  - ~5 колонок (недели месяца)
  - Интенсивность цвета = количество действий
- **Интерактивность:**
  - Hover tooltip с датой и количеством действий
  - Month selector
- **Цвета:** От светлого к темному (0-4+ действий)

#### Format Distribution
- **Цель:** Показать какие форматы пользователь предпочитает (TV, Movie, OVA, etc.)
- **Тип графика:** Horizontal Bar Chart
- **Данные:**
  - Форматы: TV, Movie, OVA, ONA, Special, Music
  - Количество тайтлов каждого формата
- **Интерактивность:**
  - Hover tooltip
  - Tap для фильтрации

#### Studio Distribution
- **Цель:** Показать топ-10 студий по количеству просмотренных тайтлов
- **Тип графика:** Horizontal Bar Chart
- **Данные:**
  - Топ-10 студий
  - Количество тайтлов от каждой студии
- **Интерактивность:**
  - Hover tooltip с названием студии
  - Tap на студию для открытия StudioDetailsPage

---

### 2. Activity History (GitHub-style)

#### Year-long Contribution Graph
- **Цель:** Показать ежедневную активность пользователя за год
- **Дизайн:** GitHub contribution graph
- **Структура:**
  ```
  Jan  Feb  Mar  Apr  May  Jun  Jul  Aug  Sep  Oct  Nov  Dec
  M  ░ ░ ▓ ░ █ ░ ░ ░ ▓ ░ ░ ░ ...  (365 ячеек)
  W  ░ ▓ ░ ░ ░ ░ ▓ ░ ░ ░ ░ ░ ...
  F  ░ ░ ░ ░ ▓ ░ ░ ░ ░ ░ ░ ░ ...
  ```
- **Данные:**
  - 365 дней (или 366 для високосного года)
  - Каждая ячейка = 1 день
  - Цвет зависит от количества действий:
    - Уровень 0: Нет действий (серый/прозрачный)
    - Уровень 1: 1-2 действия (светлый)
    - Уровень 2: 3-5 действий (средний)
    - Уровень 3: 6-10 действий (темный)
    - Уровень 4: 11+ действий (самый темный)

#### Tracked Activities
Отслеживаемые типы активности:
1. **Added to list** - Добавление нового тайтла в список
2. **Updated progress** - Обновление прогресса (эпизоды/главы)
3. **Changed status** - Изменение статуса (Watching → Completed)
4. **Updated score** - Изменение оценки
5. **Added to favorites** - Добавление в избранное
6. **Removed from favorites** - Удаление из избранного
7. **Custom list modification** - Добавление/удаление из кастомных списков
8. **Notes updated** - Обновление заметок

#### Interactive Features
- **Hover tooltip:**
  ```
  October 15, 2025
  5 actions on this day
  - Updated progress: 3
  - Changed status: 1
  - Updated score: 1
  ```
- **Click on day:** Открывает диалог с детальной историей действий
- **Year selector:** Dropdown для выбора года (2024, 2025, etc.)
- **Statistics:**
  - Total activity count for year
  - Current streak (consecutive days with activity)
  - Longest streak
  - Most active day/week/month
  - Average actions per day
- **Color scheme:** Следует цветам текущей темы приложения

#### Activity Detail Dialog
При клике на день открывается диалог:
```
Activity on October 15, 2025 (5 actions)

Updated Progress (3)
  • Attack on Titan - Episode 15 → 16
  • One Piece - Episode 1089 → 1090
  • Demon Slayer - Chapter 45 → 46

Changed Status (1)
  • Jujutsu Kaisen: Watching → Completed

Updated Score (1)
  • Spy x Family: 8.5 → 9.0
```

---

## 🏗️ Implementation Plan

### Phase 1: Data Collection & Storage (1-2 days)

#### 1.1 Create Activity Model
```dart
@HiveType(typeId: 10)
class ActivityEntry extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final DateTime timestamp;
  
  @HiveField(2)
  final String activityType; // 'added', 'progress', 'status', 'score', etc.
  
  @HiveField(3)
  final int mediaId;
  
  @HiveField(4)
  final String mediaTitle;
  
  @HiveField(5)
  final String? mediaType; // 'ANIME', 'MANGA'
  
  @HiveField(6)
  final Map<String, dynamic>? details; // Old/new values
  
  ActivityEntry({...});
}
```

#### 1.2 Activity Tracking Service
```dart
class ActivityTrackingService {
  final LocalStorageService _localStorage;
  
  // Log activity when user performs action
  Future<void> logActivity({
    required String activityType,
    required int mediaId,
    required String mediaTitle,
    Map<String, dynamic>? details,
  }) async {
    final activity = ActivityEntry(...);
    await _localStorage.saveActivity(activity);
  }
  
  // Get activities for date range
  Future<List<ActivityEntry>> getActivities({
    DateTime? startDate,
    DateTime? endDate,
  }) async {...}
  
  // Get activity count per day for heatmap
  Future<Map<DateTime, int>> getActivityHeatmapData(int year) async {...}
}
```

#### 1.3 Integrate Activity Logging
Добавить вызовы `logActivity()` во все места, где происходят изменения:
- `updateMediaListEntry()` в AniListService
- `saveUserFavorites()` в LocalStorageService
- Custom list operations
- etc.

---

### Phase 2: Charts Implementation (3-4 days)

#### 2.1 Add fl_chart Dependency
```yaml
dependencies:
  fl_chart: ^0.68.0
```

#### 2.2 Create Statistics Service
```dart
class StatisticsService {
  // Genre distribution
  Future<Map<String, int>> getGenreDistribution({String? type}) async {...}
  
  // Score distribution
  Future<Map<double, int>> getScoreDistribution({String? type}) async {...}
  
  // Watching timeline (monthly)
  Future<Map<DateTime, int>> getMonthlyTimeline({String? type}) async {...}
  
  // Format distribution
  Future<Map<String, int>> getFormatDistribution({String? type}) async {...}
  
  // Studio distribution (top 10)
  Future<List<StudioStat>> getTopStudios({int limit = 10}) async {...}
}
```

#### 2.3 Create Chart Widgets

**Genre Pie Chart Widget:**
```dart
class GenrePieChart extends StatelessWidget {
  final Map<String, int> genreData;
  
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: _buildSections(),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        ...
      ),
    );
  }
}
```

**Score Histogram Widget:**
```dart
class ScoreHistogram extends StatelessWidget {
  final Map<double, int> scoreData;
  
  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: _buildBarGroups(),
        titlesData: _buildTitles(),
        ...
      ),
    );
  }
}
```

**Timeline Chart Widget:**
```dart
class TimelineChart extends StatelessWidget {
  final Map<DateTime, int> timelineData;
  
  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: _buildLines(),
        titlesData: _buildTitles(),
        ...
      ),
    );
  }
}
```

#### 2.4 Create Charts Page
```dart
class ChartsPage extends StatefulWidget {
  @override
  State<ChartsPage> createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  String _selectedType = 'ANIME'; // ANIME, MANGA, ALL
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Statistics & Charts'),
        actions: [
          // Type filter dropdown
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Genre Distribution
            _buildChartSection(
              title: 'Genre Distribution',
              chart: GenrePieChart(...),
            ),
            
            // Score Distribution
            _buildChartSection(
              title: 'Score Distribution',
              chart: ScoreHistogram(...),
            ),
            
            // Watching Timeline
            _buildChartSection(
              title: 'Watching History',
              chart: TimelineChart(...),
            ),
            
            // Format Distribution
            _buildChartSection(
              title: 'Format Distribution',
              chart: FormatBarChart(...),
            ),
            
            // Top Studios
            _buildChartSection(
              title: 'Top Studios',
              chart: StudioBarChart(...),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Phase 3: Activity History Heatmap (3-4 days)

#### 3.1 Create Heatmap Widget
```dart
class ActivityHeatmap extends StatelessWidget {
  final int year;
  final Map<DateTime, int> activityData;
  final Function(DateTime) onDayTap;
  
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HeatmapPainter(
        year: year,
        activityData: activityData,
        colorScheme: _getColorScheme(),
      ),
      child: GestureDetector(
        onTapDown: _handleTap,
      ),
    );
  }
}
```

#### 3.2 Create Heatmap Painter
```dart
class HeatmapPainter extends CustomPainter {
  final int year;
  final Map<DateTime, int> activityData;
  final List<Color> colorScheme;
  
  @override
  void paint(Canvas canvas, Size size) {
    // Draw month labels
    _drawMonthLabels(canvas);
    
    // Draw week day labels (Mon, Wed, Fri)
    _drawWeekDayLabels(canvas);
    
    // Draw 365 cells
    for (int day = 0; day < 365; day++) {
      final date = _getDateForDay(day);
      final activityCount = activityData[date] ?? 0;
      final color = _getColorForCount(activityCount);
      
      _drawCell(canvas, day, color);
    }
  }
  
  Color _getColorForCount(int count) {
    if (count == 0) return colorScheme[0]; // Level 0
    if (count <= 2) return colorScheme[1]; // Level 1
    if (count <= 5) return colorScheme[2]; // Level 2
    if (count <= 10) return colorScheme[3]; // Level 3
    return colorScheme[4]; // Level 4+
  }
}
```

#### 3.3 Create Activity History Page
```dart
class ActivityHistoryPage extends StatefulWidget {
  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  int _selectedYear = DateTime.now().year;
  Map<DateTime, int> _activityData = {};
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity History'),
        actions: [
          // Year selector dropdown
        ],
      ),
      body: Column(
        children: [
          // Statistics Cards
          _buildStatsRow(),
          
          // Activity Heatmap
          ActivityHeatmap(
            year: _selectedYear,
            activityData: _activityData,
            onDayTap: _showDayDetails,
          ),
          
          // Legend
          _buildLegend(),
          
          // Recent Activity List
          Expanded(
            child: _buildRecentActivityList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard('Total Activity', '234'),
        _buildStatCard('Current Streak', '5 days'),
        _buildStatCard('Longest Streak', '23 days'),
      ],
    );
  }
}
```

#### 3.4 Create Activity Detail Dialog
```dart
class ActivityDetailDialog extends StatelessWidget {
  final DateTime date;
  final List<ActivityEntry> activities;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Activity on ${_formatDate(date)}'),
      content: SingleChildScrollView(
        child: Column(
          children: activities.map((activity) {
            return _buildActivityTile(activity);
          }).toList(),
        ),
      ),
    );
  }
}
```

---

### Phase 4: Integration & Polish (2-3 days)

#### 4.1 Add Navigation
- Add "Charts" button to Statistics page
- Add "Activity" tab to Profile page
- Deep linking support

#### 4.2 Export Features
- Export chart as PNG image
- Export activity data as CSV
- Share activity graph on social media

#### 4.3 Performance Optimization
- Cache chart data
- Lazy load old activity data
- Optimize heatmap rendering

#### 4.4 Testing
- Test with large datasets (2000+ entries)
- Test with empty data
- Test year transitions
- Test different themes

---

## 📦 Dependencies

```yaml
dependencies:
  fl_chart: ^0.68.0  # Charts library
  intl: ^0.18.0      # Date formatting (already installed)
  path_provider: ^2.1.0  # For cache (already installed)
```

---

## 🎨 UI/UX Design

### Color Schemes

**Activity Heatmap Levels (Dark Theme):**
- Level 0: `Color(0xFF1E1E1E)` - No activity (dark gray)
- Level 1: `Color(0xFF0D4429)` - Light activity (light green)
- Level 2: `Color(0xFF006D32)` - Medium activity (medium green)
- Level 3: `Color(0xFF26A641)` - High activity (bright green)
- Level 4: `Color(0xFF39D353)` - Very high activity (vibrant green)

**Activity Heatmap Levels (Light Theme):**
- Level 0: `Color(0xFFEBEDF0)` - No activity (light gray)
- Level 1: `Color(0xFF9BE9A8)` - Light activity
- Level 2: `Color(0xFF40C463)` - Medium activity
- Level 3: `Color(0xFF30A14E)` - High activity
- Level 4: `Color(0xFF216E39)` - Very high activity

**Chart Colors:**
- Primary: `AppTheme.accentBlue` (#457B9D)
- Secondary: `AppTheme.accentRed` (#E63946)
- Accent: `AppTheme.accentGold` (#FFC107)

---

## ✅ Success Criteria

- [ ] All 6 chart types implemented and working
- [ ] Activity heatmap displays 365 days correctly
- [ ] Activity tracking logs all user actions
- [ ] Tooltips show accurate data on hover
- [ ] Year selector works for multiple years
- [ ] Statistics cards show correct counts
- [ ] Export features working (PNG, CSV)
- [ ] Performance optimized for large datasets
- [ ] Responsive design for desktop and mobile
- [ ] Follows app theme colors
- [ ] No memory leaks or performance issues

---

## 📝 Notes

### Technical Considerations
- Use `fl_chart` for charts (well-maintained, performant)
- Custom `CustomPainter` for heatmap (better control)
- Cache chart data to avoid recalculation
- Use `Isolate` for heavy calculations if needed

### Future Enhancements (v1.2.0+)
- Animated chart transitions
- More chart types (radar, scatter)
- Comparison with other users
- Activity badges/achievements
- Weekly/monthly email reports
- Push notifications for streak milestones

---

**Author:** GitHub Copilot  
**Date:** October 15, 2025  
**Version:** 1.0
