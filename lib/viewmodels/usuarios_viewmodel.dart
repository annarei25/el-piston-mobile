import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/app_database.dart';
import 'sesion_controller.dart';

class UsuariosViewModel extends ChangeNotifier {
  UsuariosViewModel(this._db, this._sesion) {
    _subUsuarios = _db.usuariosDao.watchTodos().listen((datos) {
      usuarios = datos;
      notifyListeners();
    });
    _subMecanicos = _db.mecanicosDao.watchTodos().listen((datos) {
      mecanicos = datos;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  final SesionController _sesion;

  List<Usuario> usuarios = [];
  List<Mecanico> mecanicos = [];

  late final StreamSubscription<List<Usuario>> _subUsuarios;
  late final StreamSubscription<List<Mecanico>> _subMecanicos;

  bool esYo(Usuario usuario) => usuario.id == _sesion.usuario?.id;

  // Mecánicos que todavía no tienen cuenta.
  List<Mecanico> mecanicosLibres() {
    final ocupados = usuarios.map((u) => u.mecanicoId).whereType<int>().toSet();
    return mecanicos.where((m) => !ocupados.contains(m.id)).toList();
  }

  String? nombreMecanico(int? id) {
    if (id == null) return null;
    for (final mecanico in mecanicos) {
      if (mecanico.id == id) return mecanico.nombre;
    }
    return null;
  }

  Future<String?> crear({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
    int? mecanicoId,
  }) async {
    try {
      await _db.usuariosDao.crearConPassword(
        email: email,
        nombre: nombre,
        password: password,
        rol: rol,
        mecanicoId: mecanicoId,
      );
      return null;
    } catch (e) {
      final texto = e.toString();
      if (texto.contains('UNIQUE')) return 'Ese correo ya tiene una cuenta';
      return texto.replaceFirst('Exception: ', '');
    }
  }

  Future<String?> eliminar(Usuario usuario) async {
    if (esYo(usuario)) return 'No puedes eliminar tu propia cuenta';
    await _db.usuariosDao.eliminar(usuario.id);
    return null;
  }

  @override
  void dispose() {
    _subUsuarios.cancel();
    _subMecanicos.cancel();
    super.dispose();
  }
}