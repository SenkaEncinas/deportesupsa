import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/partido_service.dart';
import '../services/pdf_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_empty_state.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_styles.dart';

class FixtureScreen extends StatefulWidget {
  final String campeonatoId;

  const FixtureScreen({
    super.key,
    required this.campeonatoId,
  });

  @override
  State<FixtureScreen> createState() => _FixtureScreenState();
}

class _FixtureScreenState extends State<FixtureScreen> {
  final CampeonatoService _campeonatoService = CampeonatoService();
  final EquipoService _equipoService = EquipoService();
  final PartidoService _partidoService = PartidoService();
  final PdfService _pdfService = PdfService();

  bool _loading = false;

  Future<void> _generarFixture() async {
    setState(() {
      _loading = true;
    });

    try {
      await _partidoService.generarFixtureIdaVueltaAleatorio(
        campeonatoId: widget.campeonatoId,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Fixture aleatorio generado correctamente.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _crearCruceManual() async {
    setState(() {
      _loading = true;
    });

    try {
      final equipos = await _equipoService.getEquipos(widget.campeonatoId);
      final activos =
          equipos.where((equipo) => equipo.estado == EquipoEstado.activo).toList();

      if (!mounted) return;

      if (activos.length < 2) {
        AppSnackbars.error(
          context,
          'Debe existir al menos 2 equipos activos para crear un cruce.',
        );
        return;
      }

      final result = await showDialog<_CruceManualResult>(
        context: context,
        builder: (_) => _CruceManualDialog(equipos: activos),
      );

      if (result == null) return;

      await _partidoService.crearCruceManual(
        campeonatoId: widget.campeonatoId,
        equipoLocal: result.local,
        equipoVisitante: result.visitante,
        jornada: result.jornada,
        idaYVuelta: result.idaYVuelta,
      );

      if (!mounted) return;

      AppSnackbars.success(
        context,
        result.idaYVuelta
            ? 'Cruce manual creado con ida y vuelta.'
            : 'Partido único creado correctamente.',
      );
    } catch (e) {
      if (!mounted) return;

      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _programarPartido(PartidoModel partido) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(2026),
      lastDate: DateTime(2035),
      initialDate: partido.fechaHora ?? DateTime.now(),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: partido.fechaHora == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(partido.fechaHora!),
    );

    if (time == null) return;

    final fechaHora = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      await _partidoService.programarPartido(
        campeonatoId: widget.campeonatoId,
        partidoId: partido.id,
        fechaHora: fechaHora,
      );

      if (!mounted) return;
      AppSnackbars.success(context, 'Partido programado correctamente.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(
        context,
        e.toString().replaceAll('Exception:', '').trim(),
      );
    }
  }

  Future<void> _descargarFixture(
    CampeonatoModel campeonato,
    List<PartidoModel> partidos,
  ) async {
    final bytes = await _pdfService.generarFixturePdf(
      campeonato: campeonato,
      partidos: partidos,
    );

    await Printing.layoutPdf(
      name: 'fixture_${campeonato.nombre}.pdf',
      onLayout: (_) async => bytes,
    );
  }

  String _fechaTexto(DateTime? fecha) {
    if (fecha == null) return 'Sin programar';

    final d = fecha.day.toString().padLeft(2, '0');
    final m = fecha.month.toString().padLeft(2, '0');
    final y = fecha.year;
    final h = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');

    return '$d/$m/$y $h:$min';
  }

  String _modoTexto(PartidoModel partido) {
    return partido.generadoPorSistema ? 'Aleatorio' : 'Manual';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<CampeonatoModel?>(
        stream: _campeonatoService.streamCampeonato(widget.campeonatoId),
        builder: (context, campeonatoSnapshot) {
          final campeonato = campeonatoSnapshot.data;

          return StreamBuilder<List<PartidoModel>>(
            stream: _partidoService.streamPartidos(widget.campeonatoId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AppLoading(message: 'Cargando fixture...');
              }

              if (snapshot.hasError) {
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Error al cargar fixture',
                  message: snapshot.error.toString(),
                );
              }

              final partidos = snapshot.data ?? [];

              final puedeEditarFixture =
                  campeonato != null &&
                  campeonato.estado != CampeonatoEstado.finalizado;

              return SingleChildScrollView(
                child: AppPage(
                  title: 'Fixture',
                  subtitle: campeonato == null
                      ? 'Cruces y programación de partidos.'
                      : campeonato.nombre,
                  actions: [
                    AppButton.secondary(
                      text: 'Volver',
                      icon: Icons.arrow_back,
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (puedeEditarFixture && partidos.isEmpty)
                      AppButton.primary(
                        text: 'Modo aleatorio',
                        icon: Icons.shuffle,
                        loading: _loading,
                        onPressed: _generarFixture,
                      ),
                    if (puedeEditarFixture)
                      AppButton.secondary(
                        text: 'Agregar cruce manual',
                        icon: Icons.add,
                        loading: _loading,
                        onPressed: _crearCruceManual,
                      ),
                    if (partidos.isNotEmpty && campeonato != null)
                      AppButton.secondary(
                        text: 'Descargar PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: () => _descargarFixture(
                          campeonato,
                          partidos,
                        ),
                      ),
                  ],
                  child: partidos.isEmpty
                      ? AppEmptyState(
                          icon: Icons.calendar_month_outlined,
                          title: 'No hay fixture generado',
                          message:
                              'Puedes generar el fixture completo en modo aleatorio o agregar cruces manuales uno por uno.',
                          buttonText:
                              puedeEditarFixture ? 'Agregar cruce manual' : null,
                          onPressed:
                              puedeEditarFixture ? _crearCruceManual : null,
                        )
                      : Column(
                          children: partidos.map((partido) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              AppBadge(
                                                text: partido.estado,
                                                type: AppBadge.typeFromEstado(
                                                  partido.estado,
                                                ),
                                              ),
                                              AppBadge(
                                                text: _modoTexto(partido),
                                                type: partido.generadoPorSistema
                                                    ? AppBadgeType.info
                                                    : AppBadgeType.primary,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            '${partido.equipoLocalNombre} vs ${partido.equipoVisitanteNombre}',
                                            style: AppTextStyles.heading3,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Vuelta ${partido.vuelta} · Jornada ${partido.jornada}',
                                            style: AppTextStyles.small,
                                          ),
                                          Text(
                                            _fechaTexto(partido.fechaHora),
                                            style: AppTextStyles.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    AppButton.secondary(
                                      text: partido.fechaHora == null
                                          ? 'Programar'
                                          : 'Reprogramar',
                                      icon: Icons.edit_calendar_outlined,
                                      onPressed: campeonato?.estado ==
                                              CampeonatoEstado.finalizado
                                          ? null
                                          : () => _programarPartido(partido),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CruceManualDialog extends StatefulWidget {
  final List<EquipoModel> equipos;

  const _CruceManualDialog({
    required this.equipos,
  });

  @override
  State<_CruceManualDialog> createState() => _CruceManualDialogState();
}

class _CruceManualDialogState extends State<_CruceManualDialog> {
  EquipoModel? _local;
  EquipoModel? _visitante;
  bool _idaYVuelta = false;

  final TextEditingController _jornadaController =
      TextEditingController(text: '1');

  @override
  void dispose() {
    _jornadaController.dispose();
    super.dispose();
  }

  void _guardar() {
    final jornada = int.tryParse(_jornadaController.text.trim()) ?? 0;

    if (_local == null || _visitante == null) return;
    if (_local!.id == _visitante!.id) return;
    if (jornada <= 0) return;

    Navigator.pop(
      context,
      _CruceManualResult(
        local: _local!,
        visitante: _visitante!,
        jornada: jornada,
        idaYVuelta: _idaYVuelta,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visitantes = widget.equipos.where((equipo) {
      return equipo.id != _local?.id;
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text(
        'Agregar cruce manual',
        style: AppTextStyles.heading3,
      ),
      content: SizedBox(
        width: 470,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _EquipoDropdown(
              label: 'Equipo local',
              value: _local,
              equipos: widget.equipos,
              onChanged: (value) {
                setState(() {
                  _local = value;

                  if (_visitante?.id == value?.id) {
                    _visitante = null;
                  }
                });
              },
            ),
            const SizedBox(height: 14),
            _EquipoDropdown(
              label: 'Equipo visitante',
              value: _visitante,
              equipos: visitantes,
              onChanged: (value) {
                setState(() {
                  _visitante = value;
                });
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _jornadaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jornada / fase',
                hintText: 'Ejemplo: 1, 2, 3...',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: _idaYVuelta,
              onChanged: (value) {
                setState(() {
                  _idaYVuelta = value;
                });
              },
              title: const Text('Crear ida y vuelta'),
              subtitle: const Text(
                'Desactívalo para semifinales, finales o partido único.',
              ),
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _idaYVuelta
                    ? 'Se crearán dos partidos: ida y vuelta con localía invertida.'
                    : 'Se creará un solo partido. Útil para semifinales, finales o partidos especiales.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton.ghost(
          text: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        AppButton.primary(
          text: 'Crear cruce',
          icon: Icons.add,
          onPressed:
              _local == null || _visitante == null || _local?.id == _visitante?.id
                  ? null
                  : _guardar,
        ),
      ],
    );
  }
}

class _EquipoDropdown extends StatelessWidget {
  final String label;
  final EquipoModel? value;
  final List<EquipoModel> equipos;
  final void Function(EquipoModel?) onChanged;

  const _EquipoDropdown({
    required this.label,
    required this.value,
    required this.equipos,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<EquipoModel>(
      value: value,
      isExpanded: true,
      items: equipos.map((equipo) {
        return DropdownMenuItem(
          value: equipo,
          child: Text(equipo.nombre),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.groups_2_outlined),
      ),
    );
  }
}

class _CruceManualResult {
  final EquipoModel local;
  final EquipoModel visitante;
  final int jornada;
  final bool idaYVuelta;

  const _CruceManualResult({
    required this.local,
    required this.visitante,
    required this.jornada,
    required this.idaYVuelta,
  });
}