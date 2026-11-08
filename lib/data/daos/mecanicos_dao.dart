import 'package:drift/drift.dart';
import '../app_database.dart';

part 'mecanicos_dao.g.dart';

@DriftAccessor(tables: [Mecanicos, Ordenes])
class MecanicosDao extends DatabaseAccessor<AppDatabase>
    with _$MecanicosDaoMixin {
  MecanicosDao(super.attachedDatabase);

  Stream<List<Mecanico>> watchTodos() => select(mecanicos).watch();

  Future<int> crear(MecanicosCompanion datos) async {
    final actuales = await select(mecanicos).get();
    if (actuales.length >= 2) {
      throw Exception('El taller solo permite 2 mecánicos. Elimina uno para agregar otro.');
    }
    return into(mecanicos).insert(datos);
  }

  Future<void> editar(int id, MecanicosCompanion datos) =>
      (update(mecanicos)..where((m) => m.id.equals(id))).write(datos);

  Future<int> cantidadOrdenes(int mecanicoId) async {
    final query = selectOnly(ordenes)
      ..addColumns([ordenes.id.count()])
      ..where(ordenes.mecanicoId.equals(mecanicoId));
    final fila = await query.getSingle();
    return fila.read(ordenes.id.count()) ?? 0;
  }

  Future<void> eliminar(int id) async {
    final cantidad = await cantidadOrdenes(id);
    if (cantidad > 0) {
      throw Exception('No se puede eliminar: tiene $cantidad orden(es) en su historial');
    }
    final cuenta = await (attachedDatabase.select(attachedDatabase.usuarios)
          ..where((u) => u.mecanicoId.equals(id)))
        .getSingleOrNull();
    if (cuenta != null) {
      throw Exception('Este mecánico tiene una cuenta de usuario. Elimina la cuenta primero.');
    }
    await (delete(mecanicos)..where((m) => m.id.equals(id))).go();
  }
}