import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

// Sal aleatoria por usuario: dos cuentas con la misma contraseña no
// tienen el mismo hash.
String generarSal() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword(String password, String salt) {
  return sha256.convert(utf8.encode('$salt:$password')).toString();
}

bool verificarPassword(String password, String salt, String hashGuardado) {
  return hashPassword(password, salt) == hashGuardado;
}