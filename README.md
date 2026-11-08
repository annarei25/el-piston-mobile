# El Pistón

Aplicación móvil para la gestión diaria de un taller mecánico de barrio: clientes, vehículos, órdenes de servicio, inventario de repuestos y facturación. Funciona completamente sin conexión a internet: todos los datos se guardan en una base de datos local en el teléfono y se conservan aunque la app se cierre.

Proyecto desarrollado para la asignatura Programación para Dispositivos Móviles.

## Tecnologías

- **Flutter** (Android)
- **Drift** sobre SQLite, para persistencia local
- **go_router**, con `StatefulShellRoute.indexedStack` para la navegación por pestañas
- **MVVM** con `ChangeNotifier` para el estado, sin paquetes externos de manejo de estado
- **InheritedWidget** propio (`AppScope`) para compartir la base de datos y el controlador de tema en toda la app

## Cómo ejecutar el proyecto

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

El comando `build_runner` genera el código de Drift (archivos `.g.dart`) a partir de las tablas declaradas en `lib/data/tables.dart`. Es necesario ejecutarlo después de clonar el repositorio y cada vez que se modifica una tabla o un DAO.

## Estructura de carpetas

```
lib/
  data/
    tables.dart            Declaración de las tablas de Drift
    app_database.dart       Base de datos principal, migraciones
    calculos_orden.dart      Cálculo de totales y saldo de una orden
    app_scope.dart           InheritedWidget para compartir base de datos y tema
    daos/                    Consultas y transacciones, una clase por entidad principal
  viewmodels/                Un ChangeNotifier por pantalla, con la lógica de presentación
  views/                     Las pantallas, organizadas por sección
  widgets/
    hojas/                   Formularios en hoja inferior (crear/editar cliente, vehículo, etc.)
  theme/                     Colores, tipografía y la extensión de colores de estado
  router/                    Configuración de go_router
  utils/                     Formato de dinero, fechas, diálogos de confirmación, llamadas
```

## Modelo de datos

Ocho tablas: `Clientes`, `Vehiculos`, `Mecanicos`, `Ordenes`, `Trabajos`, `Repuestos`, `UsosRepuesto` y `Pagos`. El dinero se guarda en centavos (enteros), para evitar errores de redondeo en los saldos. Los totales y el saldo de una orden no se almacenan: se calculan a partir de sus trabajos, repuestos y pagos, para que nunca queden desincronizados.

## Decisiones de diseño

El enunciado deja varios puntos abiertos a criterio del desarrollador. Estas son las decisiones tomadas y su razón:

- **Sin backend ni sincronización.** El enunciado pide que la app funcione sin conexión y conserve los datos al cerrarse; ninguna de las dos cosas requiere un servidor. Un backend solo haría falta si varios teléfonos debieran compartir los datos, lo cual no se pide.
- **Mecánicos editables, no fijos.** El dueño los da de alta él mismo desde la app (no vienen precargados), con un máximo de dos, acorde a lo que describe el enunciado ("dos mecánicos"). No se puede eliminar un mecánico con historial de órdenes, porque dejaría esas órdenes sin saber quién las atendió.
- **Precio de repuesto congelado.** Al agregar un repuesto a una orden, se guarda el precio vigente en ese momento. Si el precio de catálogo sube después, las órdenes ya creadas no cambian.
- **Formulario de orden en una sola pantalla con scroll**, en vez de pasos, por ser pocos campos.
- **Entrega con saldo pendiente permitida, con aviso.** El enunciado menciona clientes que pagan en dos partes, así que se permite marcar una orden como entregada aunque tenga saldo; ese saldo queda visible en el perfil del cliente.
- **Pagos y cancelación.** Un pago no puede superar el saldo pendiente de la orden. Si se cancela una orden con pagos ya registrados, la app lo advierte explícitamente (debe devolverse o acreditarse al cliente de forma manual, fuera de la app) y esos pagos no se cuentan como ingreso en Facturación.
- **Existencias al cancelar o quitar un repuesto.** Vuelven automáticamente al inventario.
- **Umbral de stock bajo**: 3 unidades por defecto, editable por repuesto.
- **Facturación de un período**: suma de los pagos cobrados en esas fechas (no del total facturado), por ser el dinero que el taller recibió realmente. Se desglosa proporcionalmente entre mano de obra y repuestos según el peso de cada uno en el total de cada orden, ya que el pago no se registra separado por concepto.
- **Kilometraje de entrada**: no puede ser menor al último registrado del vehículo. Se bloquea su edición una vez creada la orden, para no generar inconsistencias con el historial.
- **Nada se elimina de forma permanente** salvo mecánicos sin historial y repuestos o clientes que el usuario decida borrar explícitamente desde su pantalla; las órdenes no se eliminan, se cancelan, para conservar el historial del taller.
- **Tema claro y oscuro**, con un botón que cicla entre sistema, claro y oscuro. La paleta oscura sigue la guía de diseño entregada; la paleta clara fue derivada a partir de ella.
- **Sin notificaciones push** para la alerta de stock bajo: se muestra en el panel de Inicio y como contador en la pestaña Inventario, suficiente para un taller de dos mecánicos.

## Capturas

Ver carpeta [`capturas/`](./capturas) con la aplicación en uso.
