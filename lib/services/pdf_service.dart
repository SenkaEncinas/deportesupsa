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

  const PdfResultadoPartidoItem({required this.partido, required this.goles});
}

class PdfEquipoJugadoresItem {
  final EquipoModel equipo;
  final List<JugadorModel> jugadores;

  const PdfEquipoJugadoresItem({required this.equipo, required this.jugadores});
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

  /// Etiqueta del deporte en mayúsculas para títulos de PDF.
  /// Los campeonatos antiguos sin deporte se tratan como fútbol.
  String _deporteLabel(CampeonatoModel campeonato) {
    switch (campeonato.deporteEfectivo) {
      case DeporteTipo.volley:
        return 'VÓLEY';
      case DeporteTipo.basket:
        return 'BÁSQUET';
      default:
        return 'FÚTBOL';
    }
  }

  String _tituloCampeonato(CampeonatoModel campeonato) {
    return campeonato.nombre.trim().isEmpty
        ? '${_deporteLabel(campeonato)} INTERCARRERAS'
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

  Map<String, List<PartidoModel>> _agruparPorFecha(
    List<PartidoModel> partidos,
  ) {
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
            _programacionLista(partidosOrdenados, incluirSinFecha: true),
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
            _programacionLista(partidosOrdenados, incluirSinFecha: false),
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
            pw.TableHelper.fromTextArray(
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

  /// Genera el paquete completo para el día del partido.
  ///
  /// Vóley no usa el mismo paquete que fútbol/básquet: no hay tarjetas
  /// ni goles por jugador, y las jugadoras se registran directamente en
  /// mesa (no se imprime lista de plantilla). En su lugar se generan las
  /// fichas de posición por set (ver [_paginaFichasPosicionVoley]).
  ///
  /// Para fútbol/básquet son 4 hojas: la planilla oficial de control, un
  /// cartel con el nombre de cada equipo (lo más grande posible en su
  /// propia hoja, para identificar a los equipos en cancha) y una lista
  /// aparte de jugadores con el número de polera en blanco para que el
  /// equipo de mesa lo complete al momento del control.
  Future<Uint8List> generarPlanillaPartidoPdf({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> jugadoresLocal,
    required List<JugadorModel> jugadoresVisitante,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    if (campeonato.esVolley) {
      pdf.addPage(
        _paginaFichasPosicionVoley(
          campeonato: campeonato,
          partido: partido,
          logos: logos,
        ),
      );
      pdf.addPage(
        _paginaPlanillaControlVoley(
          campeonato: campeonato,
          partido: partido,
          jugadoresLocal: jugadoresLocal,
          jugadoresVisitante: jugadoresVisitante,
          logos: logos,
        ),
      );

      return pdf.save();
    }

    final localOrdenado = [...jugadoresLocal]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    final visitanteOrdenado = [...jugadoresVisitante]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    // Hoja 1: la planilla oficial de control (goles, tarjetas, firmas).
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.landscape,
        margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 18),
        build: (context) {
          return pw.Column(
            // stretch: sin esto, las tablas con columna flexible de abajo
            // toman su ancho "natural" en vez del ancho completo de la
            // hoja, y con eso un nombre corto ya no entra en una sola
            // línea y termina partiéndose a la mitad de la palabra.
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
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

    // Hojas 2 y 3: el nombre de cada equipo, lo más grande posible.
    pdf.addPage(
      _paginaNombreEquipo(
        nombreEquipo: partido.equipoLocalNombre,
        etiqueta: 'EQUIPO LOCAL',
        logos: logos,
      ),
    );

    pdf.addPage(
      _paginaNombreEquipo(
        nombreEquipo: partido.equipoVisitanteNombre,
        etiqueta: 'EQUIPO VISITANTE',
        logos: logos,
      ),
    );

    // Hoja 4: lista de jugadores de ambos equipos con el número de
    // polera vacío, para el control de mesa/puerta.
    pdf.addPage(
      _paginaListaJugadoresPolera(
        campeonato: campeonato,
        partido: partido,
        local: localOrdenado,
        visitante: visitanteOrdenado,
        logos: logos,
      ),
    );

    return pdf.save();
  }

  /// Tamaño de fuente para que el nombre del equipo ocupe todo el ancho
  /// disponible de la hoja en una sola línea, sin desbordar: entre más
  /// largo el nombre, más chico el tamaño (pero siempre grande).
  double _tamanoFuenteNombreEquipo(String nombre, double anchoDisponible) {
    final longitud = nombre.trim().isEmpty ? 1 : nombre.trim().length;
    // 0.62 se quedaba corto para mayúsculas en negrita (letras como M/W
    // son más anchas que el promedio): nombres como "CAMBRIDGE" se
    // calculaban un poco más grandes de lo que en realidad entraba, y la
    // última letra se iba a una segunda línea sola. 0.72 + un 6% de
    // margen deja aire de sobra para cualquier combinación de letras.
    final estimado = (anchoDisponible * 0.94) / (longitud * 0.72);
    return estimado.clamp(40.0, 170.0);
  }

  pw.Page _paginaNombreEquipo({
    required String nombreEquipo,
    required String etiqueta,
    required _PdfLogos logos,
  }) {
    final pageFormat = PdfPageFormat.letter.landscape;
    const margin = 46.0;
    final anchoDisponible = pageFormat.width - (margin * 2);
    final nombre = nombreEquipo.trim().isEmpty
        ? 'EQUIPO'
        : nombreEquipo.trim().toUpperCase();
    final fontSize = _tamanoFuenteNombreEquipo(nombre, anchoDisponible);

    return pw.Page(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(margin),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _logo(image: logos.logoUpsa40, width: 70, height: 44),
                _logo(image: logos.logoUpsa, width: 110, height: 44),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              etiqueta,
              style: pw.TextStyle(
                color: _verdeTexto,
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            pw.Expanded(
              child: pw.Center(
                child: pw.Text(
                  nombre,
                  textAlign: pw.TextAlign.center,
                  maxLines: 2,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.bold,
                    color: _verdeOscuro,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _paginaListaJugadoresPolera({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> local,
    required List<JugadorModel> visitante,
    required _PdfLogos logos,
  }) {
    final filasMinimas = [
      local.length,
      visitante.length,
      22,
    ].reduce((a, b) => a > b ? a : b);

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 32),
      build: (context) {
        return pw.Column(
          // stretch: si no, cada tabla de abajo toma su ancho "natural"
          // en vez del ancho completo disponible, y con la columna de
          // nombre angosta un nombre corto como "Bautista" ya no entra
          // en una sola línea y se parte a la mitad de la palabra.
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _formalHeader(
              titulo: 'LISTA DE JUGADORES · N° DE POLERA',
              subtitulo:
                  '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre} · ${_fechaCorta(partido.fechaHora)}  ${_horaTexto(partido.fechaHora)}',
              logos: logos,
            ),
            pw.SizedBox(height: 14),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _listaJugadoresPoleraTable(
                    tituloEquipo: partido.equipoLocalNombre,
                    jugadores: local,
                    filasMinimas: filasMinimas,
                  ),
                ),
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: _listaJugadoresPoleraTable(
                    tituloEquipo: partido.equipoVisitanteNombre,
                    jugadores: visitante,
                    filasMinimas: filasMinimas,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  pw.Widget _listaJugadoresPoleraTable({
    required String tituloEquipo,
    required List<JugadorModel> jugadores,
    required int filasMinimas,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: _verdeOscuro,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            tituloEquipo.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.7),
          columnWidths: const {
            0: pw.FixedColumnWidth(46),
            1: pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              children: [
                _smallCell('N°', bold: true),
                _smallCell('NOMBRE Y APELLIDO', bold: true),
              ],
            ),
            ...List.generate(filasMinimas, (index) {
              final jugador = index < jugadores.length
                  ? jugadores[index]
                  : null;

              return pw.TableRow(
                children: [
                  pw.Container(
                    constraints: const pw.BoxConstraints(minHeight: 20),
                    alignment: pw.Alignment.center,
                  ),
                  pw.Container(
                    constraints: const pw.BoxConstraints(minHeight: 20),
                    alignment: pw.Alignment.centerLeft,
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    child: pw.Text(
                      jugador?.nombreCompleto.toUpperCase() ?? '',
                      // maxLines 2 (no 1): un nombre con dos apellidos
                      // puede necesitar una segunda línea, pero solo
                      // cortando entre palabras, nunca a la mitad de una.
                      maxLines: 2,
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Fichas de posición de vóley: una por set (1, 2 y 3) para cada
  /// equipo, más una tercera fila sin nombre de equipo por si algún
  /// árbitro/mesa se equivoca al llenarla. En vóley no se imprime lista
  /// de jugadoras ni carteles con el nombre del equipo: las jugadoras se
  /// registran directamente en mesa el día del partido.
  pw.Page _paginaFichasPosicionVoley({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required _PdfLogos logos,
  }) {
    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(22, 20, 22, 18),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _logo(image: logos.logoUpsa40, width: 56, height: 36),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        _tituloCampeonato(campeonato),
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _verdeTexto,
                        ),
                      ),
                      pw.Text(
                        '${partido.equipoLocalNombre.toUpperCase()} VS ${partido.equipoVisitanteNombre.toUpperCase()} · ${_fechaCorta(partido.fechaHora)}  ${_horaTexto(partido.fechaHora)}',
                        textAlign: pw.TextAlign.center,
                        maxLines: 1,
                        style: pw.TextStyle(fontSize: 8, color: _grisMedio),
                      ),
                    ],
                  ),
                ),
                _logo(image: logos.logoUpsa, width: 84, height: 36),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'FICHAS DE POSICIÓN POR SET',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: _grisTexto,
                letterSpacing: 1,
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Expanded(
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.max,
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Expanded(
                    child: _filaFichasPosicion(
                      equipoNombre: partido.equipoLocalNombre,
                    ),
                  ),
                  pw.Expanded(
                    child: _filaFichasPosicion(
                      equipoNombre: partido.equipoVisitanteNombre,
                    ),
                  ),
                  pw.Expanded(
                    child: _filaFichasPosicion(equipoNombre: null),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Widget _filaFichasPosicion({required String? equipoNombre}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [1, 2, 3].map((numeroSet) {
        return pw.Expanded(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(5),
            child: _fichaPosicion(
              numeroSet: numeroSet,
              equipoNombre: equipoNombre,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Una ficha de posición individual: cabecera "SET N", equipo/líbero,
  /// grilla de posiciones de cancha (IV-III-II arriba, V-VI-I abajo) y
  /// entrenador/servicio, calcada de la planilla oficial de vóley.
  ///
  /// Se arma con varias `pw.Table` chicas apiladas (no `pw.Row`+
  /// `pw.Expanded`): en este árbol tan anidado, Expanded dentro de un
  /// Row que a su vez cuelga de un Column dentro de otro Column/Expanded
  /// terminaba colapsando a tamaño cero sin avisar con ningún error.
  /// Table es el patrón que ya se usaba en el resto del archivo y sí
  /// funciona de forma confiable en este mismo árbol.
  pw.Widget _fichaPosicion({
    required int numeroSet,
    required String? equipoNombre,
  }) {
    final bordeCelda = pw.BoxDecoration(
      border: pw.Border(
        right: pw.BorderSide(color: PdfColors.black, width: 0.8),
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
      ),
    );

    final bordeCeldaFinal = pw.BoxDecoration(
      border: pw.Border(
        bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
      ),
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 4),
            child: pw.Text(
              'SET $numeroSet',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    height: 26,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 6,
                    ),
                    decoration: bordeCelda,
                    child: pw.Text(
                      'R-5',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.Container(
                    height: 26,
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    decoration: bordeCeldaFinal,
                    child: pw.Text(
                      'FICHA DE POSICIÓN',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 6.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 6,
                    ),
                    decoration: bordeCelda,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'EQUIPO',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          equipoNombre?.toUpperCase() ?? '',
                          maxLines: 1,
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _verdeOscuro,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 0.8, color: PdfColors.grey700),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 6,
                    ),
                    decoration: bordeCeldaFinal,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'LÍBERO N°',
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Container(
                          width: 26,
                          height: 13,
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(
                              color: PdfColors.grey700,
                              width: 0.7,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
              2: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                children: [
                  _celdaPosicion('IV'),
                  _celdaPosicion('III'),
                  _celdaPosicion('II', bordeDerecho: false),
                ],
              ),
              pw.TableRow(
                children: [
                  _celdaPosicion('V'),
                  _celdaPosicion('VI'),
                  _celdaPosicion('I', bordeDerecho: false),
                ],
              ),
            ],
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ENTRENADOR',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Container(height: 0.8, color: PdfColors.grey700),
                      ],
                    ),
                  ),
                  pw.Container(
                    height: 34,
                    padding: const pw.EdgeInsets.symmetric(vertical: 13),
                    color: PdfColor.fromHex('F3F4F6'),
                    child: pw.Text(
                      'SERVICIO',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Celda individual de la grilla de posiciones de cancha (roles
  /// IV, III, II, V, VI, I): el número de posición y espacio en blanco
  /// para anotar a mano el número de camiseta.
  pw.Widget _celdaPosicion(String numero, {bool bordeDerecho = true}) {
    return pw.Container(
      height: 30,
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          right: bordeDerecho
              ? pw.BorderSide(color: PdfColors.black, width: 0.8)
              : pw.BorderSide.none,
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.8),
        ),
      ),
      child: pw.Text(
        numero,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Hoja oficio (216 x 330 mm, el tamaño de papel que se usa en Bolivia
  /// para este tipo de formularios), en horizontal: da ~18% más de ancho
  /// que carta/letter para que la planilla de vóley no vaya tan apretada.
  static final PdfPageFormat _oficio = PdfPageFormat(
    21.6 * PdfPageFormat.cm,
    33 * PdfPageFormat.cm,
  );

  /// Planilla de control oficial de vóley (marcador punto a punto,
  /// formación por set, sanciones, aprobación y resultado final), calcada
  /// de la planilla física de la UPSA. Se imprime junto a las fichas de
  /// posición: los árbitros de mesa llenan esta con el partido en curso.
  ///
  /// La app no lleva número de camiseta, así que ese casillero queda en
  /// blanco para llenar a mano, pero el resto de datos que sí existen
  /// (campeonato, equipos, cancha, fecha, hora y las jugadoras ya
  /// registradas de cada equipo) se precargan directamente.
  pw.Page _paginaPlanillaControlVoley({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> jugadoresLocal,
    required List<JugadorModel> jugadoresVisitante,
    required _PdfLogos logos,
  }) {
    return pw.Page(
      pageFormat: _oficio.landscape,
      margin: const pw.EdgeInsets.fromLTRB(16, 10, 16, 8),
      build: (context) {
        // Todo el contenido va dentro de un único marco (borde exterior
        // continuo) y los bloques se tocan entre sí sin separación, para
        // que se vea como una sola grilla impresa (igual que la planilla
        // original exportada de Excel) en vez de varias cajas sueltas
        // con aire entre ellas.
        return pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              _controlVoleyHeader(campeonato: campeonato, partido: partido, logos: logos),
              pw.Table(
                columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
                children: [
                  pw.TableRow(
                    children: [
                      _bloqueSetControlVoley(1),
                      _bloqueSetControlVoley(2),
                    ],
                  ),
                ],
              ),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _bloqueSetControlVoley(3, minHeight: 208),
                      _panelRosterControlVoley(
                        partido: partido,
                        jugadoresLocal: jugadoresLocal,
                        jugadoresVisitante: jugadoresVisitante,
                      ),
                    ],
                  ),
                ],
              ),
              // Sin Expanded: el ancho de la hoja ya está fijo por
              // columnWidths, pero forzar la ALTURA de esta fila con
              // Expanded hacía que, al crecer el contenido de las cajas
              // (para llenar mejor la hoja), la fila entera dejara de
              // pintarse sin ningún error — mismo patrón de colapso
              // silencioso ya documentado en _fichaPosicion. Con altura
              // natural (sin Expanded) el contenido siempre se ve, aunque
              // quede un margen chico al pie en vez de llenar el 100%.
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(3),
                  3: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _bloqueSancionesVoley(),
                      _bloqueObservacionesVoley(),
                      _bloqueAprobacionVoley(),
                      _bloqueResultadoFinalVoley(partido),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  pw.Widget _controlVoleyHeader({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required _PdfLogos logos,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.7),
      columnWidths: const {
        0: pw.FixedColumnWidth(110),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(165),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 34,
              alignment: pw.Alignment.center,
              child: _logo(image: logos.logoUpsa, width: 78, height: 30),
            ),
            pw.Container(
              height: 34,
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('PLANILLA DE CONTROL', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    'VOLEIBOL',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Formulario de Calidad', style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
            ),
            pw.Container(
              height: 34,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'UPSA P4-2-2-F15',
                    style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text('Revisión: 0', style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text('Página 1 de 1', style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(
              height: 16,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Row(
                children: [
                  _casillaConEtiqueta('ELIM.'),
                  pw.SizedBox(width: 4),
                  _casillaConEtiqueta('S.F.'),
                  pw.SizedBox(width: 4),
                  _casillaConEtiqueta('F'),
                ],
              ),
            ),
            pw.Container(
              height: 16,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'CAMPEONATO: ${campeonato.nombre.toUpperCase()}',
                maxLines: 1,
                style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Container(
              height: 16,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Row(
                children: [
                  pw.Text('GRUPO:', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 4),
                  _casillaVacia(14),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(
              height: 16,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4),
              alignment: pw.Alignment.centerLeft,
              child: pw.Row(
                children: [
                  _casillaConEtiqueta('FEM.'),
                  pw.SizedBox(width: 4),
                  _casillaConEtiqueta('MAS.'),
                ],
              ),
            ),
            pw.Container(
              height: 16,
              alignment: pw.Alignment.center,
              child: pw.Text(
                '(A) ${partido.equipoLocalNombre.toUpperCase()}   VS   ${partido.equipoVisitanteNombre.toUpperCase()} (B)',
                maxLines: 1,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _verdeOscuro),
              ),
            ),
            pw.Container(
              height: 16,
              alignment: pw.Alignment.center,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('CATEGORÍA:', style: const pw.TextStyle(fontSize: 6)),
                  pw.SizedBox(width: 3),
                  _casillaConEtiqueta('MAY.'),
                  pw.SizedBox(width: 3),
                  _casillaConEtiqueta('JUV.'),
                  pw.SizedBox(width: 3),
                  _casillaConEtiqueta('MEN.'),
                  pw.SizedBox(width: 3),
                  _casillaConEtiqueta('INF.'),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(height: 14),
            pw.Container(
              height: 14,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Row(
                children: [
                  pw.Text('CIUDAD:', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(width: 4),
                  pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
                ],
              ),
            ),
            pw.Container(
              height: 14,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'COLISEO: ${campeonato.cancha.toUpperCase()}',
                maxLines: 1,
                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Container(height: 14),
            pw.Container(height: 14),
            pw.Container(
              height: 14,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Text(
                'HORA: ${_horaTexto(partido.fechaHora)}   FECHA: ${_fechaCorta(partido.fechaHora)}',
                maxLines: 1,
                style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _casillaVacia(double size) {
    return pw.Container(
      width: size,
      height: size,
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.6)),
    );
  }

  pw.Widget _casillaConEtiqueta(String etiqueta) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        _casillaVacia(7),
        pw.SizedBox(width: 2),
        pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 6)),
      ],
    );
  }

  /// Un bloque "SET N" de la planilla de control: dos mitades (equipo A
  /// y equipo B) con formación inicial y grilla de anotación numerada
  /// (marcador punto a punto), calcado del papel oficial. Se arma con
  /// `pw.Table` en vez de `pw.Row`+`pw.Expanded`: a esta profundidad de
  /// anidamiento (Column > Table > celda > Column...) Expanded colapsa a
  /// tamaño cero sin avisar (ver nota en [_fichaPosicion]).
  pw.Widget _bloqueSetControlVoley(int numeroSet, {double minHeight = 0}) {
    return pw.Container(
      constraints: pw.BoxConstraints(minHeight: minHeight),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.7)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              'SET $numeroSet',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
            ),
          ),
          pw.Table(
            columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.7)),
                    ),
                    child: _mitadEquipoControlVoley(esInicio: true),
                  ),
                  _mitadEquipoControlVoley(esInicio: false),
                ],
              ),
            ],
          ),
          // Amonestaciones/castigos son del SET completo (no por mitad de
          // equipo) en la planilla oficial: una sola línea que cruza todo
          // el ancho del bloque, debajo de las dos mitades.
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
            child: pw.Row(
              children: [
                pw.Text('AMONESTACIONES:', style: pw.TextStyle(fontSize: 5.3, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 4),
                pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
                pw.SizedBox(width: 10),
                pw.Text('CASTIGOS:', style: pw.TextStyle(fontSize: 5.3, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(width: 4),
                pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Una mitad de equipo dentro de un SET: en la planilla oficial cada
  /// mitad tiene su propio campo "Empezó"/"Terminó" (uno a cada lado del
  /// set) y, lado a lado, la formación inicial (posiciones I-VI) y la
  /// grilla de anotación numerada 1-33.
  pw.Widget _mitadEquipoControlVoley({required bool esInicio}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            esInicio
                ? 'Empezó: _______   Equipo:  A (  )  B (  )'
                : 'Equipo:  A (  )  B (  )   Terminó: _______',
            style: const pw.TextStyle(fontSize: 5),
          ),
          pw.SizedBox(height: 2),
          pw.Table(
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.top,
            columnWidths: const {0: pw.FlexColumnWidth(5), 1: pw.FlexColumnWidth(2)},
            children: [
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 3),
                    child: _bloqueFormacionVoley(),
                  ),
                  _bloquePuntosGridVoley(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formación inicial (I-VI, titulares/suplentes), marcas de anotación
  /// por rotación y la referencia impresa de "turnos al ataque" (orden de
  /// saque 1-5/2-6/3-7/4-8), calcado de la planilla oficial: una sola
  /// tabla de 7 columnas (etiqueta de fila + las 6 posiciones I-VI), tal
  /// como se ve en el papel — antes "turnos al ataque" era un cuadrito
  /// aparte con un solo valor, y en el original son 4 filas completas
  /// que repiten su valor bajo cada una de las 6 posiciones.
  pw.Widget _bloqueFormacionVoley() {
    const posiciones = ['I', 'II', 'III', 'IV', 'V', 'VI'];
    final fondoHeader = PdfColor.fromHex('F3F4F6');

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: const {
        0: pw.FixedColumnWidth(58),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
        3: pw.FlexColumnWidth(),
        4: pw.FlexColumnWidth(),
        5: pw.FlexColumnWidth(),
        6: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: fondoHeader),
          children: [
            _etiquetaFormacionVoley('ORDEN AL SAQUE'),
            ...posiciones.map(
              (p) => _celdaFormacionVoley(p, bold: true, height: 12),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('JUGADORES INICIALES'),
            ..._celdasVaciasVoley(height: 12),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('SUPLENTES / JUGADOR N°'),
            ..._celdasVaciasVoley(height: 12),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('ANOTACIÓN'),
            ..._celdasFormacionVoley(const [':', ':', ':', ':', ':', ':'], height: 7, fontSize: 5.6),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley(''),
            ..._celdasFormacionVoley(const [':', ':', ':', ':', ':', ':'], height: 7, fontSize: 5.6),
          ],
        ),
        _filaTurnosAlAtaqueVoley('1° / 5°', '1   5'),
        _filaTurnosAlAtaqueVoley('2° / 6°', '2   6'),
        _filaTurnosAlAtaqueVoley('3° / 7°', '3   7'),
        _filaTurnosAlAtaqueVoley('4° / 8°', '4   8'),
      ],
    );
  }

  pw.TableRow _filaTurnosAlAtaqueVoley(String etiqueta, String valor) {
    return pw.TableRow(
      children: [
        _etiquetaFormacionVoley(etiqueta),
        ..._celdasFormacionVoley(List.filled(6, valor), height: 7, fontSize: 5.2),
      ],
    );
  }

  pw.Widget _etiquetaFormacionVoley(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        texto,
        maxLines: 2,
        overflow: pw.TextOverflow.visible,
        style: pw.TextStyle(fontSize: 4.2, fontWeight: pw.FontWeight.bold, color: PdfColors.black),
      ),
    );
  }

  List<pw.Widget> _celdasVaciasVoley({required double height}) {
    return List.generate(6, (_) => pw.Container(height: height));
  }

  List<pw.Widget> _celdasFormacionVoley(
    List<String> valores, {
    required double height,
    required double fontSize,
  }) {
    return valores
        .map(
          (v) => _celdaFormacionVoley(v, height: height, fontSize: fontSize),
        )
        .toList();
  }

  pw.Widget _celdaFormacionVoley(
    String texto, {
    bool bold = false,
    double height = 9,
    double fontSize = 5.6,
  }) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      child: pw.Text(
        texto,
        style: pw.TextStyle(fontSize: fontSize, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  /// Grilla de anotación: números 1 a 33 (marcador punto a punto) en 3
  /// columnas de 11 filas, más una fila final "T" (tiempos fuera), tal
  /// como en la planilla oficial.
  pw.Widget _bloquePuntosGridVoley() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth(), 2: pw.FlexColumnWidth()},
      children: [
        ...List.generate(11, (fila) {
          return pw.TableRow(
            children: List.generate(3, (col) {
              final numero = fila + 1 + (col * 11);
              return pw.Container(
                height: 7,
                alignment: pw.Alignment.center,
                child: pw.Text('$numero', style: const pw.TextStyle(fontSize: 5.2)),
              );
            }),
          );
        }),
        pw.TableRow(
          children: [
            pw.Container(
              height: 7,
              alignment: pw.Alignment.center,
              child: pw.Text('T', style: pw.TextStyle(fontSize: 4.6, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(height: 7),
            pw.Container(height: 7),
          ],
        ),
      ],
    );
  }

  /// Panel con el listado de jugadoras por equipo: se precarga con las
  /// jugadoras ya registradas en la app (hasta 12, ordenadas por
  /// nombre), y deja líneas en blanco para las que falten hasta 12 —
  /// así el equipo de mesa solo completa a quienes falten en vez de
  /// transcribir toda la lista a mano.
  pw.Widget _panelRosterControlVoley({
    required PartidoModel partido,
    required List<JugadorModel> jugadoresLocal,
    required List<JugadorModel> jugadoresVisitante,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.7)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              'EQUIPOS',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
            ),
          ),
          pw.Table(
            columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(right: pw.BorderSide(color: PdfColors.black, width: 0.7)),
                    ),
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _listaRosterVoley(
                          '(A) ${partido.equipoLocalNombre.toUpperCase()}',
                          jugadoresLocal,
                        ),
                        pw.SizedBox(height: 3),
                        _liberoCapitanEntrenadorVoley(),
                      ],
                    ),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(3),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                      children: [
                        _listaRosterVoley(
                          '(B) ${partido.equipoVisitanteNombre.toUpperCase()}',
                          jugadoresVisitante,
                        ),
                        pw.SizedBox(height: 3),
                        _liberoCapitanEntrenadorVoley(),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _listaRosterVoley(String titulo, List<JugadorModel> jugadores) {
    final ordenadas = [...jugadores]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          titulo,
          maxLines: 1,
          style: pw.TextStyle(fontSize: 5.6, fontWeight: pw.FontWeight.bold, color: _verdeOscuro),
        ),
        pw.SizedBox(height: 2),
        ...List.generate(12, (index) {
          final jugadora = index < ordenadas.length ? ordenadas[index] : null;

          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 12,
                  child: pw.Text('${index + 1}.', style: const pw.TextStyle(fontSize: 5.3)),
                ),
                if (jugadora != null)
                  pw.Expanded(
                    child: pw.Text(
                      jugadora.nombreCompleto.toUpperCase(),
                      maxLines: 1,
                      overflow: pw.TextOverflow.clip,
                      style: const pw.TextStyle(fontSize: 5.3),
                    ),
                  )
                else
                  pw.Expanded(
                    child: pw.Container(height: 0.5, color: PdfColors.grey500),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _liberoCapitanEntrenadorVoley() {
    return pw.Table(
      columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              child: pw.Text('LÍBERO', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 1),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              child: pw.Text('LÍBERO', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _lineaFirmaVoley('Capitán'),
            _lineaFirmaVoley('Capitán'),
          ],
        ),
        pw.TableRow(
          children: [
            _lineaFirmaVoley('Firma'),
            _lineaFirmaVoley('Firma'),
          ],
        ),
        pw.TableRow(
          children: [
            _lineaFirmaVoley('Entrenador'),
            _lineaFirmaVoley('Entrenador'),
          ],
        ),
        pw.TableRow(
          children: [
            _lineaFirmaVoley('Firma'),
            _lineaFirmaVoley('Firma'),
          ],
        ),
      ],
    );
  }

  pw.Widget _lineaFirmaVoley(String etiqueta) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 2),
      child: pw.Row(
        children: [
          pw.Text('$etiqueta:', style: const pw.TextStyle(fontSize: 4.8)),
          pw.SizedBox(width: 3),
          pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  /// Sanciones: tabla real con líneas de grilla (no simples renglones en
  /// blanco), columnas A/P/E/D/A·B/SET/ESCORE, tal como en la planilla
  /// oficial.
  pw.Widget _bloqueSancionesVoley() {
    final columnas = {
      0: const pw.FlexColumnWidth(1),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(2),
      6: const pw.FlexColumnWidth(2),
    };

    return _bloqueVoleyConTitulo(
      titulo: 'SANCIONES',
      child: pw.Table(
        border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.4),
        columnWidths: columnas,
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
            children: [
              _ccVoley('A', bold: true),
              _ccVoley('P', bold: true),
              _ccVoley('E', bold: true),
              _ccVoley('D', bold: true),
              _ccVoley('A·B', bold: true),
              _ccVoley('SET', bold: true),
              _ccVoley('ESCORE', bold: true),
            ],
          ),
          ...List.generate(
            9,
            (_) => pw.TableRow(
              children: List.generate(7, (_) => _ccVoley('', height: 13)),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _bloqueObservacionesVoley() {
    return _bloqueVoleyConTitulo(
      titulo: 'OBSERVACIONES',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: List.generate(
          8,
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 12),
            child: pw.Container(height: 0.5, color: PdfColors.grey500),
          ),
        ),
      ),
    );
  }

  /// Aprobación: 1er/2do árbitro y anotador (nombre+firma), jueces de
  /// línea numerados 1-4 y capitanes A/B, tal como en la planilla oficial.
  pw.Widget _bloqueAprobacionVoley() {
    return _bloqueVoleyConTitulo(
      titulo: 'APROBACIÓN',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Row(
            children: [
              pw.SizedBox(width: 42, child: pw.Text('ÁRBITROS', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold))),
              pw.Expanded(child: pw.Text('NOMBRE', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
              pw.Expanded(child: pw.Text('FIRMA', style: pw.TextStyle(fontSize: 4.8, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
            ],
          ),
          pw.SizedBox(height: 6),
          _filaAprobacionVoley('1°'),
          _filaAprobacionVoley('2°'),
          _filaAprobacionVoley('Anotador'),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _casillaNumeradaVoley('1'),
              pw.Expanded(
                child: pw.Text(
                  'JUEZ DE LÍNEA',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
                ),
              ),
              _casillaNumeradaVoley('2'),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              _casillaNumeradaVoley('3'),
              pw.SizedBox(width: 6),
              _casillaNumeradaVoley('4'),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Text('A', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 4),
              pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
              pw.SizedBox(width: 8),
              pw.Text('CAPITANES', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 8),
              pw.Text('B', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 4),
              pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _filaAprobacionVoley(String etiqueta) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 9),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.SizedBox(width: 42, child: pw.Text(etiqueta, style: const pw.TextStyle(fontSize: 5.3))),
          pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
          pw.SizedBox(width: 6),
          pw.Expanded(child: pw.Container(height: 0.5, color: PdfColors.grey500)),
        ],
      ),
    );
  }

  pw.Widget _casillaNumeradaVoley(String numero) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 16,
          height: 16,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.6)),
          child: pw.Text(numero, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );
  }

  /// Resultado final: puntos por set (ambos equipos), duración total del
  /// set, horarios de inicio/fin y ganador, tal como en la planilla
  /// oficial.
  pw.Widget _bloqueResultadoFinalVoley(PartidoModel partido) {
    return _bloqueVoleyConTitulo(
      titulo: 'RESULTADO FINAL',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'EQUIPO:  A ${partido.equipoLocalNombre.toUpperCase()}     ·     B ${partido.equipoVisitanteNombre.toUpperCase()}  :EQUIPO',
            maxLines: 2,
            style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.4),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(2),
              4: pw.FlexColumnWidth(5),
              5: pw.FlexColumnWidth(2),
              6: pw.FlexColumnWidth(1),
              7: pw.FlexColumnWidth(1),
              8: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
                children: [
                  _ccVoley('T', bold: true),
                  _ccVoley('S', bold: true),
                  _ccVoley('G', bold: true),
                  _ccVoley('PUNTOS', bold: true),
                  _ccVoley('SET · DURACIÓN', bold: true),
                  _ccVoley('PUNTOS', bold: true),
                  _ccVoley('G', bold: true),
                  _ccVoley('S', bold: true),
                  _ccVoley('T', bold: true),
                ],
              ),
              ...List.generate(
                3,
                (i) => pw.TableRow(
                  children: [
                    _ccVoley(''),
                    _ccVoley(''),
                    _ccVoley(''),
                    _ccVoley(''),
                    _ccVoley('${i + 1}   (         )'),
                    _ccVoley(''),
                    _ccVoley(''),
                    _ccVoley(''),
                    _ccVoley(''),
                  ],
                ),
              ),
              pw.TableRow(
                children: [
                  _ccVoley(''),
                  _ccVoley(''),
                  _ccVoley(''),
                  _ccVoley(''),
                  _ccVoley('TOTAL (   min)'),
                  _ccVoley(''),
                  _ccVoley(''),
                  _ccVoley(''),
                  _ccVoley(''),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Comenzó a hrs.:', style: const pw.TextStyle(fontSize: 4.6)),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Finalizó a hrs.:', style: const pw.TextStyle(fontSize: 4.6)),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Duración total:', style: const pw.TextStyle(fontSize: 4.6)),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              pw.Text('GANADOR:', style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 4),
              pw.Expanded(child: pw.Container(height: 0.6, color: PdfColors.black)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _ccVoley(String text, {bool bold = false, double height = 16}) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
      child: pw.Text(
        text,
        maxLines: 1,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 5.3, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  pw.Widget _bloqueVoleyConTitulo({required String titulo, required pw.Widget child}) {
    return pw.Container(
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black, width: 0.7)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              titulo,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(color: PdfColors.white, fontSize: 7, fontWeight: pw.FontWeight.bold, letterSpacing: 0.6),
            ),
          ),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: child),
        ],
      ),
    );
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
            _logo(image: logos.logoUpsa40, width: 72, height: 52),
            _logo(image: logos.logoUpsa, width: 116, height: 52),
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
        style: pw.TextStyle(fontSize: 12, color: _grisMedio),
      );
    }

    final agrupados = _agruparPorFecha(partidos);
    final sinFecha = partidos
        .where((partido) => partido.fechaHora == null)
        .toList();

    final widgets = <pw.Widget>[];

    if (agrupados.isEmpty && (!incluirSinFecha || sinFecha.isEmpty)) {
      widgets.add(
        pw.Text(
          'No hay partidos programados con fecha y hora.',
          style: pw.TextStyle(fontSize: 12, color: _grisMedio),
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
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
                  // Incluye penales si el partido se definió así,
                  // por ejemplo: "1 - 1 (4 - 3 pen.)".
                  partido.definidoPorPenales &&
                          partido.penalesLocal != null &&
                          partido.penalesVisitante != null
                      ? '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0} (${partido.penalesLocal} - ${partido.penalesVisitante} pen.)'
                      : '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: partido.definidoPorPenales ? 11 : 20,
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
            style: pw.TextStyle(fontSize: 9, color: _grisMedio),
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
        : goles
              .map((gol) {
                final cantidad = gol.cantidad > 1 ? ' x${gol.cantidad}' : '';
                return '${gol.jugadorNombre}$cantidad';
              })
              .join('\n');

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
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(jugadores, style: const pw.TextStyle(fontSize: 9)),
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
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'COORDINACIÓN DE DEPORTES UPSA',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
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
              child: _logo(image: logos.logoUpsa, width: 92, height: 40),
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
                    // La planilla usa el deporte del campeonato. La versión
                    // específica para vóley (sets) y básquet (faltas) queda
                    // preparada para una siguiente fase.
                    _deporteLabel(campeonato),
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
          final visitanteJugador = index < visitante.length
              ? visitante[index]
              : null;

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
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 150, height: 1, color: PdfColors.black),
            pw.Spacer(),
            pw.Text(
              'ÁRBITRO:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 120, height: 1, color: PdfColors.black),
            pw.SizedBox(width: 18),
            pw.Text(
              '1° ASISTENTE:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(width: 8),
            pw.Container(width: 95, height: 1, color: PdfColors.black),
            pw.SizedBox(width: 18),
            pw.Text(
              '2° ASISTENTE:',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
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
        pw.Text(texto, style: const pw.TextStyle(fontSize: 7)),
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
            _logo(image: logos.logoUpsa40, width: 70, height: 44),
            _logo(image: logos.logoUpsa, width: 110, height: 44),
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
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
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
    return pw.TableHelper.fromTextArray(
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

  const _PdfLogos({required this.logoUpsa, required this.logoUpsa40});
}
