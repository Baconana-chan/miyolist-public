# MiyoList v1.1.2 Release Notes

**Release Date:** October 10, 2025  
**Version:** 1.1.2+3

## 🎉 Major Features

### Edit List Entries
Полноценный диалог для редактирования записей аниме и манги! Теперь можно изменять все параметры прямо в приложении.

**Что можно редактировать:**
- ✅ **Статус** - Watching/Reading, Completed, Planning и т.д.
- ✅ **Оценка** - От 0 до 10 с шагом 0.5
- ✅ **Прогресс** - Эпизоды/главы с кнопками +/- и быстрой кнопкой "Max"
- ✅ **Даты** - Начала просмотра и завершения (с возможностью очистки)
- ✅ **Повторы** - Счётчик rewatches/rereads
- ✅ **Заметки** - Многострочное текстовое поле
- ✅ **Удаление** - С подтверждением

**UI/UX:**
- 🎨 Адаптивный диалог (600px ширина, до 700px высота)
- 🌙 Поддержка тёмной темы
- 📱 Touch-friendly элементы
- ⚡ Мгновенное обновление UI
- 🔔 Уведомления об успехе/ошибках

### Intelligent Sync System
Умная система синхронизации с защитой от спама и автоматической синхронизацией!

**Auto-Sync:**
- ⏱️ Автоматически синхронизирует изменения через 2 минуты после последней правки
- 🔄 Таймер сбрасывается при новых изменениях
- 🤫 Тихая синхронизация в фоне (без уведомлений)
- 📦 Группирует несколько изменений в один запрос

**Sync Cooldown:**
- 🛡️ Кнопка синхронизации неактивна 1 минуту после использования
- ⏲️ Показывает оставшееся время в tooltip (например, "Wait 45s")
- 💫 Анимация загрузки во время синхронизации
- 👁️ Визуальная индикация состояния (серая иконка когда недоступна)

**Background Sync:**
- 📱 Автоматически синхронизирует при сворачивании приложения
- 💾 Сохраняет изменения перед закрытием
- 🎯 Синхронизирует только если есть pending изменения
- 🔕 Не мешает пользователю (silent sync)

## 🔧 Technical Improvements

### New Components
- `EditEntryDialog` widget с полным набором полей
- `_syncWithAniList()` метод с поддержкой auto-sync
- `_markAsModified()` отслеживание изменений
- `_canSync()` проверка cooldown
- `_getSecondsUntilNextSync()` countdown таймер

### State Management
- `WidgetsBindingObserver` для lifecycle events
- `Timer` для auto-sync задержки
- `DateTime` tracking для cooldown и modifications
- Clean disposal всех ресурсов

### LocalStorageService Updates
- `deleteAnimeEntry(int entryId)` - удаление аниме
- `deleteMangaEntry(int entryId)` - удаление манги

## 📝 Changes

### Modified Files
1. **anime_list_page.dart**
   - Added lifecycle observer
   - Implemented auto-sync system
   - Enhanced sync button UI
   - Added modification tracking
   
2. **local_storage_service.dart**
   - Added delete methods for entries
   
3. **pubspec.yaml**
   - Version bump: 1.1.1+2 → 1.1.2+3

## 🎨 UI Updates

### Sync Button States
1. **Idle**: Обычная иконка синхронизации
2. **Syncing**: Circular progress indicator
3. **Cooldown**: Серая иконка, показывает "Wait Xs"
4. **Success**: Зелёное уведомление "✓ Synced successfully"
5. **Error**: Красное уведомление с описанием ошибки

### Edit Dialog
- Responsive layout (адаптируется к размеру экрана)
- Scrollable content area
- Context-aware labels (anime vs manga)
- Icon + text buttons для лучшей UX
- Proper spacing и padding

## 🐛 Bug Fixes
- ✅ Fixed sync button spamming (cooldown protection)
- ✅ Fixed memory leaks (proper timer disposal)
- ✅ Fixed lifecycle observer cleanup
- ✅ Fixed duplicate sync requests

## 📊 Performance

### Memory
- Minimal memory footprint (single Timer instance)
- Clean resource disposal
- No memory leaks

### Battery
- Timer doesn't wake device
- Background sync is best-effort
- No constant polling

### Network
- Cooldown prevents API spam (max 1 sync per minute)
- Auto-sync batches changes (max 1 per 2 minutes)
- Silent failures for non-critical operations

## 🔒 Privacy & Security
- Синхронизация только если cloud sync включён
- Учитывает privacy settings пользователя
- Не отправляет данные для private profiles
- Secure Supabase connection

## 📱 Platform Support
- ✅ **Android**: Full support
- ✅ **iOS**: Full support
- ⚠️ **Desktop**: Limited (lifecycle events may differ)
- ⚠️ **Web**: Limited (no true backgrounding)

## 🚀 Getting Started

### Editing Entries
1. Кликните на любую карточку аниме/манги
2. Измените нужные поля
3. Нажмите "Save"
4. Изменения сохраняются локально
5. Автоматическая синхронизация через 2 минуты

### Manual Sync
1. Нажмите кнопку синхронизации (иконка sync)
2. Дождитесь завершения
3. Кнопка станет неактивна на 1 минуту
4. Tooltip покажет countdown

### Background Sync
1. Отредактируйте записи
2. Сверните приложение
3. Изменения синхронизируются автоматически
4. Никаких дополнительных действий не требуется

## 📚 Documentation
- `docs/EDIT_ENTRY_FEATURE.md` - Полное описание диалога редактирования
- `docs/AUTO_SYNC_FEATURE.md` - Подробности системы синхронизации
- `docs/TODO.md` - Обновлённый список задач
- `CHANGELOG.md` - История изменений

## 🎯 What's Next

### Planned for v1.1.3
- [ ] Search functionality
- [ ] Add to list feature
- [ ] Add to favorites implementation
- [ ] Improved error recovery UI

### Future Enhancements
- [ ] Configurable sync timing in settings
- [ ] Sync queue for offline changes
- [ ] Conflict resolution
- [ ] Retry logic with exponential backoff
- [ ] Last synced time indicator

## 💬 Feedback
Нашли баг или есть предложения? Создайте issue в репозитории!

## 🙏 Contributors
- Main Developer: VIC

---

**Full Changelog:** v1.1.1...v1.1.2
