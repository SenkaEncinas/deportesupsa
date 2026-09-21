/// Armado de la llave eliminatoria: qué cruce juega contra cuál y en qué
/// orden se dibuja cada ronda.
///
/// La regla es la misma en todas las rondas y es la del cuadro de la
/// Copa UPSA: **la llave `i` se cruza con la llave `n + 1 - i`**.
///
/// En octavos eso da la siembra clásica sobre los clasificados:
///
///     1 vs 16 → llave 1        5 vs 12 → llave 5
///     2 vs 15 → llave 2        6 vs 11 → llave 6
///     3 vs 14 → llave 3        7 vs 10 → llave 7
///     4 vs 13 → llave 4        8 vs  9 → llave 8
///
/// Y la misma regla, aplicada ahora sobre los números de llave, define
/// las rondas siguientes:
///
///     Cuartos:    1 vs 8, 2 vs 7, 3 vs 6, 4 vs 5
///     Semifinal:  1 vs 4, 2 vs 3
///     Final:      1 vs 2
///
/// Lo importante de este esquema es que el 1° y el 2° de la tabla solo
/// se pueden encontrar en la final, el 1° y el 3° recién en semifinales,
/// etc.: terminar mejor la fase de grupos vale. El bug que arrastraba la
/// app era cruzar la llave 1 con la llave 2 en cuartos, o sea mandar al
/// 1° contra el 2° apenas pasaban la primera ronda.
library;

/// Clave de cada ronda. Se guarda en el partido (`rondaLlave`) para no
/// tener que deducir la ronda contando partidos.
class RondaLlave {
  static const String treintaidosavos = 'treintaidosavos';
  static const String dieciseisavos = 'dieciseisavos';
  static const String octavos = 'octavos';
  static const String cuartos = 'cuartos';
  static const String semifinal = 'semifinal';
  static const String finalRonda = 'final';

  /// Clave de la ronda que tiene [cantidadPartidos] cruces.
  static String porCantidadDePartidos(int cantidadPartidos) {
    switch (cantidadPartidos) {
      case 1:
        return finalRonda;
      case 2:
        return semifinal;
      case 4:
        return cuartos;
      case 8:
        return octavos;
      case 16:
        return dieciseisavos;
      case 32:
        return treintaidosavos;
      default:
        return 'llaves';
    }
  }

  /// Nombre para mostrar de una clave de ronda.
  static String nombre(String clave) {
    switch (clave) {
      case finalRonda:
        return 'Final';
      case semifinal:
        return 'Semifinales';
      case cuartos:
        return 'Cuartos de final';
      case octavos:
        return 'Octavos de final';
      case dieciseisavos:
        return 'Dieciseisavos de final';
      case treintaidosavos:
        return 'Treintaidosavos de final';
      default:
        return 'Llaves';
    }
  }

  /// Qué tan avanzada está la ronda: 0 es la primera que se juega y el
  /// número crece hasta la final. Sirve para ordenar las rondas sin
  /// depender de la jornada.
  static int orden(String clave) {
    switch (clave) {
      case treintaidosavos:
        return 0;
      case dieciseisavos:
        return 1;
      case octavos:
        return 2;
      case cuartos:
        return 3;
      case semifinal:
        return 4;
      case finalRonda:
        return 5;
      default:
        return -1;
    }
  }
}

/// Un cruce de la llave, ya ubicado en su ronda.
///
/// En la primera ronda el cruce se define por siembra ([siembraLocal] y
/// [siembraVisitante] son puestos de la tabla de clasificados, 1 = mejor
/// clasificado). En las rondas siguientes se define por los ganadores de
/// la ronda anterior ([vieneDeLocal] y [vieneDeVisitante] son números de
/// llave de esa ronda anterior).
class CruceLlave {
  /// Clave de ronda (ver [RondaLlave]).
  final String ronda;

  /// 0 para la primera ronda de la llave, y va creciendo hasta la final.
  /// Se guarda como `jornada` del partido para que el fixture ordene las
  /// rondas solo.
  final int rondaIndice;

  /// Número de llave dentro de la ronda (1..n), igual que en el cuadro.
  final int llave;

  /// Posición de arriba hacia abajo al dibujar la llave. No coincide con
  /// [llave]: el dibujo se ordena para que cada cruce quede pegado a los
  /// dos de los que sale, y así los conectores no se crucen.
  final int ordenVisual;

  final int? siembraLocal;
  final int? siembraVisitante;
  final int? vieneDeLocal;
  final int? vieneDeVisitante;

  const CruceLlave({
    required this.ronda,
    required this.rondaIndice,
    required this.llave,
    required this.ordenVisual,
    this.siembraLocal,
    this.siembraVisitante,
    this.vieneDeLocal,
    this.vieneDeVisitante,
  });

  /// Primera ronda: los equipos salen de la siembra, no de un ganador.
  bool get esPrimeraRonda => rondaIndice == 0;
}

/// Utilidades de la llave eliminatoria.
class Llaves {
  Llaves._();

  /// Potencia de 2 igual o inmediatamente mayor a [cantidad]. Es el
  /// tamaño real del cuadro: con 12 clasificados el cuadro es de 16 y
  /// los 4 mejores pasan directo de ronda.
  static int tamanoCuadro(int cantidad) {
    if (cantidad < 2) return 0;

    var tamano = 2;
    while (tamano < cantidad) {
      tamano *= 2;
    }
    return tamano;
  }

  /// `true` si [n] es potencia de 2: un cuadro de ese tamaño no deja a
  /// nadie libre en la primera ronda.
  static bool esPotenciaDeDos(int n) => n > 0 && (n & (n - 1)) == 0;

  /// Orden de dibujo de las llaves de una ronda de [cantidadLlaves]
  /// cruces, de arriba hacia abajo.
  ///
  /// Cada llave de una ronda se abre en las dos que la alimentan, de
  /// modo que dos cruces vecinos del dibujo son siempre los que se
  /// juntan en la ronda siguiente y las líneas no se cruzan.
  ///
  /// La última llave de cada columna se abre al revés a propósito: así
  /// la llave 2 queda siempre al pie del cuadro y el 1° y el 2° de la
  /// tabla arrancan en extremos opuestos, como en el cuadro dibujado a
  /// mano. Con 8 llaves el orden es `[1, 8, 4, 5, 3, 6, 7, 2]`:
  ///
  ///     llave 1 (1-16)  ┐
  ///     llave 8 (8-9)   ┴─ cuartos 1
  ///     llave 4 (4-13)  ┐
  ///     llave 5 (5-12)  ┴─ cuartos 4
  ///     llave 3 (3-14)  ┐
  ///     llave 6 (6-11)  ┴─ cuartos 3
  ///     llave 7 (7-10)  ┐
  ///     llave 2 (2-15)  ┴─ cuartos 2
  static List<int> ordenVisual(int cantidadLlaves) {
    if (cantidadLlaves <= 1) return const [1];
    if (cantidadLlaves == 2) return const [1, 2];

    final anterior = ordenVisual(cantidadLlaves ~/ 2);
    final orden = <int>[];

    for (var i = 0; i < anterior.length; i++) {
      final llave = anterior[i];
      final espejo = cantidadLlaves + 1 - llave;

      // La de más abajo va invertida para que el 2 siga siendo el
      // último de la columna ronda tras ronda.
      if (i == anterior.length - 1) {
        orden.add(espejo);
        orden.add(llave);
      } else {
        orden.add(llave);
        orden.add(espejo);
      }
    }

    return orden;
  }

  /// La estructura completa del cuadro para [cantidadClasificados]
  /// equipos: todas las rondas, desde la primera hasta la final.
  ///
  /// Si los clasificados no son potencia de 2, el cuadro se completa
  /// hasta la potencia de 2 siguiente y las siembras sobrantes quedan
  /// vacías: ese cruce es un "libre" y el equipo pasa directo.
  static List<CruceLlave> estructura(int cantidadClasificados) {
    final tamano = tamanoCuadro(cantidadClasificados);
    if (tamano < 2) return const [];

    final cruces = <CruceLlave>[];

    var cantidadLlaves = tamano ~/ 2;
    var rondaIndice = 0;

    while (cantidadLlaves >= 1) {
      final ronda = RondaLlave.porCantidadDePartidos(cantidadLlaves);
      final orden = ordenVisual(cantidadLlaves);

      for (var llave = 1; llave <= cantidadLlaves; llave++) {
        // El rival de la llave i es siempre la llave (o la siembra)
        // que está a la misma distancia del otro extremo.
        final espejo = (rondaIndice == 0 ? tamano : cantidadLlaves * 2) +
            1 -
            llave;

        cruces.add(
          CruceLlave(
            ronda: ronda,
            rondaIndice: rondaIndice,
            llave: llave,
            ordenVisual: orden.indexOf(llave),
            siembraLocal: rondaIndice == 0 ? llave : null,
            siembraVisitante: rondaIndice == 0 ? espejo : null,
            vieneDeLocal: rondaIndice == 0 ? null : llave,
            vieneDeVisitante: rondaIndice == 0 ? null : espejo,
          ),
        );
      }

      if (cantidadLlaves == 1) break;

      cantidadLlaves = cantidadLlaves ~/ 2;
      rondaIndice++;
    }

    return cruces;
  }

  /// Número de llave de la ronda siguiente al que pasa el ganador de la
  /// llave [llave], en una ronda de [cantidadLlaves] cruces. Devuelve
  /// `null` si [llave] es la final y ya no hay ronda siguiente.
  ///
  /// Como la llave `i` juega contra la `n + 1 - i` y las dos caen en el
  /// mismo cruce, el destino es la menor de las dos.
  static int? llaveSiguiente({
    required int llave,
    required int cantidadLlaves,
  }) {
    if (cantidadLlaves <= 1) return null;

    final espejo = cantidadLlaves + 1 - llave;
    return llave < espejo ? llave : espejo;
  }

  /// Texto para el equipo todavía sin definir de un cruce: "Ganador
  /// llave 8". Es lo que se muestra en el cuadro mientras la ronda
  /// anterior no se terminó de jugar.
  static String pendiente(int? vieneDeLlave) {
    if (vieneDeLlave == null) return 'Por definir';
    return 'Ganador llave $vieneDeLlave';
  }
}
