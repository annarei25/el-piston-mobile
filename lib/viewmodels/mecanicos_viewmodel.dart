import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';

class MecanicosViewModel extends ChangeNotifier {
  MecanicosViewModel(this._db) {
    _sub = _db.mecanicosDao.watchTodos().listen((datos) {
      mecanicos = datos;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  StreamSubscription<List<Mecanico>>? _sub;
  List<Mecanico> mecanicos = [];

  // Devuelve un mensaje de error, o null si se eliminó sin problema.
  Future<String?> eliminar(int id) async {
    try {
      await _db.mecanicosDao.eliminar(id);
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}