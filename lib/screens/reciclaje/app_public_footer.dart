import 'package:flutter/material.dart';

import '../../utils/patrocinadores_assets.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

/// Pie de página de las pantallas públicas.
///
/// Sigue el patrón habitual de sitios de ligas deportivas: una franja
/// propia de auspiciadores (grilla de logos pareja, separada del
/// contenido) y debajo una banda oscura con la marca y el contacto.
///
/// Los logos se descubren solos desde los assets (ver
/// [PatrocinadoresAssets]), así que sumar o sacar un patrocinador es
/// dejar o borrar un archivo — no hay que tocar esta pantalla.
class AppPublicFooter extends StatelessWidget {
  const AppPublicFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PatrocinadoresLogos>(
      future: PatrocinadoresAssets.cargar(),
      builder: (context, snapshot) {
        final logos = snapshot.data;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logos != null && logos.hayAlguno)
              _FranjaAuspiciantes(logos: logos),
            const _BandaMarca(),
          ],
        );
      },
    );
  }
}

class _FranjaAuspiciantes extends StatelessWidget {
  final PatrocinadoresLogos logos;

  const _FranjaAuspiciantes({required this.logos});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: isMobile ? 26 : 34,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Text(
                'AUSPICIAN',
                textAlign: TextAlign.center,
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 16),
              // Todos en una sola línea, con los principales al medio:
              // los secundarios se parten en dos mitades y los
              // destacados van en el centro. En pantallas angostas el
              // `Wrap` los reacomoda solo en vez de aplastarlos.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: isMobile ? 14 : 26,
                runSpacing: isMobile ? 14 : 20,
                children: _ordenados(logos)
                    .map(
                      (logo) => _TileLogo(
                        ruta: logo.ruta,
                        ancho: logo.destacado
                            ? (isMobile ? 120 : 160)
                            : (isMobile ? 92 : 124),
                        alto: logo.destacado
                            ? (isMobile ? 48 : 60)
                            : (isMobile ? 38 : 46),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Orden final de la tira: mitad de los secundarios, los destacados al
/// medio, y la otra mitad. Así los principales quedan centrados aunque
/// queden dos logos de un lado y tres del otro.
List<_LogoFooter> _ordenados(PatrocinadoresLogos logos) {
  final corte = logos.secundarios.length ~/ 2;

  return [
    ...logos.secundarios
        .take(corte)
        .map((ruta) => _LogoFooter(ruta: ruta, destacado: false)),
    ...logos.principal.map((ruta) => _LogoFooter(ruta: ruta, destacado: true)),
    ...logos.secundarios
        .skip(corte)
        .map((ruta) => _LogoFooter(ruta: ruta, destacado: false)),
  ];
}

class _LogoFooter {
  final String ruta;
  final bool destacado;

  const _LogoFooter({required this.ruta, required this.destacado});
}

/// Cada logo ocupa una caja del mismo alto y se ajusta adentro: si se
/// normalizara solo por ancho, un logo cuadrado quedaría gigante al lado
/// de un logotipo ancho. Sin recuadro ni borde: los logos ya traen su
/// propia forma y encajonarlos ensuciaba la franja.
class _TileLogo extends StatelessWidget {
  final String ruta;
  final double ancho;
  final double alto;

  const _TileLogo({
    required this.ruta,
    required this.ancho,
    required this.alto,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      child: Image.asset(
        ruta,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _BandaMarca extends StatelessWidget {
  const _BandaMarca();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.horizontalPadding(context),
        vertical: isMobile ? 24 : 30,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              // En móvil la marca y el contacto van apilados y centrados;
              // en pantallas anchas, uno a cada lado.
              isMobile
                  ? Column(
                      children: [
                        const _MarcaUpsa(centrado: true),
                        const SizedBox(height: 18),
                        const _Contacto(centrado: true),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Expanded(child: _MarcaUpsa(centrado: false)),
                        SizedBox(width: 24),
                        _Contacto(centrado: false),
                      ],
                    ),
              const SizedBox(height: 22),
              const Divider(height: 1, color: Colors.white24),
              const SizedBox(height: 14),
              // Copyright y crédito de autoría en la misma línea cuando
              // hay ancho; apilados y centrados en celular.
              isMobile
                  ? Column(
                      children: [
                        _Copyright(centrado: true),
                        const SizedBox(height: 12),
                        const _CreditoCreador(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: _Copyright(centrado: false)),
                        const SizedBox(width: 16),
                        const _CreditoCreador(),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Copyright extends StatelessWidget {
  final bool centrado;

  const _Copyright({required this.centrado});

  @override
  Widget build(BuildContext context) {
    return Text(
      '© ${DateTime.now().year} Universidad Privada de Santa Cruz de la Sierra · Coordinación de Deportes',
      textAlign: centrado ? TextAlign.center : TextAlign.start,
      style: AppTextStyles.small.copyWith(
        color: Colors.white.withValues(alpha: 0.72),
      ),
    );
  }
}

/// Crédito de quien desarrolló la aplicación. Va discreto: texto chico y
/// el isotipo en su versión monocromática blanca, que es la que el manual
/// de marca de 57 Nations define para fondos oscuros.
class _CreditoCreador extends StatelessWidget {
  const _CreditoCreador();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Desarrollado por',
          style: AppTextStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(width: 8),
        Opacity(
          opacity: 0.9,
          child: Image.asset(
            'assets/images/logo_57nations_blanco.png',
            height: 17,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => Text(
              '57 Nations',
              style: AppTextStyles.small.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Nations',
          style: AppTextStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MarcaUpsa extends StatelessWidget {
  final bool centrado;

  const _MarcaUpsa({required this.centrado});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centrado
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Image.asset(
                'assets/images/logo_upsa.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.school_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Deportes UPSA',
              style: AppTextStyles.title.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Text(
            'Fixtures, resultados, tablas de posiciones y goleadores de los campeonatos universitarios.',
            textAlign: centrado ? TextAlign.center : TextAlign.start,
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ),
      ],
    );
  }
}

class _Contacto extends StatelessWidget {
  final bool centrado;

  const _Contacto({required this.centrado});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centrado
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.end,
      children: [
        Text(
          'COORDINACIÓN DE DEPORTES',
          style: AppTextStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.6),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jorge Joaquín Antequera Castedo',
          textAlign: centrado ? TextAlign.center : TextAlign.end,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Campus UPSA · Santa Cruz de la Sierra',
          textAlign: centrado ? TextAlign.center : TextAlign.end,
          style: AppTextStyles.small.copyWith(
            color: Colors.white.withValues(alpha: 0.72),
          ),
        ),
      ],
    );
  }
}
