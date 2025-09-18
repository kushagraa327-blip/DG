import 'package:flutter/material.dart';

DateTime? _currentBackPressTime;

/// DoublePressBackWidget
class DoublePressBackWidget extends StatelessWidget {
  final Widget child;
  final String? message;
  final WillPopCallback? onWillPop;

  const DoublePressBackWidget({
    super.key,
    required this.child,
    this.message,
    this.onWillPop,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: child,
      onWillPop: () {
        DateTime now = DateTime.now();

        onWillPop?.call();
        if (_currentBackPressTime == null ||
            now.difference(_currentBackPressTime!) > const Duration(seconds: 2)) {
          _currentBackPressTime = now;
         // snackBar(message ?? 'Press back again to exit');

          return Future.value(false);
        }
        return Future.value(true);
      },
    );
  }
}
