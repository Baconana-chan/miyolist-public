# Notification System Implementation

## Дата: 12 октября 2025
## Версия: v1.5.0

---

## ✅ Реализованные функции

### 1. **Модели данных**
**Файл:** `lib/core/models/notification.dart`

#### AniListNotification
Полная модель уведомления с поддержкой всех типов AniList:
- `AIRING` - Выход нового эпизода
- `ACTIVITY_*` - Лайки, ответы, упоминания в активностях
- `THREAD_*` - Активность на форуме
- `FOLLOWING` - Новые подписчики
- `RELATED_MEDIA_ADDITION` - Добавление новых тайтлов

**Поля:**
- `id`, `type` - Идентификация
- `userId`, `userName`, `userAvatar` - Информация о пользователе
- `mediaId`, `mediaTitle`, `mediaImage` - Информация о медиа
- `episode` - Номер эпизода (для AIRING)
- `activityId` - ID активности
- `threadId`, `threadTitle` - Информация о треде форума
- `context` - Дополнительный контекст
- `createdAt` - Время создания
- `isRead` - Статус прочтения

**Методы:**
- `getTypeIcon()` - Эмодзи для типа (📺, ❤️, 💬, 👤, 🎬)
- `getTypeName()` - Человекочитаемое название категории
- `getFormattedText()` - Форматированный текст уведомления

#### NotificationSettings
Настройки уведомлений по категориям:
- `enabledAiring` - Уведомления о выходе эпизодов
- `enabledActivity` - Активности (лайки, ответы)
- `enabledForum` - Форумные уведомления
- `enabledFollows` - Новые подписчики
- `enabledMedia` - Новые тайтлы

---

### 2. **Сервис уведомлений**
**Файл:** `lib/core/services/notification_service.dart`

**Основные методы:**

#### `fetchNotifications()`
Получает уведомления с AniList API:
```dart
Future<List<AniListNotification>> fetchNotifications({
  int page = 1,
  int perPage = 25,
  List<String>? types,
  bool resetUnreadCount = false,
})
```

**Параметры:**
- `page`, `perPage` - Пагинация
- `types` - Фильтр по типам уведомлений
- `resetUnreadCount` - Сбросить счётчик непрочитанных

**GraphQL запрос:**
- Использует фрагменты для каждого типа уведомления
- `AiringNotification`, `FollowingNotification`, `ActivityMessageNotification`, и т.д.
- Получает полную информацию (пользователи, медиа, треды)

#### `getUnreadCount()`
Получает количество непрочитанных уведомлений:
```dart
Future<int> getUnreadCount()
```

#### `markAllAsRead()`
Помечает все уведомления как прочитанные:
```dart
Future<void> markAllAsRead()
```

#### `getNotificationUrl()`
Генерирует URL для открытия в браузере:
```dart
String getNotificationUrl(AniListNotification notification)
```

**URLs:**
- Airing: `https://anilist.co/anime/{mediaId}`
- Activity: `https://anilist.co/activity/{activityId}`
- Forum: `https://anilist.co/forum/thread/{threadId}`
- Follows: `https://anilist.co/user/{userId}`
- Media: `https://anilist.co/anime/{mediaId}`

#### `shouldOpenInApp()`
Определяет, открывать ли уведомление в приложении:
```dart
bool shouldOpenInApp(AniListNotification notification)
```

**Открываются в приложении:**
- `AIRING` - Переход на страницу тайтла
- `RELATED_MEDIA_ADDITION` - Переход на страницу нового тайтла

**Открываются в браузере:**
- Все остальные (активности, форум, профили)

---

### 3. **UI - Страница уведомлений**
**Файл:** `lib/features/notifications/presentation/pages/notifications_page.dart`

#### Функционал

**AppBar:**
- Заголовок "Notifications"
- Счётчик непрочитанных (красный badge)
- Кнопка настроек

**Вкладки (TabBar):**
1. **All** - Все уведомления
2. **Airing** - Только выходы эпизодов
3. **Activity** - Лайки, ответы, упоминания
4. **Forum** - Форумные уведомления
5. **Follows** - Новые подписчики
6. **Media** - Новые тайтлы

**Карточка уведомления (_NotificationCard):**
- Аватар пользователя или обложка медиа
- Эмодзи иконка типа уведомления
- Форматированный текст
- Относительное время (5m ago, 2h ago, 3d ago)
- Индикатор непрочитанного (синяя точка)
- Клик для открытия

**Состояния с каомодзи:**
- Загрузка: `(｡•́︿•̀｡)` "Loading notifications..."
- Ошибка: `(╥﹏╥)` "Failed to load notifications"
- Пусто: `( ˘▽˘)っ♨` "No notifications"

**Pull-to-refresh:**
- Перезагрузка уведомлений
- Сброс счётчика непрочитанных

#### Диалог настроек (_NotificationSettingsDialog)

Переключатели (Switch) для каждой категории:
- ✅ Airing
- ✅ Activity
- ✅ Forum
- ✅ Follows
- ✅ Media

Сохранение настроек в Hive.

---

### 4. **Навигация**
**Файл:** `lib/features/activity/presentation/pages/activity_page.dart`

Добавлена кнопка уведомлений в AppBar:
```dart
actions: [
  Stack(
    children: [
      IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          // Переход на NotificationsPage
        },
      ),
      if (_unreadCount > 0)
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text('$_unreadCount'),
          ),
        ),
    ],
  ),
],
```

**Функционал:**
- Иконка колокольчика в AppBar
- Красный badge с количеством непрочитанных
- Периодическое обновление счётчика (каждую минуту)

---

## 🎨 Дизайн

### Цветовая схема
- **Background:** AppTheme.background (#1A1A1A)
- **Surface:** AppTheme.surface (#2A2A2A)
- **Accent Blue:** AppTheme.accentBlue (#64B5F6)
- **Accent Red:** AppTheme.accentRed (#E57373) - для badge
- **Text Primary:** AppTheme.textPrimary (#FFFFFF)
- **Text Gray:** AppTheme.textGray (#9E9E9E)

### Типы уведомлений и иконки

| Тип | Иконка | Категория | Пример текста |
|-----|--------|-----------|---------------|
| AIRING | 📺 | Airing | "Episode 1 of Gnosia aired." |
| ACTIVITY_LIKE | ❤️ | Activity | "zerohead liked your activity." |
| ACTIVITY_REPLY | ❤️ | Activity | "User replied to your activity." |
| THREAD_SUBSCRIBED | 💬 | Forum | "NagisaFurukawa commented in your subscribed thread." |
| FOLLOWING | 👤 | Follows | "Positivitybro18 started following you." |
| RELATED_MEDIA_ADDITION | 🎬 | Media | "Blue Lock was recently added to the site." |

---

## 🔧 Технические детали

### GraphQL API
Использует AniList GraphQL API для получения уведомлений:
- Endpoint: `https://graphql.anilist.co`
- Требуется OAuth токен
- Query: `Page { notifications { ... } }`

### Хранение данных
**Hive:**
- Настройки уведомлений: `notification_settings`
- Время последней проверки: `notification_last_check`

### Обработка ссылок
**url_launcher пакет:**
- Открытие внешних ссылок (форум, профили)
- `LaunchMode.externalApplication` - открытие в браузере

**Внутренняя навигация:**
- `Navigator.push()` для страниц тайтлов
- Переход на `MediaDetailsPage`

### Периодическое обновление
**Timer:**
```dart
Timer.periodic(const Duration(minutes: 1), (_) {
  _loadUnreadCount();
});
```

Обновляет счётчик непрочитанных каждую минуту.

---

## 📊 Статистика

**Создано файлов:** 3
- `lib/core/models/notification.dart` (~180 строк)
- `lib/core/services/notification_service.dart` (~220 строк)
- `lib/features/notifications/presentation/pages/notifications_page.dart` (~450 строк)

**Изменено файлов:** 1
- `lib/features/activity/presentation/pages/activity_page.dart` (добавлена кнопка уведомлений)

**Всего кода:** ~850 строк

---

## ✅ Тестирование

### Сценарии для проверки:

1. **Открытие страницы уведомлений**
   - ✅ Нажать на иконку колокольчика
   - ✅ Проверить загрузку уведомлений
   - ✅ Проверить отображение каомодзи при загрузке

2. **Фильтрация по категориям**
   - ✅ Переключаться между вкладками (All, Airing, Activity, Forum, Follows, Media)
   - ✅ Проверить фильтрацию уведомлений

3. **Открытие уведомлений**
   - ✅ Нажать на AIRING уведомление → открывается страница тайтла в приложении
   - ✅ Нажать на ACTIVITY уведомление → открывается браузер с активностью
   - ✅ Нажать на FORUM уведомление → открывается браузер с тредом
   - ✅ Нажать на FOLLOWS уведомление → открывается браузер с профилем

4. **Настройки**
   - ✅ Открыть диалог настроек
   - ✅ Включить/выключить категории
   - ✅ Сохранить настройки

5. **Счётчик непрочитанных**
   - ✅ Проверить отображение badge с числом
   - ✅ Проверить сброс после просмотра

6. **Pull-to-refresh**
   - ✅ Потянуть вниз для перезагрузки
   - ✅ Проверить обновление списка

7. **Пустые состояния**
   - ✅ Проверить каомодзи при пустом списке
   - ✅ Проверить каомодзи при ошибке
   - ✅ Проверить кнопку "Retry"

---

## 🎯 Следующие шаги

### Возможные улучшения:

1. **Push-уведомления** (Post-release)
   - flutter_local_notifications
   - Фоновая проверка новых уведомлений
   - Локальные уведомления

2. **Группировка уведомлений**
   - По дате (Today, Yesterday, This Week)
   - По типу

3. **Действия в уведомлениях**
   - Быстрый ответ на комментарий
   - Лайк прямо из уведомления

4. **Кэширование**
   - Сохранение уведомлений в Hive
   - Офлайн-режим просмотра

5. **Анимации**
   - Fade in для новых уведомлений
   - Swipe to dismiss

---

## 📦 Зависимости

Добавлены в `pubspec.yaml`:
```yaml
dependencies:
  url_launcher: ^6.1.14 # Для открытия ссылок в браузере
  cached_network_image: ^3.3.0 # Уже было
  graphql_flutter: ^5.1.2 # Уже было
  hive: ^2.2.3 # Уже было
```

---

## 🐛 Известные ограничения

1. **Нет пометки конкретного уведомления как прочитанного**
   - AniList API не поддерживает это
   - Только сброс всех непрочитанных

2. **Форумные уведомления только в браузере**
   - AniList не оптимизировал API для форума
   - Невозможно отобразить в приложении

3. **Ограниченная информация о контексте**
   - Для некоторых типов уведомлений API не возвращает полный контекст
   - Например, текст комментария может быть обрезан

---

**Дата завершения:** 12 октября 2025  
**Версия:** v1.5.0  
**Статус:** ✅ Готово к использованию
