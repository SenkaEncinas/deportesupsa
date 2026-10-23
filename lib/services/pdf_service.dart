import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../utils/fechas.dart';

part 'pdf/flyers.dart';
part 'pdf/planilla_futbol.dart';
part 'pdf/planilla_voley.dart';
part 'pdf/comunes.dart';

class PdfGolPartidoItem {
  final String jugadorNombre;
  final String equipoId;
  final String equipoNombre;
  final int cantidad;

  const PdfGolPartidoItem({
    required this.jugadorNombre,
    required this.equipoId,
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

// Colores, medidas y rutas que comparten todos los PDF.

final PdfColor _verdeOscuro = PdfColor.fromHex('004D3A');

final PdfColor _verdeTexto = PdfColor.fromHex('4F7F3A');

final PdfColor _grisClaro = PdfColor.fromHex('E5E7EB');

final PdfColor _grisMedio = PdfColor.fromHex('6B7280');

final PdfColor _grisTexto = PdfColor.fromHex('111827');

const String _logoUpsaPath = 'assets/images/logo_upsa.png';

// Subset de Noto Emoji (monocromo, licencia OFL) con solo los 3 glifos
// que se usan en el flyer (⚽ 🏐 🏀): la fuente Helvetica que trae el
// paquete `pdf` por defecto no tiene glifos fuera de caracteres
// latinos acentuados, así que un emoji literal sin esta fuente
// simplemente no se pinta (confirmado en pruebas).
const String _emojiDeportesPath = 'assets/fonts/noto_emoji_deportes.ttf';

/// Carpetas de logos de patrocinadores. Se descubren solos: lo que se
/// deje acá (png/jpg) aparece en la franja de auspiciadores del flyer,
/// ordenado por nombre de archivo, sin tocar código.
///
/// Lo que va en `principal/` se dibuja aparte, centrado y más grande
/// (auspiciador principal); el resto va en la tira de abajo.
const String _patrocinadoresDir = 'assets/images/patrocinadores/';

const String _patrocinadorPrincipalDir =
    'assets/images/patrocinadores/principal/';

/// Tamaño de afiche vertical (proporción ~4:5, estilo publicación de
/// Instagram) en vez de una hoja carta: este PDF está pensado para
/// compartirse en redes, no para imprimirse como documento de oficina.
final PdfPageFormat _flyerFormat = PdfPageFormat(400, 500);

/// Alto que la columna del flyer le reserva al pie anclado
/// (coordinador + franja de auspiciadores + respiro).
const double _altoReservadoPie = 124;

final PdfColor _flyerFondoOscuro = PdfColor.fromHex('0E4832');

final PdfColor _flyerFondoMedio = PdfColor.fromHex('2E7D4F');

final PdfColor _flyerFondoClaro = PdfColor.fromHex('86BE4B');

final PdfColor _flyerAmarillo = PdfColor.fromHex('D7E85A');

final PdfColor _flyerVerdeTeal = PdfColor.fromHex('12705C');

final PdfColor _flyerPillFechaFondo = PdfColor.fromHex('8FC93E');

final PdfColor _flyerPillFechaTexto = PdfColor.fromHex('2B3A0F');

final PdfColor _flyerGrupoPill = PdfColor.fromHex('EDEDED');

/// Anchos de las tres columnas de una fila del flyer; los goleadores
/// debajo de un resultado usan los mismos para quedar alineados.
const _flyerColumnas = {
  0: pw.FixedColumnWidth(48),
  1: pw.FlexColumnWidth(),
  2: pw.FixedColumnWidth(38),
};

/// Hoja oficio (216 x 330 mm, el tamaño de papel que se usa en Bolivia
/// para este tipo de formularios), en horizontal: da ~18% más de ancho
/// que carta/letter para que la planilla de vóley no vaya tan apretada.
final PdfPageFormat _oficio = PdfPageFormat(
  21.6 * PdfPageFormat.cm,
  33 * PdfPageFormat.cm,
);

class PdfService {
  Future<_PdfLogos> _loadLogos() async {
    final logoUpsaData = await rootBundle.load(_logoUpsaPath);
    final emojiData = await rootBundle.load(_emojiDeportesPath);

    return _PdfLogos(
      logoUpsa: pw.MemoryImage(logoUpsaData.buffer.asUint8List()),
      emojiDeportes: pw.Font.ttf(emojiData),
      patrocinadorPrincipal: await _loadImagenesDe(
        _patrocinadorPrincipalDir,
        incluirSubcarpetas: true,
      ),
      patrocinadores: await _loadImagenesDe(
        _patrocinadoresDir,
        incluirSubcarpetas: false,
      ),
    );
  }

  /// Lee el manifiesto de assets y carga las imágenes de [carpeta]. Si
  /// no hay nada (o el manifiesto no se puede leer) devuelve una lista
  /// vacía y el flyer simplemente no dibuja esa parte: nunca rompe la
  /// generación del PDF por un logo.
  Future<List<pw.MemoryImage>> _loadImagenesDe(
    String carpeta, {
    required bool incluirSubcarpetas,
  }) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);

      final rutas = manifest.listAssets().where((ruta) {
        if (!ruta.startsWith(carpeta) || !_esImagenSoportada(ruta)) {
          return false;
        }
        if (incluirSubcarpetas) return true;
        // Solo archivos sueltos de esta carpeta, sin bajar a
        // subcarpetas (ahí vive el auspiciador principal).
        return !ruta.substring(carpeta.length).contains('/');
      }).toList()..sort();

      final imagenes = <pw.MemoryImage>[];

      for (final ruta in rutas) {
        try {
          final data = await rootBundle.load(ruta);
          imagenes.add(pw.MemoryImage(data.buffer.asUint8List()));
        } catch (_) {
          // Un logo ilegible no debe tumbar todo el PDF: se omite.
        }
      }

      return imagenes;
    } catch (_) {
      return const [];
    }
  }

  bool _esImagenSoportada(String ruta) {
    final minuscula = ruta.toLowerCase();
    return minuscula.endsWith('.png') ||
        minuscula.endsWith('.jpg') ||
        minuscula.endsWith('.jpeg');
  }

  String _horaTexto(DateTime? fecha) {
    if (fecha == null) return '--:--';
    return Fechas.hora(fecha);
  }

  String _fechaCorta(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha';
    return Fechas.dia(fecha);
  }

  /// Formato oración ("Miércoles 02 de septiembre"), el estilo que usa
  /// el flyer de programación/resultados, liviano sobre la píldora de
  /// la card.
  String _diaMesTextoFlyer(DateTime fecha) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];

    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];

    final diaSemana = dias[fecha.weekday - 1];
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = meses[fecha.month - 1];

    return '$diaSemana $dia de $mes';
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

      final key = Fechas.clave(fecha);

      agrupados.putIfAbsent(key, () => []);
      agrupados[key]!.add(partido);
    }

    return agrupados;
  }

  /// Flyer de programación: una hoja por fecha/jornada (formato vertical
  /// tipo afiche para redes), en vez de un documento plano con todo el
  /// campeonato junto. Los partidos sin programar (sin fecha/hora) van
  /// en una hoja final aparte.
  Future<Uint8List> generarFixturePdf({
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
  }) async {
    final logos = await _loadLogos();
    final pdf = pw.Document();

    _agregarPaginasFlyerFixture(
      pdf: pdf,
      campeonato: campeonato,
      partidos: partidos,
      logos: logos,
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

    _agregarPaginasFlyerFixture(
      pdf: pdf,
      campeonato: campeonato,
      partidos: partidos,
      logos: logos,
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

    final agrupados = _agruparResultadosPorFecha(resultados);
    final sinFecha = resultados
        .where((item) => item.partido.fechaHora == null)
        .toList();

    if (agrupados.isEmpty && sinFecha.isEmpty) {
      pdf.addPage(
        _paginaFlyerResultadosJornada(
          campeonato: campeonato,
          resultados: const [],
          etiquetaFecha: 'Sin resultados en este rango',
          logos: logos,
        ),
      );

      return pdf.save();
    }

    for (final resultadosDia in agrupados.values) {
      final fecha = resultadosDia.first.partido.fechaHora!;

      pdf.addPage(
        _paginaFlyerResultadosJornada(
          campeonato: campeonato,
          resultados: resultadosDia,
          etiquetaFecha: _diaMesTextoFlyer(fecha),
          logos: logos,
        ),
      );
    }

    if (sinFecha.isNotEmpty) {
      pdf.addPage(
        _paginaFlyerResultadosJornada(
          campeonato: campeonato,
          resultados: sinFecha,
          etiquetaFecha: 'Resultados sin fecha',
          logos: logos,
        ),
      );
    }

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
  /// Futsal tampoco usa el paquete de fútbol 7/11: solo se imprime la
  /// planilla de control de una hoja calcada de la física de la UPSA
  /// (ver [_paginaPlanillaFutsal]) — sin carteles de equipo ni lista de
  /// poleras aparte.
  ///
  /// Para fútbol 7/11/básquet son 4 hojas: la planilla oficial de
  /// control, un cartel con el nombre de cada equipo (lo más grande
  /// posible en su propia hoja, para identificar a los equipos en
  /// cancha) y una lista aparte de jugadores con el número de polera en
  /// blanco para que el equipo de mesa lo complete al momento del
  /// control.
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

    if (campeonato.modalidad == ModalidadDeporte.futsal) {
      pdf.addPage(
        _paginaPlanillaFutsal(
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

    // Hoja 1: la planilla oficial de control (anotación, faltas o
    // tarjetas según el deporte, y firmas).
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
              _planillaEquiposHeader(campeonato, partido),
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
}

class _PdfLogos {
  final pw.MemoryImage logoUpsa;
  final pw.Font emojiDeportes;
  final List<pw.MemoryImage> patrocinadorPrincipal;
  final List<pw.MemoryImage> patrocinadores;

  const _PdfLogos({
    required this.logoUpsa,
    required this.emojiDeportes,
    this.patrocinadorPrincipal = const [],
    this.patrocinadores = const [],
  });

  bool get tienePatrocinadores =>
      patrocinadorPrincipal.isNotEmpty || patrocinadores.isNotEmpty;
}
