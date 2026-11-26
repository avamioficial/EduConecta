import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'escaner_rostro_page.dart';
import 'niveles_page.dart';
import 'registro_page.dart';
import 'logo_giratorio.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  bool _cargando = false;

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _ingresar() async {
    final embedding = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (_) => const EscanerRostroPage(titulo: 'Ingresar con rostro'),
      ),
    );
    if (embedding == null || !mounted) return;

    setState(() => _cargando = true);
    try {
      final respuesta = await Supabase.instance.client.functions.invoke(
        'ingresar',
        headers: {'apikey': supabaseKey},
        body: {'embedding': embedding},
      );
      final datos = respuesta.data;
      final nombre = (datos is Map && datos['usuario'] is Map)
          ? datos['usuario']['nombre']?.toString()
          : null;
      final tokenHash = (datos is Map) ? datos['token_hash']?.toString() : null;
      if (nombre == null || tokenHash == null) {
        if (mounted) _mensaje('Respuesta inesperada del servidor');
        return;
      }

      // Canjea el código de un solo uso por una sesión real
      await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.magiclink,
        tokenHash: tokenHash,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => BienvenidaPage(nombre: nombre)),
      );
    } on FunctionException catch (e) {
      if (!mounted) return;
      final detalle = e.details;
      _mensaje((detalle is Map && detalle['error'] != null)
          ? detalle['error'].toString()
          : 'No se pudo ingresar (error ${e.status})');
    } on AuthException catch (e) {
      if (!mounted) return;
      _mensaje('No se pudo iniciar la sesión: ${e.message}');
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                                const Center(child: LogoGiratorio(tamano: 160)),
                const SizedBox(height: 16),
                Text(
                  'Educonecta',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'by Avami',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _cargando ? null : _ingresar,
                  icon: const Icon(Icons.camera_alt),
                  label: _cargando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingresar con rostro'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _cargando
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const RegistroPage()),
                          ),
                  child: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BienvenidaPage extends StatelessWidget {
  const BienvenidaPage({super.key, required this.nombre});

  final String nombre;

  @override
  Widget build(BuildContext context) {
    final correo = Supabase.instance.client.auth.currentUser?.email;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenido'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Hola, $nombre 👋',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              correo == null
                  ? 'Sin sesión activa'
                  : 'Sesión iniciada como $correo',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NivelesPage()),
              ),
              child: const Text('Empezar a aprender Dart'),
            ),
            const SizedBox(height: 12),
                        OutlinedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const InicioPage()),
                    (ruta) => false,
                  );
                }
              },
              child: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primera pantalla de la app: muestra el logo y entra directo si hay sesión.
class RaizPage extends StatefulWidget {
  const RaizPage({super.key});

  @override
  State<RaizPage> createState() => _RaizPageState();
}

class _RaizPageState extends State<RaizPage> {
  late final Future<String?> _nombre = _cargarConPausa();

  // Espera un mínimo para que se vea el logo girando.
  Future<String?> _cargarConPausa() async {
    final resultados = await Future.wait<String?>([
      _cargarNombre(),
      Future<String?>.delayed(const Duration(milliseconds: 2000), () => null),
    ]);
    return resultados.first;
  }

  Future<String?> _cargarNombre() async {
    final cliente = Supabase.instance.client;
    final usuario = cliente.auth.currentUser;
    if (usuario == null) return null;
    try {
      final fila = await cliente
          .from('usuarios')
          .select('nombre')
          .eq('id', usuario.id)
          .single();
      return fila['nombre'] as String?;
    } catch (_) {
      // Sesión vencida o sin conexión: se pide el rostro de nuevo.
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _nombre,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: LogoGiratorio(tamano: 160)),
          );
        }
        final nombre = snapshot.data;
        return nombre == null
            ? const InicioPage()
            : BienvenidaPage(nombre: nombre);
      },
    );
  }
}