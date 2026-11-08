import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/daos/ordenes_dao.dart';

class VehiculoDetalleViewModel extends ChangeNotifier {
  VehiculoDetalleViewModel(this._db, this.vehiculoId) {
    _subVehiculo = _db.vehiculosDao.watchUno(vehiculoId).listen(
      (datos) {
        vehiculo = datos;
        cargando = false;
        notifyListeners();
      },
      onError: (_) {
        error = 'Este vehículo no existe.';
        cargando = false;
        notifyListeners();
      },
    );
    _subOrdenes = _db.ordenesDao.watchOrdenes().listen((todas) {
      historial = todas.where((o) => o.vehiculo.id == vehiculoId).toList();
      notifyListeners();
    });
  }

  final AppDatabase _db;
  final int vehiculoId;

  Vehiculo? vehiculo;
  List<OrdenResumen> historial = [];
  bool cargando = true;
  String? error;

  late final StreamSubscription<Vehiculo> _subVehiculo;
  late final StreamSubscription<List<OrdenResumen>> _subOrdenes;

  @override
  void dispose() {
    _subVehiculo.cancel();
    _subOrdenes.cancel();
    super.dispose();
  }
}