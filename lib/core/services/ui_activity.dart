import 'package:flutter/widgets.dart';

/// Tells background work when the user is busy with the UI, so optional
/// jobs (Harmonic Queue's analysis) wait for a quiet moment instead of
/// competing with a scroll for the CPU.
///
/// [UiActivityListener] sits above every route and records scrolls; a job
/// asks [isQuiet] before it starts.
abstract final class UiActivity {
  static DateTime _lastScroll = DateTime.fromMillisecondsSinceEpoch(0);
  static int _activeDrags = 0;

  /// How long after the last scroll the UI counts as quiet.
  static const Duration quietAfter = Duration(seconds: 2);

  static void markScroll() => _lastScroll = DateTime.now();

  /// No scroll in progress or within [quietAfter], and the app in front.
  static bool get isQuiet {
    if (_activeDrags > 0) return false;
    if (DateTime.now().difference(_lastScroll) < quietAfter) return false;
    final state = WidgetsBinding.instance.lifecycleState;
    return state == null || state == AppLifecycleState.resumed;
  }

  static void _onNotification(ScrollNotification n) {
    if (n is ScrollStartNotification) {
      _activeDrags++;
    } else if (n is ScrollEndNotification) {
      if (_activeDrags > 0) _activeDrags--;
    }
    markScroll();
  }

  @visibleForTesting
  static void reset() {
    _lastScroll = DateTime.fromMillisecondsSinceEpoch(0);
    _activeDrags = 0;
  }
}

/// Records scroll activity of everything below it for [UiActivity]. Never
/// stops a notification and never rebuilds anything.
class UiActivityListener extends StatelessWidget {
  const UiActivityListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          UiActivity._onNotification(n);
          return false;
        },
        child: child,
      );
}
