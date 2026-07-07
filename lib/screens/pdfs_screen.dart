import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/jugador_service.dart';
import '../services/partido_service.dart';
import '../services/pdf_service.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_section_header.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';

class PdfsScreen extends StatefulWidget {
  final String campeonatoId;

  const PdfsScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  State<PdfsScreen> createState() => _PdfsScreenState();
}

class _PdfsScreenState extends State<PdfsScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final EquipoService _equipoService = EquipoService();
  final JugadorService _jugadorService = JugadorService();
  final PartidoService _partidoService = PartidoService();
  final PdfService _pdfService = PdfService();

  late Future<_PdfData> _dataFuture;

  DateTime? _fixtureInicio;
  DateTime? _fixtureFin;
  DateTime? _resultadosInicio;
  DateTime? _resultadosFin;
  DateTime? _planillasInicio;
  DateTime? _planillasFin;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _fixtureInicio = DateTime(now.year, now.month, now.day);
    _fixtureFin = DateTime(now.year, now.month, now.day + 7);

    _resultadosInicio = DateTime(now.year, now.month, now.day - 7);
    _resultadosFin = DateTime(now.year, now.month, now.day);

    _planillasInicio = null;
    _planillasFin = null;

    _dataFuture = _loadData();
  }

  Future<_PdfData> _loadData() async {
    final campeonato =
        await _campeonatoService.getCampeonato(widget.campeonatoId);
    final equipos = await _equipoService.getEquipos(widget.campeonatoId);
    final partidos = await _partidoService.getPartidos(widget.campeonatoId);

    return _PdfData(
      campeonato: campeonato,
      equipos: equipos,
      partidos: partidos,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _dataFuture = _loadData();
    });
  }

  DateTime _inicioDelDia(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _finDelDia(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  bool _estaEnRango(DateTime fecha, DateTime inicio, DateTime fin) {
    final desde = _inicioDelDia(inicio);
    final hasta = _finDelDia(fin);

    return !fecha.isBefore(desde) && !fecha.isAfter(hasta);
  }

  String _fechaBoton(DateTime? fecha) {
    if (fecha == null) return 'Elegir fecha';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();

    return '$dia/$mes/$anio';
  }

  Future<void> _pickDate({
    required DateTime? current,
    required void Function(DateTime date) onSelected,
  }) async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDate: current ?? now,
    );

    if (date == null) return;

    onSelected(date);
  }

  List<PartidoModel> _filtrarPartidosPlanillas(List<PartidoModel> partidos) {
    if (_planillasInicio == null || _planillasFin == null) {
      return _partidosOrdenados(partidos);
    }

    return _partidosOrdenados(
      partidos.where((partido) {
        final fecha = partido.fechaHora;

        if (fecha == null) return false;

        return _estaEnRango(
          fecha,
          _planillasInicio!,
          _planillasFin!,
        );
      }).toList(),
    );
  }

  void _limpiarFiltroPlanillas() {
    setState(() {
      _planillasInicio = null;
      _planillasFin = null;
    });
  }

  Future<void> _imprimirFixtureCompleto(_PdfData data) async {
    if (data.campeonato == null) return;

    if (data.partidos.isEmpty) {
      AppSnackbars.warning(context, 'No hay partidos para imprimir.');
      return;
    }

    final bytes = await _pdfService.generarFixturePdf(
      campeonato: data.campeonato!,
      partidos: data.partidos,
    );

    await Printing.layoutPdf(
      name: 'fixture_completo_${data.campeonato!.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirFixtureRango(_PdfData data) async {
    if (data.campeonato == null) return;

    if (_fixtureInicio == null || _fixtureFin == null) {
      AppSnackbars.warning(context, 'Selecciona fecha inicio y fecha fin.');
      return;
    }

    if (_fixtureFin!.isBefore(_fixtureInicio!)) {
      AppSnackbars.error(
        context,
        'La fecha fin no puede ser anterior a la fecha inicio.',
      );
      return;
    }

    final partidosFiltrados = data.partidos.where((partido) {
      final fecha = partido.fechaHora;

      if (fecha == null) return false;

      return _estaEnRango(fecha, _fixtureInicio!, _fixtureFin!);
    }).toList();

    if (partidosFiltrados.isEmpty) {
      AppSnackbars.warning(
        context,
        'No hay partidos programados en ese rango de fechas.',
      );
      return;
    }

    final bytes = await _pdfService.generarFixturePorRangoPdf(
      campeonato: data.campeonato!,
      partidos: partidosFiltrados,
      fechaInicio: _fixtureInicio!,
      fechaFin: _fixtureFin!,
    );

    await Printing.layoutPdf(
      name: 'programacion_${data.campeonato!.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirResultadosRango(_PdfData data) async {
    if (data.campeonato == null) return;

    if (_resultadosInicio == null || _resultadosFin == null) {
      AppSnackbars.warning(context, 'Selecciona fecha inicio y fecha fin.');
      return;
    }

    if (_resultadosFin!.isBefore(_resultadosInicio!)) {
      AppSnackbars.error(
        context,
        'La fecha fin no puede ser anterior a la fecha inicio.',
      );
      return;
    }

    final partidosFiltrados = data.partidos.where((partido) {
      final fecha = partido.fechaHora;

      if (fecha == null) return false;

      final tieneResultado = partido.resultadoRegistrado &&
          partido.golesLocal != null &&
          partido.golesVisitante != null;

      return tieneResultado &&
          _estaEnRango(fecha, _resultadosInicio!, _resultadosFin!);
    }).toList();

    if (partidosFiltrados.isEmpty) {
      AppSnackbars.warning(
        context,
        'No hay resultados registrados en ese rango de fechas.',
      );
      return;
    }

    final resultados = <PdfResultadoPartidoItem>[];

    for (final partido in partidosFiltrados) {
      final golesSnap = await FirebaseFirestore.instance
          .collection('campeonatos')
          .doc(widget.campeonatoId)
          .collection('goles')
          .where('partidoId', isEqualTo: partido.id)
          .get();

      final goles = golesSnap.docs.map((doc) {
        final data = doc.data();

        return PdfGolPartidoItem(
          jugadorNombre: (data['jugadorNombre'] ?? '').toString(),
          equipoNombre: (data['equipoNombre'] ?? '').toString(),
          cantidad: (data['cantidad'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      resultados.add(
        PdfResultadoPartidoItem(
          partido: partido,
          goles: goles,
        ),
      );
    }

    final bytes = await _pdfService.generarResultadosPorRangoPdf(
      campeonato: data.campeonato!,
      resultados: resultados,
      fechaInicio: _resultadosInicio!,
      fechaFin: _resultadosFin!,
    );

    await Printing.layoutPdf(
      name: 'resultados_${data.campeonato!.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirListaEquipo(
    _PdfData data,
    EquipoModel equipo,
  ) async {
    if (data.campeonato == null) return;

    final jugadores = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: equipo.id,
    );

    final bytes = await _pdfService.generarListaEquipoPdf(
      campeonato: data.campeonato!,
      equipo: equipo,
      jugadores: jugadores,
    );

    await Printing.layoutPdf(
      name: 'lista_${equipo.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirTodasListasEquipos(_PdfData data) async {
    if (data.campeonato == null) return;

    if (data.equipos.isEmpty) {
      AppSnackbars.warning(context, 'No hay equipos registrados.');
      return;
    }

    final equiposConJugadores = <PdfEquipoJugadoresItem>[];

    for (final equipo in data.equipos) {
      final jugadores = await _jugadorService.getJugadoresPorEquipo(
        campeonatoId: widget.campeonatoId,
        equipoId: equipo.id,
      );

      equiposConJugadores.add(
        PdfEquipoJugadoresItem(
          equipo: equipo,
          jugadores: jugadores,
        ),
      );
    }

    final bytes = await _pdfService.generarListasEquiposPdf(
      campeonato: data.campeonato!,
      equipos: equiposConJugadores,
    );

    await Printing.layoutPdf(
      name: 'listas_equipos_${data.campeonato!.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirPlanillaPartido(
    _PdfData data,
    PartidoModel partido,
  ) async {
    if (data.campeonato == null) return;

    final jugadoresLocal = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: partido.equipoLocalId,
    );

    final jugadoresVisitante = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: partido.equipoVisitanteId,
    );

    final bytes = await _pdfService.generarPlanillaPartidoPdf(
      campeonato: data.campeonato!,
      partido: partido,
      jugadoresLocal: jugadoresLocal,
      jugadoresVisitante: jugadoresVisitante,
    );

    await Printing.layoutPdf(
      name:
          'planilla_${partido.equipoLocalNombre}_vs_${partido.equipoVisitanteNombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  Future<void> _imprimirRankingGoleadores(_PdfData data) async {
    if (data.campeonato == null) return;

    final rankingSnap = await FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(widget.campeonatoId)
        .collection('ranking_goleadores')
        .orderBy('totalGoles', descending: true)
        .limit(10)
        .get();

    final ranking = rankingSnap.docs.map((doc) {
      final data = doc.data();

      return PdfRankingGoleadorItem(
        jugadorNombre: (data['jugadorNombre'] ?? '').toString(),
        equipoNombre: (data['equipoNombre'] ?? '').toString(),
        totalGoles: (data['totalGoles'] as num?)?.toInt() ?? 0,
        partidosConGol: (data['partidosConGol'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    if (ranking.isEmpty) {
      AppSnackbars.warning(context, 'Todavía no hay ranking de goleadores.');
      return;
    }

    final bytes = await _pdfService.generarRankingGoleadoresPdf(
      campeonato: data.campeonato!,
      ranking: ranking,
    );

    await Printing.layoutPdf(
      name: 'ranking_goleadores_${data.campeonato!.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  List<PartidoModel> _partidosOrdenados(List<PartidoModel> partidos) {
    final sorted = [...partidos];

    sorted.sort((a, b) {
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

    return sorted;
  }

  String _partidoFechaTexto(PartidoModel partido) {
    final fecha = partido.fechaHora;

    if (fecha == null) return 'Sin fecha programada';

    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year;
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$anio $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_PdfData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando centro de impresión...');
          }

          if (snapshot.hasError) {
            return AppEmptyState(
              icon: Icons.error_outline,
              title: 'Error al cargar reportes',
              message: snapshot.error.toString(),
            );
          }

          final data = snapshot.data!;
          final partidosPlanillas = _filtrarPartidosPlanillas(data.partidos);

          return SingleChildScrollView(
            child: AppPage(
              title: 'Centro de impresión',
              subtitle: data.campeonato == null
                  ? 'Reportes y planillas del campeonato.'
                  : data.campeonato!.nombre,
              actions: [
                AppButton.secondary(
                  text: 'Actualizar',
                  icon: Icons.refresh,
                  onPressed: _refresh,
                ),
                AppButton.secondary(
                  text: 'Volver',
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroPrintCard(),
                  const SizedBox(height: 20),
                  _FixtureRangeCard(
                    inicio: _fixtureInicio,
                    fin: _fixtureFin,
                    onPickInicio: () {
                      _pickDate(
                        current: _fixtureInicio,
                        onSelected: (date) {
                          setState(() {
                            _fixtureInicio = date;
                          });
                        },
                      );
                    },
                    onPickFin: () {
                      _pickDate(
                        current: _fixtureFin,
                        onSelected: (date) {
                          setState(() {
                            _fixtureFin = date;
                          });
                        },
                      );
                    },
                    fechaBoton: _fechaBoton,
                    onPrintRange: data.partidos.isEmpty
                        ? null
                        : () => _imprimirFixtureRango(data),
                    onPrintAll: data.partidos.isEmpty
                        ? null
                        : () => _imprimirFixtureCompleto(data),
                  ),
                  const SizedBox(height: 18),
                  _ResultadosRangeCard(
                    inicio: _resultadosInicio,
                    fin: _resultadosFin,
                    onPickInicio: () {
                      _pickDate(
                        current: _resultadosInicio,
                        onSelected: (date) {
                          setState(() {
                            _resultadosInicio = date;
                          });
                        },
                      );
                    },
                    onPickFin: () {
                      _pickDate(
                        current: _resultadosFin,
                        onSelected: (date) {
                          setState(() {
                            _resultadosFin = date;
                          });
                        },
                      );
                    },
                    fechaBoton: _fechaBoton,
                    onPrint: data.partidos.isEmpty
                        ? null
                        : () => _imprimirResultadosRango(data),
                  ),
                  const SizedBox(height: 18),
                  _RankingCard(
                    onPrint: () => _imprimirRankingGoleadores(data),
                  ),
                  const SizedBox(height: 22),
                  _PartidosPrintSection(
                    partidos: partidosPlanillas,
                    totalPartidos: data.partidos.length,
                    filtroActivo:
                        _planillasInicio != null && _planillasFin != null,
                    inicio: _planillasInicio,
                    fin: _planillasFin,
                    fechaBoton: _fechaBoton,
                    fechaTexto: _partidoFechaTexto,
                    onPickInicio: () {
                      _pickDate(
                        current: _planillasInicio,
                        onSelected: (date) {
                          setState(() {
                            _planillasInicio = date;
                          });
                        },
                      );
                    },
                    onPickFin: () {
                      _pickDate(
                        current: _planillasFin,
                        onSelected: (date) {
                          setState(() {
                            _planillasFin = date;
                          });
                        },
                      );
                    },
                    onClearFilter: _limpiarFiltroPlanillas,
                    onPrintPartido: (partido) =>
                        _imprimirPlanillaPartido(data, partido),
                  ),
                  const SizedBox(height: 22),
                  _EquiposPrintSection(
                    equipos: data.equipos,
                    onPrintAll: () => _imprimirTodasListasEquipos(data),
                    onPrintEquipo: (equipo) =>
                        _imprimirListaEquipo(data, equipo),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeroPrintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primaryDark,
      showBorder: false,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.print_outlined,
              color: AppColors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reportes listos para imprimir',
                  style: AppTextStyles.heading2.copyWith(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Genera planillas de control, fixture por fechas, resultados, listas de equipos y ranking de goleadores.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white.withOpacity(0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FixtureRangeCard extends StatelessWidget {
  final DateTime? inicio;
  final DateTime? fin;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;
  final String Function(DateTime?) fechaBoton;
  final VoidCallback? onPrintRange;
  final VoidCallback? onPrintAll;

  const _FixtureRangeCard({
    required this.inicio,
    required this.fin,
    required this.onPickInicio,
    required this.onPickFin,
    required this.fechaBoton,
    required this.onPrintRange,
    required this.onPrintAll,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Programación / Fixture', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            'Imprime partidos programados dentro de un rango de fechas. Los partidos sin fecha no se incluyen en este reporte.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _DateRangeRow(
            inicio: inicio,
            fin: fin,
            fechaBoton: fechaBoton,
            onPickInicio: onPickInicio,
            onPickFin: onPickFin,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AppButton.primary(
                text: 'Imprimir por rango',
                icon: Icons.date_range_outlined,
                onPressed: onPrintRange,
              ),
              AppButton.secondary(
                text: 'Fixture completo',
                icon: Icons.picture_as_pdf_outlined,
                onPressed: onPrintAll,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultadosRangeCard extends StatelessWidget {
  final DateTime? inicio;
  final DateTime? fin;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;
  final String Function(DateTime?) fechaBoton;
  final VoidCallback? onPrint;

  const _ResultadosRangeCard({
    required this.inicio,
    required this.fin,
    required this.onPickInicio,
    required this.onPickFin,
    required this.fechaBoton,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resultados por fecha', style: AppTextStyles.heading3),
          const SizedBox(height: 6),
          Text(
            'Imprime los partidos finalizados dentro de un rango de fechas, con marcador y goleadores.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _DateRangeRow(
            inicio: inicio,
            fin: fin,
            fechaBoton: fechaBoton,
            onPickInicio: onPickInicio,
            onPickFin: onPickFin,
          ),
          const SizedBox(height: 14),
          AppButton.primary(
            text: 'Imprimir resultados',
            icon: Icons.fact_check_outlined,
            onPressed: onPrint,
          ),
        ],
      ),
    );
  }
}

class _RankingCard extends StatelessWidget {
  final VoidCallback onPrint;

  const _RankingCard({
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.sports_soccer,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ranking de goleadores', style: AppTextStyles.heading3),
                const SizedBox(height: 4),
                Text(
                  'Imprime el Top 10 de goleadores del campeonato.',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AppButton.secondary(
            text: 'Imprimir Top 10',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: onPrint,
          ),
        ],
      ),
    );
  }
}

class _DateRangeRow extends StatelessWidget {
  final DateTime? inicio;
  final DateTime? fin;
  final String Function(DateTime?) fechaBoton;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;

  const _DateRangeRow({
    required this.inicio,
    required this.fin,
    required this.fechaBoton,
    required this.onPickInicio,
    required this.onPickFin,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AppButton.secondary(
            text: 'Inicio: ${fechaBoton(inicio)}',
            icon: Icons.calendar_today_outlined,
            onPressed: onPickInicio,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton.secondary(
            text: 'Fin: ${fechaBoton(fin)}',
            icon: Icons.event_outlined,
            onPressed: onPickFin,
          ),
        ),
      ],
    );
  }
}

class _PartidosPrintSection extends StatelessWidget {
  final List<PartidoModel> partidos;
  final int totalPartidos;
  final bool filtroActivo;
  final DateTime? inicio;
  final DateTime? fin;
  final String Function(DateTime?) fechaBoton;
  final String Function(PartidoModel partido) fechaTexto;
  final VoidCallback onPickInicio;
  final VoidCallback onPickFin;
  final VoidCallback onClearFilter;
  final void Function(PartidoModel partido) onPrintPartido;

  const _PartidosPrintSection({
    required this.partidos,
    required this.totalPartidos,
    required this.filtroActivo,
    required this.inicio,
    required this.fin,
    required this.fechaBoton,
    required this.fechaTexto,
    required this.onPickInicio,
    required this.onPickFin,
    required this.onClearFilter,
    required this.onPrintPartido,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Planillas de control por partido',
          subtitle:
              'Filtra por fecha para encontrar rápido el partido y generar la hoja manual de control.',
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateRangeRow(
                inicio: inicio,
                fin: fin,
                fechaBoton: fechaBoton,
                onPickInicio: onPickInicio,
                onPickFin: onPickFin,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      filtroActivo
                          ? 'Mostrando ${partidos.length} de $totalPartidos partidos.'
                          : 'Mostrando todos los partidos.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  AppButton.ghost(
                    text: 'Limpiar filtro',
                    icon: Icons.filter_alt_off_outlined,
                    onPressed: filtroActivo ? onClearFilter : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (partidos.isEmpty)
                Text(
                  filtroActivo
                      ? 'No hay partidos programados en ese rango.'
                      : 'No hay partidos generados.',
                )
              else
                ...partidos.map((partido) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                    ),
                    subtitle: Text(
                      '${fechaTexto(partido)} · Vuelta ${partido.vuelta} · Jornada ${partido.jornada}',
                    ),
                    trailing: AppButton.secondary(
                      text: 'Planilla',
                      icon: Icons.print_outlined,
                      onPressed: () => onPrintPartido(partido),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _EquiposPrintSection extends StatelessWidget {
  final List<EquipoModel> equipos;
  final VoidCallback onPrintAll;
  final void Function(EquipoModel equipo) onPrintEquipo;

  const _EquiposPrintSection({
    required this.equipos,
    required this.onPrintAll,
    required this.onPrintEquipo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Planillas de equipos',
          subtitle: 'Imprime listas de jugadores por equipo para control manual.',
        ),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppButton.primary(
                text: 'Imprimir todas las planillas',
                icon: Icons.print_outlined,
                onPressed: equipos.isEmpty ? null : onPrintAll,
              ),
              const SizedBox(height: 14),
              if (equipos.isEmpty)
                const Text('No hay equipos registrados.')
              else
                ...equipos.map((equipo) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(equipo.nombre),
                    subtitle: Text(
                      '${equipo.cantidadJugadoresRegistrados} jugadores',
                    ),
                    trailing: AppButton.secondary(
                      text: 'Imprimir',
                      icon: Icons.picture_as_pdf_outlined,
                      onPressed: () => onPrintEquipo(equipo),
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _PdfData {
  final CampeonatoModel? campeonato;
  final List<EquipoModel> equipos;
  final List<PartidoModel> partidos;

  const _PdfData({
    required this.campeonato,
    required this.equipos,
    required this.partidos,
  });
}