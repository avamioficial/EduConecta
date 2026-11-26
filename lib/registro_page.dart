import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'escaner_rostro_page.dart';
import 'config.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _edad = TextEditingController();
  final _correo = TextEditingController();
  String? _pais;
  bool _consentimiento = false;
  bool _guardando = false;

  static const _paises = [
    'Perú', 'Argentina', 'Bolivia', 'Chile', 'Colombia', 'Costa Rica',
    'Ecuador', 'El Salvador', 'España', 'Estados Unidos', 'Guatemala',
    'Honduras', 'México', 'Nicaragua', 'Panamá', 'Paraguay',
    'República Dominicana', 'Uruguay', 'Venezuela', 'Otro',
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _edad.dispose();
    _correo.dispose();
    super.dispose();
  }

  void _mensaje(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consentimiento) {
      _mensaje('Debes aceptar el uso de tu rostro para continuar');
      return;
    }
    final embedding = await Navigator.of(context).push<List<double>>(
      MaterialPageRoute(
        builder: (_) => const EscanerRostroPage(titulo: 'Registro de rostro'),
      ),
    );
    if (embedding == null || !mounted) return;

    setState(() => _guardando = true);
    try {
      await Supabase.instance.client.functions.invoke(
        'registrar',
        headers: {'apikey': supabaseKey},
        body: {
          'nombre': _nombre.text.trim(),
          'edad': int.parse(_edad.text.trim()),
          'pais': _pais,
          'correo': _correo.text.trim().toLowerCase(),
          'embedding': embedding,
        },
      );
      if (!mounted) return;
      _formKey.currentState!.reset();
      _pais = null;
      _consentimiento = false;
      _mensaje('Registro guardado ✅');
    } on FunctionException catch (e) {
      if (!mounted) return;
      final detalle = e.details;
      final texto = (detalle is Map && detalle['error'] != null)
          ? detalle['error'].toString()
          : 'No se pudo registrar (error ${e.status})';
      _mensaje(texto);
    } catch (e) {
      if (!mounted) return;
      _mensaje('Error inesperado: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nombre,
                    decoration: const InputDecoration(
                        labelText: 'Nombre', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Escribe tu nombre'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _edad,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Edad', border: OutlineInputBorder()),
                    validator: (v) {
                      final n = int.tryParse((v ?? '').trim());
                      if (n == null || n < 1 || n > 120) {
                        return 'Ingresa una edad válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: 'País', border: OutlineInputBorder()),
                    items: _paises
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => _pais = v,
                    validator: (v) => v == null ? 'Elige tu país' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _correo,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'Correo', border: OutlineInputBorder()),
                    validator: (v) {
                      final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch((v ?? '').trim());
                      return ok ? null : 'Correo no válido';
                    },
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _consentimiento,
                    onChanged: (v) =>
                        setState(() => _consentimiento = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Acepto que se guarden datos de mi rostro para '
                      'ingresar a la app con el escáner facial.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Continuar y registrar rostro'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}