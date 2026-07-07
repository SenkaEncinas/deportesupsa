import 'package:flutter/material.dart';

import '../models/jugador_model.dart';
import '../models/partido_model.dart';
import '../services/auth_service.dart';
import '../services/jugador_service.dart';
import '../services/resultado_service.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';

class ResultadoFormScreen extends StatefulWidget {
  final String campeonatoId;
  final PartidoModel partido;

  const ResultadoFormScreen({
    super.key,
    required this.campeonatoId,
    required this.partido,
  });

  @override
  State<ResultadoFormScreen> createState() => _ResultadoFormScreenState();
}

class _ResultadoFormScreenState extends State<ResultadoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _jugadorService = JugadorService();
  final _resultadoService = ResultadoService();

  final _golesLocalController = TextEditingController();
  final _golesVisitanteController = TextEditingController();
  final _observacionController = TextEditingController();

  String _tipoResultado = TipoResultado.normal;
  bool _loading = false;

  late Future<List<JugadorModel>> _jugadoresFuture;

  final List<_GolInputState> _goles = [];
  final List<_TarjetaInputState> _tarjetas = [];

  @override
  void initState() {
    super.initState();

    _golesLocalController.text = widget.partido.golesLocal?.toString() ?? '';
    _golesVisitanteController.text =
        widget.partido.golesVisitante?.toString() ?? '';
    _tipoResultado = widget.partido.tipoResultado;
    _observacionController.text = widget.partido.observacionResultado ?? '';

    _jugadoresFuture = _loadJugadores();
  }

  Future<List<JugadorModel>> _loadJugadores() async {
    final local = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: widget.partido.equipoLocalId,
    );

    final visitante = await _jugadorService.getJugadoresPorEquipo(
      campeonatoId: widget.campeonatoId,
      equipoId: widget.partido.equipoVisitanteId,
    );

    return [...local, ...visitante]
        .where((jugador) => jugador.estado == JugadorEstado.activo)
        .toList();
  }

  @override
  void dispose() {
    _golesLocalController.dispose();
    _golesVisitanteController.dispose();
    _observacionController.dispose();

    for (final tarjeta in _tarjetas) {
      tarjeta.dispose();
    }

    super.dispose();
  }

  void _addGol() {
    setState(() {
      _goles.add(_GolInputState());
    });
  }

  void _removeGol(int index) {
    setState(() {
      _goles.removeAt(index);
    });
  }

  void _addTarjeta() {
    setState(() {
      _tarjetas.add(_TarjetaInputState());
    });
  }

  void _removeTarjeta(int index) {
    setState(() {
      final item = _tarjetas.removeAt(index);
      item.dispose();
    });
  }

  int _parseInt(String value) {
    return int.tryParse(value.trim()) ?? 0;
  }

  Future<void> _guardar(List<JugadorModel> jugadores) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final admin = await _authService.requireAdmin();

      final golesInputs = <GolJugadorInput>[];
      final tarjetasInputs = <TarjetaJugadorInput>[];

      if (_tipoResultado == TipoResultado.normal) {
        for (final item in _goles) {
          if (item.jugadorId == null || item.jugadorId!.isEmpty) continue;

          final jugador = jugadores.firstWhere(
            (j) => j.id == item.jugadorId,
          );

          golesInputs.add(
            GolJugadorInput(
              equipoId: jugador.equipoId,
              equipoNombre: jugador.equipoNombre,
              jugadorId: jugador.id,
              jugadorNombre: jugador.nombreCompleto,
              cantidad: item.cantidad,
            ),
          );
        }

        for (final item in _tarjetas) {
          final amarillas = item.amarillas;
          final rojas = item.rojas;

          if (item.jugadorId == null || item.jugadorId!.isEmpty) {
            if (amarillas > 0 || rojas > 0) {
              throw Exception(
                'Selecciona un jugador en todos los registros de tarjetas.',
              );
            }
            continue;
          }

          if (amarillas == 0 && rojas == 0) {
            continue;
          }

          final jugador = jugadores.firstWhere(
            (j) => j.id == item.jugadorId,
          );

          tarjetasInputs.add(
            TarjetaJugadorInput(
              equipoId: jugador.equipoId,
              equipoNombre: jugador.equipoNombre,
              jugadorId: jugador.id,
              jugadorNombre: jugador.nombreCompleto,
              amarillas: amarillas,
              rojas: rojas,
              motivo: item.motivoController.text.trim().isEmpty
                  ? null
                  : item.motivoController.text.trim(),
            ),
          );
        }
      }

      await _resultadoService.registrarResultado(
        campeonatoId: widget.campeonatoId,
        partidoId: widget.partido.id,
        golesLocal: _parseInt(_golesLocalController.text),
        golesVisitante: _parseInt(_golesVisitanteController.text),
        golesJugadores: golesInputs,
        tarjetasJugadores: tarjetasInputs,
        tipoResultado: _tipoResultado,
        observacionResultado: _observacionController.text.trim().isEmpty
            ? null
            : _observacionController.text.trim(),
        usuarioId: admin.id,
      );

      if (!mounted) return;

      AppSnackbars.success(context, 'Resultado registrado correctamente.');
      Navigator.pop(context);
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

  String? _requiredNumber(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number < 0) return 'Valor inválido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<JugadorModel>>(
        future: _jugadoresFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando jugadores...');
          }

          final jugadores = snapshot.data ?? [];

          return SingleChildScrollView(
            child: AppPage(
              title: 'Registrar resultado',
              subtitle:
                  '${widget.partido.equipoLocalNombre} vs ${widget.partido.equipoVisitanteNombre}',
              actions: [
                AppButton.secondary(
                  text: 'Cancelar',
                  icon: Icons.close,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
                AppButton.primary(
                  text: 'Guardar resultado',
                  icon: Icons.save_outlined,
                  loading: _loading,
                  onPressed: () => _guardar(jugadores),
                ),
              ],
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              label: widget.partido.equipoLocalNombre,
                              hint: 'Goles local',
                              controller: _golesLocalController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.sports_soccer,
                              validator: _requiredNumber,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: AppTextField(
                              label: widget.partido.equipoVisitanteNombre,
                              hint: 'Goles visitante',
                              controller: _golesVisitanteController,
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.sports_soccer,
                              validator: _requiredNumber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _DropdownField<String>(
                        label: 'Tipo de resultado',
                        value: _tipoResultado,
                        items: const [
                          DropdownMenuItem(
                            value: TipoResultado.normal,
                            child: Text('Normal'),
                          ),
                          DropdownMenuItem(
                            value: TipoResultado.walkover,
                            child: Text('Walkover'),
                          ),
                          DropdownMenuItem(
                            value: TipoResultado.sancion,
                            child: Text('Sanción'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _tipoResultado = value;
                            if (_tipoResultado != TipoResultado.normal) {
                              _goles.clear();

                              for (final tarjeta in _tarjetas) {
                                tarjeta.dispose();
                              }

                              _tarjetas.clear();
                            }
                          });
                        },
                      ),
                      if (_tipoResultado != TipoResultado.normal) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Observación obligatoria',
                          hint:
                              'Ejemplo: resultado administrativo por ausencia del equipo.',
                          controller: _observacionController,
                          maxLines: 4,
                          prefixIcon: Icons.notes_outlined,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'La observación es obligatoria.';
                            }
                            return null;
                          },
                        ),
                      ],
                      if (_tipoResultado == TipoResultado.normal) ...[
                        const SizedBox(height: 22),
                        _GolesSection(
                          goles: _goles,
                          jugadores: jugadores,
                          onAdd: _addGol,
                          onRemove: _removeGol,
                          onRefresh: () => setState(() {}),
                        ),
                        const SizedBox(height: 24),
                        _TarjetasSection(
                          tarjetas: _tarjetas,
                          jugadores: jugadores,
                          onAdd: _addTarjeta,
                          onRemove: _removeTarjeta,
                          onRefresh: () => setState(() {}),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GolesSection extends StatelessWidget {
  final List<_GolInputState> goles;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _GolesSection({
    required this.goles,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Goles por jugador',
                style: AppTextStyles.heading3,
              ),
            ),
            AppButton.secondary(
              text: 'Agregar gol',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (goles.isEmpty)
          _InfoBox(
            text:
                'Agrega los goles por jugador. La suma debe coincidir con el resultado final.',
          )
        else
          Column(
            children: List.generate(goles.length, (index) {
              final item = goles[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _DropdownField<String>(
                        label: 'Jugador',
                        value: item.jugadorId,
                        items: jugadores.map((jugador) {
                          return DropdownMenuItem(
                            value: jugador.id,
                            child: Text(
                              '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          item.jugadorId = value;
                          onRefresh();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SmallNumberField(
                        label: 'Goles',
                        value: item.cantidad,
                        onChanged: (value) {
                          item.cantidad = value;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _TarjetasSection extends StatelessWidget {
  final List<_TarjetaInputState> tarjetas;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _TarjetasSection({
    required this.tarjetas,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tarjetas por jugador',
                style: AppTextStyles.heading3,
              ),
            ),
            AppButton.secondary(
              text: 'Agregar tarjeta',
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (tarjetas.isEmpty)
          _InfoBox(
            text:
                'Aquí puedes registrar amarillas y rojas por jugador. Si no hubo tarjetas, deja esta sección vacía.',
          )
        else
          Column(
            children: List.generate(tarjetas.length, (index) {
              final item = tarjetas[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: _DropdownField<String>(
                            label: 'Jugador',
                            value: item.jugadorId,
                            items: jugadores.map((jugador) {
                              return DropdownMenuItem(
                                value: jugador.id,
                                child: Text(
                                  '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              item.jugadorId = value;
                              onRefresh();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallNumberField(
                            label: 'Amarillas',
                            value: item.amarillas,
                            onChanged: (value) {
                              item.amarillas = value;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SmallNumberField(
                            label: 'Rojas',
                            value: item.rojas,
                            onChanged: (value) {
                              item.rojas = value;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => onRemove(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: item.motivoController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Motivo / detalle opcional',
                        hintText: 'Ejemplo: doble amarilla, conducta antideportiva...',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GolInputState {
  String? jugadorId;
  int cantidad = 1;
}

class _TarjetaInputState {
  String? jugadorId;
  int amarillas = 1;
  int rojas = 0;
  final TextEditingController motivoController = TextEditingController();

  void dispose() {
    motivoController.dispose();
  }
}

class _SmallNumberField extends StatelessWidget {
  final String label;
  final int value;
  final void Function(int) onChanged;

  const _SmallNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(),
          onChanged: (value) {
            final parsed = int.tryParse(value) ?? 0;
            onChanged(parsed < 0 ? 0 : parsed);
          },
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
          style: AppTextStyles.body,
          dropdownColor: AppColors.surface,
        ),
      ],
    );
  }
}