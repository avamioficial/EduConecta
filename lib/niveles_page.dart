import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'contenido.dart';
import 'leccion_page.dart';
import 'modelos.dart';

class NivelesPage extends StatelessWidget {
  const NivelesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tu camino en Dart')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: niveles.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final nivel = niveles[i];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(child: Text('${nivel.numero}')),
              title: Text(nivel.titulo),
              subtitle: Text(nivel.descripcion),
              trailing: Icon(
                nivel.disponible ? Icons.chevron_right : Icons.lock_outline,
              ),
              onTap: () {
                if (!nivel.disponible) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente')),
                  );
                  return;
                }
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => NivelPage(nivel: nivel)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Resultado {
  const _Resultado(this.aciertos, this.total);

  final int aciertos;
  final int total;

  bool get perfecto => aciertos == total;
}

class NivelPage extends StatefulWidget {
  const NivelPage({super.key, required this.nivel});

  final Nivel nivel;

  @override
  State<NivelPage> createState() => _NivelPageState();
}

class _NivelPageState extends State<NivelPage> {
  // número de lección -> mejor resultado
  Map<int, _Resultado> _resultados = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final filas = await Supabase.instance.client
          .from('progreso')
          .select('leccion, aciertos, total')
          .eq('nivel', widget.nivel.numero);
      if (!mounted) return;
      setState(() {
        _resultados = {
          for (final f in filas)
            (f['leccion'] as int): _Resultado(
              f['aciertos'] as int,
              f['total'] as int,
            ),
        };
      });
    } catch (_) {
      // Sin sesión o sin conexión: se muestran las lecciones sin progreso.
    }
  }

  String _subtitulo(Leccion leccion, _Resultado? r) {
    if (r == null) return '${leccion.ejercicios.length} ejercicios';
    if (r.perfecto) return 'Completada: ${r.aciertos} de ${r.total}';
    return 'Mejor resultado: ${r.aciertos} de ${r.total} · inténtalo de nuevo';
  }

  @override
  Widget build(BuildContext context) {
    final nivel = widget.nivel;
    return Scaffold(
      appBar: AppBar(title: Text('Nivel ${nivel.numero}: ${nivel.titulo}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: nivel.lecciones.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final leccion = nivel.lecciones[i];
          final r = _resultados[i + 1];
          final completada = r != null && r.perfecto;
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(leccion.titulo),
              subtitle: Text(_subtitulo(leccion, r)),
              trailing: completada
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.chevron_right),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LeccionPage(
                      leccion: leccion,
                      nivel: nivel.numero,
                      numero: i + 1,
                    ),
                  ),
                );
                _cargar();
              },
            ),
          );
        },
      ),
    );
  }
}