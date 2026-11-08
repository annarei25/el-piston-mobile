import 'package:drift/drift.dart';
import '../app_database.dart';

part 'repuestos_dao.g.dart';

@DriftAccessor(tables: [Repuestos])
class RepuestosDao extends DatabaseAccessor<AppDatabase>
    with _$RepuestosDaoMixin {
  RepuestosDao(super.attachedDatabase);

  Stream<List<Repuesto>> watchTodos() => select(repuestos).watch();

  // Para el panel de inicio y el filtro "Solo bajos" del inventario.
  Stream<List<Repuesto>> watchBajos() => (select(repuestos)
        ..where((r) => r.existencias.isSmallerOrEqual(r.umbralAlerta)))
      .watch();

  Stream<List<Repuesto>> buscar(String texto) {
    final filtro = '%$texto%';
    return (select(repuestos)
          ..where((r) => r.nombre.like(filtro) | r.codigo.like(filtro)))
        .watch();
  }

  Future<int> crear(RepuestosCompanion datos) => into(repuestos).insert(datos);

  Future<void> editar(int id, RepuestosCompanion datos) =>
      (update(repuestos)..where((r) => r.id.equals(id))).write(datos);
}