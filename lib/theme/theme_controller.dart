import 'package:flutter/material.dart';

// Cicla entre sistema, claro y oscuro. ChangeNotifier avisa a la app
// entera cuando cambia, para que MaterialApp se redibuje con el nuevo tema.
class ThemeController extends ChangeNotifier {
  ThemeMode _modo = ThemeMode.system;
  ThemeMode get modo => _modo;

  IconData get icono => switch (_modo) {
        ThemeMode.system => Icons.brightness_auto,
        ThemeMode.light => Icons.light_mode,
        ThemeMode.dark => Icons.dark_mode,
      };

  void alternar() {
    _modo = switch (_modo) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
  }
}