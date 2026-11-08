import '../data/app_database.dart';

String nombreEstado(EstadoOrden estado) => switch (estado) {
      EstadoOrden.recibida => 'RECIBIDA',
      EstadoOrden.enDiagnostico => 'EN DIAGNÓSTICO',
      EstadoOrden.enReparacion => 'EN REPARACIÓN',
      EstadoOrden.listaParaEntregar => 'LISTA PARA ENTREGAR',
      EstadoOrden.entregada => 'ENTREGADA',
      EstadoOrden.cancelada => 'CANCELADA',
    };