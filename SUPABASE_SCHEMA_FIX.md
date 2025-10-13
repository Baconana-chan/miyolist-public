# Supabase Schema Fix - snake_case Conversion

## Проблема
При синхронизации данных с Supabase возникала ошибка:
```
PostgrestException: Could not find the 'bannerImage' column of 'users' in the schema cache
```

**Причина:** Flutter модели использовали camelCase (`bannerImage`), а схема Supabase использует snake_case (`banner_image`).

## Решение

Добавлены методы `toSupabaseJson()` во все модели для конвертации полей в формат snake_case, соответствующий схеме PostgreSQL.

### Изменённые файлы

#### 1. `lib/core/models/user_model.dart`
- Добавлен метод `toSupabaseJson()`
- Конвертирует поля: `bannerImage` → `banner_image`, `createdAt` → `created_at`, etc.
- `displayAdultContent` не синхронизируется (нет в таблице users)

#### 2. `lib/core/models/anime_model.dart`
- Добавлен метод `toSupabaseJson()`
- Конвертирует все поля в snake_case для JSONB хранения
- Упрощённая структура title (вместо вложенного объекта)

#### 3. `lib/core/models/media_list_entry.dart`
- Добавлен метод `toSupabaseJson()`
- Конвертирует поля: `mediaId` → `media_id`, `progressVolumes` → `progress_volumes`, etc.
- Использует `media?.toSupabaseJson()` для вложенного объекта

#### 4. `lib/features/auth/presentation/pages/login_page.dart`
- Изменены вызовы:
  - `user.toJson()` → `user.toSupabaseJson()`
  - `e.toJson()` → `e.toSupabaseJson()` для anime/manga списков

## Соответствие схемы Supabase

### Таблица `users`
```sql
- id (BIGINT)
- name (TEXT)
- avatar (TEXT)
- banner_image (TEXT)  ← исправлено
- about (TEXT)
- created_at (TIMESTAMPTZ)  ← исправлено
- updated_at (TIMESTAMPTZ)  ← исправлено
```

### Таблица `anime_lists` / `manga_lists`
```sql
- id (BIGINT)
- user_id (BIGINT)  ← исправлено
- media_id (BIGINT)  ← исправлено
- status (TEXT)
- score (DOUBLE PRECISION)
- progress (INT)
- progress_volumes (INT)  ← исправлено
- repeat (INT)
- notes (TEXT)
- started_at (TIMESTAMPTZ)  ← исправлено
- completed_at (TIMESTAMPTZ)  ← исправлено
- updated_at (TIMESTAMPTZ)  ← исправлено
- synced_at (TIMESTAMPTZ)
- media (JSONB)
```

## Результат

✅ Все данные теперь корректно синхронизируются с Supabase
✅ Сохранена обратная совместимость (`toJson()` остаётся для локального Hive)
✅ Чёткое разделение: `toJson()` для Hive, `toSupabaseJson()` для Supabase

## Версия
- Исправлено в v1.1.1
- Дата: 10 октября 2025
