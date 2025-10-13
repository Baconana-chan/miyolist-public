import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Типы каомодзи для разных состояний
enum KaomojiType {
  loading,    // Загрузка
  error,      // Ошибка
  empty,      // Пусто
  noData,     // Нет данных
  success,    // Успех
  thinking,   // Думает
  sad,        // Грустно
  happy,      // Радостно
}

/// Виджет с анимированным каомодзи
class KaomojiWidget extends StatefulWidget {
  final KaomojiType type;
  final String? message;
  final double size;
  final Widget? action;

  const KaomojiWidget({
    Key? key,
    required this.type,
    this.message,
    this.size = 48,
    this.action,
  }) : super(key: key);

  @override
  State<KaomojiWidget> createState() => _KaomojiWidgetState();
}

class _KaomojiWidgetState extends State<KaomojiWidget>
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
    _animation = Tween<double>(begin: 0.8, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getKaomoji() {
    switch (widget.type) {
      case KaomojiType.loading:
        return '( ˘▽˘)っ♨';
      case KaomojiType.error:
        return '(╥﹏╥)';
      case KaomojiType.empty:
        return '(｡•́︿•̀｡)';
      case KaomojiType.noData:
        return '(⊙_◎)';
      case KaomojiType.success:
        return '✧( ु•⌄• )◞';
      case KaomojiType.thinking:
        return '(´•̥ ω •̥`)';
      case KaomojiType.sad:
        return '( ˃̣̣̥⌓˂̣̣̥ )';
      case KaomojiType.happy:
        return '.｡ﾟ+..｡(❁´◕‿◕)｡ﾟ+..｡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Text(
                  _getKaomoji(),
                  style: TextStyle(
                    fontSize: widget.size,
                    height: 1.2,
                  ),
                ),
              );
            },
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.message!,
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (widget.action != null) ...[
            const SizedBox(height: 24),
            widget.action!,
          ],
        ],
      ),
    );
  }
}

/// Специализированные виджеты для частых случаев
class KaomojiLoader extends StatelessWidget {
  final String? message;

  const KaomojiLoader({
    Key? key,
    this.message = 'Loading...',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KaomojiWidget(
      type: KaomojiType.loading,
      message: message,
    );
  }
}

class KaomojiError extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const KaomojiError({
    Key? key,
    this.message = 'Something went wrong',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KaomojiWidget(
      type: KaomojiType.error,
      message: message,
      action: onRetry != null
          ? ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            )
          : null,
    );
  }
}

class KaomojiEmpty extends StatelessWidget {
  final String? message;
  final Widget? action;

  const KaomojiEmpty({
    Key? key,
    this.message = 'Nothing here yet',
    this.action,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KaomojiWidget(
      type: KaomojiType.empty,
      message: message,
      action: action,
    );
  }
}
