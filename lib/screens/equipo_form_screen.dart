import 'package:flutter/material.dart';

import '../models/equipo_model.dart';
import '../services/auth_service.dart';
import '../services/equipo_service.dart';
import 'reciclaje/app_button.dart';
import 'reciclaje/app_card.dart';
import 'reciclaje/app_colors.dart';
import 'reciclaje/app_page.dart';
import 'reciclaje/app_snackbars.dart';
import 'reciclaje/app_text_field.dart';
import 'reciclaje/app_text_styles.dart';

class EquipoFormScreen extends StatefulWidget {
  final String campeonatoId;
  final EquipoModel? equipo;

  const EquipoFormScreen({
    super.key,
    required this.campeonatoId,
    this.equipo,
  });

  bool get isEditing => equipo != null;

  @override
  State<EquipoFormScreen> createState() => _EquipoFormScreenState();
}

class _EquipoFormScreenState extends State<EquipoFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _authService = AuthService();
  final _equipoService = EquipoService();

  final _nombreController = TextEditingController();
  final _representanteController = TextEditingController();
  final _carreraController = TextEditingController();
  final _facultadController = TextEditingController();
  final _observacionController = TextEditingController();

  String _estado = EquipoEstado.activo;
  bool _loading = false;

  @override
  void initState() {
    super.initState();

    final equipo = widget.equipo;

    if (equipo != null) {
      _nombreController.text = equipo.nombre;
      _representanteController.text = equipo.representante;
      _carreraController.text = equipo.carrera ?? '';
      _facultadController.text = equipo.facultad ?? '';
      _estado = equipo.estado;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _representanteController.dispose();
    _carreraController.dispose();
    _facultadController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
    });

    try {
      final admin = await _authService.requireAdmin();

      if (widget.isEditing) {
        await _equipoService.editarEquipo(
          campeonatoId: widget.campeonatoId,
          equipoId: widget.equipo!.id,
          cambios: {
            'nombre': _nombreController.text.trim(),
            'representante': _representanteController.text.trim(),
            'carrera': _carreraController.text.trim().isEmpty
                ? null
                : _carreraController.text.trim(),
            'facultad': _facultadController.text.trim().isEmpty
                ? null
                : _facultadController.text.trim(),
            'estado': _estado,
          },
          observacion: _observacionController.text,
          usuarioId: admin.id,
          usuarioNombre: admin.nombre,
        );

        if (!mounted) return;

        AppSnackbars.success(context, 'Equipo actualizado correctamente.');
      } else {
        await _equipoService.crearEquipo(
          campeonatoId: widget.campeonatoId,
          nombre: _nombreController.text,
          representante: _representanteController.text,
          carrera: _carreraController.text,
          facultad: _facultadController.text,
          usuarioId: admin.id,
        );

        if (!mounted) return;

        AppSnackbars.success(context, 'Equipo creado correctamente.');
      }

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

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: AppPage(
          title: widget.isEditing ? 'Editar equipo' : 'Nuevo equipo',
          subtitle: widget.isEditing
              ? 'Toda edición de planilla requiere una observación obligatoria.'
              : 'Registra un equipo participante del campeonato.',
          actions: [
            AppButton.secondary(
              text: 'Cancelar',
              icon: Icons.close,
              onPressed: _loading ? null : () => Navigator.pop(context),
            ),
            AppButton.primary(
              text: widget.isEditing ? 'Actualizar' : 'Guardar',
              icon: Icons.save_outlined,
              loading: _loading,
              onPressed: _guardar,
            ),
          ],
          child: AppCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _SectionTitle(
                    title: 'Datos del equipo',
                    subtitle:
                        'La carrera y facultad quedan habilitadas, pero pueden dejarse vacías si no aplican.',
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Nombre del equipo',
                    hint: 'Ejemplo: Ingeniería Informática',
                    controller: _nombreController,
                    prefixIcon: Icons.groups_2_outlined,
                    validator: (value) {
                      return _required(value, 'El nombre del equipo es obligatorio.');
                    },
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Representante',
                    hint: 'Nombre del representante o encargado',
                    controller: _representanteController,
                    prefixIcon: Icons.person_outline,
                    validator: (value) {
                      return _required(value, 'El representante es obligatorio.');
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Carrera',
                          hint: 'Opcional',
                          controller: _carreraController,
                          prefixIcon: Icons.school_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: AppTextField(
                          label: 'Facultad',
                          hint: 'Opcional',
                          controller: _facultadController,
                          prefixIcon: Icons.account_balance_outlined,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isEditing) ...[
                    const SizedBox(height: 22),
                    _SectionTitle(
                      title: 'Estado y observación',
                      subtitle:
                          'La observación es obligatoria para dejar respaldo del cambio.',
                    ),
                    const SizedBox(height: 18),
                    _DropdownField<String>(
                      label: 'Estado del equipo',
                      value: _estado,
                      items: const [
                        DropdownMenuItem(
                          value: EquipoEstado.activo,
                          child: Text('Activo'),
                        ),
                        DropdownMenuItem(
                          value: EquipoEstado.inactivo,
                          child: Text('Inactivo'),
                        ),
                        DropdownMenuItem(
                          value: EquipoEstado.retirado,
                          child: Text('Retirado'),
                        ),
                        DropdownMenuItem(
                          value: EquipoEstado.descalificado,
                          child: Text('Descalificado'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _estado = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Observación obligatoria',
                      hint:
                          'Ejemplo: corrección del nombre del equipo por error de registro.',
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
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      widget.isEditing
                          ? 'Este cambio quedará registrado en el historial de planilla del equipo.'
                          : 'Después de crear el equipo podrás registrar sus jugadores desde el módulo de jugadores.',
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
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.circle,
          color: AppColors.primary,
          size: 12,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.heading3),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
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
          initialValue: value,
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