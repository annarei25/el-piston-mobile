import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';
import '../viewmodels/sesion_controller.dart';
import 'app_database.dart';

class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.database,
    required this.themeController,
    required this.sesion,
    required super.child,
  });

  final AppDatabase database;
  final ThemeController themeController;
  final SesionController sesion;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no está en el árbol de widgets');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      database != oldWidget.database ||
      themeController != oldWidget.themeController ||
      sesion != oldWidget.sesion;
}