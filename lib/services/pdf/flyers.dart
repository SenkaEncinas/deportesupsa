part of '../pdf_service.dart';

/// Flyers de programación y de resultados (las placas para redes).
///
/// Vive en su propio archivo para que `pdf_service.dart` no sea una sola
/// clase de 4.400 líneas. Es una extensión privada de [PdfService]:
/// usa sus mismos colores, logos y ayudantes.
extension _PdfFlyers on PdfService {
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
    return _flyerFila(
      partido: partido,
      etiqueta: 'HORARIO',
      valor: _horaTexto(partido.fechaHora),
      centro: _flyerEquiposVs(partido),
    );
  }

  /// Una fila del flyer: a la izquierda una píldora con su etiqueta
  /// (HORARIO o MARCADOR), al medio los equipos y a la derecha el grupo.
  /// La comparten el flyer de programación y el de resultados, que antes
  /// repetían la tabla entera.
  pw.Widget _flyerFila({
    required PartidoModel partido,
    required String etiqueta,
    required String valor,
    required pw.Widget centro,
    double tamanoValor = 8,
  }) {
    final grupo = _grupoCortoPdf(partido.grupoId);

    return pw.Table(
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: _flyerColumnas,
      children: [
        pw.TableRow(
          children: [
            pw.Column(
              children: [
                _flyerEtiqueta(etiqueta),
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
                    valor,
                    maxLines: 1,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: tamanoValor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6),
              child: centro,
            ),
            grupo == null
                ? pw.SizedBox()
                : pw.Column(
                    children: [
                      _flyerEtiqueta('GRUPO'),
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

  pw.Widget _flyerEtiqueta(String texto) {
    return pw.Text(
      texto,
      style: pw.TextStyle(
        color: _grisMedio,
        fontSize: 5.5,
        fontWeight: pw.FontWeight.bold,
        letterSpacing: 0.5,
      ),
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

      final key = Fechas.clave(fecha);

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
    final marcador =
        partido.definidoPorPenales &&
            partido.penalesLocal != null &&
            partido.penalesVisitante != null
        ? '${partido.golesLocal ?? 0}-${partido.golesVisitante ?? 0} (${partido.penalesLocal}-${partido.penalesVisitante} pen.)'
        : '${partido.golesLocal ?? 0} - ${partido.golesVisitante ?? 0}';

    final golesLocal = item.goles
        .where(
          (gol) => gol.equipoId == partido.equipoLocalId && gol.cantidad > 0,
        )
        .toList();
    final golesVisitante = item.goles
        .where(
          (gol) =>
              gol.equipoId == partido.equipoVisitanteId && gol.cantidad > 0,
        )
        .toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _flyerFila(
          partido: partido,
          etiqueta: 'MARCADOR',
          valor: marcador,
          tamanoValor: partido.definidoPorPenales ? 6 : 9,
          centro: pw.RichText(
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
        if (golesLocal.isNotEmpty || golesVisitante.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Table(
            columnWidths: _flyerColumnas,
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
}
