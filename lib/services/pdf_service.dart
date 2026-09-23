import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
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

  // Subset de Noto Emoji (monocromo, licencia OFL) con solo los 3 glifos
  // que se usan en el flyer (⚽ 🏐 🏀): la fuente Helvetica que trae el
  // paquete `pdf` por defecto no tiene glifos fuera de caracteres
  // latinos acentuados, así que un emoji literal sin esta fuente
  // simplemente no se pinta (confirmado en pruebas).
  static const String _emojiDeportesPath =
      'assets/fonts/noto_emoji_deportes.ttf';

  /// Carpetas de logos de patrocinadores. Se descubren solos: lo que se
  /// deje acá (png/jpg) aparece en la franja de auspiciadores del flyer,
  /// ordenado por nombre de archivo, sin tocar código.
  ///
  /// Lo que va en `principal/` se dibuja aparte, centrado y más grande
  /// (auspiciador principal); el resto va en la tira de abajo.
  static const String _patrocinadoresDir = 'assets/images/patrocinadores/';
  static const String _patrocinadorPrincipalDir =
      'assets/images/patrocinadores/principal/';

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

      final key =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

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

  /// Agrega una hoja de flyer por fecha/jornada al documento: la misma
  /// pieza que usa el fixture completo, reutilizada tal cual para la
  /// versión "por rango" — el pedido fue justamente que programación y
  /// resultados por rango se vean igual al flyer ya aprobado, en vez de
  /// mantener un documento plano aparte para cada variante.
  void _agregarPaginasFlyerFixture({
    required pw.Document pdf,
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
    required _PdfLogos logos,
  }) {
    final partidosOrdenados = _ordenarPartidos(partidos);
    final agrupados = _agruparPorFecha(partidosOrdenados);
    final sinFecha = partidosOrdenados
        .where((partido) => partido.fechaHora == null)
        .toList();

    if (agrupados.isEmpty && sinFecha.isEmpty) {
      pdf.addPage(
        _paginaFlyerJornada(
          campeonato: campeonato,
          partidos: const [],
          etiquetaFecha: 'Sin partidos generados',
          logos: logos,
        ),
      );

      return;
    }

    for (final partidosDia in agrupados.values) {
      final fecha = partidosDia.first.fechaHora!;

      pdf.addPage(
        _paginaFlyerJornada(
          campeonato: campeonato,
          partidos: partidosDia,
          etiquetaFecha: _diaMesTextoFlyer(fecha),
          logos: logos,
        ),
      );
    }

    if (sinFecha.isNotEmpty) {
      pdf.addPage(
        _paginaFlyerJornada(
          campeonato: campeonato,
          partidos: sinFecha,
          etiquetaFecha: 'Partidos sin programar',
          logos: logos,
          sinFecha: true,
        ),
      );
    }
  }

  /// Tamaño de afiche vertical (proporción ~4:5, estilo publicación de
  /// Instagram) en vez de una hoja carta: este PDF está pensado para
  /// compartirse en redes, no para imprimirse como documento de oficina.
  static final PdfPageFormat _flyerFormat = PdfPageFormat(400, 500);

  /// Alto que la columna del flyer le reserva al pie anclado
  /// (coordinador + franja de auspiciadores + respiro).
  static const double _altoReservadoPie = 124;

  static final PdfColor _flyerFondoOscuro = PdfColor.fromHex('0E4832');
  static final PdfColor _flyerFondoMedio = PdfColor.fromHex('2E7D4F');
  static final PdfColor _flyerFondoClaro = PdfColor.fromHex('86BE4B');
  static final PdfColor _flyerAmarillo = PdfColor.fromHex('D7E85A');
  static final PdfColor _flyerVerdeTeal = PdfColor.fromHex('12705C');
  static final PdfColor _flyerPillFechaFondo = PdfColor.fromHex('8FC93E');
  static final PdfColor _flyerPillFechaTexto = PdfColor.fromHex('2B3A0F');
  static final PdfColor _flyerGrupoPill = PdfColor.fromHex('EDEDED');

  /// Divide el nombre del campeonato en dos líneas al estilo del afiche
  /// de referencia ("25º COPA UPSA" en blanco / "FÚTBOL PRE PROMO 2026"
  /// en amarillo): se corta justo después de la última aparición de
  /// "upsa" en el nombre, que es como vienen armados los nombres reales
  /// ("25º Copa Upsa Fútbol Pre Promo 2026", "CopaUpsa Voleibol
  /// Varones"...). Si el nombre no contiene "upsa", se muestra entero
  /// en la línea grande y se omite la línea blanca.
  ({String eyebrow, String titulo}) _flyerTitulo(CampeonatoModel campeonato) {
    final nombre = campeonato.nombre.trim();

    if (nombre.isEmpty) {
      return (eyebrow: 'COPA UPSA', titulo: _deporteCardLabel(campeonato));
    }

    final idx = nombre.toLowerCase().lastIndexOf('upsa');

    if (idx == -1) {
      return (eyebrow: '', titulo: nombre.toUpperCase());
    }

    final eyebrow = nombre.substring(0, idx + 4).trim();
    final resto = nombre.substring(idx + 4).trim();

    if (resto.isEmpty) {
      return (eyebrow: '', titulo: eyebrow.toUpperCase());
    }

    return (eyebrow: eyebrow.toUpperCase(), titulo: resto.toUpperCase());
  }

  /// La hoja del flyer: fondo, patrón, encabezado y pie.
  ///
  /// Entre el flyer de programación y el de resultados solo cambian
  /// el subtítulo y la tarjeta del medio; todo lo demás (el degradado
  /// de tres paradas, el patrón de fondo, el pie anclado con los
  /// auspiciadores) se arma una sola vez acá.
  pw.Page _paginaFlyer({
    required CampeonatoModel campeonato,
    required String subtitulo,
    required _PdfLogos logos,
    required pw.Widget card,
  }) {
    final titulo = _flyerTitulo(campeonato);

    return pw.Page(
      pageFormat: _flyerFormat,
      margin: pw.EdgeInsets.zero,
      build: (context) {
        return pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  gradient: pw.LinearGradient(
                    begin: pw.Alignment.topCenter,
                    end: pw.Alignment.bottomCenter,
                    // Tres paradas como en la plantilla: se mantiene
                    // verde oscuro casi toda la hoja y recién abajo abre
                    // al verde claro.
                    colors: [
                      _flyerFondoOscuro,
                      _flyerFondoMedio,
                      _flyerFondoClaro,
                    ],
                    stops: const [0.0, 0.62, 1.0],
                  ),
                ),
              ),
            ),
            pw.Positioned.fill(child: _flyerPatronFondo()),
            // El pie (coordinador + auspiciadores) va anclado con
            // `Positioned` y no dentro de la columna: en el flujo normal,
            // cuando la card crecía (muchos partidos o muchos
            // goleadores) empujaba el pie fuera de la hoja y el paquete
            // `pdf` lo descartaba sin avisar. Anclado siempre sale, y la
            // columna de arriba reserva su alto.
            pw.Positioned(
              left: 26,
              right: 26,
              bottom: 18,
              child: _flyerPie(logos),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.fromLTRB(26, 30, 26, _altoReservadoPie),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (titulo.eyebrow.isNotEmpty) ...[
                    pw.Text(
                      titulo.eyebrow,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 15,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                  ],
                  pw.Text(
                    titulo.titulo,
                    textAlign: pw.TextAlign.center,
                    maxLines: 2,
                    style: pw.TextStyle(
                      color: _flyerAmarillo,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _dashedPill(
                    color: PdfColors.white,
                    radius: 14,
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: pw.Text(
                        subtitulo,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 18),
                  card,
                  // Sin `Expanded` de relleno: con la franja de
                  // auspiciadores el contenido ya ocupa casi toda la
                  // hoja, y el espaciador dejaba al pie sin lugar, así
                  // que el paquete `pdf` descartaba la franja entera sin
                  // avisar. Con separaciones fijas siempre entra.
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  pw.Page _paginaFlyerJornada({
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
    required String etiquetaFecha,
    required _PdfLogos logos,
    bool sinFecha = false,
  }) {
    // Siempre "PROGRAMACIÓN SEMANAL" en vez del ordinal de la jornada
    // ("2DA FECHA"): se pidió así para no tener que pensar qué número de
    // fecha corresponde a cada hoja.
    return _paginaFlyer(
      campeonato: campeonato,
      subtitulo: sinFecha ? 'PARTIDOS SIN PROGRAMAR' : 'PROGRAMACIÓN SEMANAL',
      logos: logos,
      card: _flyerCard(
        campeonato: campeonato,
        partidos: partidos,
        etiquetaFecha: etiquetaFecha,
        logos: logos,
      ),
    );
  }

  /// Textura de fondo del flyer: la grilla de cruces gruesas que alterna
  /// "+" y "×", calcada de la plantilla original (ahí son formas macizas
  /// y grandes, no tipografía). Se dibujan como polígonos con el canvas
  /// de bajo nivel: un glifo de texto queda mucho más fino que el
  /// patrón real, y así tampoco hace falta un asset de imagen.
  pw.Widget _flyerPatronFondo() {
    // La transparencia va con `pw.Opacity` y no con el alpha del color:
    // el operador de color del PDF ignora el canal alfa, así que las
    // cruces salían blancas macizas y se comían el afiche.
    return pw.Opacity(
      opacity: 0.08,
      child: pw.CustomPaint(
        painter: (canvas, size) {
          const paso = 60.0;
          const brazo = 14.0; // medio largo de la cruz
          const grosor = 4.5; // medio grosor del brazo

          canvas.setFillColor(PdfColors.white);

          var fila = 0;
          for (var y = -paso / 2; y < size.y + paso; y += paso) {
            final desfase = fila.isOdd ? paso / 2 : 0.0;
            var columna = 0;

            for (var x = -paso / 2 + desfase; x < size.x + paso; x += paso) {
              _cruzPatron(
                canvas,
                cx: x,
                cy: y,
                brazo: brazo,
                grosor: grosor,
                enAspa: (fila + columna).isOdd,
              );
              columna++;
            }

            fila++;
          }

          canvas.fillPath();
        },
      ),
    );
  }

  /// Agrega al path una cruz maciza de 12 vértices centrada en (cx, cy).
  /// Con [enAspa] la misma cruz se rota 45° y queda como "×".
  void _cruzPatron(
    PdfGraphics canvas, {
    required double cx,
    required double cy,
    required double brazo,
    required double grosor,
    required bool enAspa,
  }) {
    const vertices = [
      [1, 1],
      [2, 1],
      [2, -1],
      [1, -1],
      [1, -2],
      [-1, -2],
      [-1, -1],
      [-2, -1],
      [-2, 1],
      [-1, 1],
      [-1, 2],
      [1, 2],
    ];

    // cos45 = sin45 = 0.7071: rotar el mismo polígono convierte "+" en "×".
    const k = 0.70710678;

    for (var i = 0; i < vertices.length; i++) {
      final ux = vertices[i][0] == 2 || vertices[i][0] == -2
          ? (vertices[i][0] ~/ 2) * brazo
          : vertices[i][0] * grosor;
      final uy = vertices[i][1] == 2 || vertices[i][1] == -2
          ? (vertices[i][1] ~/ 2) * brazo
          : vertices[i][1] * grosor;

      final px = enAspa ? (ux - uy) * k : ux;
      final py = enAspa ? (ux + uy) * k : uy;

      if (i == 0) {
        canvas.moveTo(cx + px, cy + py);
      } else {
        canvas.lineTo(cx + px, cy + py);
      }
    }

    canvas.closePath();
  }

  /// Envuelve [child] con un borde punteado (la librería de PDF no tiene
  /// un `BorderStyle.dashed` como Flutter, así que se dibuja a mano con
  /// el canvas de bajo nivel) y forma de píldora si el alto lo permite.
  pw.Widget _dashedPill({
    required pw.Widget child,
    required PdfColor color,
    double radius = 14,
    double strokeWidth = 1.1,
  }) {
    return pw.CustomPaint(
      child: child,
      painter: (canvas, size) {
        canvas
          ..setStrokeColor(color)
          ..setLineWidth(strokeWidth)
          ..setLineDashPattern(const [4, 3])
          ..drawRRect(0, 0, size.x, size.y, radius, radius)
          ..strokePath()
          ..setLineDashPattern(const []);
      },
    );
  }

  /// La tarjeta blanca del flyer: sombra, recuadro, logo y píldora
  /// de fecha, con una fila por cada cosa a listar.
  ///
  /// La usan el flyer de programación y el de resultados; lo único
  /// que cambia entre los dos es qué fila se dibuja y qué decir
  /// cuando no hay nada que mostrar.
  pw.Widget _flyerCardBase({
    required CampeonatoModel campeonato,
    required String etiquetaFecha,
    required _PdfLogos logos,
    required String mensajeVacio,
    required List<pw.Widget> filas,
  }) {
    // La sombra va con `CustomPaint` (se pinta antes que el hijo) y no
    // con `boxShadow`: el paquete `pdf` dibuja la sombra del decorado
    // como un rectángulo recto, ignorando el `borderRadius`, y asomaban
    // esquinas duras. Así se calca la sombra maciza y desplazada que
    // tiene la card en la plantilla original.
    return pw.CustomPaint(
      painter: (canvas, size) {
        canvas
          ..setFillColor(PdfColor(0, 0, 0, 0.17))
          ..drawRRect(3, -5, size.x, size.y, 22, 22)
          ..fillPath();
      },
      child: pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(22),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                _flyerIconoDeporte(campeonato, logos),
                pw.SizedBox(width: 8),
                pw.Text(
                  _deporteCardLabel(campeonato),
                  style: pw.TextStyle(
                    color: _verdeOscuro,
                    fontSize: 15,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(width: 8),
                _flyerIconoDeporte(campeonato, logos),
              ],
            ),
            pw.SizedBox(height: 8),
            _flyerPildoraFecha(etiquetaFecha),
            pw.SizedBox(height: 12),
            if (filas.isEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 10),
                child: pw.Text(
                  mensajeVacio,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(color: _grisMedio, fontSize: 10),
                ),
              )
            else
              ...filas.map(
                (fila) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: fila,
                ),
              ),
          ],
        ),
      ),
    );
  }

  pw.Widget _flyerCard({
    required CampeonatoModel campeonato,
    required List<PartidoModel> partidos,
    required String etiquetaFecha,
    required _PdfLogos logos,
  }) {
    return _flyerCardBase(
      campeonato: campeonato,
      etiquetaFecha: etiquetaFecha,
      logos: logos,
      mensajeVacio: 'No hay partidos para mostrar.',
      filas: partidos.map(_flyerPartidoRow).toList(),
    );
  }

  /// Píldora de fecha con fondo (como en el afiche de referencia), en
  /// vez del texto plano que se usaba antes. Se centra con `pw.Table`
  /// (3 columnas: vacío-flex | píldora-intrínseca | vacío-flex) en lugar
  /// de `pw.Center`/`Row`-centrado: en este punto exacto del árbol,
  /// centrar un Container con fondo y bordes redondeados con esos dos
  /// widgets hacía que el paquete `pdf` dejara de pintar TODO lo
  /// anterior de la página sin lanzar ninguna excepción (ver nota
  /// histórica de este mismo bug en el flyer). `Table` no lo dispara y
  /// logra el mismo resultado visual.
  pw.Widget _flyerPildoraFecha(String etiquetaFecha) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.IntrinsicColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: _flyerPillFechaFondo,
                borderRadius: pw.BorderRadius.circular(999),
              ),
              child: pw.Text(
                etiquetaFecha,
                textAlign: pw.TextAlign.center,
                maxLines: 1,
                style: pw.TextStyle(
                  color: _flyerPillFechaTexto,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(),
          ],
        ),
      ],
    );
  }

  /// Emoji del deporte (⚽ 🏐 🏀), con la fuente Noto Emoji embebida en
  /// `logos.emojiDeportes`: la fuente Helvetica que trae el paquete
  /// `pdf` por defecto no tiene esos glifos (confirmado en pruebas —
  /// sin esta fuente el emoji queda en blanco), así que hace falta una
  /// fuente propia que sí los incluya.
  pw.Widget _flyerIconoDeporte(CampeonatoModel campeonato, _PdfLogos logos) {
    return pw.Text(
      _emojiDeporte(campeonato.deporteEfectivo),
      style: pw.TextStyle(font: logos.emojiDeportes, fontSize: 15),
    );
  }

  String _emojiDeporte(String deporte) {
    switch (deporte) {
      case DeporteTipo.volley:
        return '🏐';
      case DeporteTipo.basket:
        return '🏀';
      default:
        return '⚽';
    }
  }

  pw.Widget _flyerPartidoRow(PartidoModel partido) {
    final grupo = _grupoCortoPdf(partido.grupoId);

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FixedColumnWidth(48),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(38),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Column(
              children: [
                pw.Text(
                  'HORARIO',
                  style: pw.TextStyle(
                    color: _grisMedio,
                    fontSize: 5.5,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Container(
                  width: 40,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: _verdeOscuro,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    _horaTexto(partido.fechaHora),
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: _flyerEquiposVs(partido),
            ),
            grupo == null
                ? pw.SizedBox()
                : pw.Column(
                    children: [
                      pw.Text(
                        'GRUPO',
                        style: pw.TextStyle(
                          color: _grisMedio,
                          fontSize: 5.5,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: _flyerGrupoPill,
                          borderRadius: pw.BorderRadius.circular(999),
                        ),
                        child: pw.Text(
                          '"$grupo"',
                          style: pw.TextStyle(
                            color: _grisTexto,
                            fontSize: 7.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ],
    );
  }

  /// Todos los auspiciadores en una sola línea con el principal justo al
  /// medio: los secundarios se parten en dos mitades y cada mitad va en
  /// una columna flexible del mismo ancho, así el logo principal queda
  /// centrado exacto aunque queden 2 logos de un lado y 3 del otro.
  ///
  /// Se centra con `pw.Table` y no con `Row`+`Expanded` porque en este
  /// árbol el `Expanded` del paquete `pdf` colapsa a cero sin avisar.
  pw.Widget _filaPatrocinadores({
    required List<pw.MemoryImage> principal,
    required List<pw.MemoryImage> resto,
  }) {
    // Seis logos tienen que entrar en el ancho útil de la card (~330 pt):
    // si las cajas son más anchas, el paquete `pdf` los desborda y los
    // recorta en vez de achicarlos.
    // El tope de alto es generoso a propósito: un logo vertical (Essenza)
    // se queda corto de área si se lo limita a la altura de los
    // horizontales, y termina viéndose diminuto al lado de dolorsan o
    // Creación. Medido con los logos reales, con estos valores los seis
    // quedan entre ~490 y ~950 pt² y la fila suma ~320 pt de los ~332
    // disponibles.
    const areaLogo = 950.0;
    const anchoLogo = 56.0;
    const altoLogo = 30.0;
    const areaPrincipal = 1550.0;
    const anchoPrincipal = 66.0;
    const altoPrincipal = 31.0;

    if (principal.isEmpty) {
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: resto
            .map(
              (logo) => _cajaLogo(
                logo,
                area: areaLogo,
                anchoMax: anchoLogo,
                altoMax: altoLogo,
              ),
            )
            .toList(),
      );
    }

    final corte = resto.length ~/ 2;
    final izquierda = resto.take(corte).toList();
    final derecha = resto.skip(corte).toList();

    pw.Widget mitad(List<pw.MemoryImage> logos) {
      if (logos.isEmpty) return pw.SizedBox();
      return pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: logos
            .map(
              (logo) => _cajaLogo(
                logo,
                area: areaLogo,
                anchoMax: anchoLogo,
                altoMax: altoLogo,
              ),
            )
            .toList(),
      );
    }

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.IntrinsicColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            mitad(izquierda),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: principal
                  .map(
                    (logo) => _cajaLogo(
                      logo,
                      area: areaPrincipal,
                      anchoMax: anchoPrincipal,
                      altoMax: altoPrincipal,
                    ),
                  )
                  .toList(),
            ),
            mitad(derecha),
          ],
        ),
      ],
    );
  }

  /// Los logos se normalizan por **área**, no por caja fija: los
  /// auspiciadores tienen proporciones muy distintas (dolorsan es cuatro
  /// veces más ancho que alto, Essenza es más alto que ancho) y con una
  /// caja común unos se ven enormes y otros diminutos. Igualando el área
  /// que ocupa cada uno, todos pesan visualmente parecido. Los topes de
  /// ancho y alto evitan que uno muy alargado se escape de la fila.
  pw.Widget _cajaLogo(
    pw.MemoryImage logo, {
    required double area,
    required double anchoMax,
    required double altoMax,
  }) {
    final ancho = (logo.width ?? 0).toDouble();
    final alto = (logo.height ?? 0).toDouble();

    if (ancho <= 0 || alto <= 0) return pw.SizedBox();

    var escala = math.sqrt(area / (ancho * alto));
    escala = math.min(escala, anchoMax / ancho);
    escala = math.min(escala, altoMax / alto);

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 1.5),
      child: pw.SizedBox(
        width: ancho * escala,
        height: alto * escala,
        child: pw.Image(logo, fit: pw.BoxFit.contain),
      ),
    );
  }

  /// Nombres de los dos equipos con una regla debajo de cada uno y el
  /// "vs." al medio, calcado del afiche de referencia (ahí el subrayado
  /// es una línea que cruza todo el espacio del nombre, no el subrayado
  /// pegado al texto que da `TextDecoration.underline`).
  pw.Widget _flyerEquiposVs(PartidoModel partido) {
    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.IntrinsicColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            _flyerNombreEquipo(partido.equipoLocalNombre),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: pw.Text(
                'vs.',
                style: pw.TextStyle(
                  color: _grisTexto,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            _flyerNombreEquipo(partido.equipoVisitanteNombre),
          ],
        ),
      ],
    );
  }

  pw.Widget _flyerNombreEquipo(String nombre) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          nombre,
          textAlign: pw.TextAlign.center,
          maxLines: 1,
          overflow: pw.TextOverflow.clip,
          style: pw.TextStyle(
            color: _flyerVerdeTeal,
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(height: 0.9, color: _grisClaro),
      ],
    );
  }

  /// Pie completo del flyer: la firma del coordinador y, debajo, la
  /// franja de auspiciadores. Va anclado al fondo de la hoja (ver
  /// [_paginaFlyerJornada]) para que no dependa de cuánto creció la card.
  pw.Widget _flyerPie(_PdfLogos logos) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [_flyerCoordinador(logos), _flyerFranjaPatrocinadores(logos)],
    );
  }

  /// Firma del flyer: logo, separador vertical y los dos renglones del
  /// coordinador en una sola fila, tal como en el afiche de referencia
  /// (antes iba apilado y centrado).
  pw.Widget _flyerCoordinador(_PdfLogos logos) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.ClipOval(
          child: pw.Container(
            width: 36,
            height: 36,
            color: PdfColors.white,
            padding: const pw.EdgeInsets.all(4),
            alignment: pw.Alignment.center,
            child: _logo(image: logos.logoUpsa, width: 28, height: 28),
          ),
        ),
        pw.SizedBox(width: 11),
        pw.Container(width: 1, height: 27, color: PdfColor(1, 1, 1, 0.55)),
        pw.SizedBox(width: 12),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              'Coordinador de deportes UPSA',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              'Jorge Joaquín Antequera Castedo',
              style: pw.TextStyle(
                color: PdfColor(1, 1, 1, 0.85),
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Franja de auspiciadores al pie del flyer, sobre una barra blanca
  /// para que cualquier logo (con fondo claro, oscuro o transparente) se
  /// lea bien sobre el degradado verde.
  ///
  /// El logo que esté en `patrocinadores/principal/` va solo en la
  /// primera fila, centrado y más grande; el resto se reparte parejo en
  /// la tira de abajo. Si no hay ningún logo, no ocupa espacio.
  pw.Widget _flyerFranjaPatrocinadores(_PdfLogos logos) {
    if (!logos.tienePatrocinadores) return pw.SizedBox();

    final principal = logos.patrocinadorPrincipal;
    final resto = logos.patrocinadores;

    return pw.Column(
      children: [
        pw.SizedBox(height: 9),
        pw.Text(
          'AUSPICIAN',
          style: pw.TextStyle(
            color: PdfColor(1, 1, 1, 0.75),
            fontSize: 6,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.6,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: _filaPatrocinadores(principal: principal, resto: resto),
        ),
      ],
    );
  }

  Map<String, List<PdfResultadoPartidoItem>> _agruparResultadosPorFecha(
    List<PdfResultadoPartidoItem> resultados,
  ) {
    final ordenados = [...resultados]
      ..sort((a, b) {
        final fechaA = a.partido.fechaHora;
        final fechaB = b.partido.fechaHora;
        if (fechaA != null && fechaB != null) {
          return fechaA.compareTo(fechaB);
        }
        if (fechaA == null && fechaB != null) return 1;
        if (fechaA != null && fechaB == null) return -1;
        return a.partido.jornada.compareTo(b.partido.jornada);
      });

    final agrupados = <String, List<PdfResultadoPartidoItem>>{};

    for (final item in ordenados) {
      final fecha = item.partido.fechaHora;
      if (fecha == null) continue;

      final key =
          '${fecha.year}-${fecha.month.toString().padLeft(2, '0')}-${fecha.day.toString().padLeft(2, '0')}';

      agrupados.putIfAbsent(key, () => []);
      agrupados[key]!.add(item);
    }

    return agrupados;
  }

  /// Flyer de resultados: misma pieza visual que el flyer de programación
  /// (fondo degradado, título, píldora punteada, card blanca, footer),
  /// pero cada fila muestra el marcador final en vez del horario — el
  /// pedido fue que "resultados" y "programación" se vean igual.
  pw.Page _paginaFlyerResultadosJornada({
    required CampeonatoModel campeonato,
    required List<PdfResultadoPartidoItem> resultados,
    required String etiquetaFecha,
    required _PdfLogos logos,
  }) {
    return _paginaFlyer(
      campeonato: campeonato,
      subtitulo: 'RESULTADOS SEMANALES',
      logos: logos,
      card: _flyerCardResultados(
        campeonato: campeonato,
        resultados: resultados,
        etiquetaFecha: etiquetaFecha,
        logos: logos,
      ),
    );
  }

  pw.Widget _flyerCardResultados({
    required CampeonatoModel campeonato,
    required List<PdfResultadoPartidoItem> resultados,
    required String etiquetaFecha,
    required _PdfLogos logos,
  }) {
    return _flyerCardBase(
      campeonato: campeonato,
      etiquetaFecha: etiquetaFecha,
      logos: logos,
      mensajeVacio: 'No hay resultados para mostrar.',
      filas: resultados.map(_flyerResultadoRow).toList(),
    );
  }

  pw.Widget _flyerResultadoRow(PdfResultadoPartidoItem item) {
    final partido = item.partido;
    final grupo = _grupoCortoPdf(partido.grupoId);
    final marcador =
        partido.definidoPorPenales &&
            partido.penalesLocal != null &&
            partido.penalesVisitante != null
        ? '${partido.golesLocal ?? 0}-${partido.golesVisitante ?? 0} (${partido.penalesLocal}-${partido.penalesVisitante} pen.)'
        : '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}';

    final golesLocal = item.goles
        .where(
          (gol) =>
              gol.equipoNombre == partido.equipoLocalNombre && gol.cantidad > 0,
        )
        .toList();
    final golesVisitante = item.goles
        .where(
          (gol) =>
              gol.equipoNombre == partido.equipoVisitanteNombre &&
              gol.cantidad > 0,
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const {
            0: pw.FixedColumnWidth(48),
            1: pw.FlexColumnWidth(),
            2: pw.FixedColumnWidth(38),
          },
          children: [
            pw.TableRow(
              children: [
                pw.Column(
                  children: [
                    pw.Text(
                      'MARCADOR',
                      style: pw.TextStyle(
                        color: _grisMedio,
                        fontSize: 5.5,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Container(
                      width: 40,
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: _verdeOscuro,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        marcador,
                        maxLines: 1,
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: partido.definidoPorPenales ? 6 : 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                  child: pw.RichText(
                    textAlign: pw.TextAlign.center,
                    text: pw.TextSpan(
                      children: [
                        pw.TextSpan(
                          text: partido.equipoLocalNombre,
                          style: pw.TextStyle(
                            color: _flyerVerdeTeal,
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                            decorationColor: _flyerVerdeTeal,
                          ),
                        ),
                        pw.TextSpan(
                          text: '  vs.  ',
                          style: pw.TextStyle(
                            color: _grisTexto,
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.TextSpan(
                          text: partido.equipoVisitanteNombre,
                          style: pw.TextStyle(
                            color: _flyerVerdeTeal,
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            decoration: pw.TextDecoration.underline,
                            decorationColor: _flyerVerdeTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                grupo == null
                    ? pw.SizedBox()
                    : pw.Column(
                        children: [
                          pw.Text(
                            'GRUPO',
                            style: pw.TextStyle(
                              color: _grisMedio,
                              fontSize: 5.5,
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: pw.BoxDecoration(
                              color: _flyerGrupoPill,
                              borderRadius: pw.BorderRadius.circular(999),
                            ),
                            child: pw.Text(
                              '"$grupo"',
                              style: pw.TextStyle(
                                color: _grisTexto,
                                fontSize: 7.5,
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
        if (golesLocal.isNotEmpty || golesVisitante.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Table(
            columnWidths: const {
              0: pw.FixedColumnWidth(48),
              1: pw.FlexColumnWidth(),
              2: pw.FixedColumnWidth(38),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.SizedBox(),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 6),
                    child: pw.Table(
                      columnWidths: const {
                        0: pw.FlexColumnWidth(),
                        1: pw.FlexColumnWidth(),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(right: 4),
                              child: _flyerGoleadoresColumna(golesLocal),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.only(left: 4),
                              child: _flyerGoleadoresColumna(golesVisitante),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Goleadores de un equipo, uno por línea, debajo de su nombre — se
  /// pidió explícitamente que cada gol quede bajo su equipo en vez de
  /// una sola línea compartida entre ambos.
  ///
  /// El nombre puede partirse en dos líneas en vez de cortarse: con
  /// `maxLines: 1` los nombres largos quedaban truncados a la mitad. La
  /// cantidad va en una pastilla verde aparte, así se lee "quién" y
  /// "cuántos" de un golpe de vista sin cargar la tipografía.
  pw.Widget _flyerGoleadoresColumna(List<PdfGolPartidoItem> goleadores) {
    if (goleadores.isEmpty) return pw.SizedBox();

    // Todo en un `RichText` por línea, sin contenedores: una pastilla
    // con `Container` acá se estiraba y tapaba media card (el paquete
    // `pdf` la expandía en vez de ajustarla al texto). Con spans el
    // nombre puede partirse en dos líneas y el "×N" resalta en verde
    // sin ningún widget de layout de por medio.
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: goleadores.map((gol) {
        final cuerpo = _cuerpoGoleador(gol);

        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 1.8),
          child: pw.RichText(
            textAlign: pw.TextAlign.center,
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: gol.jugadorNombre,
                  style: pw.TextStyle(
                    color: _grisMedio,
                    fontSize: cuerpo,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (gol.cantidad > 1)
                  pw.TextSpan(
                    text: '  ×${gol.cantidad}',
                    style: pw.TextStyle(
                      color: _flyerVerdeTeal,
                      fontSize: cuerpo,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Tamaño de letra del goleador según el largo del nombre: se pidió que
  /// cada goleador entre en **una sola línea**, y los nombres completos
  /// bolivianos ("MARIO ALEJANDRO FERNANDEZ SALVATIERRA") no entran a un
  /// cuerpo fijo en la mitad de la card. En vez de cortarlos o partirlos
  /// en dos renglones, se achica la letra lo justo para que entren.
  double _cuerpoGoleador(PdfGolPartidoItem gol) {
    final largo = gol.jugadorNombre.trim().length + (gol.cantidad > 1 ? 4 : 0);

    if (largo <= 20) return 6.6;
    if (largo <= 26) return 5.8;
    if (largo <= 32) return 5.1;
    if (largo <= 40) return 4.5;
    return 4.1;
  }

  /// "Grupo B" -> "B": igual que en la app, el flyer solo muestra la
  /// letra del grupo (ver el equivalente en la tabla de posiciones).
  String? _grupoCortoPdf(String? grupoId) {
    if (grupoId == null || grupoId.trim().isEmpty) return null;
    final partes = grupoId.trim().split(RegExp(r'\s+'));
    return partes.isEmpty ? grupoId : partes.last;
  }

  String _deporteCardLabel(CampeonatoModel campeonato) {
    switch (campeonato.modalidad) {
      case ModalidadDeporte.futbol11:
        return 'FÚTBOL 11';
      case ModalidadDeporte.futbol7:
        return 'FÚTBOL 7';
      case ModalidadDeporte.futsal:
        return 'FUTSAL';
      case ModalidadDeporte.volleySala:
      case ModalidadDeporte.volleyMixto:
        return 'VÓLEY';
      case ModalidadDeporte.basket5:
      case ModalidadDeporte.basket3x3:
        return 'BÁSQUET';
      default:
        return _deporteLabel(campeonato);
    }
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

  /// Planilla de control de futsal (5 vs 5), calcada de la planilla
  /// física de la UPSA: cabecera con código de formulario y, por cada
  /// equipo, un bloque con sus datos, la lista de jugadores (número,
  /// tarjetas y goles por tiempo) y las faltas acumulativas del tiempo.
  /// Es la única hoja que se imprime para futsal: sin carteles de
  /// equipo ni lista de poleras aparte (eso es solo para fútbol 7/11).
  pw.Page _paginaPlanillaFutsal({
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> jugadoresLocal,
    required List<JugadorModel> jugadoresVisitante,
    required _PdfLogos logos,
  }) {
    final localOrdenado = [...jugadoresLocal]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    final visitanteOrdenado = [...jugadoresVisitante]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    return pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.fromLTRB(28, 22, 28, 18),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            _futsalPlanillaHeader(campeonato: campeonato, logos: logos),
            pw.SizedBox(height: 10),
            _futsalEquipoBloque(
              numero: 1,
              nombreEquipo: partido.equipoLocalNombre,
              campeonato: campeonato,
              partido: partido,
              jugadores: localOrdenado,
            ),
            pw.SizedBox(height: 10),
            _futsalEquipoBloque(
              numero: 2,
              nombreEquipo: partido.equipoVisitanteNombre,
              campeonato: campeonato,
              partido: partido,
              jugadores: visitanteOrdenado,
            ),
            pw.SizedBox(height: 16),
            _futsalResultadoFinal(),
          ],
        );
      },
    );
  }

  pw.Widget _futsalPlanillaHeader({
    required CampeonatoModel campeonato,
    required _PdfLogos logos,
  }) {
    final faseTexto = campeonato.tieneFasesSeparadas
        ? (campeonato.estaEnFaseDeGrupos
              ? 'FASE DE GRUPOS'
              : 'FASE ELIMINATORIA')
        : 'FASE DE GRUPOS';

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.8),
      columnWidths: const {
        0: pw.FixedColumnWidth(110),
        1: pw.FlexColumnWidth(),
        2: pw.FixedColumnWidth(120),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Container(
              height: 56,
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.all(6),
              child: _logo(image: logos.logoUpsa, width: 90, height: 40),
            ),
            pw.Container(
              height: 56,
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'PLANILLA DE CONTROL',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'FÚTSAL - $faseTexto',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Formulario de Calidad',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
            ),
            pw.Container(
              height: 56,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8),
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'UPSA P4-2-2-F10',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Revisión: 1',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                  pw.Text(
                    'Página 1 de 1',
                    style: const pw.TextStyle(fontSize: 7.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _futsalEquipoBloque({
    required int numero,
    required String nombreEquipo,
    required CampeonatoModel campeonato,
    required PartidoModel partido,
    required List<JugadorModel> jugadores,
  }) {
    const filasMinimas = 12;
    final filas = jugadores.length > filasMinimas
        ? jugadores.length
        : filasMinimas;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _futsalEquipoInfoRow(
            numero: numero,
            nombreEquipo: nombreEquipo,
            campeonato: campeonato,
            partido: partido,
          ),
          _futsalJugadoresTable(jugadores: jugadores, filas: filas),
          _futsalFaltasAcumulativas(),
        ],
      ),
    );
  }

  pw.Widget _futsalEquipoInfoRow({
    required int numero,
    required String nombreEquipo,
    required CampeonatoModel campeonato,
    required PartidoModel partido,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Table(
        columnWidths: const {
          0: pw.FixedColumnWidth(18),
          1: pw.FlexColumnWidth(3),
          2: pw.FlexColumnWidth(4),
          3: pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Container(
                width: 18,
                height: 18,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                ),
                child: pw.Text(
                  '$numero',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 8),
                child: pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'EQUIPO: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.TextSpan(
                        text: nombreEquipo.toUpperCase(),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _verdeOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'CAMPEONATO: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.TextSpan(
                      text: campeonato.nombre.toUpperCase(),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.Text(
                'FECHA: ${_fechaCorta(partido.fechaHora)}   HRS: ${_horaTexto(partido.fechaHora)}',
                textAlign: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Columnas: nombre, N° de camiseta, tarjetas (amarilla/roja) y goles
  /// por tiempo (1° y 2°) con su total. Sin encabezado "TARJETAS"/"GOLES"
  /// que agrupe visualmente dos columnas (el paquete de PDF no soporta
  /// colspan de forma confiable): cada columna ya es autoexplicativa.
  pw.Widget _futsalJugadoresTable({
    required List<JugadorModel> jugadores,
    required int filas,
  }) {
    final columnWidths = {
      0: const pw.FlexColumnWidth(5),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FlexColumnWidth(1),
      3: const pw.FlexColumnWidth(1),
      4: const pw.FlexColumnWidth(1),
      5: const pw.FlexColumnWidth(1),
      6: const pw.FlexColumnWidth(1.3),
    };

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.6),
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
          children: [
            _futsalHeaderCell(
              'NOMBRE Y APELLIDOS',
              align: pw.Alignment.centerLeft,
            ),
            _futsalHeaderCell('N°'),
            _futsalHeaderCell('T.AM'),
            _futsalHeaderCell('T.ROJA'),
            _futsalHeaderCell('GOL 1T'),
            _futsalHeaderCell('GOL 2T'),
            _futsalHeaderCell('TOTAL'),
          ],
        ),
        ...List.generate(filas, (index) {
          final jugador = index < jugadores.length ? jugadores[index] : null;

          return pw.TableRow(
            children: [
              pw.Container(
                constraints: const pw.BoxConstraints(minHeight: 16),
                alignment: pw.Alignment.centerLeft,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                child: pw.Text(
                  jugador?.nombreCompleto.toUpperCase() ?? '',
                  maxLines: 1,
                  style: const pw.TextStyle(fontSize: 7.5),
                ),
              ),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
              pw.Container(constraints: const pw.BoxConstraints(minHeight: 16)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _futsalHeaderCell(
    String texto, {
    pw.Alignment align = pw.Alignment.center,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      alignment: align,
      child: pw.Text(
        texto,
        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  /// Faltas acumulativas por tiempo (1°/2°): a partir de la 5ta falta de
  /// equipo en el tiempo, el rival cobra desde el punto de penal sin
  /// barrera. Se deja además un casillero chico para los dos tiempos
  /// muertos que tiene cada equipo por partido.
  pw.Widget _futsalFaltasAcumulativas() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Table(
        columnWidths: const {
          0: pw.FlexColumnWidth(2),
          1: pw.FlexColumnWidth(5),
          2: pw.FlexColumnWidth(5),
          3: pw.FlexColumnWidth(3),
        },
        children: [
          pw.TableRow(
            children: [
              pw.Text(
                'FALTAS\nACUMULATIVAS',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              _futsalFaltasFila('1° T'),
              _futsalFaltasFila('2° T'),
              _futsalTimeoutBox(),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _futsalFaltasFila(String etiqueta) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          etiqueta,
          style: pw.TextStyle(fontSize: 6.5, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        ...List.generate(5, (i) {
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2),
            child: pw.Container(
              width: 12,
              height: 12,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.6),
              ),
              child: pw.Text(
                '${i + 1}',
                style: const pw.TextStyle(fontSize: 6),
              ),
            ),
          );
        }),
        pw.SizedBox(width: 4),
        pw.Text('MIN', style: const pw.TextStyle(fontSize: 6)),
      ],
    );
  }

  pw.Widget _futsalTimeoutBox() {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        _futsalTimeoutCasilla('1'),
        pw.SizedBox(width: 3),
        _futsalTimeoutCasilla('2'),
        pw.SizedBox(width: 3),
        pw.Text('MIN', style: const pw.TextStyle(fontSize: 6)),
      ],
    );
  }

  pw.Widget _futsalTimeoutCasilla(String numero) {
    return pw.Container(
      width: 12,
      height: 12,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
      ),
      child: pw.Text(numero, style: const pw.TextStyle(fontSize: 6)),
    );
  }

  pw.Widget _futsalResultadoFinal() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'RESULTADO FINAL:',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        pw.Container(width: 50, height: 0.8, color: PdfColors.grey700),
        pw.SizedBox(width: 10),
        pw.Text(
          'VS',
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 10),
        pw.Container(width: 50, height: 0.8, color: PdfColors.grey700),
      ],
    );
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
            pw.Center(
              child: _logo(image: logos.logoUpsa, width: 110, height: 44),
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
                _logo(image: logos.logoUpsa, width: 56, height: 36),
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
                  pw.Expanded(child: _filaFichasPosicion(equipoNombre: null)),
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
      // Márgenes al mínimo imprimible: cada punto que se recupera acá va
      // a las grillas de los SETs, que es lo que se pidió agrandar todo
      // lo posible dentro de la hoja oficio.
      margin: const pw.EdgeInsets.fromLTRB(5, 4, 5, 3),
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
              _controlVoleyHeader(
                campeonato: campeonato,
                partido: partido,
                logos: logos,
              ),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(),
                  1: pw.FlexColumnWidth(),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _bloqueSetControlVoley(1),
                      _bloqueSetControlVoley(2),
                    ],
                  ),
                ],
              ),
              // OBSERVACIONES y RESULTADO FINAL van apilados debajo de SET
              // 3 (no en una fila propia al pie): esa columna quedaba más
              // corta que la de EQUIPOS, dejando un hueco vacío — usarlo
              // para estos dos bloques libera toda una fila de la hoja,
              // espacio que se reparte agrandando SET 1/2/3 y EQUIPOS.
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                        children: [
                          _bloqueSetControlVoley(3),
                          pw.SizedBox(height: 6),
                          pw.Table(
                            columnWidths: const {
                              0: pw.FlexColumnWidth(2),
                              1: pw.FlexColumnWidth(3),
                            },
                            children: [
                              pw.TableRow(
                                children: [
                                  _bloqueObservacionesVoley(),
                                  _bloqueResultadoFinalVoley(partido),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      _panelRosterControlVoley(
                        partido: partido,
                        jugadoresLocal: jugadoresLocal,
                        jugadoresVisitante: jugadoresVisitante,
                      ),
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
                  pw.Text(
                    'PLANILLA DE CONTROL',
                    style: const pw.TextStyle(fontSize: 7),
                  ),
                  pw.Text(
                    'VOLEIBOL',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Formulario de Calidad',
                    style: const pw.TextStyle(fontSize: 6),
                  ),
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
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Revisión: 0',
                    style: const pw.TextStyle(fontSize: 6.5),
                  ),
                  pw.Text(
                    'Página 1 de 1',
                    style: const pw.TextStyle(fontSize: 6.5),
                  ),
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
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              height: 16,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              alignment: pw.Alignment.centerLeft,
              child: pw.Row(
                children: [
                  pw.Text(
                    'GRUPO:',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
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
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _verdeOscuro,
                ),
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
                  pw.Text(
                    'CIUDAD:',
                    style: pw.TextStyle(
                      fontSize: 6,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Expanded(
                    child: pw.Container(height: 0.5, color: PdfColors.grey500),
                  ),
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
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
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
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
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
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.6),
      ),
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
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              'SET $numeroSet',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.7,
                        ),
                      ),
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
                pw.Text(
                  'AMONESTACIONES:',
                  style: pw.TextStyle(
                    fontSize: 5.3,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Container(height: 0.5, color: PdfColors.grey500),
                ),
                pw.SizedBox(width: 10),
                pw.Text(
                  'CASTIGOS:',
                  style: pw.TextStyle(
                    fontSize: 5.3,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Expanded(
                  child: pw.Container(height: 0.5, color: PdfColors.grey500),
                ),
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
            columnWidths: const {
              0: pw.FlexColumnWidth(9),
              1: pw.FlexColumnWidth(2),
            },
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
        0: pw.FixedColumnWidth(70),
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
              (p) => _celdaFormacionVoley(p, bold: true, height: 21),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('JUGADORES INICIALES'),
            ..._celdasVaciasVoley(height: 21),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('SUPLENTES / JUGADOR N°'),
            ..._celdasVaciasVoley(height: 21),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley('ANOTACIÓN'),
            ..._celdasFormacionVoley(
              const [':', ':', ':', ':', ':', ':'],
              height: 11.5,
              fontSize: 7.8,
            ),
          ],
        ),
        pw.TableRow(
          children: [
            _etiquetaFormacionVoley(''),
            ..._celdasFormacionVoley(
              const [':', ':', ':', ':', ':', ':'],
              height: 11.5,
              fontSize: 7.8,
            ),
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
        ..._celdasFormacionVoley(
          List.filled(6, valor),
          height: 11.3,
          fontSize: 7.7,
        ),
      ],
    );
  }

  pw.Widget _etiquetaFormacionVoley(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      alignment: pw.Alignment.centerLeft,
      child: pw.Text(
        texto,
        maxLines: 2,
        overflow: pw.TextOverflow.visible,
        style: pw.TextStyle(
          fontSize: 6.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
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
        .map((v) => _celdaFormacionVoley(v, height: height, fontSize: fontSize))
        .toList();
  }

  pw.Widget _celdaFormacionVoley(
    String texto, {
    bool bold = false,
    double height = 9,
    double fontSize = 7.5,
  }) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Grilla de anotación: números 1 a 33 (marcador punto a punto) en 3
  /// columnas de 11 filas, más una fila final "T" (tiempos fuera), tal
  /// como en la planilla oficial.
  pw.Widget _bloquePuntosGridVoley() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
      columnWidths: const {
        0: pw.FlexColumnWidth(),
        1: pw.FlexColumnWidth(),
        2: pw.FlexColumnWidth(),
      },
      children: [
        ...List.generate(11, (fila) {
          return pw.TableRow(
            children: List.generate(3, (col) {
              final numero = fila + 1 + (col * 11);
              return pw.Container(
                height: 8.3,
                alignment: pw.Alignment.center,
                child: pw.Text(
                  '$numero',
                  style: const pw.TextStyle(fontSize: 5.3),
                ),
              );
            }),
          );
        }),
        pw.TableRow(
          children: [
            pw.Container(
              height: 8.3,
              alignment: pw.Alignment.center,
              child: pw.Text(
                'T',
                style: pw.TextStyle(
                  fontSize: 5.1,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(height: 8.3),
            pw.Container(height: 8.3),
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
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              'EQUIPOS',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth(),
            },
            children: [
              pw.TableRow(
                children: [
                  pw.Container(
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(
                          color: PdfColors.black,
                          width: 0.7,
                        ),
                      ),
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

  /// Tabla con grilla real (bordes visibles), no simples renglones de
  /// texto: más fácil de leer y llenar para la mesa. La columna "N°"
  /// queda vacía a propósito — el equipo de mesa anota ahí el número de
  /// polera real de cada jugadora, la app no guarda ese dato.
  pw.Widget _listaRosterVoley(String titulo, List<JugadorModel> jugadores) {
    final ordenadas = [...jugadores]
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          titulo,
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _verdeOscuro,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey600, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(22),
            1: pw.FlexColumnWidth(),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              children: [
                _celdaRosterVoley(
                  'N°',
                  bold: true,
                  alinear: pw.Alignment.center,
                ),
                _celdaRosterVoley('NOMBRE Y APELLIDO', bold: true),
              ],
            ),
            ...List.generate(12, (index) {
              final jugadora = index < ordenadas.length
                  ? ordenadas[index]
                  : null;

              return pw.TableRow(
                children: [
                  _celdaRosterVoley('', alinear: pw.Alignment.center),
                  _celdaRosterVoley(
                    jugadora?.nombreCompleto.toUpperCase() ?? '',
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  pw.Widget _celdaRosterVoley(
    String texto, {
    bool bold = false,
    pw.Alignment alinear = pw.Alignment.centerLeft,
  }) {
    return pw.Container(
      height: 18,
      padding: const pw.EdgeInsets.symmetric(horizontal: 5),
      alignment: alinear,
      child: pw.Text(
        texto,
        maxLines: 1,
        overflow: pw.TextOverflow.clip,
        style: pw.TextStyle(
          fontSize: 7.6,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
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
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              child: pw.Text(
                'LÍBERO',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              child: pw.Text(
                'LÍBERO',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [_lineaFirmaVoley('Capitán'), _lineaFirmaVoley('Capitán')],
        ),
        pw.TableRow(
          children: [_lineaFirmaVoley('Firma'), _lineaFirmaVoley('Firma')],
        ),
        pw.TableRow(
          children: [
            _lineaFirmaVoley('Entrenador'),
            _lineaFirmaVoley('Entrenador'),
          ],
        ),
        pw.TableRow(
          children: [_lineaFirmaVoley('Firma'), _lineaFirmaVoley('Firma')],
        ),
      ],
    );
  }

  pw.Widget _lineaFirmaVoley(String etiqueta) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3.5, horizontal: 3),
      child: pw.Row(
        children: [
          pw.Text('$etiqueta:', style: const pw.TextStyle(fontSize: 6)),
          pw.SizedBox(width: 4),
          pw.Expanded(
            child: pw.Container(height: 0.5, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// OBSERVACIONES con renglones suficientes para llegar hasta el fondo
  /// de la hoja: esta columna (SET 3 + observaciones + resultado final)
  /// quedaba más corta que la de EQUIPOS y dejaba un hueco muerto abajo
  /// a la izquierda. Estirar los renglones de observaciones llena ese
  /// espacio sin tocar RESULTADO FINAL, y de paso le da más lugar a la
  /// planillera para escribir.
  pw.Widget _bloqueObservacionesVoley() {
    return _bloqueVoleyConTitulo(
      titulo: 'OBSERVACIONES',
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: List.generate(
          10,
          (_) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 11),
            child: pw.Container(height: 0.5, color: PdfColors.grey500),
          ),
        ),
      ),
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
          pw.SizedBox(height: 3),
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
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Comenzó a hrs.:',
                      style: const pw.TextStyle(fontSize: 4.6),
                    ),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Finalizó a hrs.:',
                      style: const pw.TextStyle(fontSize: 4.6),
                    ),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Duración total:',
                      style: const pw.TextStyle(fontSize: 4.6),
                    ),
                    pw.Container(height: 0.5, color: PdfColors.grey500),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            children: [
              pw.Text(
                'GANADOR:',
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(width: 4),
              pw.Expanded(
                child: pw.Container(height: 0.6, color: PdfColors.black),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _ccVoley(String text, {bool bold = false, double height = 10}) {
    return pw.Container(
      height: height,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
      child: pw.Text(
        text,
        maxLines: 1,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 5.3,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _bloqueVoleyConTitulo({
    required String titulo,
    required pw.Widget child,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Container(
            color: PdfColors.black,
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text(
              titulo,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 0.6,
              ),
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
        pw.Center(child: _logo(image: logos.logoUpsa, width: 116, height: 52)),
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
        pw.Center(child: _logo(image: logos.logoUpsa, width: 110, height: 44)),
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
