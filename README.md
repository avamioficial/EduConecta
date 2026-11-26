# Educonecta

*by Avami*

Plataforma móvil para aprender programación (primer curso: **Dart**), con ingreso por
**reconocimiento facial**, lecciones con corrección inmediata y progreso guardado por usuario.

> **Estado: prototipo funcional.** Probado en Android. Ver los pendientes al final.

## Qué incluye

- Registro con consentimiento explícito, captura del rostro y **prueba de vida**
  (parpadeo y giro de cabeza, en orden aleatorio).
- Ingreso con el rostro, sin contraseña, que crea una **sesión real** de Supabase Auth.
- Rechazo de rostros que ya están registrados.
- Curso de Dart, Nivel 1: 4 lecciones y 12 ejercicios con explicación, código y retroalimentación.
- Una lección solo cuenta como completada si se aciertan todos los ejercicios; se conserva el mejor resultado.
- Progreso por usuario, protegido con reglas de seguridad en la base de datos.
- Identidad visual propia: tema oscuro, ícono y logo giratorio.

## Tecnologías

- **Flutter / Dart** (`camera`, `face_detection_tflite`, `flutter_litert`, `supabase_flutter`)
- **Supabase**: PostgreSQL con `pgvector`, Auth y Edge Functions (Deno / TypeScript)
- Modelo de rostros MobileFaceNet (vector de 192 números), incluido en `face_detection_tflite`

## Cómo funciona

```
App Flutter
  |  vector facial (192 números)
  v
Edge Function (registrar / ingresar)
  |--> PostgreSQL + pgvector: busca el rostro más cercano
  |--> código de un solo uso --> la app lo canjea por una sesión (Supabase Auth)

App con sesión --> tabla progreso (RLS: cada usuario solo ve y guarda lo suyo)
```

## Seguridad y privacidad

- **No se guardan fotos**: solo un vector numérico del rostro, con consentimiento del usuario.
- Las tablas `usuarios` y `rostros` no son accesibles desde la app: solo mediante funciones del servidor.
- La tabla `progreso` usa RLS: cada usuario solo accede a sus filas.
- **Limitación conocida:** la prueba de vida corre en el celular. Protege contra fotos fijas,
  pero no contra quien manipule la app o llame al servidor directamente. No es de nivel bancario.

## Cómo ejecutarlo

Requisitos: Flutter instalado, un celular Android y un proyecto de Supabase.

1. Crear el proyecto en Supabase con **Automatically expose new tables** desactivado y
   **Enable automatic RLS** activado.
2. Ejecutar [`supabase/esquema.sql`](supabase/esquema.sql) en el SQL Editor.
3. Crear las funciones `registrar` e `ingresar` con los archivos de
   [`supabase/functions`](supabase/functions) y apagar **Verify JWT with legacy secret** en ambas.
4. Copiar `lib/config.example.dart` como `lib/config.dart` y completar la URL y la clave *publishable*.
5. `flutter pub get` y `flutter run` con el celular conectado.

El reconocimiento facial **no funciona en navegador** con el paquete actual.

## Pendientes

- Ingreso de respaldo (correo o PIN) y varias muestras del rostro por usuario.
- Límites de intentos, política de privacidad y autorización para menores de edad.
- Niveles 2 al 8 del curso, y el tigre mascota como guía.
- Versión web y publicación en Play Store.
- Confirmar la licencia del modelo facial antes de cualquier uso comercial.
