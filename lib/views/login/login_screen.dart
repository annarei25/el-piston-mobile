import 'package:flutter/material.dart';
import '../../data/app_scope.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarController = TextEditingController();

  Future<bool>? _modo;
  bool _enviando = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _modo ??= AppScope.of(context).sesion.hayUsuarios();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _enviar(bool hayUsuarios) async {
    if (!_formKey.currentState!.validate()) return;

    final sesion = AppScope.of(context).sesion;
    setState(() {
      _enviando = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final error = hayUsuarios
        ? await sesion.iniciarSesion(email, password)
        : await sesion.crearDuenoInicial(
            nombre: _nombreController.text.trim(),
            email: email,
            password: password,
          );

    // Si el inicio de sesión funcionó, el router ya cambió de pantalla
    // y este widget ya no existe.
    if (!mounted) return;
    setState(() {
      _enviando = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<bool>(
          future: _modo,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final hayUsuarios = snapshot.data!;

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('EL PISTÓN',
                            textAlign: TextAlign.center,
                            style: tema.textTheme.headlineLarge),
                        const SizedBox(height: 8),
                        Text(
                          hayUsuarios
                              ? 'Inicia sesión para continuar'
                              : 'Configura el taller: crea la cuenta del dueño',
                          textAlign: TextAlign.center,
                          style: tema.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        if (!hayUsuarios) ...[
                          TextFormField(
                            controller: _nombreController,
                            decoration: const InputDecoration(labelText: 'Nombre del dueño'),
                            validator: (valor) => (valor == null || valor.trim().length < 3)
                                ? 'Mínimo 3 caracteres'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
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
                          decoration: const InputDecoration(labelText: 'Contraseña'),
                          obscureText: true,
                          validator: (valor) {
                            if (hayUsuarios) {
                              return (valor ?? '').isEmpty ? 'Escribe la contraseña' : null;
                            }
                            return (valor ?? '').length < 6 ? 'Mínimo 6 caracteres' : null;
                          },
                        ),
                        if (!hayUsuarios) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmarController,
                            decoration: const InputDecoration(labelText: 'Repetir contraseña'),
                            obscureText: true,
                            validator: (valor) => valor != _passwordController.text
                                ? 'Las contraseñas no coinciden'
                                : null,
                          ),
                        ],
                        const SizedBox(height: 16),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyMedium
                                  ?.copyWith(color: tema.colorScheme.error),
                            ),
                          ),
                        FilledButton(
                          onPressed: _enviando ? null : () => _enviar(hayUsuarios),
                          child: _enviando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(hayUsuarios ? 'ENTRAR' : 'CREAR CUENTA Y ENTRAR'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}