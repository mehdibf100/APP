import 'dart:async';

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  /// Exécute la fonction [action] après un délai, annulant toute action précédente
  void run(Function action) {
    _timer?.cancel();
    _timer = Timer(delay, () {
      action();
    });
  }

  /// Annule le timer en cours s'il existe
  void cancel() {
    _timer?.cancel();
  }
}
