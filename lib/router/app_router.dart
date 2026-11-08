import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/app_database.dart';
import '../viewmodels/sesion_controller.dart';
import '../views/login/login_screen.dart';
import '../views/inicio/inicio_screen.dart';
import '../views/ordenes/ordenes_screen.dart';
import '../views/ordenes/orden_detalle_screen.dart';
import '../views/ordenes/orden_formulario_screen.dart';
import '../views/clientes/clientes_screen.dart';
import '../views/clientes/cliente_detalle_screen.dart';
import '../views/vehiculos/vehiculo_detalle_screen.dart';
import '../views/inventario/inventario_screen.dart';
import '../views/facturacion/facturacion_screen.dart';
import '../views/mecanicos/mecanicos_screen.dart';
import '../views/usuarios/usuarios_screen.dart';
import '../widgets/shell_scaffold.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

const _staff = {RolUsuario.dueno, RolUsuario.recepcion};
const _soloDueno = {RolUsuario.dueno};

// Rutas con restricción de rol. Las que no aparecen aquí (Inicio, listado y
// detalle de órdenes) son para cualquier usuario con sesión; el detalle
// controla por su cuenta que el mecánico solo vea sus órdenes.
Set<RolUsuario>? _rolesDe(String ubicacion) {
  if (ubicacion == '/ordenes/nueva' || ubicacion.endsWith('/editar')) {
    return _staff;
  }
  const reglas = <String, Set<RolUsuario>>{
    '/facturacion': _soloDueno,
    '/mecanicos': _soloDueno,
    '/usuarios': _soloDueno,
    '/clientes': _staff,
    '/inventario': _staff,
    '/vehiculos': _staff,
  };
  for (final entrada in reglas.entries) {
    if (ubicacion.startsWith(entrada.key)) return entrada.value;
  }
  return null;
}

GoRouter crearRouter(SesionController sesion) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/inicio',
    refreshListenable: sesion,
    redirect: (context, state) {
      final ubicacion = state.matchedLocation;

      if (!sesion.conSesion) {
        return ubicacion == '/login' ? null : '/login';
      }
      if (ubicacion == '/login') return '/inicio';

      final roles = _rolesDe(ubicacion);
      if (roles != null && !sesion.puede(roles)) return '/inicio';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inicio',
              builder: (context, state) => const InicioScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/ordenes',
              builder: (context, state) => OrdenesScreen(
                estadoInicial: state.uri.queryParameters['estado'],
              ),
              routes: [
                GoRoute(
                  path: 'nueva',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => OrdenFormularioScreen(
                    clienteInicialId:
                        int.tryParse(state.uri.queryParameters['clienteId'] ?? ''),
                    vehiculoInicialId:
                        int.tryParse(state.uri.queryParameters['vehiculoId'] ?? ''),
                  ),
                ),
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => OrdenDetalleScreen(
                    ordenId: int.parse(state.pathParameters['id']!),
                  ),
                  routes: [
                    GoRoute(
                      path: 'editar',
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => OrdenFormularioScreen(
                        ordenId: int.parse(state.pathParameters['id']!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/clientes',
              builder: (context, state) => const ClientesScreen(),
              routes: [
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: _rootNavigatorKey,
                  builder: (context, state) => ClienteDetalleScreen(
                    clienteId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/inventario',
              builder: (context, state) => const InventarioScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/vehiculos/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => VehiculoDetalleScreen(
          vehiculoId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/facturacion',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FacturacionScreen(),
      ),
      GoRoute(
        path: '/mecanicos',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const MecanicosScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const UsuariosScreen(),
      ),
    ],
  );
}