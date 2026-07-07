import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';

class PdfGolPartidoItem {
  final String jugadorNombre;
  final String equipoNombre;
  final int cantidad;

  const PdfGolPartidoItem({
    required this.jugadorNombre,
    required this.equipoNombre,
    required this.cantidad,
  });
}

class PdfResultadoPartidoItem {
  final PartidoModel partido;
  final List<PdfGolPartidoItem> goles;

  const PdfResultadoPartidoItem({
    required this.partido,
    required this.goles,
  });
}

class PdfEquipoJugadoresItem {
  final EquipoModel equipo;
  final List<JugadorModel> jugadores;

  const PdfEquipoJugadoresItem({
    required this.equipo,
    required this.jugadores,
  });
}

class PdfRankingGoleadorItem {
  final String jugadorNombre;
  final String equipoNombre;
  final int totalGoles;
  final int partidosConGol;

  const PdfRankingGoleadorItem({
    required this.jugadorNombre,
    required this.equipoNombre,
    required this.totalGoles,
    required this.partidosConGol,
  });
}

class PdfService {
  static final PdfColor _verde = PdfColor.fromHex('006B4F');
  static final PdfColor _verdeOscuro = PdfColor.fromHex('004D3A');
  static final PdfColor _verdeTexto = PdfColor.fromHex('4F7F3A');
  static final PdfColor _grisClaro = PdfColor.fromHex('E5E7EB');
  static final PdfColor _grisMedio = PdfColor.fromHex('6B7280');
  static final PdfColor _grisTexto = PdfColor.fromHex('111827');

  static const String _logoUpsaPath = 'assets/images/logo_upsa.png';
  static const String _logoUpsa40Path = 'assets/images/logo_upsa_40.png';

  Future<_PdfLogos> _loadLogos() async {
    final logoUpsaData = await rootBundle.load(_logoUpsaPath);
    final logoUpsa40Data = await rootBundle.load(_logoUpsa40Path);

    return _PdfLogos(
      logoUpsa: pw.MemoryImage(logoUpsaData.buffer.asUint8List()),
      logoUpsa40: pw.MemoryImage(logoUpsa40Data.buffer.asUint8List()),
    );
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin programar';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  String _horaTexto(DateTime? fecha) {
    if (fecha == null) return '--:--';

    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$hora:$minuto';
  }

  String _fechaCorta(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  String _diaMesTexto(DateTime fecha) {
    final dias = [
      'LUNES',
      'MARTES',
      'MIÉRCOLES',
      'JUEVES',
      'VIERNES',
      'SÁBADO',
      'DOMINGO',
    ];

    final meses = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];

    return '$diaSemana $dia DE $mes';
  }

  String _rangoTexto(DateTime? inicio, DateTime? fin) {
    if (inicio == null || fin == null) return '';
    return '${_fechaCorta(inicio)} - ${_fechaCorta(fin)}';
  }

  String _tituloCampeonato(CampeonatoModel campeonato) {
    return campeonato.nombre.trim().isEmpty
        ? 'FÚTBOL INTERCARRERAS'
        : campeonato.nombre.trim().toUpperCase();
  }

  List<PartidoModel> _ordenarPartidos(List<PartidoModel> partidos) {
    final ordenados = [...partidos];

    ordenados.sort((a, b) {
      if (a.fechaHora != null && b.fechaHora != null) {
        final fechaCompare = a.fechaHora!.compareTo(b.fechaHora!);
        if (fechaCompare != 0) return fechaCompare;
      }

      if (a.fechaHora == null && b.fechaHora != null) return 1;
      if (a.fechaHora != null && b.fechaHora == null) return -1;

      final vueltaCompare = a.vuelta.compareTo(b.vuelta);
      if (vueltaCompare != 0) return vueltaCompare;

      return a.jornada.compareTo(b.jornada);
    });

    return ordenados;
  }

  Map<String, List<PartidoModel>> _agruparPorFecha(List<PartidoModel> partidos) {
    final agrupados = <String, List<PartidoModel>>{};

    for (final partido in _ordenarPartidos(partidos)) {
      final fecha = partido.fechaHora;
      if (fecha == null) continue;

      final key =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

      agrupados.putIfAbsent(key, () => []);
      agrupados[key]!.add(partido);
    }

    return agrupados;
  }

  Future<Uint8List> generarFixturePdf({
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();
    final partidosOrdenados = _ordenarPartidos(partidos);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
        build: (context) {
          return [
            _programacionHeader(
              campeonato: campeonato,
              titulo: 'PROGRAMACIÓN COMPLETA',
              logos: logos,
            ),
            pw.SizedBox(height: 24),
            _programacionLista(
              partidosOrdenados,
              incluirSinFecha: true,
            ),
            pw.SizedBox(height: 28),
            _coordinacionFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarFixturePorRangoPdf({
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();
    final partidosOrdenados = _ordenarPartidos(partidos);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
        build: (context) {
          return [
            _programacionHeader(
              campeonato: campeonato,
              titulo: 'PROGRAMACIÓN',
              subtitulo: _rangoTexto(fechaInicio, fechaFin),
              logos: logos,
            ),
            pw.SizedBox(height: 24),
            _programacionLista(
              partidosOrdenados,
              incluirSinFecha: false,
            ),
            pw.SizedBox(height: 28),
            _coordinacionFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarResultadosPorRangoPdf({
    required CampeonatoModel campeonato,
    required List<PdfResultadoPartidoItem> resultados,
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(44, 38, 44, 38),
        build: (context) {
          return [
            _programacionHeader(
              campeonato: campeonato,
              titulo: 'RESULTADOS',
              subtitulo: _rangoTexto(fechaInicio, fechaFin),
              logos: logos,
            ),
            pw.SizedBox(height: 22),
            ...resultados.map(_resultadoCard),
            pw.SizedBox(height: 24),
            _coordinacionFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarRankingGoleadoresPdf({
    required CampeonatoModel campeonato,
    required List<PdfRankingGoleadorItem> ranking,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(48, 42, 48, 42),
        build: (context) {
          return [
            _programacionHeader(
              campeonato: campeonato,
              titulo: 'RANKING DE GOLEADORES',
              subtitulo: 'TOP 10',
              logos: logos,
            ),
            pw.SizedBox(height: 24),
            pw.Table.fromTextArray(
              headers: const [
                'POS.',
                'JUGADOR',
                'EQUIPO',
                'GOLES',
                'PARTIDOS CON GOL',
              ],
              data: List.generate(ranking.length, (index) {
                final item = ranking[index];

                return [
                  '${index + 1}',
                  item.jugadorNombre,
                  item.equipoNombre,
                  '${item.totalGoles}',
                  '${item.partidosConGol}',
                ];
              }),
              headerDecoration: pw.BoxDecoration(color: _verdeOscuro),
              headerStyle: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(7),
              border: pw.TableBorder.all(color: _grisClaro),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.SizedBox(height: 28),
            _coordinacionFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarPlanillaPartidoPdf({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> jugadoresLocal,
    required List<JugadorModel> jugadoresVisitante,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    final localOrdenado = [...jugadoresLocal]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    final visitanteOrdenado = [...jugadoresVisitante]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 18),
        build: (context) {
          return pw.Column(
            children: [
              _planillaHeader(
                campeonato: campeonato,
                partido: partido,
                logos: logos,
              ),
              _planillaEquiposHeader(partido),
              _planillaJugadoresTable(
                local: localOrdenado,
                visitante: visitanteOrdenado,
              ),
              pw.SizedBox(height: 12),
              _planillaFooter(),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarListaEquipoPdf({
    required CampeonatoModel campeonato,
    required EquipoModel equipo,
    required List<JugadorModel> jugadores,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    final jugadoresOrdenados = [...jugadores]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
        build: (context) {
          return [
            _formalHeader(
              titulo: 'PLANILLA DE EQUIPO',
              subtitulo: campeonato.nombre,
              logos: logos,
            ),
            pw.SizedBox(height: 16),
            _equipoInfo(equipo, jugadoresOrdenados.length),
            pw.SizedBox(height: 14),
            _listaEquipoTable(jugadoresOrdenados),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generarListasEquiposPdf({
    required CampeonatoModel campeonato,
    required List<PdfEquipoJugadoresItem> equipos,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    for (final item in equipos) {
      final jugadoresOrdenados = [...item.jugadores]
        ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
          build: (context) {
            return [
              _formalHeader(
                titulo: 'PLANILLA DE EQUIPO',
                subtitulo: campeonato.nombre,
                logos: logos,
              ),
              pw.SizedBox(height: 16),
              _equipoInfo(item.equipo, jugadoresOrdenados.length),
              pw.SizedBox(height: 14),
              _listaEquipoTable(jugadoresOrdenados),
            ];
          },
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _programacionHeader({
    required CampeonatoModel campeonato,
    required String titulo,
    required _PdfLogos logos,
    String? subtitulo,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _logo(
              image: logos.logoUpsa40,
              width: 72,
              height: 52,
            ),
            _logo(
              image: logos.logoUpsa,
              width: 116,
              height: 52,
            ),
          ],
        ),
        pw.SizedBox(height: 42),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                _tituloCampeonato(campeonato),
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  color: _verdeTexto,
                  fontSize: 25,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  color: _verdeTexto,
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              if (subtitulo != null && subtitulo.trim().isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  subtitulo,
                  style: pw.TextStyle(
                    color: _grisTexto,
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _programacionLista(
    List<PartidoModel> partidos, {
    required bool incluirSinFecha,
  }) {
    if (partidos.isEmpty) {
      return pw.Text(
        'No hay partidos para mostrar.',
        style: pw.TextStyle(
          fontSize: 12,
          color: _grisMedio,
        ),
      );
    }

    final agrupados = _agruparPorFecha(partidos);
    final sinFecha = partidos.where((partido) => partido.fechaHora == null).toList();

    final widgets = <pw.Widget>[];

    if (agrupados.isEmpty && (!incluirSinFecha || sinFecha.isEmpty)) {
      widgets.add(
        pw.Text(
          'No hay partidos programados con fecha y hora.',
          style: pw.TextStyle(
            fontSize: 12,
            color: _grisMedio,
          ),
        ),
      );
    }

    agrupados.forEach((_, partidosDia) {
      final fecha = partidosDia.first.fechaHora!;

      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8, top: 12),
          child: pw.Text(
            _diaMesTexto(fecha),
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      for (final partido in partidosDia) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 44,
                  child: pw.Text(
                    _horaTexto(partido.fechaHora),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '${partido.equipoLocalNombre.toUpperCase()} VS ${partido.equipoVisitanteNombre.toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    'CANCHA 1',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      widgets.add(pw.SizedBox(height: 10));
    });

    if (incluirSinFecha && sinFecha.isNotEmpty) {
      widgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8, top: 16),
          child: pw.Text(
            'PARTIDOS SIN PROGRAMAR',
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      );

      for (final partido in sinFecha) {
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 44,
                  child: pw.Text(
                    '--:--',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    '${partido.equipoLocalNombre.toUpperCase()} VS ${partido.equipoVisitanteNombre.toUpperCase()}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ),
                pw.SizedBox(
                  width: 80,
                  child: pw.Text(
                    'CANCHA 1',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: widgets,
    );
  }

  pw.Widget _resultadoCard(PdfResultadoPartidoItem item) {
    final partido = item.partido;

    final golesLocal = item.goles
        .where((gol) => gol.equipoNombre == partido.equipoLocalNombre)
        .toList();

    final golesVisitante = item.goles
        .where((gol) => gol.equipoNombre == partido.equipoVisitanteNombre)
        .toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisClaro),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'FINAL DEL PARTIDO',
            style: pw.TextStyle(
              color: _verdeOscuro,
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  partido.equipoLocalNombre.toUpperCase(),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                width: 92,
                margin: const pw.EdgeInsets.symmetric(horizontal: 16),
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                decoration: pw.BoxDecoration(
                  color: _verdeOscuro,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  partido.equipoVisitanteNombre.toUpperCase(),
                  textAlign: pw.TextAlign.left,
                  style: pw.TextStyle(
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '${_fechaTexto(partido.fechaHora)} · Jornada ${partido.jornada}',
            style: pw.TextStyle(
              fontSize: 9,
              color: _grisMedio,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _goleadoresBox(
                  titulo: partido.equipoLocalNombre,
                  goles: golesLocal,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: _goleadoresBox(
                  titulo: partido.equipoVisitanteNombre,
                  goles: golesVisitante,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _goleadoresBox({
    required String titulo,
    required List<PdfGolPartidoItem> goles,
  }) {
    final jugadores = goles.isEmpty
        ? 'Sin goles registrados'
        : goles.map((gol) {
            final cantidad = gol.cantidad > 1 ? ' x${gol.cantidad}' : '';
            return '${gol.jugadorNombre}$cantidad';
          }).join('\n');

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('F9FAFB'),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _grisClaro),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            jugadores,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _coordinacionFooter() {
    return pw.Center(
      child: pw.Column(
        children: [
          pw.Text(
            'JORGE JOAQUIN ANTEQUERA CASTEDO',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'COORDINACIÓN DE DEPORTES UPSA',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _planillaHeader({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required _PdfLogos logos,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(130),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(130),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 54,
              alignment: pw.Alignment.center,
              child: _logo(
                image: logos.logoUpsa,
                width: 92,
                height: 40,
              ),
            ),
            pw.Container(
              height: 54,
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'PLANILLA DE CONTROL',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    'FÚTBOL',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Formulario de Calidad',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 54,
              padding: const pw.EdgeInsets.all(8),
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'UPSA P4-2-2-F8',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Revisión: 2',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    'Página 1 de 1',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _planillaInfoCell(''),
            _planillaInfoCell(
              'CAMPEONATO: ${campeonato.nombre.toUpperCase()}',
              bold: true,
            ),
            _planillaInfoCell(
              'FECHA: ${_fechaCorta(partido.fechaHora)}   HORA: ${_horaTexto(partido.fechaHora)}',
              bold: true,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _planillaEquiposHeader(PartidoModel partido) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(27),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(24),
        3: pw.FixedColumnWidth(24),
        4: pw.FixedColumnWidth(25),
        5: pw.FixedColumnWidth(25),
        6: pw.FixedColumnWidth(27),
        7: pw.FlexColumnWidth(),
        8: pw.FixedColumnWidth(24),
        9: pw.FixedColumnWidth(24),
        10: pw.FixedColumnWidth(25),
        11: pw.FixedColumnWidth(25),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
          children: [
            _smallCell('N°', bold: true),
            _smallCell(
              'EQUIPO: ${partido.equipoLocalNombre.toUpperCase()}',
              bold: true,
            ),
            _smallCell('TARJETAS', bold: true),
            _smallCell('', bold: true),
            _smallCell('GOLES', bold: true),
            _smallCell('', bold: true),
            _smallCell('N°', bold: true),
            _smallCell(
              'EQUIPO: ${partido.equipoVisitanteNombre.toUpperCase()}',
              bold: true,
            ),
            _smallCell('TARJETAS', bold: true),
            _smallCell('', bold: true),
            _smallCell('GOLES', bold: true),
            _smallCell('', bold: true),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F9FAFB')),
          children: [
            _smallCell('', bold: true),
            _smallCell('NOMBRE Y APELLIDO', bold: true),
            _smallCell('TA', bold: true),
            _smallCell('TR', bold: true),
            _smallCell('1T', bold: true),
            _smallCell('2T', bold: true),
            _smallCell('', bold: true),
            _smallCell('NOMBRE Y APELLIDO', bold: true),
            _smallCell('TA', bold: true),
            _smallCell('TR', bold: true),
            _smallCell('1T', bold: true),
            _smallCell('2T', bold: true),
          ],
        ),
      ],
    );
  }

  pw.Widget _planillaJugadoresTable({
    required List<JugadorModel> local,
    required List<JugadorModel> visitante,
  }) {
    final totalRows = [
      local.length,
      visitante.length,
      22,
    ].reduce((a, b) => a > b ? a : b);

    return pw.Expanded(
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.65),
        columnWidths: const {
          0: pw.FixedColumnWidth(27),
          1: pw.FlexColumnWidth(),
          2: pw.FixedColumnWidth(24),
          3: pw.FixedColumnWidth(24),
          4: pw.FixedColumnWidth(25),
          5: pw.FixedColumnWidth(25),
          6: pw.FixedColumnWidth(27),
          7: pw.FlexColumnWidth(),
          8: pw.FixedColumnWidth(24),
          9: pw.FixedColumnWidth(24),
          10: pw.FixedColumnWidth(25),
          11: pw.FixedColumnWidth(25),
        },
        children: List.generate(totalRows, (index) {
          final localJugador = index < local.length ? local[index] : null;
          final visitanteJugador =
              index < visitante.length ? visitante[index] : null;

          return pw.TableRow(
            children: [
              _rowCell(''),
              _rowCell(localJugador?.nombreCompleto.toUpperCase() ?? ''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(visitanteJugador?.nombreCompleto.toUpperCase() ?? ''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(''),
              _rowCell(''),
            ],
          );
        }),
      ),
    );
  }

  pw.Widget _planillaFooter() {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _lineaFirma('FIRMA CAPITÁN'),
            _lineaFirma('FIRMA ÁRBITRO'),
            _lineaFirma('FIRMA CAPITÁN'),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          children: [
            pw.Text(
              'RESULTADO FINAL:',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 150, height: 1, color: PdfColors.black),
            pw.Spacer(),
            pw.Text(
              'ÁRBITRO:',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 120, height: 1, color: PdfColors.black),
            pw.SizedBox(width: 18),
            pw.Text(
              '1° ASISTENTE:',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 95, height: 1, color: PdfColors.black),
            pw.SizedBox(width: 18),
            pw.Text(
              '2° ASISTENTE:',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 95, height: 1, color: PdfColors.black),
          ],
        ),
      ],
    );
  }

  pw.Widget _lineaFirma(String texto) {
    return pw.Column(
      children: [
        pw.Container(width: 130, height: 1, color: PdfColors.black),
        pw.SizedBox(height: 4),
        pw.Text(
          texto,
          style: const pw.TextStyle(fontSize: 7),
        ),
      ],
    );
  }

  pw.Widget _planillaInfoCell(String text, {bool bold = false}) {
    return pw.Container(
      height: 24,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _smallCell(String text, {bool bold = false}) {
    return pw.Container(
      height: 17,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        maxLines: 1,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _rowCell(String text) {
    return pw.Container(
      height: 13.2,
      alignment: pw.Alignment.centerLeft,
      padding: const pw.EdgeInsets.symmetric(horizontal: 3),
      child: pw.Text(
        text,
        maxLines: 1,
        style: const pw.TextStyle(fontSize: 6.4),
      ),
    );
  }

  pw.Widget _formalHeader({
    required String titulo,
    required String subtitulo,
    required _PdfLogos logos,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _logo(
              image: logos.logoUpsa40,
              width: 70,
              height: 44,
            ),
            _logo(
              image: logos.logoUpsa,
              width: 110,
              height: 44,
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _verdeOscuro,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                subtitulo,
                style: const pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _equipoInfo(EquipoModel equipo, int cantidadJugadores) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _grisClaro),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Equipo: ${equipo.nombre}'),
          pw.Text('Representante: ${equipo.representante}'),
          pw.Text('Carrera: ${equipo.carrera ?? "No aplica"}'),
          pw.Text('Facultad: ${equipo.facultad ?? "No aplica"}'),
          pw.Text('Jugadores registrados: $cantidadJugadores'),
        ],
      ),
    );
  }

  pw.Widget _listaEquipoTable(List<JugadorModel> jugadores) {
    return pw.Table.fromTextArray(
      headers: const [
        'N°',
        'Número de registro',
        'Nombre completo',
        'Firma',
        'Observación',
      ],
      data: List.generate(jugadores.length, (index) {
        final jugador = jugadores[index];

        return [
          '${index + 1}',
          jugador.codigoEstudiante,
          jugador.nombreCompleto,
          '',
          '',
        ];
      }),
      headerDecoration: pw.BoxDecoration(color: _verdeOscuro),
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
        fontSize: 8,
      ),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellPadding: const pw.EdgeInsets.all(6),
      border: pw.TableBorder.all(color: _grisClaro),
      cellAlignment: pw.Alignment.centerLeft,
    );
  }

  pw.Widget _logo({
    required pw.MemoryImage image,
    required double width,
    required double height,
  }) {
    return pw.Image(
      image,
      width: width,
      height: height,
      fit: pw.BoxFit.contain,
    );
  }
}

class _PdfLogos {
  final pw.MemoryImage logoUpsa;
  final pw.MemoryImage logoUpsa40;

  const _PdfLogos({
    required this.logoUpsa,
    required this.logoUpsa40,
  });
}