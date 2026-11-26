import 'package:flutter/material.dart';

/// Colores de la marca (tomados de la hoja de la mascota y del logo).
class Marca {
  static const fondo = Color(0xFF020C32); // azul marino
  static const superficie = Color(0xFF0B1A47); // tarjetas
  static const borde = Color(0xFF28418F);
  static const naranja = Color(0xFFFF8A1F); // color principal
  static const celeste = Color(0xFF1FE5FF); // acento
  static const texto = Color(0xFFF2F6FF);
  static const textoSuave = Color(0xFFB4C0E3);
  static const acierto = Color(0xFF34D399);
  static const error = Color(0xFFFF6B7A);
}

ThemeData temaEduconecta() {
  final esquema = const ColorScheme.dark(
    primary: Marca.naranja,
    onPrimary: Marca.fondo,
    secondary: Marca.celeste,
    onSecondary: Marca.fondo,
    tertiary: Marca.celeste,
    surface: Marca.fondo,
    onSurface: Marca.texto,
    onSurfaceVariant: Marca.textoSuave,
    error: Marca.error,
    onError: Marca.fondo,
    outline: Marca.borde,
    outlineVariant: Marca.borde,
  ).copyWith(
    surfaceContainerLowest: Marca.fondo,
    surfaceContainerLow: Marca.superficie,
    surfaceContainer: Marca.superficie,
    surfaceContainerHigh: Marca.superficie,
    surfaceContainerHighest: Marca.superficie,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    scaffoldBackgroundColor: Marca.fondo,
  );
}