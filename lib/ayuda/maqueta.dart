import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../screens/reciclaje/app_colors.dart';

/// Piezas para dibujar maquetas simplificadas de las pantallas de la app
/// dentro de las guías de ayuda. No son capturas: usan los mismos
/// colores, radios, íconos y textos que la app, en tamaño reducido.
///
/// Todas se dibujan dentro de [MqMarco], que mide siempre
/// [MqMarco.ancho] × [MqMarco.alto] y se escala entero para entrar en
/// el ancho disponible.

const double _r = 10; // radio de tarjetas y campos, como la app a escala
const _sombra = [
  BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
];

TextStyle _texto(
  double size, {
  FontWeight peso = FontWeight.w600,
  Color color = AppColors.textPrimary,
}) => TextStyle(
  fontSize: size,
  fontWeight: peso,
  color: color,
  height: 1.25,
  decoration: TextDecoration.none,
);

/// La pantalla: barra de título (con flecha de volver si corresponde)
/// y el contenido debajo.
class MqMarco extends StatelessWidget {
  static const double ancho = 360;
  static const double alto = 256;

  final String titulo;
  final bool volver;
  final List<Widget> acciones;
  final Widget child;

  /// Algo que va encima de todo (un diálogo sobre fondo oscurecido).
  final Widget? superpuesto;

  const MqMarco({
    super.key,
    required this.titulo,
    required this.child,
    this.volver = true,
    this.acciones = const [],
    this.superpuesto,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      height: alto,
      // Sin recortar: la mano del indicador "tocá acá" puede salir por
      // el borde hacia el margen gris, en vez de quedar cortada.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (volver) ...[
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(
                            titulo,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _texto(12, peso: FontWeight.w800),
                          ),
                        ),
                        for (final accion in acciones) ...[
                          const SizedBox(width: 6),
                          accion,
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (superpuesto != null) ...[
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0x73111827),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            Positioned.fill(child: Center(child: superpuesto)),
          ],
        ],
      ),
    );
  }
}

enum MqTipoBoton { relleno, borde, texto, peligro }

class MqBoton extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final MqTipoBoton tipo;

  const MqBoton(
    this.texto, {
    super.key,
    this.icono,
    this.tipo = MqTipoBoton.relleno,
  });

  const MqBoton.borde(this.texto, {super.key, this.icono})
    : tipo = MqTipoBoton.borde;

  const MqBoton.texto(this.texto, {super.key, this.icono})
    : tipo = MqTipoBoton.texto;

  const MqBoton.peligro(this.texto, {super.key, this.icono})
    : tipo = MqTipoBoton.peligro;

  @override
  Widget build(BuildContext context) {
    final (fondo, frente, borde) = switch (tipo) {
      MqTipoBoton.relleno => (AppColors.primary, AppColors.white, null),
      MqTipoBoton.peligro => (AppColors.danger, AppColors.white, null),
      MqTipoBoton.borde => (
        AppColors.white,
        AppColors.primary,
        AppColors.primary,
      ),
      MqTipoBoton.texto => (Colors.transparent, AppColors.primary, null),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
        border: borde == null ? null : Border.all(color: borde),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: 11, color: frente),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _texto(9.5, peso: FontWeight.w800, color: frente),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un botón que es solo un ícono (lápiz, tacho, flecha...).
class MqIcono extends StatelessWidget {
  final IconData icono;
  final Color color;

  const MqIcono(this.icono, {super.key, this.color = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Icon(icono, size: 15, color: color),
    );
  }
}

/// Un campo de formulario con su etiqueta arriba.
class MqCampo extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData? icono;
  final bool desplegable;

  const MqCampo(
    this.etiqueta,
    this.valor, {
    super.key,
    this.icono,
    this.desplegable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(etiqueta, style: _texto(8.5, color: AppColors.textSecondary)),
        const SizedBox(height: 3),
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              if (icono != null) ...[
                Icon(icono, size: 11, color: AppColors.textSecondary),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _texto(9.5, peso: FontWeight.w500),
                ),
              ),
              if (desplegable)
                const Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Una tarjeta blanca, como `AppCard`.
class MqTarjeta extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const MqTarjeta({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(9),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: AppColors.border),
        boxShadow: _sombra,
      ),
      child: child,
    );
  }
}

/// Una fila de una lista: ícono, título, detalle y algo a la derecha.
class MqFila extends StatelessWidget {
  final String titulo;
  final String? detalle;
  final IconData? icono;
  final Widget? derecha;

  const MqFila(
    this.titulo, {
    super.key,
    this.detalle,
    this.icono,
    this.derecha,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Row(
        children: [
          if (icono != null) ...[
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icono, size: 12, color: AppColors.primary),
            ),
            const SizedBox(width: 7),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _texto(9.5, peso: FontWeight.w700),
                ),
                if (detalle != null)
                  Text(
                    detalle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _texto(8, color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (derecha != null) ...[const SizedBox(width: 6), derecha!],
        ],
      ),
    );
  }
}

/// Varias filas dentro de un borde, separadas por líneas.
class MqLista extends StatelessWidget {
  final List<Widget> filas;

  const MqLista(this.filas, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(_r),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < filas.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.border),
            filas[i],
          ],
        ],
      ),
    );
  }
}

/// Etiqueta de estado ("Activo", "Programado"...), como `AppBadge`.
class MqEtiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  final Color fondo;

  const MqEtiqueta(
    this.texto, {
    super.key,
    this.color = AppColors.primary,
    this.fondo = AppColors.primaryLight,
  });

  const MqEtiqueta.exito(this.texto, {super.key})
    : color = AppColors.success,
      fondo = AppColors.successLight;

  const MqEtiqueta.info(this.texto, {super.key})
    : color = AppColors.info,
      fondo = AppColors.infoLight;

  const MqEtiqueta.aviso(this.texto, {super.key})
    : color = AppColors.secondaryDark,
      fondo = AppColors.warningLight;

  const MqEtiqueta.neutra(this.texto, {super.key})
    : color = AppColors.textSecondary,
      fondo = AppColors.surfaceContainer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _texto(8, peso: FontWeight.w800, color: color),
      ),
    );
  }
}

class MqInterruptor extends StatelessWidget {
  final String etiqueta;
  final bool valor;

  const MqInterruptor(this.etiqueta, {super.key, this.valor = true});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(etiqueta, style: _texto(9.5))),
        Container(
          width: 26,
          height: 15,
          padding: const EdgeInsets.all(2),
          alignment: valor ? Alignment.centerRight : Alignment.centerLeft,
          decoration: BoxDecoration(
            color: valor ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Container(
            width: 11,
            height: 11,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Texto de sección en mayúsculas ("EN ESTA PANTALLA", "COMPETENCIA").
class MqSeccion extends StatelessWidget {
  final String texto;

  const MqSeccion(this.texto, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        texto.toUpperCase(),
        style: _texto(
          7.5,
          peso: FontWeight.w800,
          color: AppColors.textMuted,
        ).copyWith(letterSpacing: 0.8),
      ),
    );
  }
}

/// Un texto suelto de la pantalla (título de sección, aclaración).
class MqTexto extends StatelessWidget {
  final String texto;
  final double size;
  final bool fuerte;
  final Color color;

  const MqTexto(
    this.texto, {
    super.key,
    this.size = 9.5,
    this.fuerte = false,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _texto(
        size,
        peso: fuerte ? FontWeight.w800 : FontWeight.w500,
        color: color,
      ),
    );
  }
}

/// Un módulo del detalle del campeonato (ícono y nombre).
class MqModulo extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const MqModulo(this.titulo, this.icono, {super.key});

  @override
  Widget build(BuildContext context) {
    return MqTarjeta(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(titulo, style: _texto(9, peso: FontWeight.w800)),
        ],
      ),
    );
  }
}

/// Un diálogo para poner en [MqMarco.superpuesto].
class MqDialogo extends StatelessWidget {
  final String titulo;
  final Widget child;
  final List<Widget> acciones;

  const MqDialogo({
    super.key,
    required this.titulo,
    required this.child,
    this.acciones = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: _texto(11.5, peso: FontWeight.w800)),
          const SizedBox(height: 7),
          child,
          if (acciones.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final accion in acciones) ...[
                  const SizedBox(width: 6),
                  accion,
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Calendario chico con un día elegido.
class MqCalendario extends StatelessWidget {
  final String mes;
  final int dia;

  const MqCalendario({super.key, this.mes = 'Octubre 2026', this.dia = 24});

  @override
  Widget build(BuildContext context) {
    // Octubre de 2026 empieza en jueves.
    const desfase = 3;
    return SizedBox(
      width: 170,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mes, style: _texto(9.5, peso: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final d in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: _texto(7.5, color: AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
          for (var semana = 0; semana < 5; semana++)
            Row(
              children: [
                for (var c = 0; c < 7; c++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final n = semana * 7 + c - desfase + 1;
                        final valido = n >= 1 && n <= 31;
                        final elegido = n == dia;
                        return Container(
                          height: 15,
                          margin: const EdgeInsets.all(1),
                          alignment: Alignment.center,
                          decoration: elegido
                              ? const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                )
                              : null,
                          child: Text(
                            valido ? '$n' : '',
                            style: _texto(
                              7.5,
                              color: elegido
                                  ? AppColors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Reloj grande con la hora elegida.
class MqReloj extends StatelessWidget {
  final String hora;

  const MqReloj(this.hora, {super.key});

  @override
  Widget build(BuildContext context) {
    final partes = hora.split(':');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _digitos(partes.first, activo: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Text(':', style: _texto(22, peso: FontWeight.w800)),
            ),
            _digitos(partes.last),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: AppColors.surfaceContainer,
            shape: BoxShape.circle,
          ),
          child: CustomPaint(
            painter: _AgujaPainter(int.tryParse(partes.first) ?? 12),
          ),
        ),
      ],
    );
  }

  Widget _digitos(String texto, {bool activo = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: activo ? AppColors.primaryLight : AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: _texto(
          22,
          peso: FontWeight.w800,
          color: activo ? AppColors.primaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _AgujaPainter extends CustomPainter {
  final int hora;

  _AgujaPainter(this.hora);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final angulo = (hora % 12) / 12 * 2 * math.pi - math.pi / 2;
    final punta =
        centro + Offset(math.cos(angulo), math.sin(angulo)) * size.width * 0.34;
    final lapiz = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2;
    canvas.drawLine(centro, punta, lapiz);
    canvas.drawCircle(centro, 3, lapiz);
    canvas.drawCircle(punta, 9, lapiz..color = AppColors.primary);
  }

  @override
  bool shouldRepaint(covariant _AgujaPainter old) => old.hora != hora;
}

/// Señala el elemento que hay que tocar: anillo del color de acento,
/// una onda que se expande y una mano que llega, presiona y se repite.
///
/// Ciclo de 1,8 s: la mano llega en el 0–35 % (ease-out), presiona en el
/// 35–50 % y la onda ocupa el 45–100 %. Si el sistema pide reducir el
/// movimiento, queda todo quieto.
///
/// Con [resultado] en true es la variante del último paso: un resaltado
/// verde suave sobre lo que cambió, sin mano.
class MqTocaAca extends StatefulWidget {
  final Widget child;
  final bool resultado;
  final double radio;

  const MqTocaAca({
    super.key,
    required this.child,
    this.resultado = false,
    this.radio = 9,
  });

  const MqTocaAca.resultado({super.key, required this.child, this.radio = 9})
    : resultado = true;

  @override
  State<MqTocaAca> createState() => _MqTocaAcaState();
}

class _MqTocaAcaState extends State<MqTocaAca>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ciclo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final quieto =
        widget.resultado ||
        MediaQuery.maybeDisableAnimationsOf(context) == true;
    if (quieto) {
      _ciclo
        ..stop()
        ..value = 0.5;
    } else if (!_ciclo.isAnimating) {
      _ciclo.repeat();
    }
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radio = BorderRadius.circular(widget.radio);

    if (widget.resultado) {
      return DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radio,
          border: Border.all(color: AppColors.success, width: 1.5),
          color: AppColors.success.withValues(alpha: 0.10),
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _ciclo,
      child: widget.child,
      builder: (context, child) {
        final t = _ciclo.value;
        final llegada = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
        final presion = t < 0.35 || t > 0.5
            ? 1.0
            : 1 - 0.15 * math.sin((t - 0.35) / 0.15 * math.pi);
        final onda = ((t - 0.45) / 0.55).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // La onda, detrás del elemento.
            if (onda > 0)
              Positioned.fill(
                child: Transform.scale(
                  scale: 1 + 0.35 * onda,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radio,
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.55 * (1 - onda),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radio,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: child,
            ),
            // La mano, que llega desde abajo a la derecha.
            Positioned(
              right: -14 - 26 * (1 - llegada),
              bottom: -16 - 26 * (1 - llegada),
              child: Opacity(
                opacity: llegada,
                child: Transform.scale(scale: presion, child: const _Mano()),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Mano extends StatelessWidget {
  const _Mano();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: const BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.touch_app_rounded,
        size: 17,
        color: AppColors.primaryDark,
      ),
    );
  }
}
