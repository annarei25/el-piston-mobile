import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';
import 'daos/clientes_dao.dart';
import 'daos/vehiculos_dao.dart';
import 'daos/mecanicos_dao.dart';
import 'daos/repuestos_dao.dart';
import 'daos/ordenes_dao.dart';
import 'daos/usuarios_dao.dart';

export 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Clientes,
    Vehiculos,
    Mecanicos,
    Ordenes,
    Trabajos,
    Repuestos,
    UsosRepuesto,
    Pagos,
    Usuarios,
  ],
  daos: [
    ClientesDao,
    VehiculosDao,
    MecanicosDao,
    RepuestosDao,
    OrdenesDao,
    UsuariosDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'el_piston'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(usuarios);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}