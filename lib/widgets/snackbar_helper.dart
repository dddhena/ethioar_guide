import 'package:flutter/material.dart';

class SnackbarHelper {
  static void show(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    final sb = SnackBar(content: Text(message), duration: duration);
    ScaffoldMessenger.of(context).showSnackBar(sb);
  }
}
