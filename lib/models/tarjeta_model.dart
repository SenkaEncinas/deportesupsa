import 'model_helpers.dart';

/// Sanción individual a un jugador durante un partido. En fútbol/futsal
/// son tarjetas amarillas/rojas reales; en vóley/básquet, el mismo campo
/// se usa para una sanción por mesa (amarillas=1) o una sanción forzada
/// -expulsión/descalificación- (rojas=1), ver [SancionTipo].
class TarjetaModel {
  final String id;
  final String partidoId;
  final String equipoId;
  final String equipoNombre;
  final String jugadorId;
  final String jugadorNombre;
  final int amarillas;
  final int rojas;
  final String? motivo;
  final DateTime? fechaRegistro;
  final String registradoPor;

  const TarjetaModel({
    required this.id,
    required this.partidoId,
    required this.equipoId,
    required this.equipoNombre,
    required this.jugadorId,
    required this.jugadorNombre,
    required this.amarillas,
    required this.rojas,
    this.motivo,
    this.fechaRegistro,
    required this.registradoPor,
  });

  factory TarjetaModel.fromMap(String id, Map<String, dynamic> map) {
    return TarjetaModel(
      id: id,
      partidoId: stringFromJson(map['partidoId']),
      equipoId: stringFromJson(map['equipoId']),
      equipoNombre: stringFromJson(map['equipoNombre']),
      jugadorId: stringFromJson(map['jugadorId']),
      jugadorNombre: stringFromJson(map['jugadorNombre']),
      amarillas: intFromJson(map['amarillas']),
      rojas: intFromJson(map['rojas']),
      motivo: map['motivo'] == null ? null : stringFromJson(map['motivo']),
      fechaRegistro: dateFromJson(map['fechaRegistro']),
      registradoPor: stringFromJson(map['registradoPor']),
    );
  }

  bool get esExpulsion => rojas > 0;
}

/// Tipo de sanción para deportes sin tarjetas tradicionales (vóley,
/// básquet): se traduce a amarillas/rojas para reutilizar el mismo
/// modelo y la misma pantalla de "Jugadores sancionados".
class SancionTipo {
  static const String porMesa = 'por_mesa';
  static const String forzada = 'forzada';
}
