import 'package:drift/drift.dart';
import '../app_database.dart';
import '../calculos_orden.dart';

part 'clientes_dao.g.dart';

@DriftAccessor(tables: [Clientes, Vehiculos, Ordenes])
class ClientesDao extends DatabaseAccessor<AppDatabase>
    with _$ClientesDaoMixin {
  ClientesDao(super.attachedDatabase);

  Stream<List<Cliente>> watchTodos() => select(clientes).watch();

  Stream<List<Cliente>> buscar(String texto) {
    final filtro = '%$texto%';
    return (select(clientes)
          ..where((c) => c.nombre.like(filtro) | c.telefono.like(filtro)))
        .watch();
  }

  Future<int> crear(ClientesCompanion datos) => into(clientes).insert(datos);

  Future<void> editar(int id, ClientesCompanion datos) =>
      (update(clientes)..where((c) => c.id.equals(id))).write(datos);

  Future<int> cantidadVehiculos(int clienteId) async {
    final query = selectOnly(vehiculos)
      ..addColumns([vehiculos.id.count()])
      ..where(vehiculos.clienteId.equals(clienteId));
    final fila = await query.getSingle();
    return fila.read(vehiculos.id.count()) ?? 0;
  }

  // Suma el saldo de todas las órdenes no canceladas de los vehículos
  // del cliente.
  Future<int> saldoCliente(int clienteId) async {
    final filas = await (select(ordenes).join([
      innerJoin(vehiculos, vehiculos.id.equalsExp(ordenes.vehiculoId)),
    ])
          ..where(vehiculos.clienteId.equals(clienteId)))
        .get();

    final calculos = CalculosOrden(attachedDatabase);
    var total = 0;
    for (final fila in filas) {
      final orden = fila.readTable(ordenes);
      if (orden.estado == EstadoOrden.cancelada) continue;
      total += await calculos.saldo(orden.id);
    }
    return total;
  }
}