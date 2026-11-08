import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/daos/ordenes_dao.dart';

class InicioViewModel extends ChangeNotifier {
  InicioViewModel(this._db, {this.mecanicoFijoId}) {
    _subOrdenes = _db.ordenesDao
        .watchOrdenes(mecanicoId: mecanicoFijoId)
        .listen((datos) {
      ordenes = datos;
      notifyListeners();
    });
    _subRepuestos = _db.repuestosDao.watchBajos().listen((datos) {
      repuestosBajos = datos;
      notifyListeners();
    });
    _subFacturacion = _db.ordenesDao.watchFacturacionDelMes().listen((valor) {
      facturacionMesCentavos = valor;
      notifyListeners();
    });
    _subMecanicos = _db.mecanicosDao.watchTodos().listen((datos) {
      mecanicos = datos;
      notifyListeners();
    });
  }

  final AppDatabase _db;

  // Si no es nulo, el usuario es mecánico: solo cuenta sus órdenes.
  final int? mecanicoFijoId;

  List<OrdenResumen> ordenes = [];
  List<Repuesto> repuestosBajos = [];
  int facturacionMesCentavos = 0;
  List<Mecanico> mecanicos = [];

  late final StreamSubscription<List<OrdenResumen>> _subOrdenes;
  late final StreamSubscription<List<Repuesto>> _subRepuestos;
  late final StreamSubscription<int> _subFacturacion;
  late final StreamSubscription<List<Mecanico>> _subMecanicos;

  int conteoPorEstado(EstadoOrden estado) =>
      ordenes.where((o) => o.orden.estado == estado).length;

  int get saldoTotalPendiente => ordenes
      .where((o) => o.orden.estado != EstadoOrden.cancelada)
      .fold(0, (suma, o) => suma + o.saldoCentavos);

  int get cantidadConSaldo => ordenes
      .where((o) =>
          o.orden.estado != EstadoOrden.cancelada && o.saldoCentavos > 0)
      .length;

  List<OrdenResumen> ordenesActivasDe(int mecanicoId) => ordenes
      .where((o) =>
          o.mecanico.id == mecanicoId &&
          o.orden.estado != EstadoOrden.entregada &&
          o.orden.estado != EstadoOrden.cancelada)
      .toList();

  @override
  void dispose() {
    _subOrdenes.cancel();
    _subRepuestos.cancel();
    _subFacturacion.cancel();
    _subMecanicos.cancel();
    super.dispose();
  }
}