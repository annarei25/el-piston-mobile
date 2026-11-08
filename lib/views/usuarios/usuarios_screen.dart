import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/app_database.dart';
import '../../data/app_scope.dart';
import '../../utils/confirmaciones.dart';
import '../../utils/roles.dart';
import '../../viewmodels/usuarios_viewmodel.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  UsuariosViewModel? _viewModel;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    _viewModel ??= UsuariosViewModel(app.database, app.sesion);
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _eliminar(Usuario usuario) async {
    final confirmado = await confirmar(
      context,
      titulo: 'Eliminar usuario',
      mensaje: '¿Eliminar a ${usuario.nombre}? Ya no podrá entrar a la app.',
      textoConfirmar: 'ELIMINAR',
    );
    if (!confirmado) return;

    final error = await _viewModel!.eliminar(usuario);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: () => context.pop()),
          title: const Text('USUARIOS'),
        ),
        body: viewModel.usuarios.isEmpty
            ? const Center(child: Text('No hay usuarios'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: viewModel.usuarios.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, indice) {
                  final usuario = viewModel.usuarios[indice];
                  final mecanico = viewModel.nombreMecanico(usuario.mecanicoId);
                  return Card(
                    child: ListTile(
                      title: Text(usuario.nombre),
                      subtitle: Text(
                        '${usuario.email} · ${etiquetaRol(usuario.rol)}'
                        '${mecanico != null ? ' · $mecanico' : ''}',
                      ),
                      trailing: viewModel.esYo(usuario)
                          ? const Text('Tú')
                          : IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _eliminar(usuario),
                            ),
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _nuevo(),
          icon: const Icon(Icons.add),
          label: const Text('NUEVO USUARIO'),
        ),
      ),
    );
  }

  Future<void> _nuevo() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _HojaUsuario(viewModel: _viewModel!),
    );
  }
}

class _HojaUsuario extends StatefulWidget {
  const _HojaUsuario({required this.viewModel});
  final UsuariosViewModel viewModel;

  @override
  State<_HojaUsuario> createState() => _HojaUsuarioState();
}

class _HojaUsuarioState extends State<_HojaUsuario> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  RolUsuario _rol = RolUsuario.recepcion;
  int? _mecanicoId;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rol == RolUsuario.mecanico && _mecanicoId == null) {
      setState(() => _error = 'Elige a qué mecánico pertenece la cuenta');
      return;
    }

    setState(() {
      _guardando = true;
      _error = null;
    });

    final error = await widget.viewModel.crear(
      nombre: _nombreController.text,
      email: _emailController.text,
      password: _passwordController.text,
      rol: _rol,
      mecanicoId: _rol == RolUsuario.mecanico ? _mecanicoId : null,
    );

    if (!mounted) return;
    if (error != null) {
      setState(() {
        _guardando = false;
        _error = error;
      });
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final libres = widget.viewModel.mecanicosLibres();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('NUEVO USUARIO', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (valor) => (valor == null || valor.trim().length < 3)
                    ? 'Mínimo 3 caracteres'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Correo'),
                keyboardType: TextInputType.emailAddress,
                validator: (valor) => _emailRegex.hasMatch((valor ?? '').trim())
                    ? null
                    : 'Correo no válido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Contraseña inicial'),
                obscureText: true,
                validator: (valor) =>
                    (valor ?? '').length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              Text('ROL', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 8),
              SegmentedButton<RolUsuario>(
                segments: const [
                  ButtonSegment(value: RolUsuario.recepcion, label: Text('Recepción')),
                  ButtonSegment(value: RolUsuario.mecanico, label: Text('Mecánico')),
                  ButtonSegment(value: RolUsuario.dueno, label: Text('Dueño')),
                ],
                selected: {_rol},
                onSelectionChanged: (seleccion) => setState(() {
                  _rol = seleccion.first;
                  _mecanicoId = null;
                }),
              ),
              if (_rol == RolUsuario.mecanico) ...[
                const SizedBox(height: 16),
                Text('MECÁNICO', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                if (libres.isEmpty)
                  Text(
                    'Todos los mecánicos ya tienen cuenta. Crea un mecánico primero '
                    'desde Inicio › Gestionar.',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                else
                  Wrap(
                    spacing: 8,
                    children: libres
                        .map((m) => ChoiceChip(
                              label: Text(m.nombre),
                              selected: _mecanicoId == m.id,
                              onSelected: (_) => setState(() => _mecanicoId = m.id),
                            ))
                        .toList(),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _guardando ? null : _guardar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('CREAR USUARIO'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}