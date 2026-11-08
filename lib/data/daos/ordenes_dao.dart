import 'package:drift/drift.dart';

import '../app_database.dart';
import '../calculos_orden.dart';

part 'ordenes_dao.g.dart';

// Una orden con su vehículo, cliente y mecánico ya resueltos, más sus
// totales. Es lo que pide la lista de órdenes y el panel de inicio.
class OrdenResumen {
  OrdenResumen({
    required this.orden,
    required this.vehiculo,
    required this.cliente,
    required this.mecanico,
    required this.totalCentavos,
    required this.saldoCentavos,
  });

  final Orden orden;
  final Vehiculo vehiculo;
  final Cliente cliente;
  final Mecanico mecanico;
  final int totalCentavos;
  final int saldoCentavos;
}

// Un repuesto usado en una orden, con sus datos de catálogo incluidos.
class UsoConRepuesto {
  UsoConRepuesto({required this.uso, required this.repuesto});
  final UsoRepuesto uso;
  final Repuesto repuesto;
}

// Un pago con los datos de la orden, el vehículo y el cliente a los
// que pertenece. Para la lista de Facturación.
class PagoConOrden {
  PagoConOrden({
    required this.pago,
    required this.orden,
    required this.vehiculo,
    required this.cliente,
  });

  final Pago pago;
  final Orden orden;
  final Vehiculo vehiculo;
  final Cliente cliente;
}

@DriftAccessor(
  tables: [
    Ordenes,
    Trabajos,
    UsosRepuesto,
    Pagos,
    Vehiculos,
    Clientes,
    Mecanicos,
  ],
)
class OrdenesDao extends DatabaseAccessor<AppDatabase> with _$OrdenesDaoMixin {
  OrdenesDao(super.attachedDatabase);

  late final _calculos = CalculosOrden(attachedDatabase);

  // Filtros opcionales por estado y por mecánico, para la pantalla
  // Órdenes y las tarjetas del Inicio.
  Stream<List<OrdenResumen>> watchOrdenes({
    EstadoOrden? estado,
    int? mecanicoId,
  }) {
    final query = select(ordenes).join([
      innerJoin(vehiculos, vehiculos.id.equalsExp(ordenes.vehiculoId)),
      innerJoin(clientes, clientes.id.equalsExp(vehiculos.clienteId)),
      innerJoin(mecanicos, mecanicos.id.equalsExp(ordenes.mecanicoId)),
    ]);
    if (estado != null) {
      query.where(ordenes.estado.equalsValue(estado));
    }
    if (mecanicoId != null) {
      query.where(ordenes.mecanicoId.equals(mecanicoId));
    }
    query.orderBy([OrderingTerm.desc(ordenes.creadaEn)]);

    return query.watch().asyncMap((filas) async {
      final resultado = <OrdenResumen>[];
      for (final fila in filas) {
        final orden = fila.readTable(ordenes);
        final trabajos = await _calculos.totalTrabajos(orden.id);
        final repuestos = await _calculos.totalRepuestos(orden.id);
        final pagado = await _calculos.totalPagado(orden.id);
        resultado.add(
          OrdenResumen(
            orden: orden,
            vehiculo: fila.readTable(vehiculos),
            cliente: fila.readTable(clientes),
            mecanico: fila.readTable(mecanicos),
            totalCentavos: trabajos + repuestos,
            saldoCentavos: trabajos + repuestos - pagado,
          ),
        );
      }
      return resultado;
    });
  }

  Stream<List<Orden>> watchDeVehiculo(int vehiculoId) =>
      (select(ordenes)..where((o) => o.vehiculoId.equals(vehiculoId))).watch();

  Future<Orden> obtener(int id) =>
      (select(ordenes)..where((o) => o.id.equals(id))).getSingle();

  Stream<List<Trabajo>> watchTrabajos(int ordenId) =>
      (select(trabajos)..where((t) => t.ordenId.equals(ordenId))).watch();

  Stream<List<Pago>> watchPagos(int ordenId) =>
      (select(pagos)..where((p) => p.ordenId.equals(ordenId))).watch();

  Stream<List<UsoConRepuesto>> watchRepuestosUsados(int ordenId) {
    final query = select(usosRepuesto).join([
      innerJoin(repuestos, repuestos.id.equalsExp(usosRepuesto.repuestoId)),
    ])..where(usosRepuesto.ordenId.equals(ordenId));
    return query.watch().map(
      (filas) => filas
          .map(
            (f) => UsoConRepuesto(
              uso: f.readTable(usosRepuesto),
              repuesto: f.readTable(repuestos),
            ),
          )
          .toList(),
    );
  }

  Future<int> saldo(int ordenId) => _calculos.saldo(ordenId);

  Future<int> crearOrden(OrdenesCompanion datos) => into(ordenes).insert(datos);

  Future<void> editarOrden(int id, OrdenesCompanion datos) =>
      (update(ordenes)..where((o) => o.id.equals(id))).write(datos);

  Future<void> cambiarEstado(int id, EstadoOrden nuevoEstado) =>
      (update(ordenes)..where((o) => o.id.equals(id))).write(
        OrdenesCompanion(estado: Value(nuevoEstado)),
      );

  Future<void> agregarTrabajo(TrabajosCompanion datos) =>
      into(trabajos).insert(datos);

  Future<void> quitarTrabajo(int id) =>
      (delete(trabajos)..where((t) => t.id.equals(id))).go();

  // Agrega el repuesto a la orden y descuenta la existencia. Si una de
  // las dos escrituras falla, ninguna se guarda.
  Future<void> agregarRepuesto({
    required int ordenId,
    required int repuestoId,
    required int cantidad,
    required int precioUnitarioCentavos,
  }) {
    return transaction(() async {
      final repuesto = await (select(
        repuestos,
      )..where((r) => r.id.equals(repuestoId))).getSingle();
      if (repuesto.existencias < cantidad) {
        throw Exception('No hay suficientes existencias de ${repuesto.nombre}');
      }
      await into(usosRepuesto).insert(
        UsosRepuestoCompanion.insert(
          ordenId: ordenId,
          repuestoId: repuestoId,
          cantidad: cantidad,
          precioUnitarioCentavos: precioUnitarioCentavos,
        ),
      );
      await (update(repuestos)..where((r) => r.id.equals(repuestoId))).write(
        RepuestosCompanion(existencias: Value(repuesto.existencias - cantidad)),
      );
    });
  }

  Future<void> quitarRepuesto(int usoId) {
    return transaction(() async {
      final uso = await (select(
        usosRepuesto,
      )..where((u) => u.id.equals(usoId))).getSingle();
      await (delete(usosRepuesto)..where((u) => u.id.equals(usoId))).go();
      final repuesto = await (select(
        repuestos,
      )..where((r) => r.id.equals(uso.repuestoId))).getSingle();
      await (update(
        repuestos,
      )..where((r) => r.id.equals(uso.repuestoId))).write(
        RepuestosCompanion(
          existencias: Value(repuesto.existencias + uso.cantidad),
        ),
      );
    });
  }

  // No se permite superar el saldo pendiente de la orden.
  Future<void> registrarPago({
    required int ordenId,
    required int montoCentavos,
  }) async {
    final saldo = await _calculos.saldo(ordenId);
    if (montoCentavos > saldo) {
      throw Exception('El pago no puede superar el saldo pendiente');
    }
    await into(pagos).insert(
      PagosCompanion.insert(
        ordenId: ordenId,
        montoCentavos: montoCentavos,
        fecha: DateTime.now(),
      ),
    );
  }

  // Cancela la orden y devuelve al inventario todo lo que se había
  // descontado.
  Future<void> cancelarOrden(int ordenId) {
    return transaction(() async {
      final usos = await (select(
        usosRepuesto,
      )..where((u) => u.ordenId.equals(ordenId))).get();
      for (final uso in usos) {
        final repuesto = await (select(
          repuestos,
        )..where((r) => r.id.equals(uso.repuestoId))).getSingle();
        await (update(
          repuestos,
        )..where((r) => r.id.equals(uso.repuestoId))).write(
          RepuestosCompanion(
            existencias: Value(repuesto.existencias + uso.cantidad),
          ),
        );
      }
      await (update(ordenes)..where((o) => o.id.equals(ordenId))).write(
        const OrdenesCompanion(estado: Value(EstadoOrden.cancelada)),
      );
    });
  }

  // Suma los pagos registrados en el mes actual.
  Stream<int> watchFacturacionDelMes() {
    final ahora = DateTime.now();
    final inicioMes = DateTime(ahora.year, ahora.month, 1);
    final finMes = DateTime(ahora.year, ahora.month + 1, 1);

    final query = selectOnly(pagos)
      ..addColumns([pagos.montoCentavos.sum()])
      ..where(
        pagos.fecha.isBiggerOrEqualValue(inicioMes) &
            pagos.fecha.isSmallerThanValue(finMes),
      );

    return query.watchSingle().map(
      (fila) => fila.read(pagos.montoCentavos.sum()) ?? 0,
    );
  }

  Stream<List<PagoConOrden>> watchPagosEnPeriodo(
    DateTime desde,
    DateTime hastaExclusivo,
  ) {
    final query =
        select(pagos).join([
            innerJoin(ordenes, ordenes.id.equalsExp(pagos.ordenId)),
            innerJoin(vehiculos, vehiculos.id.equalsExp(ordenes.vehiculoId)),
            innerJoin(clientes, clientes.id.equalsExp(vehiculos.clienteId)),
          ])
          ..where(
            pagos.fecha.isBiggerOrEqualValue(desde) &
                pagos.fecha.isSmallerThanValue(hastaExclusivo),
          )
          ..orderBy([OrderingTerm.desc(pagos.fecha)]);

    return query.watch().map(
      (filas) => filas
          .map(
            (fila) => PagoConOrden(
              pago: fila.readTable(pagos),
              orden: fila.readTable(ordenes),
              vehiculo: fila.readTable(vehiculos),
              cliente: fila.readTable(clientes),
            ),
          )
          .toList(),
    );
  }

  Future<int> totalOrden(int ordenId) async {
    final trabajos = await _calculos.totalTrabajos(ordenId);
    final repuestos = await _calculos.totalRepuestos(ordenId);
    return trabajos + repuestos;
  }

  Future<int> totalPagado(int ordenId) => _calculos.totalPagado(ordenId);
}
