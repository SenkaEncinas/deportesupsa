part of '../pdf_service.dart';

/// Planilla oficial de vóley: fichas de posición por set y planilla de
/// control punto a punto.
///
/// Vive en su propio archivo para que `pdf_service.dart` no sea una sola
/// clase de 4.400 líneas. Es una extensión privada de [PdfService]:
/// usa sus mismos colores, logos y ayudantes.
extension _PdfPlanillaVoley on PdfService {
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

  /// Barra negra con el título de cada bloque de la planilla de vóley
  /// ("SET 1", "EQUIPOS"...), como en el papel oficial.
  pw.Widget _barraTituloVoley(String titulo) {
    return pw.Container(
      color: PdfColors.black,
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Text(
        titulo,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
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
          _barraTituloVoley('SET $numeroSet'),
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
          _barraTituloVoley('EQUIPOS'),
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
}
