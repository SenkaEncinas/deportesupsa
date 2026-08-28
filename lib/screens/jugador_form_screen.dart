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
import 'reciclaje/app_dialogs.dart';
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
    final campeonato = await _campeonatoService.getCampeonato(
      widget.campeonatoId,
    );
    final equipos = await _equipoService.getEquipos(widget.campeonatoId);

    return _JugadorFormData(campeonato: campeonato, equipos: equipos);
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
        })
        .join(' ');
  }

  /// Genera las filas del formulario masivo para el equipo elegido. Si
  /// el campeonato todavía no arrancó (estado "inscripción"), además
  /// precarga a los jugadores que ya tiene el equipo para poder
  /// corregirlos ahí mismo (por ejemplo, si un ayudante cargó la lista
  /// equivocada en el equipo equivocado) sin pasar por "Editar jugador"
  /// uno por uno. Una vez que el campeonato está activo, se vuelve al
  /// comportamiento de siempre: solo cupos vacíos para sumar jugadores.
  Future<void> _generarFilasSegunEquipo({
    required _JugadorFormData data,
    required String equipoId,
  }) async {
    final equipo = data.equipos.firstWhere((item) => item.id == equipoId);

    final maxJugadores =
        data.campeonato?.configuracion.cantidadMaximaJugadoresPorEquipo ?? 0;

    final puedeEditarExistentes =
        data.campeonato?.estado == CampeonatoEstado.inscripcion;

    final existentes = puedeEditarExistentes
        ? await _jugadorService.getJugadoresPorEquipo(
            campeonatoId: widget.campeonatoId,
            equipoId: equipoId,
          )
        : const <JugadorModel>[];

    if (!mounted) return;

    for (final fila in _filas) {
      fila.dispose();
    }

    _filas.clear();

    final disponibles = maxJugadores - equipo.cantidadJugadoresRegistrados;

    // Con existentes: se muestran todos los cupos (los que ya tienen
    // jugador, editables, más los vacíos) hasta el máximo del equipo.
    // Sin existentes (campeonato ya activo): solo los cupos vacíos,
    // como antes.
    final cantidadFilas = puedeEditarExistentes
        ? (maxJugadores > existentes.length ? maxJugadores : existentes.length)
        : (disponibles <= 0 ? 0 : disponibles);

    for (int i = 0; i < cantidadFilas; i++) {
      final jugador = i < existentes.length ? existentes[i] : null;
      final fila = _JugadorFilaController(jugadorOriginal: jugador);

      if (jugador != null) {
        fila.codigo.text = jugador.codigoEstudiante;
        fila.nombre.text = jugador.nombreCompleto;
      }

      _filas.add(fila);
    }

    setState(() {
      _equipoId = equipoId;
      _cuposDisponibles = disponibles;
      _erroresTabla.clear();
    });
  }

  /// Borra para siempre al jugador de esta fila (no solo la vacía): a
  /// diferencia de vaciar los campos a mano, esto sí elimina el
  /// documento real en Firestore, usando el id que ya trajo la consulta
  /// (no uno adivinado a partir del código), así que funciona sin
  /// importar cómo se haya creado el jugador originalmente.
  Future<void> _eliminarFila(_JugadorFilaController fila) async {
    final jugador = fila.jugadorOriginal;
    if (jugador == null) return;

    final confirmado = await AppDialogs.confirm(
      context: context,
      title: 'Eliminar jugador',
      message:
          '¿Eliminar a "${jugador.nombreCompleto}" (${jugador.codigoEstudiante}) '
          'de este equipo? Esta acción no se puede deshacer.',
      confirmText: 'Eliminar',
      danger: true,
    );

    if (!confirmado || !mounted) return;

    try {
      await _jugadorService.eliminarJugador(
        campeonatoId: widget.campeonatoId,
        jugadorId: jugador.id,
      );

      if (!mounted) return;

      final index = _filas.indexOf(fila);

      setState(() {
        if (index != -1) {
          fila.dispose();
          _filas[index] = _JugadorFilaController();
        }
        _cuposDisponibles += 1;
        _erroresTabla.clear();
      });

      AppSnackbars.success(context, 'Jugador eliminado correctamente.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbars.error(context, e.toString());
    }
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

  Future<void> _abrirDialogoPegado() async {
    final texto = await showDialog<String>(
      context: context,
      builder: (_) => const _PegadoExcelDialog(),
    );

    if (texto == null || texto.trim().isEmpty) return;

    _aplicarPegado(texto);
  }

  /// Interpreta el bloque de texto pegado directamente desde Excel (una
  /// fila por jugador, columnas separadas por tabulador) y rellena las
  /// casillas ya generadas para el equipo, en orden. No valida nada acá:
  /// solo intenta adivinar qué celda es el número de registro y cuáles
  /// son el nombre, dejando la validación real (única, obligatoria, solo
  /// números...) al flujo normal de "Guardar jugadores".
  void _aplicarPegado(String texto) {
    final lineas = texto
        .split(RegExp(r'\r?\n'))
        .map((linea) => linea.trim())
        .where((linea) => linea.isNotEmpty)
        .toList();

    if (lineas.isEmpty) return;

    final disponibles = _filas.length;
    final aUsar = lineas.length > disponibles ? disponibles : lineas.length;

    setState(() {
      for (int i = 0; i < aUsar; i++) {
        final fila = _extraerFilaPegado(lineas[i]);
        _filas[i].codigo.text = fila.codigo;
        _filas[i].nombre.text = fila.nombre;
      }

      _erroresTabla.clear();
    });

    if (!mounted) return;

    if (lineas.length > disponibles) {
      AppSnackbars.error(
        context,
        'El pegado trae ${lineas.length} filas pero solo hay $disponibles cupos disponibles: se llenaron las primeras $disponibles.',
      );
    } else {
      AppSnackbars.success(
        context,
        'Se rellenaron $aUsar jugadores desde el pegado. Revisa la lista antes de guardar.',
      );
    }
  }

  /// Separa una fila pegada de Excel en (número de registro, nombre
  /// completo) sin asumir un orden fijo de columnas: descarta una celda
  /// corta (1-3 dígitos) que suele ser el correlativo de la planilla,
  /// toma como número de registro la celda numérica más larga (con
  /// posible sufijo de letras, ej. carnet "1234567 SC"), y arma el
  /// nombre completo con el resto de celdas de texto en el orden en que
  /// aparecen (así da igual si el Excel trae primero el nombre o el
  /// apellido en columnas separadas).
  ({String codigo, String nombre}) _extraerFilaPegado(String linea) {
    var celdas = linea
        .split('\t')
        .map((celda) => celda.trim())
        .where((celda) => celda.isNotEmpty)
        .toList();

    if (celdas.length <= 1) {
      celdas = linea
          .trim()
          .split(RegExp(r'\s{2,}'))
          .map((celda) => celda.trim())
          .where((celda) => celda.isNotEmpty)
          .toList();
    }

    String? codigo;
    final partesNombre = <String>[];

    for (final celda in celdas) {
      if (codigo == null &&
          celdas.length > 2 &&
          RegExp(r'^\d{1,3}$').hasMatch(celda)) {
        continue; // correlativo de la planilla, se descarta
      }

      final matchCodigo = RegExp(
        r'^(\d{5,12})\s*([A-Za-z]{0,3})$',
      ).firstMatch(celda);

      if (codigo == null && matchCodigo != null) {
        final numero = matchCodigo.group(1)!;
        final sufijo = matchCodigo.group(2) ?? '';
        codigo = sufijo.isEmpty ? numero : '$numero ${sufijo.toUpperCase()}';
        continue;
      }

      partesNombre.add(celda);
    }

    return (codigo: codigo ?? '', nombre: partesNombre.join(' '));
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
        errores.add('Fila $numero: escribe nombre y apellido para "$nombre".');
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
          jugadorOriginal: fila.jugadorOriginal,
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

    return _ParseResult(jugadores: jugadores, errores: errores);
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

    final equipo = data.equipos.firstWhere((item) => item.id == _equipoId);

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

        // Filas nuevas (cupo vacío que se llenó) vs. filas que ya tenían
        // un jugador y se corrigieron: cada una va a un método distinto
        // del servicio. Las que ya tenían jugador pero no cambiaron
        // nada no generan ninguna escritura.
        final paraCrear = jugadoresMasivos
            .where((jugador) => !jugador.esEdicion)
            .toList();
        final paraEditar = jugadoresMasivos
            .where((jugador) => jugador.esEdicion && jugador.cambio)
            .toList();

        final maxJugadores =
            data.campeonato?.configuracion.cantidadMaximaJugadoresPorEquipo;

        if (maxJugadores != null &&
            equipo.cantidadJugadoresRegistrados + paraCrear.length >
                maxJugadores) {
          throw Exception(
            'El equipo ${equipo.nombre} superaría el máximo de $maxJugadores jugadores.',
          );
        }

        final codigosExistentes = await _buscarCodigosExistentes(paraCrear);

        if (codigosExistentes.isNotEmpty) {
          throw Exception(
            'Estos números de registro ya existen en el campeonato: ${codigosExistentes.join(', ')}.',
          );
        }

        for (final jugador in paraCrear) {
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

        for (final jugador in paraEditar) {
          await _jugadorService.editarJugador(
            campeonatoId: widget.campeonatoId,
            jugadorId: jugador.jugadorOriginal!.id,
            cambios: {
              'codigoEstudiante': jugador.codigoEstudiante,
              'nombreCompleto': jugador.nombreCompleto,
            },
            observacion: _observacionController.text.trim(),
            usuarioId: admin.id,
            usuarioNombre: admin.nombre,
          );
        }

        if (!mounted) return;

        final partes = <String>[];
        if (paraCrear.isNotEmpty) {
          partes.add(
            '${paraCrear.length} ${paraCrear.length == 1 ? 'jugador registrado' : 'jugadores registrados'}',
          );
        }
        if (paraEditar.isNotEmpty) {
          partes.add(
            '${paraEditar.length} ${paraEditar.length == 1 ? 'jugador corregido' : 'jugadores corregidos'}',
          );
        }

        AppSnackbars.success(
          context,
          partes.isEmpty
              ? 'No había cambios que guardar.'
              : '${partes.join(' · ')} correctamente.',
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
              title: widget.isEditing
                  ? 'Editar jugador'
                  : 'Registrar jugadores',
              subtitle: widget.isEditing
                  ? 'Toda edición de jugador requiere observación obligatoria.'
                  : data.campeonato?.estado == CampeonatoEstado.inscripcion
                  ? 'Selecciona un equipo: puedes cargar jugadores nuevos y también corregir los que ya tiene, mientras el campeonato no haya iniciado.'
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
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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

                          _generarFilasSegunEquipo(data: data, equipoId: value);
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
                          onPegar: _abrirDialogoPegado,
                          onEliminar: _eliminarFila,
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
                          !widget.isEditing &&
                                  data.campeonato?.estado ==
                                      CampeonatoEstado.inscripcion
                              ? 'El número de registro debe ser único dentro del campeonato. Las filas con jugadores ya registrados se pueden corregir directamente; si vacías una de esas filas y guardas, ese jugador no se modifica ni se elimina (para eso cambia su estado desde su ficha individual).'
                              : 'El número de registro debe ser único dentro del campeonato. Puedes llenar todas las casillas disponibles o dejar vacías las que no uses.',
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
  final VoidCallback onPegar;
  final void Function(_JugadorFilaController fila)? onEliminar;

  const _JugadoresMasivosForm({
    required this.filas,
    required this.cuposDisponibles,
    required this.cantidadConDatos,
    required this.errores,
    required this.onChanged,
    required this.onClear,
    required this.onPegar,
    this.onEliminar,
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

    final hayExistentes = filas.any((fila) => fila.jugadorOriginal != null);

    return Column(
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text(
              hayExistentes ? 'Jugadores del equipo' : 'Jugadores disponibles para registrar',
              style: AppTextStyles.heading3,
            ),
            AppBadge(
              text: '$cantidadConDatos / ${filas.length}',
              type: cantidadConDatos > 0
                  ? AppBadgeType.success
                  : AppBadgeType.neutral,
              icon: Icons.groups_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Copia y pega la lista completa desde Excel: se rellenan solas todas las casillas de abajo.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AppButton.primary(
                    text: 'Pegar desde Excel',
                    icon: Icons.content_paste_go_rounded,
                    onPressed: onPegar,
                  ),
                  AppButton.ghost(
                    text: 'Limpiar',
                    icon: Icons.cleaning_services_outlined,
                    onPressed: onClear,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Column(
          children: List.generate(filas.length, (index) {
            final fila = filas[index];

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _JugadorRegistroRow(
                index: index,
                fila: fila,
                onChanged: onChanged,
                onEliminar: fila.jugadorOriginal != null && onEliminar != null
                    ? () => onEliminar!(fila)
                    : null,
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
  final VoidCallback? onEliminar;

  const _JugadorRegistroRow({
    required this.index,
    required this.fila,
    required this.onChanged,
    this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final campos = Row(
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

    if (fila.jugadorOriginal == null) return campos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 46),
          child: Row(
            children: [
              Expanded(
                child: AppBadge(
                  text: 'Ya registrado · corrígelo si hace falta',
                  type: AppBadgeType.info,
                  icon: Icons.badge_outlined,
                ),
              ),
              if (onEliminar != null)
                TextButton.icon(
                  onPressed: onEliminar,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Eliminar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
            ],
          ),
        ),
        campos,
      ],
    );
  }
}

/// Diálogo para pegar de una sola vez la lista de jugadores copiada
/// directamente de Excel (una fila por jugador). No valida el contenido
/// acá: solo junta el texto pegado y se lo devuelve al formulario, que
/// lo interpreta y rellena las casillas para que el ayudante revise
/// antes de guardar.
class _PegadoExcelDialog extends StatefulWidget {
  const _PegadoExcelDialog();

  @override
  State<_PegadoExcelDialog> createState() => _PegadoExcelDialogState();
}

class _PegadoExcelDialogState extends State<_PegadoExcelDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      title: Text('Pegar lista desde Excel', style: AppTextStyles.heading3),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'En Excel selecciona las columnas con el número de registro, nombres y apellidos, copia (Ctrl+C) y pega aquí (Ctrl+V). No importa el orden de las columnas ni si hay una columna extra de numeración: el sistema la reconoce sola.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 12,
              minLines: 8,
              autofocus: true,
              decoration: const InputDecoration(
                hintText:
                    '1\tFranklin Antoine\tSejas Hurtado\t2023112770\n2\tRicardo\tBalcazar Chavez\t2023109834\n...',
                alignLabelWithHint: true,
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
          text: 'Rellenar lista',
          icon: Icons.content_paste_go_rounded,
          onPressed: () => Navigator.pop(context, _controller.text),
        ),
      ],
    );
  }
}

class _JugadorFormData {
  final CampeonatoModel? campeonato;
  final List<EquipoModel> equipos;

  const _JugadorFormData({required this.campeonato, required this.equipos});
}

class _JugadorFilaController {
  final TextEditingController codigo = TextEditingController();
  final TextEditingController nombre = TextEditingController();

  /// Si esta fila corresponde a un jugador que ya existía (se precargó
  /// para poder corregirlo), en vez de a un cupo vacío para uno nuevo.
  final JugadorModel? jugadorOriginal;

  _JugadorFilaController({this.jugadorOriginal});

  void dispose() {
    codigo.dispose();
    nombre.dispose();
  }
}

class _JugadorMasivoInput {
  final String codigoEstudiante;
  final String nombreCompleto;
  final JugadorModel? jugadorOriginal;

  const _JugadorMasivoInput({
    required this.codigoEstudiante,
    required this.nombreCompleto,
    this.jugadorOriginal,
  });

  bool get esEdicion => jugadorOriginal != null;

  bool get cambio =>
      jugadorOriginal == null ||
      jugadorOriginal!.codigoEstudiante.toUpperCase() !=
          codigoEstudiante.toUpperCase() ||
      jugadorOriginal!.nombreCompleto != nombreCompleto;
}

class _ParseResult {
  final List<_JugadorMasivoInput> jugadores;
  final List<String> errores;

  const _ParseResult({required this.jugadores, required this.errores});
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
