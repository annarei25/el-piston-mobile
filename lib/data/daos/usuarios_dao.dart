import 'package:drift/drift.dart';

import '../../utils/password.dart';
import '../app_database.dart';

part 'usuarios_dao.g.dart';

@DriftAccessor(tables: [Usuarios])
class UsuariosDao extends DatabaseAccessor<AppDatabase>
    with _$UsuariosDaoMixin {
  UsuariosDao(super.attachedDatabase);

  Future<bool> hayUsuarios() async {
    final lista = await (select(usuarios)..limit(1)).get();
    return lista.isNotEmpty;
  }

  Future<Usuario?> buscarPorEmail(String email) =>
      (select(usuarios)..where((u) => u.email.equals(email))).getSingleOrNull();

  Future<Usuario?> buscarPorId(int id) =>
      (select(usuarios)..where((u) => u.id.equals(id))).getSingleOrNull();

  Stream<List<Usuario>> watchTodos() => select(usuarios).watch();

  Future<int> crearConPassword({
    required String email,
    required String nombre,
    required String password,
    required RolUsuario rol,
    int? mecanicoId,
  }) async {
    if (rol == RolUsuario.mecanico && mecanicoId == null) {
      throw Exception(
        'Una cuenta de mecánico debe estar vinculada a un mecánico',
      );
    }
    if (mecanicoId != null) {
      final ocupado = await (select(
        usuarios,
      )..where((u) => u.mecanicoId.equals(mecanicoId))).getSingleOrNull();
      if (ocupado != null) {
        throw Exception('Ese mecánico ya tiene una cuenta');
      }
    }

    final salt = generarSal();
    return into(usuarios).insert(
      UsuariosCompanion.insert(
        email: email.trim().toLowerCase(),
        nombre: nombre.trim(),
        passwordHash: hashPassword(password, salt),
        salt: salt,
        rol: rol,
        mecanicoId: Value(mecanicoId),
      ),
    );
  }

  Future<void> eliminar(int id) =>
      (delete(usuarios)..where((u) => u.id.equals(id))).go();
}
