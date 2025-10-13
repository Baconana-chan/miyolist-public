import 'package:hive/hive.dart';
import '../models/search_filters.dart';

/// Сервис для управления историей поиска
class SearchHistoryService {
  static const String _boxName = 'search_history';
  static const int _maxHistoryItems = 20;
  
  Box<dynamic>? _box;
  
  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }
  
  /// Добавить запрос в историю
  Future<void> addToHistory(String query, {SearchFilters? filters}) async {
    if (query.trim().isEmpty) return;
    
    final history = await getHistory();
    
    // Удаляем дубликаты
    history.removeWhere((item) => item.query.toLowerCase() == query.toLowerCase());
    
    // Добавляем новый запрос в начало
    history.insert(0, SearchHistoryItem(
      query: query,
      timestamp: DateTime.now(),
      filters: filters,
    ));
    
    // Ограничиваем размер истории
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    // Сохраняем в Hive
    final jsonList = history.map((item) => item.toJson()).toList();
    await _box?.put('history', jsonList);
  }
  
  /// Получить историю поиска
  Future<List<SearchHistoryItem>> getHistory() async {
    final jsonList = _box?.get('history') as List<dynamic>?;
    
    if (jsonList == null) return [];
    
    return jsonList
        .map((json) => SearchHistoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  /// Получить недавние запросы (последние 5)
  Future<List<String>> getRecentSearches() async {
    final history = await getHistory();
    return history
        .take(5)
        .map((item) => item.query)
        .toList();
  }
  
  /// Удалить запрос из истории
  Future<void> removeFromHistory(String query) async {
    final history = await getHistory();
    history.removeWhere((item) => item.query == query);
    
    final jsonList = history.map((item) => item.toJson()).toList();
    await _box?.put('history', jsonList);
  }
  
  /// Очистить всю историю
  Future<void> clearHistory() async {
    await _box?.delete('history');
  }
  
  /// Получить популярные поисковые запросы (mock данные для примера)
  Future<List<String>> getPopularSearches() async {
    // В реальном приложении это можно получать с сервера
    // или анализировать локальную статистику
    return [
      'One Piece',
      'Attack on Titan',
      'Demon Slayer',
      'Jujutsu Kaisen',
      'My Hero Academia',
      'Naruto',
      'Bleach',
      'Dragon Ball',
    ];
  }
  
  /// Закрыть box
  Future<void> close() async {
    await _box?.close();
  }
}
