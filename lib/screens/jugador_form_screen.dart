import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/jugador_model.dart';
import '../services/auth_service.dart';
import '../services/campeonato_service.dart';
import '../services/equipo_service.dart';
import '../services/jugador_service.dart';
import 'reciclaje/app_badge.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_loading.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';

class JugadorFormScreen extends StatefulWidget {
  final String campeonatoId;
  final JugadorModel? jugador;

  const JugadorFormScreen({
    super.key,
    required this.campeonatoId,
    this.jugador,
  });

  bool get isEditing => jugador != null;

  @override
  State<JugadorFormScreen> createState() => _JugadorFormScreenState();
}

class _JugadorFormScreenState extends State<JugadorFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _campeonatoService = CampeonatoService();
  final _equipoService = EquipoService();
  final _jugadorService = JugadorService();

  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _observacionController = TextEditingController();

  final List<_JugadorFilaController> _filas = [];

  String? _equipoId;
  String _estado = JugadorEstado.activo;
  bool _loading = false;

  int _cuposDisponibles = 0;
  List<String> _erroresTabla = [];

  late Future<_JugadorFormData> _dataFuture;

  @override
  void initState() {
    super.initState();

    final jugador = widget.jugador;

    if (jugador != null) {
      _codigoController.text = jugador.codigoEstudiante;
      _nombreController.text = jugador.nombreCompleto;
      _equipoId = jugador.equipoId;
      _estado = jugador.estado;
    }

    _dataFuture = _loadData();
  }

  Future<_JugadorFormData> _loadData() async {
    final campeonato =
        await _campeonatoService.getCampeonato(widget.campeonatoId);
    final equipos = await _equipoService.getEquipos(widget.campeonatoId);

    return _JugadorFormData(
      campeonato: campeonato,
      equipos: equipos,
    );
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _observacionController.dispose();

    for (final fila in _filas) {
      fila.dispose();
    }

    super.dispose();
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String _normalizarCodigo(String codigo) {
    return codigo.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
  }

  String _docIdFromCodigo(String codigo) {
    return _normalizarCodigo(codigo).replaceAll(RegExp(r'[^A-Z0-9_-]'), '_');
  }

  String _limpiarNombre(String nombre) {
    return nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .map((palabra) {
      final limpia = palabra.trim();
      if (limpia.isEmpty) return limpia;
      return limpia[0].toUpperCase() + limpia.substring(1);
    }).join(' ');
  }

  void _generarFilasSegunEquipo({
    required _JugadorFormData data,
    required String equipoId,
  }) {
    final equipo = data.equipos.firstWhere((item) => item.id == equipoId);

    final maxJugadores =
        data.campeonato?.configuracion.cantidadMaximaJugadoresPorEquipo ?? 0;

    final disponibles = maxJugadores - equipo.cantidadJugadoresRegistrados;

    for (final fila in _filas) {
      fila.dispose();
    }

    _filas.clear();

    final cantidadFilas = disponibles <= 0 ? 0 : disponibles;

    for (int i = 0; i < cantidadFilas; i++) {
      _filas.add(_JugadorFilaController());
    }

    setState(() {
      _equipoId = equipoId;
      _cuposDisponibles = disponibles;
      _erroresTabla.clear();
    });
  }

  int _cantidadFilasConDatos() {
    return _filas.where((fila) {
      return fila.codigo.text.trim().isNotEmpty ||
          fila.nombre.text.trim().isNotEmpty;
    }).length;
  }

  void _limpiarFormularioMasivo() {
    setState(() {
      for (final fila in _filas) {
        fila.codigo.clear();
        fila.nombre.clear();
      }

      _erroresTabla.clear();
    });
  }

  _ParseResult _leerTablaJugadores() {
    final jugadores = <_JugadorMasivoInput>[];
    final errores = <String>[];
    final codigosVistos = <String>{};
    final codigosRepetidos = <String>{};

    for (int i = 0; i < _filas.length; i++) {
      final numero = i + 1;
      final fila = _filas[i];

      final codigoRaw = fila.codigo.text.trim();
      final nombreRaw = fila.nombre.text.trim();

      final filaVacia = codigoRaw.isEmpty && nombreRaw.isEmpty;

      if (filaVacia) continue;

      if (codigoRaw.isEmpty && nombreRaw.isNotEmpty) {
        errores.add('Fila $numero: falta el número de registro.');
        continue;
      }

      if (codigoRaw.isNotEmpty && nombreRaw.isEmpty) {
        errores.add('Fila $numero: falta el nombre completo.');
        continue;
      }

      final codigo = _normalizarCodigo(codigoRaw);
      final nombre = _limpiarNombre(nombreRaw);

      if (!RegExp(r'^[0-9]+$').hasMatch(codigo)) {
        errores.add(
          'Fila $numero: el número de registro "$codigo" debe tener solo números.',
        );
        continue;
      }

      if (codigo.length < 5) {
        errores.add(
          'Fila $numero: el número de registro "$codigo" parece demasiado corto.',
        );
        continue;
      }

      if (nombre.length < 5 || !nombre.contains(' ')) {
        errores.add(
          'Fila $numero: escribe nombre y apellido para "$nombre".',
        );
        continue;
      }

      if (RegExp(r'[0-9]').hasMatch(nombre)) {
        errores.add(
          'Fila $numero: el nombre "$nombre" no debería contener números.',
        );
        continue;
      }

      if (codigosVistos.contains(codigo)) {
        codigosRepetidos.add(codigo);
        continue;
      }

      codigosVistos.add(codigo);

      jugadores.add(
        _JugadorMasivoInput(
          codigoEstudiante: codigo,
          nombreCompleto: nombre,
        ),
      );
    }

    if (jugadores.isEmpty && errores.isEmpty) {
      errores.add('Debes ingresar al menos un jugador.');
    }

    if (codigosRepetidos.isNotEmpty) {
      errores.add(
        'Hay números de registro repetidos: ${codigosRepetidos.join(', ')}.',
      );
    }

    return _ParseResult(
      jugadores: jugadores,
      errores: errores,
    );
  }

  Future<List<String>> _buscarCodigosExistentes(
    List<_JugadorMasivoInput> jugadores,
  ) async {
    final existentes = <String>[];

    for (final jugador in jugadores) {
      final docId = _docIdFromCodigo(jugador.codigoEstudiante);

      final doc = await FirebaseFirestore.instance
          .collection('campeonatos')
          .doc(widget.campeonatoId)
          .collection('jugadores')
          .doc(docId)
          .get();

      if (doc.exists) {
        existentes.add(jugador.codigoEstudiante);
      }
    }

    return existentes;
  }

  Future<void> _guardar(_JugadorFormData data) async {
    if (!_formKey.currentState!.validate()) return;

    if (_equipoId == null || _equipoId!.isEmpty) {
      AppSnackbars.error(context, 'Selecciona un equipo.');
      return;
    }

    final equipo = data.equipos.firstWhere(
      (item) => item.id == _equipoId,
    );

    setState(() {
      _loading = true;
      _erroresTabla.clear();
    });

    try {
      final admin = await _authService.requireAdmin();

      if (widget.isEditing) {
        await _jugadorService.editarJugador(
          campeonatoId: widget.campeonatoId,
          jugadorId: widget.jugador!.id,
          cambios: {
            'codigoEstudiante': _codigoController.text.trim(),
            'nombreCompleto': _nombreController.text.trim(),
            'estado': _estado,
          },
          observacion: _observacionController.text.trim(),
          usuarioId: admin.id,
          usuarioNombre: admin.nombre,
        );

        if (!mounted) return;

        AppSnackbars.success(context, 'Jugador actualizado correctamente.');
      } else {
        final parseResult = _leerTablaJugadores();

        if (parseResult.errores.isNotEmpty) {
          setState(() {
            _erroresTabla = parseResult.errores;
          });

          throw Exception('Corrige los errores antes de guardar.');
        }

        final jugadoresMasivos = parseResult.jugadores;

        final maxJugadores =
            data.campeonato?.configuracion.cantidadMaximaJugadoresPorEquipo;

        if (maxJugadores != null &&
            equipo.cantidadJugadoresRegistrados + jugadoresMasivos.length >
                maxJugadores) {
          throw Exception(
            'El equipo ${equipo.nombre} superaría el máximo de $maxJugadores jugadores.',
          );
        }

        final codigosExistentes = await _buscarCodigosExistentes(
          jugadoresMasivos,
        );

        if (codigosExistentes.isNotEmpty) {
          throw Exception(
            'Estos números de registro ya existen en el campeonato: ${codigosExistentes.join(', ')}.',
          );
        }

        for (final jugador in jugadoresMasivos) {
          await _jugadorService.crearJugador(
            campeonatoId: widget.campeonatoId,
            equipoId: equipo.id,
            equipoNombre: equipo.nombre,
            codigoEstudiante: jugador.codigoEstudiante,
            nombreCompleto: jugador.nombreCompleto,
            usuarioId: admin.id,
            usuarioNombre: admin.nombre,
            observacion: _observacionController.text.trim().isEmpty
                ? null
                : _observacionController.text.trim(),
          );
        }

        if (!mounted) return;

        AppSnackbars.success(
          context,
          '${jugadoresMasivos.length} jugadores registrados correctamente.',
        );
      }

      if (!mounted) return;
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

  bool _requiresObservation(CampeonatoModel? campeonato) {
    if (widget.isEditing) return true;
    return campeonato?.estado == CampeonatoEstado.activo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_JugadorFormData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Cargando formulario...');
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final data = snapshot.data!;
          final observationRequired = _requiresObservation(data.campeonato);

          return SingleChildScrollView(
            child: AppPage(
              title: widget.isEditing ? 'Editar jugador' : 'Registrar jugadores',
              subtitle: widget.isEditing
                  ? 'Toda edición de jugador requiere observación obligatoria.'
                  : 'Selecciona un equipo y llena todos los jugadores disponibles de una sola vez.',
              actions: [
                AppButton.secondary(
                  text: 'Cancelar',
                  icon: Icons.close,
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
                AppButton.primary(
                  text: widget.isEditing ? 'Actualizar' : 'Guardar jugadores',
                  icon: Icons.save_outlined,
                  loading: _loading,
                  onPressed: () => _guardar(data),
                ),
              ],
              child: AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _DropdownField<String>(
                        label: 'Equipo',
                        value: _equipoId,
                        enabled: !widget.isEditing,
                        items: data.equipos.map((equipo) {
                          return DropdownMenuItem(
                            value: equipo.id,
                            child: Text(
                              '${equipo.nombre} (${equipo.cantidadJugadoresRegistrados} registrados)',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;

                          _generarFilasSegunEquipo(
                            data: data,
                            equipoId: value,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (widget.isEditing) ...[
                        AppTextField(
                          label: 'Número de registro',
                          hint: 'Ejemplo: 2023112770',
                          controller: _codigoController,
                          prefixIcon: Icons.badge_outlined,
                          validator: (value) {
                            return _required(
                              value,
                              'El número de registro es obligatorio.',
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Nombre completo',
                          hint: 'Ejemplo: Mateo Encinas',
                          controller: _nombreController,
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            return _required(
                              value,
                              'El nombre completo es obligatorio.',
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _DropdownField<String>(
                          label: 'Estado',
                          value: _estado,
                          items: const [
                            DropdownMenuItem(
                              value: JugadorEstado.activo,
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: JugadorEstado.suspendido,
                              child: Text('Suspendido'),
                            ),
                            DropdownMenuItem(
                              value: JugadorEstado.retirado,
                              child: Text('Retirado'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;

                            setState(() {
                              _estado = value;
                            });
                          },
                        ),
                      ] else ...[
                        _JugadoresMasivosForm(
                          filas: _filas,
                          cuposDisponibles: _cuposDisponibles,
                          cantidadConDatos: _cantidadFilasConDatos(),
                          errores: _erroresTabla,
                          onChanged: () {
                            if (_erroresTabla.isNotEmpty) {
                              setState(() {
                                _erroresTabla.clear();
                              });
                            } else {
                              setState(() {});
                            }
                          },
                          onClear: _limpiarFormularioMasivo,
                        ),
                      ],
                      if (observationRequired) ...[
                        const SizedBox(height: 16),
                        AppTextField(
                          label: 'Observación obligatoria',
                          hint:
                              'Ejemplo: corrección por error de registro o carga de planilla con campeonato activo.',
                          controller: _observacionController,
                          maxLines: 4,
                          prefixIcon: Icons.notes_outlined,
                          validator: (value) {
                            return _required(
                              value,
                              'La observación es obligatoria.',
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'El número de registro debe ser único dentro del campeonato. Puedes llenar todas las casillas disponibles o dejar vacías las que no uses.',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

class _JugadoresMasivosForm extends StatelessWidget {
  final List<_JugadorFilaController> filas;
  final int cuposDisponibles;
  final int cantidadConDatos;
  final List<String> errores;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _JugadoresMasivosForm({
    required this.filas,
    required this.cuposDisponibles,
    required this.cantidadConDatos,
    required this.errores,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    if (filas.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.dangerLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.danger),
        ),
        child: Text(
          cuposDisponibles <= 0
              ? 'Este equipo ya alcanzó el máximo de jugadores permitidos.'
              : 'Selecciona un equipo para generar los campos de registro.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.danger,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Jugadores disponibles para registrar',
                style: AppTextStyles.heading3,
              ),
            ),
            AppBadge(
              text: '$cantidadConDatos / ${filas.length}',
              type: cantidadConDatos > 0
                  ? AppBadgeType.success
                  : AppBadgeType.neutral,
              icon: Icons.groups_2_outlined,
            ),
            const SizedBox(width: 10),
            AppButton.ghost(
              text: 'Limpiar',
              icon: Icons.cleaning_services_outlined,
              onPressed: onClear,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          children: List.generate(filas.length, (index) {
            final fila = filas[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _JugadorRegistroRow(
                index: index,
                fila: fila,
                onChanged: onChanged,
              ),
            );
          }),
        ),
        if (errores.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.danger),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: errores.map((error) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '• $error',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _JugadorRegistroRow extends StatelessWidget {
  final int index;
  final _JugadorFilaController fila;
  final VoidCallback onChanged;

  const _JugadorRegistroRow({
    required this.index,
    required this.fila,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${index + 1}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: fila.codigo,
            keyboardType: TextInputType.number,
            onChanged: (_) => onChanged(),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              labelText: 'Número de registro',
              hintText: '2023112770',
              prefixIcon: const Icon(Icons.badge_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: fila.nombre,
            keyboardType: TextInputType.text,
            onChanged: (_) => onChanged(),
            style: AppTextStyles.body,
            decoration: InputDecoration(
              labelText: 'Nombre completo',
              hintText: 'Mateo Encinas Delgadillo',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _JugadorFormData {
  final CampeonatoModel? campeonato;
  final List<EquipoModel> equipos;

  const _JugadorFormData({
    required this.campeonato,
    required this.equipos,
  });
}

class _JugadorFilaController {
  final TextEditingController codigo = TextEditingController();
  final TextEditingController nombre = TextEditingController();

  void dispose() {
    codigo.dispose();
    nombre.dispose();
  }
}

class _JugadorMasivoInput {
  final String codigoEstudiante;
  final String nombreCompleto;

  const _JugadorMasivoInput({
    required this.codigoEstudiante,
    required this.nombreCompleto,
  });
}

class _ParseResult {
  final List<_JugadorMasivoInput> jugadores;
  final List<String> errores;

  const _ParseResult({
    required this.jugadores,
    required this.errores,
  });
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final bool enabled;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label),
        const SizedBox(height: 7),
        DropdownButtonFormField<T>(
          initialValue: value,
          items: items,
          onChanged: enabled ? onChanged : null,
          decoration: const InputDecoration(),
          style: AppTextStyles.body,
          dropdownColor: AppColors.surface,
          validator: (value) {
            if (value == null) return 'Selecciona una opción.';
            return null;
          },
        ),
      ],
    );
  }
}