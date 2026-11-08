import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';

class ClienteConDatos {
  ClienteConDatos({required this.cliente, required this.cantidadVehiculos, required this.saldo});
  final Cliente cliente;
  final int cantidadVehiculos;
  final int saldo;
}

class ClientesViewModel extends ChangeNotifier {
  ClientesViewModel(this._db) {
    _sub = _db.clientesDao.watchTodos().listen(_recalcular);
  }

  final AppDatabase _db;
  StreamSubscription<List<Cliente>>? _sub;

  List<ClienteConDatos> clientes = [];
  String textoBusqueda = '';
  bool soloConSaldo = false;
  bool cargando = true;

  Future<void> _recalcular(List<Cliente> lista) async {
    final resultado = <ClienteConDatos>[];
    for (final cliente in lista) {
      final cantidad = await _db.clientesDao.cantidadVehiculos(cliente.id);
      final saldo = await _db.clientesDao.saldoCliente(cliente.id);
      resultado.add(ClienteConDatos(cliente: cliente, cantidadVehiculos: cantidad, saldo: saldo));
    }
    clientes = resultado;
    cargando = false;
    notifyListeners();
  }

  void buscar(String texto) {
    textoBusqueda = texto;
    notifyListeners();
  }

  void alternarSoloConSaldo() {
    soloConSaldo = !soloConSaldo;
    notifyListeners();
  }

  List<ClienteConDatos> get filtrados {
    final filtro = textoBusqueda.toLowerCase();
    return clientes.where((c) {
      final coincideTexto = filtro.isEmpty ||
          c.cliente.nombre.toLowerCase().contains(filtro) ||
          c.cliente.telefono.contains(filtro);
      final coincideSaldo = !soloConSaldo || c.saldo > 0;
      return coincideTexto && coincideSaldo;
    }).toList();
  }

  int get totalClientes => clientes.length;
  int get totalConSaldo => clientes.where((c) => c.saldo > 0).length;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}