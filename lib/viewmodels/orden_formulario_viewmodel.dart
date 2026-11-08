import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../data/app_database.dart';

class OrdenFormularioViewModel extends ChangeNotifier {
  OrdenFormularioViewModel(
    this._db, {
    this.ordenId,
    int? clienteInicialId,
    this.vehiculoInicialId,
  }) {
    _db.clientesDao.watchTodos().listen((datos) {
      clientes = datos;
      notifyListeners();
    });
    _db.mecanicosDao.watchTodos().listen((datos) {
      mecanicos = datos;
      mecanicoSeleccionado ??= datos.isNotEmpty ? datos.first : null;
      notifyListeners();
    });

    if (ordenId != null) {
      _cargarParaEditar(ordenId!);
    } else {
      fecha = DateTime.now();
      if (clienteInicialId != null) {
        _seleccionarClienteInicial(clienteInicialId);
      } else {
        cargando = false;
      }
    }
  }

  final AppDatabase _db;
  final int? ordenId;
  final int? vehiculoInicialId;
  bool get esEdicion => ordenId != null;

  List<Cliente> clientes = [];
  List<Mecanico> mecanicos = [];
  List<Vehiculo> vehiculosDelCliente = [];

  Cliente? clienteSeleccionado;
  Vehiculo? vehiculoSeleccionado;
  Mecanico? mecanicoSeleccionado;
  DateTime? fecha;

  final kilometrajeController = TextEditingController();
  final problemaController = TextEditingController();

  bool cargando = true;
  bool guardando = false;
  bool huboCambios = false;
  String? error;

  StreamSubscription<List<Vehiculo>>? _subVehiculos;

  Future<void> _cargarParaEditar(int id) async {
    try {
      final orden = await _db.ordenesDao.obtener(id);
      final vehiculo = await _db.vehiculosDao.watchUno(orden.vehiculoId).first;
      final listaClientes = await _db.clientesDao.watchTodos().first;
      final listaMecanicos = await _db.mecanicosDao.watchTodos().first;

      clienteSeleccionado = _buscarPorId(
        listaClientes,
        (c) => c.id,
        vehiculo.clienteId,
      );
      vehiculoSeleccionado = vehiculo;
      mecanicoSeleccionado = _buscarPorId(
        listaMecanicos,
        (m) => m.id,
        orden.mecanicoId,
      );
      fecha = orden.fechaEntrada;
      kilometrajeController.text = orden.kilometrajeEntrada.toString();
      problemaController.text = orden.problema;

      _escucharVehiculosDe(vehiculo.clienteId, mantenerSeleccion: true);
      cargando = false;
      notifyListeners();
    } catch (_) {
      error = 'Esta orden no existe.';
      cargando = false;
      notifyListeners();
    }
  }

  Future<void> _seleccionarClienteInicial(int clienteId) async {
    final lista = await _db.clientesDao.watchTodos().first;
    final cliente = _buscarPorId(lista, (c) => c.id, clienteId);
    if (cliente != null) {
      seleccionarCliente(cliente, preseleccionarVehiculoId: vehiculoInicialId);
    }
    cargando = false;
    notifyListeners();
  }

  T? _buscarPorId<T>(List<T> lista, int Function(T) idDe, int id) {
    for (final item in lista) {
      if (idDe(item) == id) return item;
    }
    return null;
  }

  void seleccionarCliente(Cliente cliente, {int? preseleccionarVehiculoId}) {
    clienteSeleccionado = cliente;
    vehiculoSeleccionado = null;
    huboCambios = true;
    _escucharVehiculosDe(
      cliente.id,
      preseleccionarId: preseleccionarVehiculoId,
    );
    notifyListeners();
  }

  void _escucharVehiculosDe(
    int clienteId, {
    bool mantenerSeleccion = false,
    int? preseleccionarId,
  }) {
    _subVehiculos?.cancel();
    _subVehiculos = _db.vehiculosDao.watchDeCliente(clienteId).listen((datos) {
      vehiculosDelCliente = datos;
      if (mantenerSeleccion && vehiculoSeleccionado != null) {
        vehiculoSeleccionado = _buscarPorId(
          datos,
          (v) => v.id,
          vehiculoSeleccionado!.id,
        );
      } else if (preseleccionarId != null && vehiculoSeleccionado == null) {
        vehiculoSeleccionado = _buscarPorId(
          datos,
          (v) => v.id,
          preseleccionarId,
        );
      }
      notifyListeners();
    });
  }

  void seleccionarVehiculo(Vehiculo vehiculo) {
    vehiculoSeleccionado = vehiculo;
    huboCambios = true;
    notifyListeners();
  }

  void seleccionarMecanico(Mecanico mecanico) {
    mecanicoSeleccionado = mecanico;
    huboCambios = true;
    notifyListeners();
  }

  void seleccionarFecha(DateTime nuevaFecha) {
    fecha = nuevaFecha;
    huboCambios = true;
    notifyListeners();
  }

  void marcarCambio() => huboCambios = true;

  String? validarKilometraje(String? valor) {
    final numero = int.tryParse(valor ?? '');
    if (numero == null || numero < 0) return 'Kilometraje inválido';
    if (!esEdicion &&
        vehiculoSeleccionado != null &&
        numero < vehiculoSeleccionado!.kilometraje) {
      return 'No puede ser menor al último registrado (${vehiculoSeleccionado!.kilometraje} km)';
    }
    return null;
  }

  // Devuelve el id de la orden guardada, o null si falló.
  Future<int?> guardar() async {
    if (clienteSeleccionado == null ||
        vehiculoSeleccionado == null ||
        mecanicoSeleccionado == null ||
        fecha == null) {
      error = 'Completa cliente, vehículo, mecánico y fecha';
      notifyListeners();
      return null;
    }

    guardando = true;
    notifyListeners();

    final problema = problemaController.text.trim();

    try {
      if (esEdicion) {
        await _db.ordenesDao.editarOrden(
          ordenId!,
          OrdenesCompanion(
            fechaEntrada: Value(fecha!),
            problema: Value(problema),
            mecanicoId: Value(mecanicoSeleccionado!.id),
          ),
        );
        return ordenId;
      }

      final kilometraje = int.parse(kilometrajeController.text);
      late final int nuevoId;
      // Crear la orden y actualizar el kilometraje del vehículo son dos
      // escrituras que deben ir juntas: si una fallara, la otra tampoco
      // debe quedar guardada.
      await _db.transaction(() async {
        nuevoId = await _db.ordenesDao.crearOrden(
          OrdenesCompanion.insert(
            vehiculoId: vehiculoSeleccionado!.id,
            mecanicoId: mecanicoSeleccionado!.id,
            fechaEntrada: fecha!,
            kilometrajeEntrada: kilometraje,
            problema: problema,
            estado: EstadoOrden.recibida,
          ),
        );
        await _db.vehiculosDao.actualizarKilometraje(
          vehiculoSeleccionado!.id,
          kilometraje,
        );
      });
      return nuevoId;
    } catch (e) {
      error = 'No se pudo guardar: $e';
      guardando = false;
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _subVehiculos?.cancel();
    kilometrajeController.dispose();
    problemaController.dispose();
    super.dispose();
  }
}
