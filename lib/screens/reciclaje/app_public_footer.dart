import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/patrocinadores_assets.dart';
import '../../utils/version_build.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'responsive.dart';

/// Sitio de quien desarrolló la app, al que lleva el crédito del footer.
const String _kSitio57Nations = 'https://nations-2b049.web.app';

/// Abre [url] en una pestaña nueva.
///
/// Se lanza derecho, sin consultar antes `canLaunchUrl`: en web, esperar
/// cualquier cosa antes de abrir hace que el navegador deje de tratarlo
/// como una acción del usuario y bloquee la pestaña, así que el click no
/// hacía nada. En Windows, además, `canLaunchUrl` devuelve `false` para
/// `https` salvo que el esquema esté declarado.
///
/// Si igual falla, se ignora: es un enlace de cortesía, no vale romper
/// el footer por eso.
Future<void> _abrir(String url) async {
  try {
    await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );
  } catch (_) {
    // Sin navegador disponible no hay nada que hacer.
  }
}

/// Envuelve un logo para que se pueda tocar cuando tiene sitio web, y lo
/// deja tal cual cuando no. Así el footer no tiene que preguntar dos
/// veces por el mismo caso.
class _EnlaceOpcional extends StatelessWidget {
  final String? url;
  final String? tooltip;
  final Widget child;

  const _EnlaceOpcional({required this.url, required this.child, this.tooltip});

  @override
  Widget build(BuildContext context) {
    if (url == null) return child;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: tooltip ?? url!,
        child: InkWell(
          onTap: () => _abrir(url!),
          borderRadius: BorderRadius.circular(8),
          child: child,
        ),
      ),
    );
  }
}

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
                      (logo) => _EnlaceOpcional(
                        url: PatrocinadoresAssets.sitioDe(logo.ruta),
                        child: _TileLogo(
                          ruta: logo.ruta,
                          ancho: logo.destacado
                              ? (isMobile ? 120 : 160)
                              : (isMobile ? 92 : 124),
                          alto: logo.destacado
                              ? (isMobile ? 48 : 60)
                              : (isMobile ? 38 : 46),
                        ),
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
              // TEMPORAL: ver `version_build.dart`.
              const _VersionDiscreta(),
            ],
          ),
        ),
      ),
    );
  }
}

/// TEMPORAL — sacar junto con `version_build.dart`.
///
/// Número de versión en la esquina inferior derecha del pie. Va chico y
/// muy tenue a propósito: no le dice nada a quien viene a mirar el
/// campeonato, pero alcanza para confirmar de un vistazo qué build está
/// publicada.
class _VersionDiscreta extends StatelessWidget {
  const _VersionDiscreta();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(
          kVersionApp,
          style: AppTextStyles.small.copyWith(
            fontSize: 9,
            height: 1,
            letterSpacing: 0.3,
            fontWeight: FontWeight.w400,
            color: Colors.white.withValues(alpha: 0.28),
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
    // En celular la banda deja poco más de 300px de ancho y el crédito
    // completo no entra: se encoge en bloque antes que recortarse.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Desarrollado por',
            style: AppTextStyles.small.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 8),
          // El logo y el nombre son un solo botón: tocar cualquiera de
          // los dos lleva al sitio de 57 Nations.
          _EnlaceOpcional(
            url: _kSitio57Nations,
            tooltip: 'Ir al sitio de 57 Nations',
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
              ),
            ),
          ),
        ],
      ),
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
