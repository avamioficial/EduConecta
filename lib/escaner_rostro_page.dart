import 'dart:io';
import 'dart:math' show Random;

import 'package:camera/camera.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_litert/flutter_litert.dart' show rotationForFrame;

enum _Paso { parpadear, girar, mirarFrente }

/// Pide retos de prueba de vida, captura el rostro y devuelve su vector.
class EscanerRostroPage extends StatefulWidget {
  const EscanerRostroPage({super.key, this.titulo = 'Escáner de rostro'});

  final String titulo;

  @override
  State<EscanerRostroPage> createState() => _EscanerRostroPageState();
}

class _EscanerRostroPageState extends State<EscanerRostroPage> {
  CameraController? _controller;
  CameraDescription? _camara;
  FaceDetector? _detector;
  String? _error;

  late final List<_Paso> _pasos;
  int _indice = 0;
  String _mensaje = '';
  DateTime _inicioPaso = DateTime.now();

  bool _vioAbiertos = false;
  bool _vioCerrados = false;
  int _framesFrontales = 0;
  bool _procesandoFrame = false;
  bool _capturando = false;

  @override
  void initState() {
    super.initState();
    final retos = [_Paso.parpadear, _Paso.girar]..shuffle(Random());
    _pasos = [...retos, _Paso.mirarFrente];
    _mensaje = _textoPaso();
    if (kIsWeb) {
      _error = 'El escáner facial solo está disponible en la app del celular '
          'por ahora.';
    } else {
      _iniciar();
    }
  }

  String _textoPaso() {
    if (_indice >= _pasos.length) return 'Capturando...';
    final titulo = 'Paso ${_indice + 1} de ${_pasos.length}\n';
    switch (_pasos[_indice]) {
      case _Paso.parpadear:
        return '${titulo}Parpadea una vez 👁️';
      case _Paso.girar:
        return '${titulo}Gira la cabeza hacia un lado ↔️';
      case _Paso.mirarFrente:
        return '${titulo}Mira al frente sin moverte';
    }
  }

  void _mostrar(String texto) {
    if (mounted && _mensaje != texto) setState(() => _mensaje = texto);
  }

  void _reiniciarPaso() {
    _vioAbiertos = false;
    _vioCerrados = false;
    _framesFrontales = 0;
    _inicioPaso = DateTime.now();
  }

  Future<void> _iniciar() async {
    try {
      final camaras = await availableCameras();
      final frontal = camaras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => camaras.first,
      );
      final controller = CameraController(
        frontal,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await controller.initialize();
      final detector = await FaceDetector.create(
        model: FaceDetectionModel.frontCamera,
      );
      if (!mounted) {
        await controller.dispose();
        await detector.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _camara = frontal;
        _detector = detector;
      });
      _reiniciarPaso();
      await controller.startImageStream(_alLlegarFrame);
    } catch (e) {
      if (mounted) setState(() => _error = 'Error al iniciar la cámara: $e');
    }
  }

  Future<void> _alLlegarFrame(CameraImage imagen) async {
    final c = _controller;
    final d = _detector;
    final cam = _camara;
    if (c == null || d == null || cam == null) return;
    if (_procesandoFrame || _capturando || !mounted) return;
    _procesandoFrame = true;
    try {
      final rotacion = rotationForFrame(
        width: imagen.width,
        height: imagen.height,
        sensorOrientation: cam.sensorOrientation,
        isFrontCamera: cam.lensDirection == CameraLensDirection.front,
        deviceOrientation: c.value.deviceOrientation,
      );
      final caras = await d.detectFacesFromCameraImage(
        imagen,
        rotation: rotacion,
        mode: FaceDetectionMode.full,
        maxDim: 640,
      );
      if (!mounted) return;
      _evaluar(caras);
    } catch (_) {
      // Un fotograma que falla se ignora.
    } finally {
      _procesandoFrame = false;
    }
  }

  void _evaluar(List<Face> caras) {
    if (_indice >= _pasos.length) return;

    if (DateTime.now().difference(_inicioPaso) > const Duration(seconds: 20)) {
      _reiniciarPaso();
      _mostrar('Otra vez:\n${_textoPaso()}');
      return;
    }
    if (caras.isEmpty) {
      _mostrar('No se ve tu rostro. Acércate y busca más luz');
      return;
    }
    if (caras.length > 1) {
      _mostrar('Debe haber una sola persona frente a la cámara');
      return;
    }

    final cara = caras.first;
    _mostrar(_textoPaso());

    switch (_pasos[_indice]) {
      case _Paso.parpadear:
        final izq = cara.leftEyeOpenProbability;
        final der = cara.rightEyeOpenProbability;
        if (izq == null || der == null) return;
        final promedio = (izq + der) / 2;
        final abiertos = promedio > 0.6;
        final cerrados = promedio < 0.45;
        if (abiertos && !_vioCerrados) _vioAbiertos = true;
        if (_vioAbiertos && cerrados) _vioCerrados = true;
        if (_vioCerrados && abiertos) _siguientePaso();
      case _Paso.girar:
        final yaw = cara.headEulerAngleY;
        if (yaw != null && yaw.abs() > 15) _siguientePaso();
      case _Paso.mirarFrente:
        // Estricto a propósito: de esta captura depende el reconocimiento.
        final yaw = cara.headEulerAngleY ?? 99;
        final izq = cara.leftEyeOpenProbability ?? 0;
        final der = cara.rightEyeOpenProbability ?? 0;
        if (yaw.abs() < 10 && izq > 0.6 && der > 0.6) {
          _framesFrontales++;
        } else {
          _framesFrontales = 0;
        }
        if (_framesFrontales >= 3) _capturar();
    }
  }

  void _siguientePaso() {
    _indice++;
    _reiniciarPaso();
    if (mounted) setState(() => _mensaje = _textoPaso());
  }

  Future<void> _capturar() async {
    final c = _controller;
    final d = _detector;
    if (c == null || d == null || _capturando) return;
    _capturando = true;
    _indice = _pasos.length;
    _mostrar('Capturando...');

    XFile? foto;
    List<double>? resultado;
    String? error;
    try {
      await c.stopImageStream();
      final tomada = await c.takePicture();
      foto = tomada;
      final bytes = await tomada.readAsBytes();
      final caras = await d.detectFacesFromBytes(
        bytes,
        mode: FaceDetectionMode.full,
      );
      if (caras.length != 1) {
        error = 'No se pudo confirmar tu rostro. Intenta de nuevo';
      } else {
        final emb = await d.getFaceEmbedding(caras.first, bytes);
        resultado = List<double>.from(emb as Iterable);
      }
    } catch (e) {
      error = 'Error al capturar: $e';
    } finally {
      if (foto != null) {
        try {
          await File(foto.path).delete();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    if (resultado != null) {
      Navigator.of(context).pop(resultado);
      return;
    }

    _capturando = false;
    _indice = 0;
    _reiniciarPaso();
    setState(() => _mensaje = '$error\n${_textoPaso()}');
    try {
      await c.startImageStream(_alLlegarFrame);
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detector?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : (c == null || !c.value.isInitialized || _detector == null)
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(child: Center(child: CameraPreview(c))),
                    LinearProgressIndicator(value: _indice / _pasos.length),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _mensaje,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
    );
  }
}