import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/daos/ordenes_dao.dart';

class OrdenDetalleViewModel extends ChangeNotifier {
  OrdenDetalleViewModel(this._db, this.ordenId, {this.mecanicoRequeridoId}) {
    _cargarDatosFijos();
    _subTrabajos = _db.ordenesDao.watchTrabajos(ordenId).listen((datos) {
      trabajos = datos;
      notifyListeners();
    });
    _subRepuestos = _db.ordenesDao.watchRepuestosUsados(ordenId).listen((datos) {
      repuestosUsados = datos;
      notifyListeners();
    });
    _subPagos = _db.ordenesDao.watchPagos(ordenId).listen((datos) {
      pagos = datos;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  final int ordenId;
  final int? mecanicoRequeridoId;

  Orden? orden;
  Vehiculo? vehiculo;
  Cliente? cliente;
  Mecanico? mecanico;
  List<Trabajo> trabajos = [];
  List<UsoConRepuesto> repuestosUsados = [];
  List<Pago> pagos = [];
  bool cargando = true;
  String? error;

  late final StreamSubscription<List<Trabajo>> _subTrabajos;
  late final StreamSubscription<List<UsoConRepuesto>> _subRepuestos;
  late final StreamSubscription<List<Pago>> _subPagos;

  // Estos datos no cambian seguido (a diferencia de trabajos/repuestos/
  // pagos), así que se cargan una vez en vez de mantenerlos como stream.
  Future<void> _cargarDatosFijos() async {
    try {
      final ordenCargada = await _db.ordenesDao.obtener(ordenId);
      if (mecanicoRequeridoId != null &&
          ordenCargada.mecanicoId != mecanicoRequeridoId) {
        throw StateError('Orden no asignada al mecánico');
      }
      final vehiculoCargado = await _db.vehiculosDao.watchUno(ordenCargada.vehiculoId).first;
      final clientes = await _db.clientesDao.watchTodos().first;
      final mecanicos = await _db.mecanicosDao.watchTodos().first;

      orden = ordenCargada;
      vehiculo = vehiculoCargado;
      cliente = clientes.firstWhere((c) => c.id == vehiculoCargado.clienteId);
      mecanico = mecanicos.firstWhere((m) => m.id == ordenCargada.mecanicoId);
      cargando = false;
      notifyListeners();
    } catch (_) {
      error = 'Esta orden no existe o no está asignada a ti.';
      cargando = false;
      notifyListeners();
    }
  }

  int get totalTrabajos => trabajos.fold(0, (suma, t) => suma + t.precioCentavos);

  int get totalRepuestos =>
      repuestosUsados.fold(0, (suma, u) => suma + u.uso.cantidad * u.uso.precioUnitarioCentavos);

  int get totalGeneral => totalTrabajos + totalRepuestos;

  int get totalPagado => pagos.fold(0, (suma, p) => suma + p.montoCentavos);

  int get saldo => totalGeneral - totalPagado;

  bool get esSoloLectura =>
      orden?.estado == EstadoOrden.entregada || orden?.estado == EstadoOrden.cancelada;

  static const _secuenciaEstados = [
    EstadoOrden.recibida,
    EstadoOrden.enDiagnostico,
    EstadoOrden.enReparacion,
    EstadoOrden.listaParaEntregar,
    EstadoOrden.entregada,
  ];

  int get faseActual => _secuenciaEstados.indexOf(orden!.estado);

  EstadoOrden? get siguienteEstado {
    final indice = faseActual;
    if (indice == -1 || indice == _secuenciaEstados.length - 1) return null;
    return _secuenciaEstados[indice + 1];
  }

  Future<void> avanzarEstado() async {
    final siguiente = siguienteEstado;
    if (siguiente == null) return;
    await _db.ordenesDao.cambiarEstado(ordenId, siguiente);
    orden = await _db.ordenesDao.obtener(ordenId);
    notifyListeners();
  }

  Future<void> cancelar() async {
    await _db.ordenesDao.cancelarOrden(ordenId);
    orden = await _db.ordenesDao.obtener(ordenId);
    notifyListeners();
  }

  Future<void> quitarTrabajo(int id) => _db.ordenesDao.quitarTrabajo(id);

  Future<void> quitarRepuesto(int usoId) => _db.ordenesDao.quitarRepuesto(usoId);

  @override
  void dispose() {
    _subTrabajos.cancel();
    _subRepuestos.cancel();
    _subPagos.cancel();
    super.dispose();
  }
}