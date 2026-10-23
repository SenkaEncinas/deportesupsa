part of '../pdf_service.dart';

/// Planilla de control de futsal y las hojas que la acompañan (cartel
/// con el nombre de cada equipo y lista de jugadores con polera).
///
/// Vive en su propio archivo para que `pdf_service.dart` no sea una sola
/// clase de 4.400 líneas. Es una extensión privada de [PdfService]:
/// usa sus mismos colores, logos y ayudantes.
extension _PdfPlanillaFutbol on PdfService {
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
        ? campeonato.nombreFaseActual.toUpperCase()
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
}
