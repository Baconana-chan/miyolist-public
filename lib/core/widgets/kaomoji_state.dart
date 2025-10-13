import 'package:flutter/material.dart';
import 'dart:math';

/// Виджет для отображения каомодзи в разных состояниях
class KaomojiState extends StatelessWidget {
  final KaomojiType type;
  final String? message;
  final String? subtitle;
  final Widget? action;
  final double size;

  const KaomojiState({
    Key? key,
    required this.type,
    this.message,
    this.subtitle,
    this.action,
    this.size = 48,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final kaomoji = _getRandomKaomoji(type);
    final defaultMessage = _getDefaultMessage(type);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Каомодзи
            Text(
              kaomoji,
              style: TextStyle(
                fontSize: size,
                fontFamily: 'Segoe UI Emoji',
              ),
            ),
            const SizedBox(height: 16),
            
            // Основное сообщение
            Text(
              message ?? defaultMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Подзаголовок (опционально)
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            // Действие (кнопка и т.д.)
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }

  /// Получить случайный каомодзи для типа
  String _getRandomKaomoji(KaomojiType type) {
    final random = Random();
    final list = _kaomojiMap[type]!;
    return list[random.nextInt(list.length)];
  }

  /// Получить стандартное сообщение для типа
  String _getDefaultMessage(KaomojiType type) {
    switch (type) {
      case KaomojiType.loading:
        return 'Loading...';
      case KaomojiType.empty:
        return 'Nothing here yet';
      case KaomojiType.error:
        return 'Something went wrong';
      case KaomojiType.notFound:
        return 'Not found';
      case KaomojiType.noConnection:
        return 'No internet connection';
      case KaomojiType.success:
        return 'All done!';
      case KaomojiType.thinking:
        return 'Thinking...';
      case KaomojiType.confused:
        return 'Hmm...';
    }
  }
}

/// Типы состояний
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

/// Карта каомодзи для каждого типа
const Map<KaomojiType, List<String>> _kaomojiMap = {
  // Загрузка - милые, ожидающие
  KaomojiType.loading: [
    '( ˘▽˘)っ♨',
    '✧( ु•⌄• )◞',
    '(｡•́︿•̀｡)',
    '( ˘•ω•˘ ).｡o',
    '.｡ﾟ+..｡(❁´◕‿◕)｡ﾟ+..｡',
    '|ω･)و',
    '(◕‿◕✿)',
  ],
  
  // Пусто - немного грустные, но милые
  KaomojiType.empty: [
    '(´•̥ ω •̥`)',
    '( ˃̣̣̥⌓˂̣̣̥ )',
    '(｡•́︿•̀｡)',
    '(つ﹏⊂)',
    '( ˘•ω•˘ ).｡o',
    '˚‧º·(˚ ˃̣̣̥⌓˂̣̣̥ )‧º·˚',
    '⋆｡˚ ❀ (˃̣̣̥⌓˂̣̣̥ ) ❀ ˚｡⋆',
  ],
  
  // Ошибка - расстроенные
  KaomojiType.error: [
    '(╥﹏╥)',
    '(T_T)',
    '( ; ω ; )',
    '(x_x)',
    '(◕︵◕)',
    '(ノ﹏ヽ)',
    '˚‧º·(˚ ˃̣̣̥⌓˂̣̣̥ )‧º·˚',
  ],
  
  // Не найдено - запутанные
  KaomojiType.notFound: [
    '(⊙_◎)',
    '(⁄ ⁄>⁄ ▽ ⁄<⁄ ⁄)',
    '(◕︵◕)',
    '( ˃̣̣̥⌓˂̣̣̥ )',
    '(｡•́︿•̀｡)',
  ],
  
  // Нет соединения - беспомощные
  KaomojiType.noConnection: [
    '(x_x)',
    '(╥﹏╥)',
    '( ; ω ; )',
    '(T_T)',
    '(ノ﹏ヽ)',
  ],
  
  // Успех - радостные
  KaomojiType.success: [
    '(◕‿◕✿)',
    '✧( ु•⌄• )◞',
    '.｡ﾟ+..｡(❁´◕‿◕)｡ﾟ+..｡',
    '( ˘▽˘)っ♨',
    '˚₊· ͟͟͞͞➳❥ (´•̥ ω •̥`)',
    '|ω･)و',
  ],
  
  // Думает - задумчивые
  KaomojiType.thinking: [
    '( ˘•ω•˘ ).｡o',
    '(｡•́︿•̀｡)',
    '(⊙_◎)',
    '( ˃̣̣̥⌓˂̣̣̥ )',
  ],
  
  // Запутался - confused
  KaomojiType.confused: [
    '(⊙_◎)',
    '(⁄ ⁄>⁄ ▽ ⁄<⁄ ⁄)',
    '(◕︵◕)',
    '(´•̥ ω •̥`)',
  ],
};

/// Виджет загрузки с каомодзи
class KaomojiLoader extends StatefulWidget {
  final String? message;
  final double size;

  const KaomojiLoader({
    Key? key,
    this.message,
    this.size = 48,
  }) : super(key: key);

  @override
  State<KaomojiLoader> createState() => _KaomojiLoaderState();
}

class _KaomojiLoaderState extends State<KaomojiLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kaomojis = _kaomojiMap[KaomojiType.loading]!;
    final random = Random();
    final kaomoji = kaomojis[random.nextInt(kaomojis.length)];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Text(
              kaomoji,
              style: TextStyle(
                fontSize: widget.size,
                fontFamily: 'Segoe UI Emoji',
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
