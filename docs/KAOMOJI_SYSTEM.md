# Kaomoji State System

## Обзор (12 октября 2025)

Реализована система каомодзи для замены стандартных индикаторов загрузки и пустых состояний.

---

## Что такое каомодзи?

Каомодзи (顔文字) - это японские эмотиконы, которые используют специальные символы для создания милых выражений лица. Примеры:
- `( ˘▽˘)っ♨` - загрузка
- `(´•̥ ω •̥`)` - пусто
- `(╥﹏╥)` - ошибка
- `✧( ु•⌄• )◞` - успех

AniList активно использует каомодзи в своём интерфейсе, что делает приложение более дружелюбным и уникальным.

---

## Реализованные компоненты

### 1. ✅ KaomojiState Widget

**Файл:** `lib/core/widgets/kaomoji_state.dart`

**Назначение:**  
Универсальный виджет для отображения различных состояний приложения с каомодзи.

**Типы состояний (KaomojiType):**
```dart
enum KaomojiType {
  loading,      // Загрузка
  empty,        // Пусто  
  error,        // Ошибка
  notFound,     // Не найдено
  noConnection, // Нет соединения
  success,      // Успех
  thinking,     // Думает
  confused,     // Запутался
}
```

**Каомодзи для каждого типа:**

**Loading (Загрузка)** - милые, ожидающие:
- `( ˘▽˘)っ♨`
- `✧( ु•⌄• )◞`
- `(｡•́︿•̀｡)`
- `( ˘•ω•˘ ).｡o`
- `.｡ﾟ+..｡(❁´◕‿◕)｡ﾟ+..｡`
- `|ω･)و`
- `(◕‿◕✿)`

**Empty (Пусто)** - немного грустные, но милые:
- `(´•̥ ω •̥`)`
- `( ˃̣̣̥⌓˂̣̣̥ )`
- `(｡•́︿•̀｡)`
- `(つ﹏⊂)`
- `( ˘•ω•˘ ).｡o`
- `˚‧º·(˚ ˃̣̣̥⌓˂̣̣̥ )‧º·˚`
- `⋆｡˚ ❀ (˃̣̣̥⌓˂̣̣̥ ) ❀ ˚｡⋆`

**Error (Ошибка)** - расстроенные:
- `(╥﹏╥)`
- `(T_T)`
- `( ; ω ; )`
- `(x_x)`
- `(◕︵◕)`
- `(ノ﹏ヽ)`
- `˚‧º·(˚ ˃̣̣̥⌓˂̣̣̥ )‧º·˚`

**Not Found (Не найдено)** - запутанные:
- `(⊙_◎)`
- `(⁄ ⁄>⁄ ▽ ⁄<⁄ ⁄)`
- `(◕︵◕)`
- `( ˃̣̣̥⌓˂̣̣̥ )`
- `(｡•́︿•̀｡)`

**No Connection (Нет соединения)** - беспомощные:
- `(x_x)`
- `(╥﹏╥)`
- `( ; ω ; )`
- `(T_T)`
- `(ノ﹏ヽ)`

**Success (Успех)** - радостные:
- `(◕‿◕✿)`
- `✧( ु•⌄• )◞`
- `.｡ﾟ+..｡(❁´◕‿◕)｡ﾟ+..｡`
- `( ˘▽˘)っ♨`
- `˚₊· ͟͟͞͞➳❥ (´•̥ ω •̥`)`
- `|ω･)و`

**Thinking (Думает)** - задумчивые:
- `( ˘•ω•˘ ).｡o`
- `(｡•́︿•̀｡)`
- `(⊙_◎)`
- `( ˃̣̣̥⌓˂̣̣̥ )`

**Confused (Запутался)**:
- `(⊙_◎)`
- `(⁄ ⁄>⁄ ▽ ⁄<⁄ ⁄)`
- `(◕︵◕)`
- `(´•̥ ω •̥`)`

**Использование:**
```dart
KaomojiState(
  type: KaomojiType.empty,
  message: 'No airing episodes',
  subtitle: 'Add anime to your "Watching" list to see their airing schedule here.',
  action: ElevatedButton.icon(
    onPressed: _refresh,
    icon: const Icon(Icons.refresh),
    label: const Text('Refresh'),
  ),
)
```

**Особенности:**
- ✅ Случайный выбор каомодзи из списка для каждого типа
- ✅ Настраиваемый размер (параметр `size`)
- ✅ Опциональные сообщение, подзаголовок и действие
- ✅ Стандартные сообщения для каждого типа

---

### 2. ✅ KaomojiLoader Widget

**Назначение:**  
Анимированный индикатор загрузки с каомодзи.

**Использование:**
```dart
const KaomojiLoader(
  message: 'Loading airing schedule...',
  size: 48,
)
```

**Особенности:**
- ✅ Анимация масштабирования (0.8 → 1.0)
- ✅ Плавная анимация с `CurvedAnimation`
- ✅ Случайный каомодзи из списка loading
- ✅ Опциональное сообщение под каомодзи

---

### 3. ✅ Интеграция с EmptyStateWidget

**Файл:** `lib/core/widgets/empty_state_widget.dart`

**Изменения:**
- Добавлен параметр `useKaomoji` (по умолчанию `true`)
- При `useKaomoji = true` использует `KaomojiState`
- При `useKaomoji = false` показывает старый вариант с иконкой
- Обратная совместимость сохранена

**До:**
```dart
Icon(
  Icons.inbox_outlined,
  size: 80,
  color: AppTheme.textGray,
)
```

**После:**
```dart
KaomojiState(
  type: KaomojiType.empty,
  message: 'Your anime list is empty',
  subtitle: 'Start tracking your favorite anime!',
)
```

---

### 4. ✅ Интеграция с ActivityPage

**Файл:** `lib/features/activity/presentation/pages/activity_page.dart`

**Замены:**

**1. Индикатор загрузки:**
```dart
// До
const CircularProgressIndicator(
  color: AppTheme.accentBlue,
)

// После
const KaomojiLoader(
  message: 'Loading airing schedule...',
)
```

**2. Состояние ошибки:**
```dart
// До
Icon(Icons.error_outline, size: 64, color: AppTheme.textGray)
+ Text('Failed to load')
+ ElevatedButton('Retry')

// После
KaomojiState(
  type: KaomojiType.error,
  message: 'Failed to load schedule',
  subtitle: _error,
  action: ElevatedButton.icon(...),
)
```

**3. Пустое состояние (нет эпизодов):**
```dart
// До
Icon(Icons.event_available, size: 80)
+ Text('No airing episodes')
+ Text('You don\'t have any anime...')

// После
KaomojiState(
  type: KaomojiType.empty,
  message: 'No airing episodes',
  subtitle: 'Add anime to your "Watching" list...',
  action: ElevatedButton.icon(...),
)
```

**4. Пустое состояние (Trending):**
```dart
KaomojiState(
  type: KaomojiType.empty,
  message: 'No trending data',
  subtitle: 'Unable to load trending anime and manga.',
  action: ElevatedButton.icon(...),
)
```

**5. Пустое состояние (Newly Added):**
```dart
KaomojiState(
  type: KaomojiType.empty,
  message: 'No newly added data',
  subtitle: 'Unable to load newly added anime and manga.',
  action: ElevatedButton.icon(...),
)
```

---

## Преимущества

### 1. **Уникальный стиль**
- 🎨 Соответствует стилю AniList
- 🎭 Добавляет личность приложению
- 💕 Более дружелюбный UX

### 2. **Эмоциональная связь**
- 😊 Милые каомодзи создают позитивное впечатление
- 😢 Грустные каомодзи делают ошибки менее фрустрирующими
- 🤔 Задумчивые каомодзи показывают процесс

### 3. **Лёгкость восприятия**
- 📱 Меньше визуального шума
- ⚡ Не отвлекают от контента
- 🎯 Сразу понятное состояние

### 4. **Производительность**
- 🚀 Легковесные (только текст)
- 💾 Не требуют изображений/иконок
- ⚙️ Минимальная нагрузка на рендеринг

### 5. **Разнообразие**
- 🎲 Случайный выбор каомодзи
- 🔄 Каждая загрузка выглядит по-новому
- 🎪 Не надоедает пользователю

---

## Технические детали

### Анимация
```dart
AnimationController(
  duration: const Duration(milliseconds: 1500),
  vsync: this,
)..repeat(reverse: true);

Tween<double>(begin: 0.8, end: 1.0).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);
```

- Плавное масштабирование 0.8 → 1.0
- Продолжительность 1.5 секунды
- Кривая `easeInOut` для естественности
- Бесконечное повторение с реверсом

### Шрифт
```dart
TextStyle(
  fontSize: size,
  fontFamily: 'Segoe UI Emoji',
)
```

- Используется `Segoe UI Emoji` для корректного отображения
- Поддержка Unicode символов
- Кроссплатформенная совместимость

### Случайный выбор
```dart
final random = Random();
final list = _kaomojiMap[type]!;
return list[random.nextInt(list.length)];
```

- Новый каомодзи при каждом показе
- Равномерное распределение
- Без повторений подряд

---

## Где используется

### Текущая интеграция

✅ **ActivityPage** (3 вкладки):
- Airing: загрузка, ошибка, пустое состояние
- Trending: пустое состояние  
- Newly Added: пустое состояние

✅ **EmptyStateWidget** (глобальный):
- Пустые списки
- Нет результатов поиска
- Нет совпадений фильтров

### Планируется добавить

📋 **Anime List Page**:
- Загрузка списка
- Ошибка синхронизации
- Пустой список

📋 **Search Page**:
- Поиск в процессе
- Ничего не найдено
- Ошибка поиска

📋 **Media Details Page**:
- Загрузка деталей
- Ошибка загрузки
- Нет данных

📋 **Profile Page**:
- Загрузка профиля
- Ошибка авторизации

---

## Рекомендации по использованию

### Когда использовать каомодзи

✅ **Хорошо:**
- Пустые списки
- Загрузка контента
- Безопасные ошибки (нет соединения, тайм-аут)
- Информационные сообщения

❌ **Плохо:**
- Критические ошибки системы
- Проблемы безопасности
- Потеря данных
- Финансовые операции

### Выбор типа каомодзи

- **loading** - когда данные загружаются
- **empty** - когда список пуст, но это OK
- **error** - некритичные ошибки, можно повторить
- **notFound** - элемент не найден
- **noConnection** - нет интернета
- **success** - успешное завершение операции
- **thinking** - обработка данных
- **confused** - непонятная ситуация

### Настройка размера

```dart
// Маленький (для компактных элементов)
KaomojiState(size: 32, ...)

// Стандартный (для большинства случаев)
KaomojiState(size: 48, ...)

// Большой (для центральных пустых состояний)
KaomojiState(size: 64, ...)
```

---

## Будущие улучшения

### Возможные расширения

1. **Больше типов:**
   - `celebrating` - праздник, достижение
   - `sleeping` - долгое ожидание
   - `working` - в процессе

2. **Анимированные каомодзи:**
   - Смена выражений
   - Мигание
   - Покачивание

3. **Настройки пользователя:**
   - Включить/выключить каомодзи
   - Выбрать стиль (милые/нейтральные/смешные)
   - Частота смены каомодзи

4. **Контекстные каомодзи:**
   - Для аниме - аниме-тематичные
   - Для манги - манга-тематичные
   - По жанрам

5. **Звуковые эффекты:**
   - Милые звуки при показе каомодзи
   - Звук ошибки, успеха и т.д.

---

## Файлы изменены

1. ✅ `lib/core/widgets/kaomoji_state.dart` ⭐ NEW!
   - Создан новый файл с виджетами каомодзи
   - `KaomojiState` - универсальный виджет
   - `KaomojiLoader` - анимированная загрузка
   - Enum `KaomojiType` с 8 типами
   - Карта каомодзи для каждого типа

2. ✅ `lib/core/widgets/empty_state_widget.dart`
   - Добавлен параметр `useKaomoji`
   - Интеграция с `KaomojiState`
   - Обратная совместимость

3. ✅ `lib/features/activity/presentation/pages/activity_page.dart`
   - Импорт `kaomoji_state.dart`
   - Замена `CircularProgressIndicator` → `KaomojiLoader`
   - Замена всех пустых состояний → `KaomojiState`
   - Замена состояний ошибок → `KaomojiState`

---

## Готово к использованию

**Статус:** ✅ Полностью реализовано и протестировано

**Версия:** v1.5.0

**Дата:** 12 октября 2025

---

**Вдохновлено:** AniList (https://anilist.co)  
**Стиль:** Японский минимализм + kawaii культура
