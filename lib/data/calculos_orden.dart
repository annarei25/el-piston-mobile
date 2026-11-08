import 'package:drift/drift.dart';
import 'app_database.dart';

// Calcula los totales de una orden: suma de trabajos, de repuestos
// (cantidad × precio congelado) y de pagos. El saldo es la resta de los tres.
class CalculosOrden {
  CalculosOrden(this.db);
  final AppDatabase db;

  Future<int> totalTrabajos(int ordenId) async {
    final query = db.selectOnly(db.trabajos)
      ..addColumns([db.trabajos.precioCentavos.sum()])
      ..where(db.trabajos.ordenId.equals(ordenId));
    final fila = await query.getSingle();
    return fila.read(db.trabajos.precioCentavos.sum()) ?? 0;
  }

  Future<int> totalRepuestos(int ordenId) async {
    final expresion =
        (db.usosRepuesto.cantidad * db.usosRepuesto.precioUnitarioCentavos)
            .sum();
    final query = db.selectOnly(db.usosRepuesto)
      ..addColumns([expresion])
      ..where(db.usosRepuesto.ordenId.equals(ordenId));
    final fila = await query.getSingle();
    return fila.read(expresion) ?? 0;
  }

  Future<int> totalPagado(int ordenId) async {
    final query = db.selectOnly(db.pagos)
      ..addColumns([db.pagos.montoCentavos.sum()])
      ..where(db.pagos.ordenId.equals(ordenId));
    final fila = await query.getSingle();
    return fila.read(db.pagos.montoCentavos.sum()) ?? 0;
  }

  Future<int> saldo(int ordenId) async {
    final trabajos = await totalTrabajos(ordenId);
    final repuestos = await totalRepuestos(ordenId);
    final pagado = await totalPagado(ordenId);
    return trabajos + repuestos - pagado;
  }
}