import '../data/app_database.dart';

String etiquetaRol(RolUsuario rol) => switch (rol) {
      RolUsuario.dueno => 'Dueño',
      RolUsuario.recepcion => 'Recepción',
      RolUsuario.mecanico => 'Mecánico',
    };