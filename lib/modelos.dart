class Ejercicio {
  const Ejercicio({
    required this.pregunta,
    this.codigo,
    required this.opciones,
    required this.correcta,
    required this.explicacion,
  });

  final String pregunta;
  final String? codigo;
  final List<String> opciones;
  final int correcta; // posición de la opción correcta (empieza en 0)
  final String explicacion;
}

class Leccion {
  const Leccion({
    required this.titulo,
    required this.explicacion,
    this.codigo,
    required this.ejercicios,
  });

  final String titulo;
  final String explicacion;
  final String? codigo;
  final List<Ejercicio> ejercicios;
}

class Nivel {
  const Nivel({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.lecciones,
  });

  final int numero;
  final String titulo;
  final String descripcion;
  final List<Leccion> lecciones;

  bool get disponible => lecciones.isNotEmpty;
}