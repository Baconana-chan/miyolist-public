# Airing Schedule Feature

## Обзор
Вкладка **Activity** - новая домашняя страница приложения с расписанием выхода эпизодов аниме.

## Структура

### Навигация
Приложение теперь имеет 3 основных раздела:
1. **Activity** 🏠 - Расписание (по умолчанию)
2. **My Lists** 📚 - Списки аниме/манга/новелл
3. **Profile** 👤 - Профиль пользователя

### Вкладка Activity

#### Секции
1. **AIRING TODAY** 🔴
   - Горизонтальная прокрутка карточек
   - Эпизоды, выходящие сегодня
   - Красный бейдж "EP X"
   - Таймер до выхода
   - Привлекательные карточки с обложками

2. **Upcoming Episodes** 📅
   - Вертикальный список
   - Эпизоды на ближайшие недели
   - Информация о времени до выхода
   - День недели или дата выхода

## Модели данных

### AiringEpisode
```dart
class AiringEpisode {
  final int id;
  final int mediaId;
  final int episode;
  final DateTime airingAt;
  final int timeUntilAiring; // секунды
  
  final String title;
  final String? coverImageUrl;
  final int? totalEpisodes;
}
```

**Методы:**
- `getTimeUntilText()` - "2d 5h", "3h 45m", "30m", "Soon"
- `isToday` - проверка выхода сегодня
- `isThisWeek` - проверка выхода на этой неделе

## Сервисы

### AiringScheduleService
```dart
class AiringScheduleService {
  Future<List<AiringEpisode>> getUserAiringSchedule();
  Future<List<AiringEpisode>> getTodayEpisodes();
  Future<List<AiringEpisode>> getThisWeekEpisodes();
  Future<List<AiringEpisode>> getUpcomingEpisodes({int count});
}
```

**Логика фильтрации:**
- Показывает только аниме со статусом `CURRENT` или `REPEATING`
- Сортирует по времени выхода (ближайшие первыми)
- Использует GraphQL AniList API

## UI Компоненты

### 1. ActivityPage
- Главная страница вкладки Activity
- Pull-to-refresh для обновления
- Автообновление каждую минуту для точных таймеров
- Обработка пустых состояний

### 2. TodayReleasesSection
- Секция "AIRING TODAY"
- Горизонтальный скролл карточек
- Градиентный заголовок (красный → оранжевый)
- Счётчик эпизодов

### 3. AiringEpisodeCard
- Карточка отдельного эпизода
- Размеры: 90×130px обложка
- Информация:
  - Название аниме
  - Номер эпизода (X / Total)
  - День/Время выхода
  - Таймер до выхода
- Навигация к MediaDetailsPage

### 4. _TodayEpisodeCard
- Компактная карточка для горизонтального скролла
- Размер: 160×260px
- Оверлеи:
  - Бейдж эпизода (красный, правый верхний угол)
  - Таймер (чёрный полупрозрачный, левый нижний угол)

## Особенности

### Форматирование времени
**До выхода:**
- `> 1 день`: "2d 5h"
- `> 1 час`: "3h 45m"
- `> 1 минута`: "30m"
- `< 1 минута`: "Soon"
- `Вышел`: "Aired"

**Дата выхода:**
- Сегодня: "Today at 14:30"
- Завтра: "Tomorrow"
- < 7 дней: "Mon", "Tue", "Wed"...
- \> 7 дней: "12.10"

### Цветовая индикация
- 🔴 **Красный**: Сегодняшние релизы, бейдж эпизода
- 🔵 **Синий**: Иконки, таймеры
- 🟠 **Оранжевый**: Акценты в градиентах
- ⚫ **Серый**: Будущие даты

### Auto-refresh
- Таймер обновляется каждую минуту
- Точное отображение времени
- Не требует перезагрузки страницы

## Навигация

### BottomNavigationBar
```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icons.home, label: 'Activity'),
    BottomNavigationBarItem(icon: Icons.library_books, label: 'My Lists'),
    BottomNavigationBarItem(icon: Icons.person, label: 'Profile'),
  ],
)
```

### Переходы
- Activity → MediaDetailsPage (по клику на карточку)
- My Lists → Anime/Manga/Novel tabs
- Profile → Settings, Statistics, etc.

## Файловая структура
```
lib/
├── core/
│   ├── models/
│   │   └── airing_episode.dart         # Модель эпизода
│   └── services/
│       └── airing_schedule_service.dart # Сервис расписания
├── features/
│   ├── activity/
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── activity_page.dart   # Главная страница
│   │       └── widgets/
│   │           ├── airing_episode_card.dart        # Карточка эпизода
│   │           └── today_releases_section.dart     # Секция релизов
│   └── main/
│       └── presentation/
│           └── pages/
│               └── main_page.dart        # Контейнер навигации
└── main.dart                            # Точка входа (обновлена)
```

## GraphQL Query

```graphql
query($page: Int, $perPage: Int) {
  Page(page: $page, perPage: $perPage) {
    airingSchedules(notYetAired: true, sort: TIME) {
      id
      airingAt
      timeUntilAiring
      episode
      mediaId
      media {
        id
        title { romaji, english }
        episodes
        coverImage { large }
        mediaListEntry {
          id
          status
          progress
        }
      }
    }
  }
}
```

## Использование

### Для пользователя
1. Открыть приложение → попадаешь на **Activity**
2. Видишь эпизоды, выходящие сегодня (если есть)
3. Прокручиваешь вниз → видишь предстоящие эпизоды
4. Клик на карточку → переход к деталям аниме
5. Pull-to-refresh → обновление расписания

### Условия показа
- Показываются только аниме из списка "Watching" (`CURRENT`)
- Повторный просмотр (`REPEATING`) тоже включен
- Скрыты аниме из других статусов

## Будущие улучшения

### Планируется (v1.6.0+)
1. **Уведомления**
   - Пуш-уведомления за 1 час до выхода
   - Уведомления в день выхода

2. **Календарь**
   - Календарный вид на неделю/месяц
   - Фильтр по дням недели

3. **Социальные функции**
   - Активность друзей
   - Комментарии к эпизодам
   - Рейтинги эпизодов

4. **Расширенные фильтры**
   - Только избранное
   - По жанрам
   - По студиям

## Тестирование

### Проверить
- ✅ Отображение сегодняшних релизов
- ✅ Форматирование таймеров
- ✅ Навигация к MediaDetailsPage
- ✅ Pull-to-refresh
- ✅ Пустое состояние (нет аниме в "Watching")
- ✅ Автообновление каждую минуту
- ✅ Bottom navigation работает

### Тестовые сценарии
```
1. Пользователь БЕЗ аниме в "Watching":
   → Показать пустое состояние с кнопкой Refresh

2. Пользователь С аниме, НО нет выходов сегодня:
   → Только секция "Upcoming Episodes"

3. Пользователь С аниме И есть выходы сегодня:
   → Секция "AIRING TODAY" + "Upcoming Episodes"

4. Клик на карточку:
   → Переход к MediaDetailsPage с правильным mediaId

5. Pull-to-refresh:
   → Обновление данных + анимация загрузки
```

## История изменений

### v1.5.0 (12 октября 2025)
- ✅ Создана вкладка Activity
- ✅ Реализовано расписание выхода эпизодов
- ✅ Добавлена секция "Airing Today"
- ✅ Добавлен список upcoming episodes
- ✅ Реализован AiringScheduleService
- ✅ Создан MainPage с bottom navigation
- ✅ Activity установлена как домашняя страница по умолчанию
