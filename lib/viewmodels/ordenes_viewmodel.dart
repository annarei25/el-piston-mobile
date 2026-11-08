import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import '../data/daos/ordenes_dao.dart';

class OrdenesViewModel extends ChangeNotifier {
  OrdenesViewModel(
    this._db, {
    EstadoOrden? estadoInicial,
    this.mecanicoFijoId,
  }) {
    estadoSeleccionado = estadoInicial;
    mecanicoSeleccionadoId = mecanicoFijoId;
    _subGlobal = _db.ordenesDao
        .watchOrdenes(mecanicoId: mecanicoFijoId)
        .listen((datos) {
      todas = datos;
      notifyListeners();
    });
    _suscribirFiltradas();
    _subMecanicos = _db.mecanicosDao.watchTodos().listen((datos) {
      mecanicos = datos;
      notifyListeners();
    });
  }

  final AppDatabase _db;

  // Si no es nulo, el usuario es mecánico y solo ve sus órdenes.
  final int? mecanicoFijoId;

  List<OrdenResumen> todas = [];
  List<OrdenResumen> _filtradasPorServidor = [];
  List<Mecanico> mecanicos = [];

  EstadoOrden? estadoSeleccionado;
  int? mecanicoSeleccionadoId;
  String textoBusqueda = '';

  late final StreamSubscription<List<OrdenResumen>> _subGlobal;
  StreamSubscription<List<OrdenResumen>>? _subFiltradas;
  late final StreamSubscription<List<Mecanico>> _subMecanicos;

  void _suscribirFiltradas() {
    _subFiltradas?.cancel();
    _subFiltradas = _db.ordenesDao
        .watchOrdenes(
          estado: estadoSeleccionado,
          mecanicoId: mecanicoSeleccionadoId,
        )
        .listen((datos) {
      _filtradasPorServidor = datos;
      notifyListeners();
    });
  }

  void filtrarPorEstado(EstadoOrden? estado) {
    estadoSeleccionado = estado;
    _suscribirFiltradas();
  }

  void filtrarPorMecanico(int? mecanicoId) {
    if (mecanicoFijoId != null) return;
    mecanicoSeleccionadoId = mecanicoId;
    _suscribirFiltradas();
  }

  void buscar(String texto) {
    textoBusqueda = texto;
    notifyListeners();
  }

  List<OrdenResumen> get ordenesFiltradas {
    if (textoBusqueda.isEmpty) return _filtradasPorServidor;
    final filtro = textoBusqueda.toLowerCase();
    return _filtradasPorServidor
        .where((o) =>
            o.vehiculo.matricula.toLowerCase().contains(filtro) ||
            o.cliente.nombre.toLowerCase().contains(filtro))
        .toList();
  }

  int conteoDeEstado(EstadoOrden? estado) {
    if (estado == null) return todas.length;
    return todas.where((o) => o.orden.estado == estado).length;
  }

  int conteoDeMecanico(int? mecanicoId) {
    if (mecanicoId == null) return todas.length;
    return todas.where((o) => o.mecanico.id == mecanicoId).length;
  }

  @override
  void dispose() {
    _subGlobal.cancel();
    _subFiltradas?.cancel();
    _subMecanicos.cancel();
    super.dispose();
  }
}