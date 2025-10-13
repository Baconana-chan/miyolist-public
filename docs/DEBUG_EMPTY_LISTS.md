# 🐛 Debug Guide - Empty Lists Issue

## Проблема

Приложение запускается, авторизация работает, но:
- ❌ Списки аниме пустые (No entries found)
- ❌ Списки манги пустые
- ❌ Кнопка синхронизации не даёт результата

## Диагностика

### Шаг 1: Проверить консольные логи

После входа в приложение и выбора типа профиля, **проверьте консоль**. Вы должны увидеть:

```
🔄 Starting data sync...
📊 Settings: Public=true, CloudSync=true
👤 Fetching user data from AniList...
✅ User data received: YourUsername
💾 Saving user locally...
✅ User saved locally (ID: 12345)
☁️ Syncing user to Supabase...
✅ User data synced to Supabase
📺 Fetching anime list from AniList...
📺 Anime list received: 50 entries
💾 Saving 50 anime entries locally...
✅ Anime list saved locally
☁️ Syncing anime list to Supabase...
✅ Anime list synced to Supabase
📚 Fetching manga list from AniList...
📚 Manga list received: 20 entries
💾 Saving 20 manga entries locally...
✅ Manga list saved locally
☁️ Syncing manga list to Supabase...
✅ Manga list synced to Supabase
⭐ Fetching favorites from AniList...
💾 Saving favorites locally...
✅ Favorites saved locally
☁️ Syncing favorites to Supabase...
✅ Favorites synced to Supabase
🎉 Data sync completed successfully!
```

### Шаг 2: Определить где ошибка

Если логи **останавливаются** на определённом месте, это укажет на проблему:

#### Остановка на "Fetching user data"
```
👤 Fetching user data from AniList...
❌ Failed to fetch user data
```
**Проблема**: Access token недействителен или истёк
**Решение**: Выйдите и войдите заново

#### Остановка на "Fetching anime list"
```
📺 Fetching anime list from AniList...
📺 Anime list received: 0 entries
```
**Проблема**: API AniList не возвращает данные
**Решение**: 
1. Проверьте, что у вас есть аниме в списке на AniList.co
2. Проверьте настройки приватности на AniList

#### Ошибка "Rate limit reached"
```
⏳ Rate limit reached. Waiting 5000ms before next request...
```
**Проблема**: Слишком много запросов к AniList API
**Решение**: Подождите 1 минуту и попробуйте снова

#### Ошибка GraphQL
```
Error fetching anime list: GraphQL error: ...
```
**Проблема**: Проблема с GraphQL запросом
**Решение**: Проверьте формат запроса в AniListService

---

## Возможные причины пустых списков

### 1. Access Token истёк

**Симптомы**:
- Авторизация проходит, но данные не загружаются
- В консоли: "Failed to fetch user data"

**Решение**:
```dart
// Выйти из приложения
IconButton(
  icon: Icon(Icons.logout),
  onPressed: () async {
    await authService.logout();
    // Вернуться на экран входа
  },
)
```

### 2. На AniList нет аниме/манги

**Симптомы**:
- В консоли: "Anime list received: 0 entries"
- Но на сайте AniList есть аниме

**Решение**:
1. Откройте https://anilist.co
2. Убедитесь, что ваш список не пуст
3. Проверьте настройки приватности (Settings → Privacy)

### 3. Hive не инициализирован

**Симптомы**:
- Ошибка: "HiveError: Box not found"
- Данные не сохраняются локально

**Решение**:
```dart
// В main.dart должно быть:
await LocalStorageService.init();
```

### 4. Неправильная структура данных

**Симптомы**:
- Ошибка: "type 'Null' is not a subtype of type 'String'"
- Данные приходят, но не парсятся

**Решение**: Проверьте `MediaListEntry.fromJson()` и `AnimeModel.fromJson()`

---

## Как проверить сохранённые данные

### Вариант 1: Debug логи

Добавьте в `_loadData()` метод `AnimeListPage`:

```dart
Future<void> _loadData() async {
  print('🔍 Loading data from local storage...');
  
  final animeList = widget.localStorageService.getAnimeList();
  final mangaList = widget.localStorageService.getMangaList();
  final user = widget.localStorageService.getUser();
  
  print('📊 Anime list: ${animeList.length} entries');
  print('📊 Manga list: ${mangaList.length} entries');
  print('👤 User: ${user?.name ?? 'null'}');
  
  setState(() {
    _animeList = animeList;
    _mangaList = mangaList;
    _isLoading = false;
  });
}
```

### Вариант 2: Hive Inspector

Используйте пакет `hive_flutter` для просмотра данных:

```dart
// В main.dart
print('📦 Hive boxes:');
print('  User box: ${Hive.box('user_box').length} items');
print('  Anime box: ${Hive.box('anime_list_box').length} items');
print('  Manga box: ${Hive.box('manga_list_box').length} items');
```

---

## Quick Fix: Принудительная синхронизация

Добавьте кнопку для ручной синхронизации:

```dart
FloatingActionButton(
  onPressed: () async {
    print('🔄 Manual sync triggered');
    
    // Get user
    final user = localStorageService.getUser();
    if (user == null) {
      print('❌ No user found');
      return;
    }
    
    // Fetch from AniList
    final anilistService = AniListService(authService);
    final animeListData = await anilistService.fetchAnimeList(user.id);
    
    print('📺 Fetched: ${animeListData?.length ?? 0} anime');
    
    if (animeListData != null) {
      final animeList = animeListData
          .map((e) => MediaListEntry.fromJson(e))
          .toList();
      
      await localStorageService.saveAnimeList(animeList);
      print('✅ Saved locally');
      
      // Reload
      setState(() {
        _animeList = animeList;
      });
    }
  },
  child: Icon(Icons.sync),
)
```

---

## Следующие шаги

1. ✅ **Перезапустите приложение** (Hot Restart)
2. ✅ **Выйдите** из аккаунта (если уже вошли)
3. ✅ **Войдите заново** и выберите тип профиля
4. ✅ **Проверьте консоль** на наличие debug логов
5. ✅ **Найдите** где останавливается процесс
6. ✅ **Пришлите** логи из консоли для диагностики

---

## Быстрая проверка

Выполните в терминале после входа:

```powershell
# В VS Code Developer Tools Console
# Найдите строки с эмодзи:
# 🔄 🎉 ❌ ✅ 📺 📚 ⭐
```

Если **НЕ видите** `🎉 Data sync completed successfully!`, значит где-то ошибка.

---

**Нужна помощь?** Пришлите логи из консоли, и я помогу найти проблему!
