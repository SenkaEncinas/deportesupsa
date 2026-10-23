part of '../pdf_service.dart';

/// Encabezados, pies y tablas que comparten la planilla de fútbol 7/11 y
/// básquet, los listados de equipos y la programación.
///
/// Vive en su propio archivo para que `pdf_service.dart` no sea una sola
/// clase de 4.400 líneas. Es una extensión privada de [PdfService]:
/// usa sus mismos colores, logos y ayudantes.
extension _PdfComunes on PdfService {
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

  /// Encabezado de la tabla de jugadores. Fútbol anota tarjetas y goles
  /// por tiempo; básquet, faltas (personales y técnicas) y puntos por
  /// mitad. Antes básquet imprimía las columnas de fútbol.
  pw.Widget _planillaEquiposHeader(
    CampeonatoModel campeonato,
    PartidoModel partido,
  ) {
    final basket = campeonato.esBasket;
    final control = basket ? 'FALTAS' : 'TARJETAS';
    final anotacion = basket ? 'PUNTOS' : 'GOLES';
    final sub = basket
        ? const ['PER', 'TÉC', '1°M', '2°M']
        : const ['TA', 'TR', '1T', '2T'];

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
            _smallCell(control, bold: true),
            _smallCell('', bold: true),
            _smallCell(anotacion, bold: true),
            _smallCell('', bold: true),
            _smallCell('N°', bold: true),
            _smallCell(
              'EQUIPO: ${partido.equipoVisitanteNombre.toUpperCase()}',
              bold: true,
            ),
            _smallCell(control, bold: true),
            _smallCell('', bold: true),
            _smallCell(anotacion, bold: true),
            _smallCell('', bold: true),
          ],
        ),
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('F9FAFB')),
          children: [
            _smallCell('', bold: true),
            _smallCell('NOMBRE Y APELLIDO', bold: true),
            for (final texto in sub) _smallCell(texto, bold: true),
            _smallCell('', bold: true),
            _smallCell('NOMBRE Y APELLIDO', bold: true),
            for (final texto in sub) _smallCell(texto, bold: true),
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
