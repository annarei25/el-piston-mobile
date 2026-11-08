import 'package:drift/drift.dart';
import '../app_database.dart';

part 'vehiculos_dao.g.dart';

@DriftAccessor(tables: [Vehiculos])
class VehiculosDao extends DatabaseAccessor<AppDatabase>
    with _$VehiculosDaoMixin {
  VehiculosDao(super.attachedDatabase);

  // Para el selector del formulario de orden y el detalle del cliente.
  Stream<List<Vehiculo>> watchDeCliente(int clienteId) =>
      (select(vehiculos)..where((v) => v.clienteId.equals(clienteId))).watch();

  Stream<Vehiculo> watchUno(int id) =>
      (select(vehiculos)..where((v) => v.id.equals(id))).watchSingle();

  Future<int> crear(VehiculosCompanion datos) => into(vehiculos).insert(datos);

  Future<void> editar(int id, VehiculosCompanion datos) =>
      (update(vehiculos)..where((v) => v.id.equals(id))).write(datos);

  // Se llama al crear una orden nueva. La validación de que no baje
  // va en el ViewModel, antes de llamar a este método.
  Future<void> actualizarKilometraje(int id, int kilometraje) =>
      (update(vehiculos)..where((v) => v.id.equals(id)))
          .write(VehiculosCompanion(kilometraje: Value(kilometraje)));
}