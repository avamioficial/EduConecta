import 'modelos.dart';

const niveles = <Nivel>[
  Nivel(
    numero: 1,
    titulo: 'Primeros pasos',
    descripcion:
        'Qué es programar, tu primer programa, variables y tipos de datos',
    lecciones: [
      // ───────────── Lección 1 ─────────────
      Leccion(
        titulo: 'Qué es programar',
        explicacion:
            'Programar es darle instrucciones a una computadora, paso a paso, '
            'para que haga algo.\n\n'
            'La computadora no piensa por sí sola: hace exactamente lo que le '
            'escribes, en el orden en que lo escribes. A una lista de pasos '
            'ordenados para resolver algo se le llama algoritmo.\n\n'
            'Para escribir esas instrucciones usamos un lenguaje de '
            'programación. En este curso usarás Dart, el lenguaje con el que '
            'se crean las apps de Flutter.',
        codigo: r'''
Algoritmo: servir un vaso de leche
1. Abrir la nevera
2. Sacar la leche
3. Servir un vaso
4. Guardar la leche''',
        ejercicios: [
          Ejercicio(
            pregunta: '¿Qué es un algoritmo?',
            opciones: [
              'Un tipo de computadora',
              'Una lista de pasos ordenados para resolver algo',
              'Un error en el código',
              'Un lenguaje de programación',
            ],
            correcta: 1,
            explicacion:
                'Un algoritmo es una serie de pasos ordenados, como una receta.',
          ),
          Ejercicio(
            pregunta: '¿Para qué sirve un lenguaje de programación?',
            opciones: [
              'Para que la computadora se apague sola',
              'Para escribir instrucciones que la computadora pueda entender',
              'Para conectarse a internet',
              'Para hacer más rápida la pantalla',
            ],
            correcta: 1,
            explicacion:
                'Es el idioma con el que le damos instrucciones a la computadora.',
          ),
          Ejercicio(
            pregunta: '¿Con qué lenguaje se crean las apps de Flutter?',
            opciones: ['Python', 'Dart', 'Java', 'C'],
            correcta: 1,
            explicacion: 'Flutter usa Dart, el lenguaje que aprenderás aquí.',
          ),
        ],
      ),

      // ───────────── Lección 2 ─────────────
      Leccion(
        titulo: 'Tu primer programa',
        explicacion:
            'Todo programa de Dart empieza en una función llamada main. Es el '
            'punto de partida: lo que escribas dentro de sus llaves { } es lo '
            'que se ejecuta.\n\n'
            'Para mostrar texto en pantalla usamos print. El texto va entre '
            'comillas.\n\n'
            'Cada instrucción termina con un punto y coma ;',
        codigo: r'''
void main() {
  print('¡Hola, mundo!');
}''',
        ejercicios: [
          Ejercicio(
            pregunta: '¿Qué muestra este programa?',
            codigo: r'''
void main() {
  print('Hola');
  print('Dart');
}''',
            opciones: [
              'HolaDart en una sola línea',
              'Hola en una línea y Dart en la siguiente',
              'Solo Hola',
              'Da error',
            ],
            correcta: 1,
            explicacion: 'Cada print escribe su texto en una línea nueva.',
          ),
          Ejercicio(
            pregunta: '¿Cuál es el punto de partida de todo programa en Dart?',
            opciones: ['print', 'main', 'void', 'start'],
            correcta: 1,
            explicacion: 'Dart siempre empieza ejecutando la función main.',
          ),
          Ejercicio(
            pregunta: '¿Qué le falta a este programa para funcionar?',
            codigo: r'''
void main() {
  print('Hola')
}''',
            opciones: [
              'Un punto y coma ; al final de la línea del print',
              'Comillas dobles',
              'La palabra start',
              'Nada, está bien',
            ],
            correcta: 0,
            explicacion:
                'Cada instrucción en Dart termina con ; y aquí falta uno.',
          ),
        ],
      ),

      // ───────────── Lección 3 ─────────────
      Leccion(
        titulo: 'Variables',
        explicacion:
            'Una variable es una caja con nombre donde guardas un dato para '
            'usarlo después.\n\n'
            'En Dart puedes crearla de tres formas:\n'
            '• var: el valor se puede cambiar después.\n'
            '• final: se le da un valor una sola vez y ya no cambia.\n'
            '• const: es un valor fijo que ya conoces al escribir el programa.',
        codigo: r'''
void main() {
  var edad = 20;
  edad = 21;
  final nombre = 'Ana';
  const pi = 3.1416;
  print(nombre);
  print(edad);
}''',
        ejercicios: [
          Ejercicio(
            pregunta: '¿Qué imprime este código?',
            codigo: r'''
var puntos = 5;
puntos = 8;
print(puntos);''',
            opciones: ['5', '8', '13', 'Da error'],
            correcta: 1,
            explicacion:
                'Una variable var puede cambiar: primero valía 5 y después 8.',
          ),
          Ejercicio(
            pregunta: '¿Qué pasa con este código?',
            codigo: r'''
final nombre = 'Ana';
nombre = 'Luis';''',
            opciones: [
              'Cambia el nombre a Luis',
              'Da error, porque un final no se puede cambiar',
              'Imprime Ana',
              'No hace nada',
            ],
            correcta: 1,
            explicacion:
                'Un final se asigna una sola vez. Cambiarlo después da error.',
          ),
          Ejercicio(
            pregunta:
                '¿Cuál usarías para un valor fijo que ya conoces al escribir '
                'el programa, como el valor de pi?',
            opciones: ['var', 'const', 'print', 'main'],
            correcta: 1,
            explicacion:
                'const es para valores fijos conocidos desde que escribes el código.',
          ),
        ],
      ),

      // ───────────── Lección 4 ─────────────
      Leccion(
        titulo: 'Tipos de datos',
        explicacion:
            'Cada dato tiene un tipo. Los cuatro básicos de Dart son:\n'
            '• int: números enteros, como 7\n'
            '• double: números con decimales, como 3.5\n'
            '• String: texto entre comillas, como \'Hola\'\n'
            '• bool: verdadero o falso (true o false)\n\n'
            'En lugar de var puedes escribir el tipo directamente.',
        codigo: r'''
void main() {
  int edad = 20;
  double altura = 1.65;
  String nombre = 'Ana';
  bool estudia = true;
  print(nombre);
  print(altura);
}''',
        ejercicios: [
          Ejercicio(
            pregunta: '¿Qué tipo usarías para guardar el precio 19.99?',
            opciones: ['int', 'double', 'String', 'bool'],
            correcta: 1,
            explicacion: 'Tiene decimales, así que es un double.',
          ),
          Ejercicio(
            pregunta: "¿De qué tipo es el valor 'Hola'?",
            opciones: ['int', 'double', 'String', 'bool'],
            correcta: 2,
            explicacion: 'El texto entre comillas es un String.',
          ),
          Ejercicio(
            pregunta: '¿Cuál de estos es un valor bool?',
            opciones: ["'true'", 'true', '1', "'sí'"],
            correcta: 1,
            explicacion:
                'true, sin comillas, es un bool. Con comillas sería un texto.',
          ),
          Ejercicio(
            pregunta: '¿Por qué falla este código?',
            codigo: r'''
int edad = 'veinte';''',
            opciones: [
              'Porque int solo guarda números enteros, no texto',
              'Porque falta el punto y coma',
              'Porque edad es una palabra reservada',
              'No falla',
            ],
            correcta: 0,
            explicacion:
                'Un int solo acepta números enteros. El texto necesita un String.',
          ),
        ],
      ),
    ],
  ),
  Nivel(
    numero: 2,
    titulo: 'Operaciones y texto',
    descripcion: 'Operadores, texto e interpolación, comentarios',
    lecciones: [],
  ),
  Nivel(
    numero: 3,
    titulo: 'Tomar decisiones',
    descripcion: 'if y else, comparaciones, switch',
    lecciones: [],
  ),
  Nivel(
    numero: 4,
    titulo: 'Repetir cosas',
    descripcion: 'Bucles for y while, listas',
    lecciones: [],
  ),
  Nivel(
    numero: 5,
    titulo: 'Funciones',
    descripcion: 'Crear funciones, parámetros, return',
    lecciones: [],
  ),
  Nivel(
    numero: 6,
    titulo: 'Colecciones y null safety',
    descripcion: 'List, Map, Set y valores nulos',
    lecciones: [],
  ),
  Nivel(
    numero: 7,
    titulo: 'Clases',
    descripcion: 'Clases, constructores y objetos',
    lecciones: [],
  ),
  Nivel(
    numero: 8,
    titulo: 'Mini proyectos',
    descripcion: 'Calculadora, adivina el número, lista de tareas',
    lecciones: [],
  ),
];