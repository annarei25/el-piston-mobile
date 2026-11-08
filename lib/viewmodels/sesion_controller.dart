import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/app_database.dart';
import '../utils/password.dart';

class SesionController extends ChangeNotifier {
  SesionController(this._db);

  static const _claveUsuario = 'sesion_usuario_id';

  final AppDatabase _db;
  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get conSesion => _usuario != null;
  RolUsuario? get rol => _usuario?.rol;
  int? get mecanicoId => _usuario?.mecanicoId;

  bool puede(Set<RolUsuario> roles) => rol != null && roles.contains(rol);

  Future<bool> hayUsuarios() => _db.usuariosDao.hayUsuarios();

  // Se llama al abrir la app, antes de mostrar cualquier pantalla.
  // Solo guarda el id del usuario, nunca la contraseña.
  Future<void> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_claveUsuario);
    if (id == null) return;

    final usuario = await _db.usuariosDao.buscarPorId(id);
    if (usuario == null) {
      // La cuenta fue eliminada: no restaurar.
      await prefs.remove(_claveUsuario);
      return;
    }
    _usuario = usuario;
    notifyListeners();
  }

  Future<String?> iniciarSesion(String email, String password) async {
    final usuario =
        await _db.usuariosDao.buscarPorEmail(email.trim().toLowerCase());
    if (usuario == null ||
        !verificarPassword(password, usuario.salt, usuario.passwordHash)) {
      return 'Correo o contraseña incorrectos';
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_claveUsuario, usuario.id);

    _usuario = usuario;
    notifyListeners();
    return null;
  }

  // Solo funciona mientras no exista ninguna cuenta: crea al dueño y entra.
  Future<String?> crearDuenoInicial({
    required String nombre,
    required String email,
    required String password,
  }) async {
    if (await _db.usuariosDao.hayUsuarios()) {
      return 'El taller ya tiene cuentas';
    }
    await _db.usuariosDao.crearConPassword(
      email: email,
      nombre: nombre,
      password: password,
      rol: RolUsuario.dueno,
    );
    return iniciarSesion(email, password);
  }

  Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveUsuario);
    _usuario = null;
    notifyListeners();
  }
}