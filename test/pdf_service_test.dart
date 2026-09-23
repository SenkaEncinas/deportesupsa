// Red de seguridad para los PDF: no comprueban cómo se ven, pero sí que
// se generen y con cuántas hojas. Alcanza para refactorizar el armado de
// las páginas sin romperlas en silencio.

import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/pdf_service.dart';

CampeonatoModel _campeonato() {
  return CampeonatoModel.fromMap('camp-1', {
    'nombre': 'Copa de prueba',
    'deporte': DeporteTipo.futbol,
    'tipoCampeonato': TipoCampeonato.gruposEliminacion,
    'estado': CampeonatoEstado.activo,
    'temporada': '02/2026',
    'cancha': 'Cancha UPSA',
    'configuracion': {'formato': TipoCampeonato.gruposEliminacion},
  });
}

PartidoModel _partido(int i, {bool jugado = false, DateTime? fecha}) {
  return PartidoModel.fromMap('p$i', {
    'jornada': 1,
    'vuelta': 1,
    'grupoId': 'Grupo A',
    'equipoLocalId': 'local$i',
    'equipoLocalNombre': 'Equipo local $i',
    'equipoVisitanteId': 'visita$i',
    'equipoVisitanteNombre': 'Equipo visitante $i',
    'estado': jugado ? PartidoEstado.finalizado : PartidoEstado.programado,
    'resultadoRegistrado': jugado,
    'golesLocal': jugado ? 2 : null,
    'golesVisitante': jugado ? 1 : null,
    if (fecha != null) 'fechaHora': fecha.toIso8601String(),
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final servicio = PdfService();

  test('el fixture genera un PDF', () async {
    final bytes = await servicio.generarFixturePdf(
      campeonato: _campeonato(),
      partidos: [
        for (var i = 1; i <= 6; i++)
          _partido(i, fecha: DateTime(2026, 10, 1 + i, 18)),
      ],
    );

    expect(bytes.isNotEmpty, isTrue);
    expect(bytes.length, greaterThan(1000));
  });

  test('el fixture sin partidos no rompe', () async {
    final bytes = await servicio.generarFixturePdf(
      campeonato: _campeonato(),
      partidos: const [],
    );

    expect(bytes.isNotEmpty, isTrue);
  });

  test('los resultados por rango generan un PDF', () async {
    final bytes = await servicio.generarResultadosPorRangoPdf(
      campeonato: _campeonato(),
      resultados: [
        for (var i = 1; i <= 4; i++)
          PdfResultadoPartidoItem(
            partido: _partido(i, jugado: true, fecha: DateTime(2026, 10, 1, 18)),
            goles: const [],
          ),
      ],
      fechaInicio: DateTime(2026, 10, 1),
      fechaFin: DateTime(2026, 10, 8),
    );

    expect(bytes.isNotEmpty, isTrue);
    expect(bytes.length, greaterThan(1000));
  });

  test('los resultados sin nada en el rango no rompen', () async {
    final bytes = await servicio.generarResultadosPorRangoPdf(
      campeonato: _campeonato(),
      resultados: const [],
      fechaInicio: DateTime(2026, 10, 1),
      fechaFin: DateTime(2026, 10, 8),
    );

    expect(bytes.isNotEmpty, isTrue);
  });
}
