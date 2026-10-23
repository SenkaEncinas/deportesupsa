part of '../resultado_form_screen.dart';

// Secciones del formulario: penales, walkover, sets, goles, tarjetas y sanciones.

class _PenalesSection extends StatelessWidget {
  final String localNombre;
  final String visitanteNombre;
  final TextEditingController penalesLocalController;
  final TextEditingController penalesVisitanteController;

  const _PenalesSection({
    required this.localNombre,
    required this.visitanteNombre,
    required this.penalesLocalController,
    required this.penalesVisitanteController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.sports, color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Empate en la fase final: registrá los penales para definir quién avanza.',
                  style: AppTextStyles.body.copyWith(
                    color: const Color(0xFF92600A),
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Penales $localNombre',
                controller: penalesLocalController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sports_soccer,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppTextField(
                label: 'Penales $visitanteNombre',
                controller: penalesVisitanteController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.sports_soccer,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null || number < 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Selector del equipo que gana por walkover o sanción en vóley/básquet,
/// con el marcador que se va a guardar bien a la vista: no es solo
/// "ganó" (25-0 por set en vóley, 20-0 en básquet) y eso pesa en la
/// diferencia de puntos de la tabla.
class _GanadorAdministrativoSelector extends StatelessWidget {
  final PartidoModel partido;
  final String? ganadorId;
  final String detalle;
  final ValueChanged<String?> onChanged;

  const _GanadorAdministrativoSelector({
    required this.partido,
    required this.ganadorId,
    required this.detalle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Equipo que se presentó', style: AppTextStyles.heading3),
        const SizedBox(height: 6),
        Text(
          detalle,
          style: AppTextStyles.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        AppDropdownField<String>(
          label: 'Gana el partido',
          value: ganadorId,
          items: [
            DropdownMenuItem(
              value: partido.equipoLocalId,
              child: Text(partido.equipoLocalNombre),
            ),
            DropdownMenuItem(
              value: partido.equipoVisitanteId,
              child: Text(partido.equipoVisitanteNombre),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

String? _validarPuntosSet(String? value) {
  final number = int.tryParse(value ?? '');
  return number == null || number < 0 ? 'Inválido' : null;
}

class _SetsSection extends StatelessWidget {
  final List<_SetInputState> sets;
  final String localNombre;
  final String visitanteNombre;
  final ({int local, int visitante}) setsGanados;
  final int setsParaGanar;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onChanged;

  const _SetsSection({
    required this.sets,
    required this.localNombre,
    required this.visitanteNombre,
    required this.setsGanados,
    required this.setsParaGanar,
    required this.onAdd,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SeccionLista(
      titulo: 'Sets del partido',
      textoAgregar: 'Agregar set',
      ayudaVacia:
          'Agrega cada set con los puntos de ambos equipos. Ejemplo: 25-20, 23-25, 15-12.',
      cantidad: sets.length,
      onAdd: onAdd,
      encabezado: AppInfoBox(
        tone: AppInfoBoxTone.primary,
        icon: Icons.scoreboard_outlined,
        text:
            'Marcador en sets: $localNombre ${setsGanados.local} - ${setsGanados.visitante} $visitanteNombre · Gana el primero en llegar a $setsParaGanar sets.',
      ),
      itemBuilder: (index) {
        final item = sets[index];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Set ${index + 1}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.small.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.localController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Local',
                    hintText: '25',
                  ),
                  onChanged: (_) => onChanged(),
                  validator: _validarPuntosSet,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: item.visitanteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Visitante',
                    hintText: '20',
                  ),
                  onChanged: (_) => onChanged(),
                  validator: _validarPuntosSet,
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
      },
    );
  }
}

class _SeccionLista extends StatelessWidget {
  final String titulo;
  final String textoAgregar;
  final String ayudaVacia;
  final int cantidad;
  final VoidCallback onAdd;
  final Widget Function(int index) itemBuilder;

  /// Algo fijo entre el título y la lista (el marcador de sets).
  final Widget? encabezado;

  const _SeccionLista({
    required this.titulo,
    required this.textoAgregar,
    required this.ayudaVacia,
    required this.cantidad,
    required this.onAdd,
    required this.itemBuilder,
    this.encabezado,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(titulo, style: AppTextStyles.heading3)),
            AppButton.secondary(
              text: textoAgregar,
              icon: Icons.add,
              onPressed: onAdd,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (encabezado != null) ...[encabezado!, const SizedBox(height: 12)],
        if (cantidad == 0)
          AppInfoBox(tone: AppInfoBoxTone.primary, text: ayudaVacia)
        else
          for (var i = 0; i < cantidad; i++) itemBuilder(i),
      ],
    );
  }
}

/// Una fila de goles, tarjetas o sanciones: el jugador, los campos
/// propios de cada sección y el botón de borrar, con un detalle opcional
/// debajo. En celular el jugador va en su propia línea y los campos
/// debajo: todo en una fila desbordaba en 375 px.
class _FilaJugador extends StatelessWidget {
  final List<JugadorModel> jugadores;
  final String? jugadorId;
  final ValueChanged<String?> onJugador;

  /// Cada campo con el ancho relativo que ocupa en escritorio.
  final List<(Widget campo, int flex)> campos;
  final VoidCallback onEliminar;
  final Widget? detalle;

  const _FilaJugador({
    required this.jugadores,
    required this.jugadorId,
    required this.onJugador,
    required this.campos,
    required this.onEliminar,
    this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final jugador = AppDropdownField<String>(
      label: 'Jugador',
      value: jugadorId,
      items: jugadores.map((jugador) {
        return DropdownMenuItem(
          value: jugador.id,
          child: Text(
            '${jugador.nombreCompleto} - ${jugador.equipoNombre}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: onJugador,
    );

    final eliminar = IconButton(
      tooltip: 'Quitar',
      onPressed: onEliminar,
      icon: const Icon(Icons.delete_outline),
    );

    final camposFila = <Widget>[
      for (final (campo, flex) in campos) ...[
        Expanded(flex: isMobile ? 1 : flex, child: campo),
        const SizedBox(width: 12),
      ],
    ]..removeLast();

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 14 : 12),
      child: Column(
        children: [
          if (isMobile) ...[
            jugador,
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [...camposFila, const SizedBox(width: 8), eliminar],
            ),
          ] else
            Row(
              children: [
                Expanded(flex: 3, child: jugador),
                const SizedBox(width: 12),
                ...camposFila,
                const SizedBox(width: 8),
                eliminar,
              ],
            ),
          if (detalle != null) ...[const SizedBox(height: 10), detalle!],
        ],
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
    return _SeccionLista(
      titulo: 'Goles por jugador',
      textoAgregar: 'Agregar gol',
      ayudaVacia:
          'Agrega los goles por jugador. La suma debe coincidir con el resultado final.',
      cantidad: goles.length,
      onAdd: onAdd,
      itemBuilder: (index) {
        final item = goles[index];

        return _FilaJugador(
          jugadores: jugadores,
          jugadorId: item.jugadorId,
          onJugador: (value) {
            item.jugadorId = value;
            onRefresh();
          },
          campos: [
            (
              _SmallNumberField(
                label: 'Goles',
                value: item.cantidad,
                onChanged: (value) => item.cantidad = value,
              ),
              1,
            ),
          ],
          onEliminar: () => onRemove(index),
        );
      },
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
    return _SeccionLista(
      titulo: 'Tarjetas por jugador',
      textoAgregar: 'Agregar tarjeta',
      ayudaVacia:
          'Aquí puedes registrar amarillas y rojas por jugador. Si no hubo tarjetas, deja esta sección vacía.',
      cantidad: tarjetas.length,
      onAdd: onAdd,
      itemBuilder: (index) {
        final item = tarjetas[index];

        return _FilaJugador(
          jugadores: jugadores,
          jugadorId: item.jugadorId,
          onJugador: (value) {
            item.jugadorId = value;
            onRefresh();
          },
          campos: [
            (
              _SmallNumberField(
                label: 'Amarillas',
                value: item.amarillas,
                onChanged: (value) => item.amarillas = value,
              ),
              1,
            ),
            (
              _SmallNumberField(
                label: 'Rojas',
                value: item.rojas,
                onChanged: (value) => item.rojas = value,
              ),
              1,
            ),
          ],
          onEliminar: () => onRemove(index),
          detalle: TextFormField(
            controller: item.motivoController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo / detalle opcional',
              hintText: 'Ejemplo: doble amarilla, conducta antideportiva...',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
        );
      },
    );
  }
}

/// Vóley y básquet no tienen tarjetas amarillas/rojas como el fútbol,
/// pero sí pueden tener una sanción a un jugador (por mesa o forzada,
/// como una descalificación). Esta sección es opcional: solo se llena
/// "si es necesario", igual que la de tarjetas en fútbol.
class _SancionesSection extends StatelessWidget {
  final List<_SancionInputState> sanciones;
  final List<JugadorModel> jugadores;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final VoidCallback onRefresh;

  const _SancionesSection({
    required this.sanciones,
    required this.jugadores,
    required this.onAdd,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _SeccionLista(
      titulo: 'Sanciones a jugadores',
      textoAgregar: 'Agregar sanción',
      ayudaVacia:
          'Solo si hubo un problema de mesa o una sanción a algún jugador. Si no pasó nada, deja esta sección vacía.',
      cantidad: sanciones.length,
      onAdd: onAdd,
      itemBuilder: (index) {
        final item = sanciones[index];

        return _FilaJugador(
          jugadores: jugadores,
          jugadorId: item.jugadorId,
          onJugador: (value) {
            item.jugadorId = value;
            onRefresh();
          },
          campos: [
            (
              AppDropdownField<String>(
                label: 'Tipo de sanción',
                value: item.tipo,
                items: const [
                  DropdownMenuItem(
                    value: SancionTipo.porMesa,
                    child: Text('Sanción por mesa'),
                  ),
                  DropdownMenuItem(
                    value: SancionTipo.forzada,
                    child: Text('Sanción forzada'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  item.tipo = value;
                  onRefresh();
                },
              ),
              2,
            ),
          ],
          onEliminar: () => onRemove(index),
          detalle: TextFormField(
            controller: item.detalleController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Detalle de lo ocurrido (opcional)',
              hintText: 'Ejemplo: conducta antideportiva con el árbitro.',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
        );
      },
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

class _SancionInputState {
  String? jugadorId;
  String tipo = SancionTipo.porMesa;
  final TextEditingController detalleController = TextEditingController();

  void dispose() {
    detalleController.dispose();
  }
}

class _SetInputState {
  final TextEditingController localController;
  final TextEditingController visitanteController;

  _SetInputState({int? local, int? visitante})
    : localController = TextEditingController(text: local?.toString() ?? ''),
      visitanteController = TextEditingController(
        text: visitante?.toString() ?? '',
      );

  void dispose() {
    localController.dispose();
    visitanteController.dispose();
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
