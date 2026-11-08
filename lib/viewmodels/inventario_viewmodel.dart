import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';

class InventarioViewModel extends ChangeNotifier {
  InventarioViewModel(this._db) {
    _sub = _db.repuestosDao.watchTodos().listen((datos) {
      repuestos = datos;
      cargando = false;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  StreamSubscription<List<Repuesto>>? _sub;

  List<Repuesto> repuestos = [];
  String textoBusqueda = '';
  bool soloBajos = false;
  bool cargando = true;

  void buscar(String texto) {
    textoBusqueda = texto;
    notifyListeners();
  }

  void alternarSoloBajos() {
    soloBajos = !soloBajos;
    notifyListeners();
  }

  List<Repuesto> get filtrados {
    final filtro = textoBusqueda.toLowerCase();
    return repuestos.where((r) {
      final coincideTexto = filtro.isEmpty ||
          r.nombre.toLowerCase().contains(filtro) ||
          r.codigo.toLowerCase().contains(filtro);
      final coincideStock = !soloBajos || r.existencias <= r.umbralAlerta;
      return coincideTexto && coincideStock;
    }).toList();
  }

  int get totalBajos => repuestos.where((r) => r.existencias <= r.umbralAlerta).length;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}