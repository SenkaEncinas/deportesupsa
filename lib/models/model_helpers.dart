import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateFromJson(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return null;
}

Object? dateToJson(DateTime? value) {
  if (value == null) return null;
  return Timestamp.fromDate(value);
}

String stringFromJson(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  return value.toString();
}

int intFromJson(dynamic value, {int defaultValue = 0}) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString()) ?? defaultValue;
}

bool boolFromJson(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  return defaultValue;
}

/// Mapa `equipoId` -> puntos de igualación. Tolera valores nulos o mal
/// tipados (documentos viejos) en vez de reventar al abrir el campeonato.
Map<String, int> igualacionesFromJson(dynamic value) {
  if (value is! Map) return const {};

  final resultado = <String, int>{};

  value.forEach((clave, valor) {
    final equipoId = clave?.toString().trim() ?? '';
    if (equipoId.isEmpty) return;

    final puntos = intFromJson(valor);
    if (puntos != 0) resultado[equipoId] = puntos;
  });

  return resultado;
}

List<String> stringListFromJson(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((item) => item.toString()).toList();
  }
  return [];
}
