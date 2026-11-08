import 'package:el_piston/data/tables.dart';
import 'package:flutter/material.dart';

// Colores de los estados de orden y de alerta de stock. No forman parte
// del ColorScheme de Material porque son específicos del negocio del
// taller, no roles genéricos de la interfaz.
@immutable
class EstadoColores extends ThemeExtension<EstadoColores> {
  const EstadoColores({
    required this.recibida,
    required this.enDiagnostico,
    required this.enReparacion,
    required this.listaParaEntregar,
    required this.entregada,
    required this.cancelada,
    required this.stockBajo,
    required this.stockAgotado,
  });

  final Color recibida;
  final Color enDiagnostico;
  final Color enReparacion;
  final Color listaParaEntregar;
  final Color entregada;
  final Color cancelada;
  final Color stockBajo;
  final Color stockAgotado;

  static const oscuro = EstadoColores(
    recibida: Color(0xFF29B6F6),
    enDiagnostico: Color(0xFFAB47BC),
    enReparacion: Color(0xFFFFA726),
    listaParaEntregar: Color(0xFF66BB6A),
    entregada: Color(0xFF78909C),
    cancelada: Color(0xFFEF5350),
    stockBajo: Color(0xFFFFA726),
    stockAgotado: Color(0xFFEF5350),
  );

  // Mismos significados, pero más oscuros para leerse sobre fondo claro.
  static const claro = EstadoColores(
    recibida: Color(0xFF0288D1),
    enDiagnostico: Color(0xFF8E24AA),
    enReparacion: Color(0xFFEF6C00),
    listaParaEntregar: Color(0xFF2E7D32),
    entregada: Color(0xFF607D8B),
    cancelada: Color(0xFFD32F2F),
    stockBajo: Color(0xFFEF6C00),
    stockAgotado: Color(0xFFD32F2F),
  );

  @override
  EstadoColores copyWith({
    Color? recibida,
    Color? enDiagnostico,
    Color? enReparacion,
    Color? listaParaEntregar,
    Color? entregada,
    Color? cancelada,
    Color? stockBajo,
    Color? stockAgotado,
  }) {
    return EstadoColores(
      recibida: recibida ?? this.recibida,
      enDiagnostico: enDiagnostico ?? this.enDiagnostico,
      enReparacion: enReparacion ?? this.enReparacion,
      listaParaEntregar: listaParaEntregar ?? this.listaParaEntregar,
      entregada: entregada ?? this.entregada,
      cancelada: cancelada ?? this.cancelada,
      stockBajo: stockBajo ?? this.stockBajo,
      stockAgotado: stockAgotado ?? this.stockAgotado,
    );
  }

  @override
  EstadoColores lerp(ThemeExtension<EstadoColores>? other, double t) {
    if (other is! EstadoColores) return this;
    return EstadoColores(
      recibida: Color.lerp(recibida, other.recibida, t)!,
      enDiagnostico: Color.lerp(enDiagnostico, other.enDiagnostico, t)!,
      enReparacion: Color.lerp(enReparacion, other.enReparacion, t)!,
      listaParaEntregar: Color.lerp(
        listaParaEntregar,
        other.listaParaEntregar,
        t,
      )!,
      entregada: Color.lerp(entregada, other.entregada, t)!,
      cancelada: Color.lerp(cancelada, other.cancelada, t)!,
      stockBajo: Color.lerp(stockBajo, other.stockBajo, t)!,
      stockAgotado: Color.lerp(stockAgotado, other.stockAgotado, t)!,
    );
  }

  // Color según el estado de una orden. Evita un switch repetido en
  // cada widget que muestra una tarjeta o una insignia de estado.
  Color deEstado(EstadoOrden estado) {
    return switch (estado) {
      EstadoOrden.recibida => recibida,
      EstadoOrden.enDiagnostico => enDiagnostico,
      EstadoOrden.enReparacion => enReparacion,
      EstadoOrden.listaParaEntregar => listaParaEntregar,
      EstadoOrden.entregada => entregada,
      EstadoOrden.cancelada => cancelada,
    };
  }
}
