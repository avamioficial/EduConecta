import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modelos.dart';
import 'tema.dart';

class CodigoBloque extends StatelessWidget {
  const CodigoBloque(this.codigo, {super.key});

  final String codigo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF06112E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Marca.borde),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          codigo,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            height: 1.4,
            color: Color(0xFFBFF6FF),
          ),
        ),
      ),
    );
  }
}

class LeccionPage extends StatefulWidget {
  const LeccionPage({
    super.key,
    required this.leccion,
    required this.nivel,
    required this.numero,
  });

  final Leccion leccion;
  final int nivel; // número del nivel (1, 2, ...)
  final int numero; // número de la lección dentro del nivel (1, 2, ...)

  @override
  State<LeccionPage> createState() => _LeccionPageState();
}

class _LeccionPageState extends State<LeccionPage> {
  int _paso = 0; // 0 = teoría, 1..n = ejercicios, n+1 = resultado
  int? _elegida;
  int _aciertos = 0;
  String? _estadoGuardado;

  int get _total => 1 + widget.leccion.ejercicios.length;

  void _responder(Ejercicio e, int i) {
    setState(() {
      _elegida = i;
      if (i == e.correcta) _aciertos++;
    });
  }

  void _continuar() {
    setState(() {
      _paso++;
      _elegida = null;
    });
    if (_paso == _total) _guardarProgreso();
  }

  void _reiniciar() {
    setState(() {
      _paso = 0;
      _elegida = null;
      _aciertos = 0;
      _estadoGuardado = null;
    });
  }

  Future<void> _guardarProgreso() async {
    final cliente = Supabase.instance.client;
    if (cliente.auth.currentUser == null) {
      setState(() => _estadoGuardado = 'Inicia sesión para guardar tu progreso');
      return;
    }
    setState(() => _estadoGuardado = 'Guardando tu progreso...');
    try {
      await cliente.rpc('guardar_progreso', params: {
        'p_nivel': widget.nivel,
        'p_leccion': widget.numero,
        'p_aciertos': _aciertos,
        'p_total': widget.leccion.ejercicios.length,
      });
      if (mounted) setState(() => _estadoGuardado = 'Progreso guardado ✅');
    } catch (_) {
      if (mounted) {
        setState(() => _estadoGuardado = 'No se pudo guardar tu progreso');
      }
    }
  }

  ButtonStyle _estiloOpcion(Ejercicio e, int i) {
    Color? relleno;
    Color borde = Marca.borde;
    if (_elegida != null) {
      if (i == e.correcta) {
        relleno = Marca.acierto.withValues(alpha: 0.18);
        borde = Marca.acierto;
      } else if (i == _elegida) {
        relleno = Marca.error.withValues(alpha: 0.18);
        borde = Marca.error;
      }
    }
    final apagada = _elegida != null && relleno == null;
    final colorTexto = apagada ? Marca.textoSuave : Marca.texto;
    return OutlinedButton.styleFrom(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      foregroundColor: colorTexto,
      disabledForegroundColor: colorTexto,
      backgroundColor: relleno,
      disabledBackgroundColor: relleno,
      side: BorderSide(color: borde, width: relleno == null ? 1 : 2),
    );
  }

  Widget _teoria(Leccion l) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          l.explicacion,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
        if (l.codigo != null) ...[
          const SizedBox(height: 20),
          CodigoBloque(l.codigo!),
        ],
        const SizedBox(height: 28),
        FilledButton(
          onPressed: _continuar,
          child: const Text('Empezar ejercicios'),
        ),
      ],
    );
  }

  Widget _ejercicio(Ejercicio e) {
    final respondido = _elegida != null;
    final acerto = _elegida == e.correcta;
    final colorAviso = acerto ? Marca.acierto : Marca.error;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(e.pregunta, style: Theme.of(context).textTheme.titleMedium),
        if (e.codigo != null) ...[
          const SizedBox(height: 14),
          CodigoBloque(e.codigo!),
        ],
        const SizedBox(height: 18),
        for (var i = 0; i < e.opciones.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: _estiloOpcion(e, i),
              onPressed: respondido ? null : () => _responder(e, i),
              child: Text(e.opciones[i]),
            ),
          ),
        if (respondido) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colorAviso.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorAviso),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  acerto ? '¡Correcto! ✅' : 'Casi 😅',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(e.explicacion),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _continuar,
            child: Text(_paso + 1 < _total ? 'Continuar' : 'Ver resultado'),
          ),
        ],
      ],
    );
  }

  Widget _resultado(Leccion l) {
    final n = l.ejercicios.length;
    final perfecto = _aciertos == n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              perfecto ? '🏆' : '💪',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              perfecto ? '¡Lección completada!' : '¡Casi lo logras!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Acertaste $_aciertos de $n'),
            if (!perfecto) ...[
              const SizedBox(height: 8),
              const Text(
                'Para completar la lección necesitas acertar todos los ejercicios.',
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _estadoGuardado ?? '',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 28),
            if (perfecto) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: _reiniciar,
                child: const Text('Repetir lección'),
              ),
            ] else ...[
              FilledButton(
                onPressed: _reiniciar,
                child: const Text('Intentar de nuevo'),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.leccion;
    final Widget cuerpo;
    if (_paso == 0) {
      cuerpo = _teoria(l);
    } else if (_paso < _total) {
      cuerpo = _ejercicio(l.ejercicios[_paso - 1]);
    } else {
      cuerpo = _resultado(l);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.titulo)),
      body: Column(
        children: [
          LinearProgressIndicator(value: _paso / _total),
          Expanded(child: cuerpo),
        ],
      ),
    );
  }
}