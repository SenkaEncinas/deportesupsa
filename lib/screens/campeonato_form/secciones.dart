part of '../campeonato_form_screen.dart';

// Bloques del formulario: banner, formato, configuración y deporte.

class _HeroCard extends StatelessWidget {
  final String tipoCampeonato;
  final String deporte;

  const _HeroCard({required this.tipoCampeonato, required this.deporte});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return AppCard(
      showBorder: false,
      padding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF003D2D), Color(0xFF005C45), AppColors.primary],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 22 : 30),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogoMark(),
                    const SizedBox(height: 20),
                    _HeroText(tipoCampeonato: tipoCampeonato, deporte: deporte),
                  ],
                )
              : Row(
                  children: [
                    const AppLogoMark(),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _HeroText(
                        tipoCampeonato: tipoCampeonato,
                        deporte: deporte,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroText extends StatelessWidget {
  final String tipoCampeonato;
  final String deporte;

  const _HeroText({required this.tipoCampeonato, required this.deporte});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            const AppBadge(
              text: 'Nuevo',
              type: AppBadgeType.success,
              icon: Icons.add_circle_outline,
            ),
            AppBadge(
              text: Etiquetas.deporte(deporte),
              type: AppBadgeType.warning,
              icon: deporteIcono(deporte),
            ),
            AppBadge(
              text: Etiquetas.tipoCampeonato(tipoCampeonato),
              type: AppBadgeType.primary,
              icon: Icons.account_tree_outlined,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Crear campeonato UPSA',
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            fontSize: isMobile ? 26 : 34,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Define los datos generales, la modalidad deportiva y el formato de competencia para que el sistema pueda preparar el fixture correctamente.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.white.withValues(alpha: 0.88),
            fontSize: isMobile ? 14 : 15,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _DynamicFormatSection extends StatelessWidget {
  final String tipoCampeonato;
  final bool esFutbol;
  final TextEditingController vueltasController;
  final TextEditingController cantidadGruposController;
  final TextEditingController clasificanPorGrupoController;
  final TextEditingController mejoresTercerosController;
  final TextEditingController clasificadosPlayoffsController;
  final bool generaCrucesAleatorios;
  final bool generaGruposAleatorios;
  final bool idaYVueltaEnGrupos;
  final bool incluyeTercerLugar;
  final ValueChanged<bool> onGeneraCrucesChanged;
  final ValueChanged<bool> onGeneraGruposChanged;
  final ValueChanged<bool> onIdaYVueltaGruposChanged;
  final ValueChanged<bool> onTercerLugarChanged;

  const _DynamicFormatSection({
    required this.tipoCampeonato,
    required this.esFutbol,
    required this.vueltasController,
    required this.cantidadGruposController,
    required this.clasificanPorGrupoController,
    required this.mejoresTercerosController,
    required this.clasificadosPlayoffsController,
    required this.generaCrucesAleatorios,
    required this.generaGruposAleatorios,
    required this.idaYVueltaEnGrupos,
    required this.incluyeTercerLugar,
    required this.onGeneraCrucesChanged,
    required this.onGeneraGruposChanged,
    required this.onIdaYVueltaGruposChanged,
    required this.onTercerLugarChanged,
  });

  bool get _usaGrupos {
    return tipoCampeonato == TipoCampeonato.faseGrupos ||
        tipoCampeonato == TipoCampeonato.gruposEliminacion;
  }

  bool get _usaEliminatoria {
    return tipoCampeonato == TipoCampeonato.eliminacionDirecta ||
        tipoCampeonato == TipoCampeonato.gruposEliminacion ||
        tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaPlayoffs {
    return tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  bool get _usaLiga {
    return tipoCampeonato == TipoCampeonato.soloIda ||
        tipoCampeonato == TipoCampeonato.idaVuelta ||
        tipoCampeonato == TipoCampeonato.ligaFinal ||
        tipoCampeonato == TipoCampeonato.ligaPlayoffs;
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reglas del formato seleccionado',
            style: AppTextStyles.heading3,
          ),
          const SizedBox(height: 6),
          Text(
            Etiquetas.descripcionFormato(tipoCampeonato),
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          if (_usaLiga)
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: 'Cantidad de vueltas',
                  hint: '1 o 2',
                  controller: vueltasController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.repeat_rounded,
                  enabled:
                      tipoCampeonato != TipoCampeonato.soloIda &&
                      tipoCampeonato != TipoCampeonato.idaVuelta,
                  validator: _numberValidator,
                ),
                // El empate lo define la fase, no una opción: en la fase
                // regular vale 1 punto; en la eliminatoria se desempata.
                if (esFutbol)
                  const _ConfigInfoTile(
                    title: 'Empates',
                    subtitle:
                        'En liga o grupos valen 1 punto. En la fase final se definen por penales.',
                  )
                else
                  const _ConfigInfoTile(
                    title: 'Sin empates',
                    subtitle:
                        'Este deporte siempre define un ganador por reglamento.',
                  ),
              ],
            ),
          if (_usaGrupos) ...[
            if (_usaLiga) const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: 'Cantidad de grupos',
                  hint: 'Ejemplo: 2',
                  controller: cantidadGruposController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.grid_view_rounded,
                  validator: _numberValidator,
                ),
                if (tipoCampeonato == TipoCampeonato.gruposEliminacion) ...[
                  AppTextField(
                    label: 'Clasifican por grupo',
                    hint: 'Ejemplo: 2',
                    controller: clasificanPorGrupoController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.military_tech_outlined,
                    validator: _numberValidator,
                  ),
                  AppTextField(
                    label: 'Mejores terceros',
                    hint: 'Ejemplo: 0',
                    controller: mejoresTercerosController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.workspace_premium_outlined,
                    validator: (value) {
                      final number = int.tryParse(value ?? '');
                      if (number == null || number < 0) {
                        return 'Valor inválido.';
                      }
                      return null;
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                _ConfigSwitch(
                  title: 'Grupos aleatorios',
                  subtitle:
                      'El sistema podrá distribuir equipos aleatoriamente.',
                  value: generaGruposAleatorios,
                  onChanged: onGeneraGruposChanged,
                ),
                _ConfigSwitch(
                  title: 'Ida y vuelta en grupos',
                  subtitle:
                      'Cada equipo juega dos veces contra sus rivales de grupo.',
                  value: idaYVueltaEnGrupos,
                  onChanged: onIdaYVueltaGruposChanged,
                ),
              ],
            ),
            if (tipoCampeonato == TipoCampeonato.gruposEliminacion) ...[
              const SizedBox(height: 16),
              _RondaResumenBox(
                listenable: Listenable.merge([
                  cantidadGruposController,
                  clasificanPorGrupoController,
                  mejoresTercerosController,
                ]),
                calcularTotal: () {
                  final grupos =
                      int.tryParse(cantidadGruposController.text.trim()) ?? 0;
                  final clasifican =
                      int.tryParse(clasificanPorGrupoController.text.trim()) ??
                      0;
                  final terceros =
                      int.tryParse(mejoresTercerosController.text.trim()) ?? 0;
                  return grupos * clasifican + terceros;
                },
                textoBase: (total) =>
                    '$total equipos clasifican a la fase final.',
              ),
            ],
          ],
          if (_usaPlayoffs) ...[
            if (_usaLiga || _usaGrupos) const SizedBox(height: 16),
            _ResponsiveFields(
              children: [
                AppTextField(
                  label: tipoCampeonato == TipoCampeonato.ligaFinal
                      ? 'Clasificados a final'
                      : 'Clasificados a playoffs',
                  hint: tipoCampeonato == TipoCampeonato.ligaFinal ? '2' : '4',
                  controller: clasificadosPlayoffsController,
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.workspace_premium_outlined,
                  enabled: tipoCampeonato != TipoCampeonato.ligaFinal,
                  validator: _numberValidator,
                ),
                _ConfigSwitch(
                  title: 'Cruces aleatorios',
                  subtitle:
                      'El sistema podrá generar los cruces automáticamente.',
                  value: generaCrucesAleatorios,
                  onChanged: onGeneraCrucesChanged,
                ),
              ],
            ),
            if (tipoCampeonato == TipoCampeonato.ligaPlayoffs) ...[
              const SizedBox(height: 16),
              _RondaResumenBox(
                listenable: clasificadosPlayoffsController,
                calcularTotal: () =>
                    int.tryParse(clasificadosPlayoffsController.text.trim()) ??
                    0,
                textoBase: (total) =>
                    '$total equipos clasifican a los playoffs.',
              ),
            ],
          ],
          if (tipoCampeonato == TipoCampeonato.eliminacionDirecta) ...[
            const SizedBox(height: 16),
            _ConfigSwitch(
              title: 'Cruces aleatorios',
              subtitle:
                  'El sistema podrá sortear los cruces iniciales de eliminación.',
              value: generaCrucesAleatorios,
              onChanged: onGeneraCrucesChanged,
            ),
          ],
          if (_usaEliminatoria) ...[
            const SizedBox(height: 16),
            _ConfigSwitch(
              title: 'Incluir partido por tercer lugar',
              subtitle:
                  'Útil cuando la organización quiere definir primer, segundo y tercer puesto.',
              value: incluyeTercerLugar,
              onChanged: onTercerLugarChanged,
            ),
          ],
        ],
      ),
    );
  }

  String? _numberValidator(String? value) {
    final number = int.tryParse(value ?? '');
    if (number == null || number <= 0) {
      return 'Valor inválido.';
    }

    return null;
  }
}

/// Resumen en vivo (se recalcula solo con [Listenable], sin depender de
/// setState del formulario) de a qué ronda eliminatoria llega la
/// configuración actual: verde y con el nombre de la ronda si el total
/// es una potencia de 2 (llave pareja, sin equipos sueltos), o una
/// advertencia con el ajuste sugerido si no cuadra.
class _RondaResumenBox extends StatelessWidget {
  final Listenable listenable;
  final int Function() calcularTotal;
  final String Function(int total) textoBase;

  const _RondaResumenBox({
    required this.listenable,
    required this.calcularTotal,
    required this.textoBase,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final total = calcularTotal();
        final cuadra = FixtureGrouping.esPotenciaDeDos(total);
        final color = cuadra ? AppColors.success : AppColors.warning;
        final colorFondo = cuadra
            ? AppColors.successLight
            : AppColors.warningLight;

        final texto = total < 2
            ? 'Define al menos 2 equipos clasificados para armar la fase final.'
            : cuadra
            ? '${textoBase(total)} Arranca en ${FixtureGrouping.rondaSegunEquipos(total).toLowerCase()}.'
            : '${textoBase(total)} Ese total no arma una llave pareja (2, 4, 8, 16 o 32): ajusta la configuración para que cuadre.';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                cuadra
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_rounded,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  texto,
                  style: AppTextStyles.body.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FormatoSelector extends StatelessWidget {
  final List<_FormatoOption> formatos;
  final String selected;
  final ValueChanged<String> onSelected;

  const _FormatoSelector({
    required this.formatos,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final columns = isMobile
            ? 1
            : constraints.maxWidth < 950
            ? 2
            : 3;

        const spacing = 14.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: formatos.map((formato) {
            return SizedBox(
              width: width,
              child: _FormatoCard(
                option: formato,
                selected: selected == formato.value,
                onTap: () => onSelected(formato.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _FormatoCard extends StatelessWidget {
  final _FormatoOption option;
  final bool selected;
  final VoidCallback onTap;

  const _FormatoCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: selected ? AppColors.primaryLight : AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Icon(
              option.icon,
              color: selected ? AppColors.white : AppColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: selected
                        ? AppColors.primaryDark
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  option.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.small.copyWith(
                    color: selected
                        ? AppColors.primaryDark.withValues(alpha: 0.75)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (selected) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ],
      ),
    );
  }
}

class _ConfigInfoTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ConfigInfoTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConfigSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: AppTextStyles.small),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  final List<Widget> children;

  const _ResponsiveFields({required this.children});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn =
            Responsive.isMobile(context) || constraints.maxWidth < 860;

        if (useColumn) {
          return Column(
            children: List.generate(children.length, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < children.length - 1 ? 14 : 0,
                ),
                child: children[index],
              );
            }),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(children.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < children.length - 1 ? 14 : 0,
                ),
                child: children[index],
              ),
            );
          }),
        );
      },
    );
  }
}

class _FormatoOption {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;

  const _FormatoOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _DeporteSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const _DeporteSelector({required this.selected, required this.onSelected});

  static const List<_FormatoOption> _deportes = [
    _FormatoOption(
      value: DeporteTipo.futbol,
      title: 'Fútbol / Futsal',
      subtitle: 'Resultado por goles, con goleadores y tarjetas.',
      icon: Icons.sports_soccer,
    ),
    _FormatoOption(
      value: DeporteTipo.volley,
      title: 'Vóley',
      subtitle: 'Resultado por sets, sin empates.',
      icon: Icons.sports_volleyball_outlined,
    ),
    _FormatoOption(
      value: DeporteTipo.basket,
      title: 'Básquet',
      subtitle: 'Resultado por puntos, con prórroga.',
      icon: Icons.sports_basketball_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = Responsive.isMobile(context);
        final columns = isMobile ? 1 : 3;

        const spacing = 14.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _deportes.map((deporte) {
            return SizedBox(
              width: width,
              child: _FormatoCard(
                option: deporte,
                selected: selected == deporte.value,
                onTap: () => onSelected(deporte.value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
