# Changelog

All notable changes to MiyoList will be documented in this file.

## [1.1.2] - 2025-10-10

### Added
- ✨ **Edit List Entries:** Полноценный диалог редактирования записей списка
  - Status dropdown (контекст-зависимый для anime/manga)
  - Score slider (0-10 с шагом 0.5)
  - Progress counter с кнопками +/-  и "Max"
  - Start/Finish date pickers с возможностью очистки
  - Rewatches/Rereads counter
  - Notes field (многострочное)
  - Delete entry с подтверждением
  - Интеграция с локальным хранилищем
- ✨ **Auto-Sync:** Автоматическая синхронизация после изменений (задержка 2 минуты)
- ✨ **Sync Cooldown:** Кнопка синхронизации неактивна 1 минуту после использования
- ✨ **Background Sync:** Синхронизация при сворачивании приложения (если есть изменения)
- ✨ **Light Novels Tab:** Отдельная вкладка для лайт новелл (визуально отделены от манги)
- 🔄 **Sync Button UI:** Показывает состояние (загрузка, cooldown с таймером, успех/ошибка)
- 📝 Методы удаления в LocalStorageService: `deleteAnimeEntry()`, `deleteMangaEntry()`

### Fixed
- 🐛 **Critical:** Исправлена ошибка type cast в `getFavorites()` при загрузке профиля
  - Ошибка: `type '_Map<dynamic, dynamic>' is not a subtype of type 'Map<String, dynamic>?'`
  - Решение: Безопасное преобразование через `Map<String, dynamic>.from()`

### Changed
- 🔄 Sync button теперь показывает countdown таймер в tooltip
- 🔄 Sync button визуально отличается в разных состояниях (loading spinner, gray icon)
- 🔄 Manga list теперь не включает Light Novels (отдельный таб)
- 🔄 Light Novels синхронизируются вместе с мангой (оба типа MANGA в AniList API)

## [1.1.1] - 2025-10-10

### Added
- ✨ **List Management:** Полноценный диалог редактирования записей списка
  - Выпадающий список статусов (контекстно-зависимый для аниме/манги)
  - Слайдер оценки (0-10 с шагом 0.5)
  - Счётчик прогресса с кнопками инкремента/декремента
  - Выбор даты начала и завершения
  - Счётчик повторных просмотров/перечитываний
  - Поле заметок (многострочное)
  - Удаление записи с подтверждением
  - Интеграция с локальным хранилищем
- 📝 `deleteAnimeEntry()` и `deleteMangaEntry()` в LocalStorageService

### Changed
- 🔄 `_showEditDialog()` теперь использует полноценный виджет EditEntryDialog

## [1.1.1] - 2025-10-10

### Fixed
- 🐛 **Critical:** Приложение больше не крашится при ошибках Supabase
- 🐛 **Critical:** Приватные профили теперь работают без ошибок облака
- 🐛 **Critical:** Исправлена регистрация AnimeModelAdapter в Hive
- � Manga статусы теперь корректные (Reading/Plan to Read вместо Watching/Plan to Watch)
- �🔧 Исправлена race condition в AniListService (GraphQL client initialization)
- 🔧 Исправлено соответствие схемы Supabase (snake_case)

### Added
- ✨ **Offline Mode:** Приложение полностью функционально без облачной синхронизации
- ✨ **UI:** Адаптивная сетка карточек (~6 карточек в ряд на Full HD)
- ✨ **UI:** Диалог "View All" для избранного (когда >12 элементов)
- ✨ **UI:** Поддержка Markdown в описании профиля
- ✨ **UI:** Кликабельные ссылки в описании профиля
- ✨ Local-First архитектура: приоритет локальной базы данных
- 📝 Метод `toSupabaseJson()` для всех моделей (UserModel, AnimeModel, MediaListEntry)
- 📝 Подробное логирование всех этапов синхронизации данных

### Changed
- 🔄 Все вызовы Supabase обёрнуты в try-catch (non-critical errors)
- 🔄 AniListService использует lazy initialization вместо constructor-based
- 🔄 GridView: фиксированные 2 колонки → адаптивная ширина (maxCrossAxisExtent: 200px)
- 🔄 Favorites: горизонтальный список → кнопка "View All" для полного просмотра
- 🔄 About: plain text → MarkdownBody с форматированием
- 🔄 Улучшена обработка ошибок во всех сервисах

### Technical Details
- Убрали `rethrow` из методов синхронизации SupabaseService
- Добавили `_ensureInitialized()` в AniListService для всех GraphQL запросов
- Конвертация полей: `bannerImage` → `banner_image`, `mediaId` → `media_id`, etc.
- Зарегистрирован `AnimeModelAdapter` в LocalStorageService
- Добавлены пакеты: `flutter_markdown ^0.7.4+1`

## [1.1.0] - 2025-10-09

### Added
- ✨ Adult content filtering based on AniList settings
- ✨ Rate limiting for AniList API (30 requests/minute)
- 🔐 Client secret support for OAuth token exchange

### Fixed
- 🐛 OAuth callback scheme fixed for Windows (`http://localhost:8080`)
- 🐛 Supabase initialization errors (nullable client)
- 🐛 Token exchange error ("invalid_client")

## [1.0.0] - 2025-10-08

### Added
- 🎉 Initial release
- ✨ OAuth2 authentication with AniList
- ✨ Private and Public profile modes
- ✨ Local storage with Hive
- ✨ Cloud sync with Supabase (for public profiles)
- ✨ Anime and Manga list management
- ✨ Favorites support
- 🖥️ Windows desktop support
- 📱 Android support (planned)

---

**Легенда:**
- ✨ New feature
- 🐛 Bug fix
- 🔧 Technical improvement
- 🔐 Security
- 🔄 Change
- 📝 Documentation
- 🖥️ Platform support
- 📱 Mobile support
