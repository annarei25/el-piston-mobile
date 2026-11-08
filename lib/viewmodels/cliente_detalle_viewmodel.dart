import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/daos/ordenes_dao.dart';

class ClienteDetalleViewModel extends ChangeNotifier {
  ClienteDetalleViewModel(this._db, this.clienteId) {
    _cargarCliente();
    _subVehiculos = _db.vehiculosDao.watchDeCliente(clienteId).listen((datos) {
      vehiculos = datos;
      notifyListeners();
    });
    // Reactivo, igual que en Detalle de vehículo: si se agrega o cambia
    // una orden mientras se ve esta pantalla, el historial se actualiza solo.
    _subOrdenes = _db.ordenesDao.watchOrdenes().listen(_recalcular);
  }

  final AppDatabase _db;
  final int clienteId;

  Cliente? cliente;
  List<Vehiculo> vehiculos = [];
  List<OrdenResumen> historial = [];
  int saldo = 0;
  bool cargando = true;
  String? error;

  late final StreamSubscription<List<Vehiculo>> _subVehiculos;
  late final StreamSubscription<List<OrdenResumen>> _subOrdenes;

  Future<void> _cargarCliente() async {
    try {
      final clientes = await _db.clientesDao.watchTodos().first;
      cliente = clientes.firstWhere((c) => c.id == clienteId);
      cargando = false;
      notifyListeners();
    } catch (_) {
      error = 'Este cliente no existe.';
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> _recalcular(List<OrdenResumen> todas) async {
    historial = todas.where((o) => o.cliente.id == clienteId).toList();
    saldo = await _db.clientesDao.saldoCliente(clienteId);
    notifyListeners();
  }

  @override
  void dispose() {
    _subVehiculos.cancel();
    _subOrdenes.cancel();
    super.dispose();
  }
}