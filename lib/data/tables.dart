import 'package:drift/drift.dart';

enum EstadoOrden {
  recibida,
  enDiagnostico,
  enReparacion,
  listaParaEntregar,
  entregada,
  cancelada,
}

// Clientes del taller. El teléfono es único y tiene 8 dígitos.
class Clientes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text().withLength(min: 3, max: 60)();
  TextColumn get telefono => text().withLength(min: 8, max: 8).unique()();
  TextColumn get direccion => text().nullable()();
}

// Vehículos. Cada uno pertenece a un cliente. La matrícula es única.
class Vehiculos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get clienteId => integer().references(Clientes, #id)();
  TextColumn get matricula => text().unique()();
  TextColumn get marca => text()();
  TextColumn get modelo => text()();
  IntColumn get anio => integer()();
  IntColumn get kilometraje => integer().withDefault(const Constant(0))();
}

// Mecánicos fijos. Se cargan al crear la base.
class Mecanicos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get nombre => text()();
}

// Visitas del vehículo al taller.
@DataClassName('Orden')
class Ordenes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get vehiculoId => integer().references(Vehiculos, #id)();
  IntColumn get mecanicoId => integer().references(Mecanicos, #id)();
  DateTimeColumn get fechaEntrada => dateTime()();
  IntColumn get kilometrajeEntrada => integer()();
  TextColumn get problema => text().withLength(min: 1, max: 500)();
  TextColumn get estado => textEnum<EstadoOrden>()();
  DateTimeColumn get creadaEn => dateTime().withDefault(currentDateAndTime)();
}

// Mano de obra de una orden.
class Trabajos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  TextColumn get descripcion => text()();
  IntColumn get precioCentavos => integer()();
}

// Repuestos del inventario. El código es único.
class Repuestos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get codigo => text().unique()();
  TextColumn get nombre => text()();
  IntColumn get precioCentavos => integer()();
  IntColumn get existencias => integer().withDefault(const Constant(0))();
  IntColumn get umbralAlerta => integer().withDefault(const Constant(3))();
} 

@DataClassName('UsoRepuesto')
class UsosRepuesto extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  IntColumn get repuestoId => integer().references(Repuestos, #id)();
  IntColumn get cantidad => integer()();
  IntColumn get precioUnitarioCentavos => integer()();
}

// Pagos y abonos de una orden.
class Pagos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ordenId => integer().references(Ordenes, #id)();
  IntColumn get montoCentavos => integer()();
  DateTimeColumn get fecha => dateTime()();
}

enum RolUsuario { dueno, recepcion, mecanico }

// Cuentas de la app. Un usuario mecánico se vincula a su registro en Mecanicos.
class Usuarios extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().unique()();
  TextColumn get nombre => text().withLength(min: 3, max: 60)();
  TextColumn get passwordHash => text()();
  TextColumn get salt => text()();
  TextColumn get rol => textEnum<RolUsuario>()();
  IntColumn get mecanicoId => integer().nullable().references(Mecanicos, #id)();
}