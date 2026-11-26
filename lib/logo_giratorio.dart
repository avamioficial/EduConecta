import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Logo que gira en 3D alternando entre dos imágenes.
class LogoGiratorio extends StatefulWidget {
  const LogoGiratorio({super.key, this.tamano = 160});

  final double tamano;

  @override
  State<LogoGiratorio> createState() => _LogoGiratorioState();
}

class _LogoGiratorioState extends State<LogoGiratorio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _imagen(String ruta) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.tamano * 0.22),
      child: Image.asset(
        ruta,
        width: widget.tamano,
        height: widget.tamano,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Dos medias vueltas por ciclo, con pausa suave en cada logo
        final t = _controller.value * 2;
        final media = t.floor();
        final avance = Curves.easeInOutCubic.transform(t - media);
        final angulo = (media + avance) * math.pi;
        final verPrimero = math.cos(angulo) >= 0;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(angulo),
          child: verPrimero
              ? _imagen('assets/logo_gorro.png')
              : Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(math.pi),
                  child: _imagen('assets/logo_tigre.png'),
                ),
        );
      },
    );
  }
}