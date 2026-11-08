import 'package:flutter/foundation.dart';

import '../data/app_database.dart';
import '../data/calculos_orden.dart';
import '../data/daos/ordenes_dao.dart';

class FacturacionViewModel extends ChangeNotifier {
  FacturacionViewModel(this._db) {
    final ahora = DateTime.now();
    desde = DateTime(ahora.year, ahora.month, 1);
    hasta = DateTime(ahora.year, ahora.month + 1, 0); // último día del mes
    _cargar();
  }

  final AppDatabase _db;
  late DateTime desde;
  late DateTime hasta;

  List<PagoConOrden> pagos = [];
  int totalManoDeObra = 0;
  int totalRepuestos = 0;
  int cantidadOrdenesEntregadas = 0;
  bool cargando = true;

  int get totalCobrado => totalManoDeObra + totalRepuestos;

  Future<void> cambiarPeriodo(DateTime nuevoDesde, DateTime nuevoHasta) async {
    desde = nuevoDesde;
    hasta = nuevoHasta;
    await _cargar();
  }

  Future<void> _cargar() async {
    cargando = true;
    notifyListeners();

    final hastaExclusivo = DateTime(hasta.year, hasta.month, hasta.day + 1);
    final lista = await _db.ordenesDao
        .watchPagosEnPeriodo(desde, hastaExclusivo)
        .first;
    final calculos = CalculosOrden(_db);

    var manoDeObra = 0;
    var repuestos = 0;
    final idsEntregadas = <int>{};

    for (final item in lista) {
      if (item.orden.estado == EstadoOrden.cancelada) continue;

      final totalTrabajos = await calculos.totalTrabajos(item.orden.id);
      final totalRepu = await calculos.totalRepuestos(item.orden.id);
      final totalOrden = totalTrabajos + totalRepu;

      // Reparto proporcional: un pago no indica a qué parte corresponde,
      // así que se distribuye según el peso de cada parte en la orden.
      if (totalOrden > 0) {
        manoDeObra += (item.pago.montoCentavos * totalTrabajos / totalOrden)
            .round();
        repuestos += (item.pago.montoCentavos * totalRepu / totalOrden).round();
      }

      if (item.orden.estado == EstadoOrden.entregada) {
        idsEntregadas.add(item.orden.id);
      }
    }

    pagos = lista;
    totalManoDeObra = manoDeObra;
    totalRepuestos = repuestos;
    cantidadOrdenesEntregadas = idsEntregadas.length;
    cargando = false;
    notifyListeners();
  }
}
