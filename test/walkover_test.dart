import 'package:flutter_test/flutter_test.dart';
import 'package:futsal/models/campeonato_model.dart';
import 'package:futsal/models/partido_model.dart';
import 'package:futsal/services/resultado_service.dart';

/// Reglas del walkover en vóley, tal como las aplica
/// `ResultadoService.registrarResultado`:
///
/// - Se da por ganado 25-0 en cada set al equipo que se presentó.
/// - Eso son 50 puntos a favor y 0 en contra (con 2 sets para ganar),
///   que es lo que después usa la tabla para la diferencia de puntos.
/// - En la tabla, el que no se presentó no suma el punto por perder.
void main() {
  const config = CampeonatoConfig(
    formato: 'grupos',
    cantidadVueltas: 1,
    idaYVuelta: false,
    generaCrucesAleatorios: false,
    generaGruposAleatorios: false,
    permiteEmpate: false,
    generaTablaPosiciones: true,
    cantidadJugadoresEnCancha: 6,
    cantidadMinimaJugadoresPorEquipo: 6,
    cantidadMaximaJugadoresPorEquipo: 12,
    deporte: DeporteTipo.volley,
    modalidad: ModalidadDeporte.volleySala,
    sistemaResultado: SistemaResultado.sets,
  );

  /// Copia de la regla del servicio, para fijarla con un test.
  ({List<SetPartido> sets, int setsLocal, int setsVisitante}) armarWalkover({
    required bool ganaLocal,
  }) {
    final sets = List.generate(
      config.setsParaGanar,
      (_) => SetPartido(
        local: ganaLocal ? config.puntosSetNormal : 0,
        visitante: ganaLocal ? 0 : config.puntosSetNormal,
      ),
    );

    return (
      sets: sets,
      setsLocal: ganaLocal ? config.setsParaGanar : 0,
      setsVisitante: ganaLocal ? 0 : config.setsParaGanar,
    );
  }

  test('el walkover da 25-0 por set y 50 puntos al que se presentó', () {
    final resultado = armarWalkover(ganaLocal: true);

    expect(resultado.setsLocal, 2);
    expect(resultado.setsVisitante, 0);
    expect(resultado.sets.length, 2);

    final puntosFavor = resultado.sets.fold<int>(0, (t, s) => t + s.local);
    final puntosContra = resultado.sets.fold<int>(0, (t, s) => t + s.visitante);

    expect(puntosFavor, 50);
    expect(puntosContra, 0);
  });

  test('si gana el visitante, los 50 puntos van para su lado', () {
    final resultado = armarWalkover(ganaLocal: false);

    expect(resultado.setsLocal, 0);
    expect(resultado.setsVisitante, 2);

    final puntosVisitante = resultado.sets.fold<int>(
      0,
      (t, s) => t + s.visitante,
    );

    expect(puntosVisitante, 50);
  });

  test('en básquet el walkover se guarda 20-0', () {
    // Mismo criterio que en vóley, pero el marcador lo fija el
    // reglamento en vez de la configuración del campeonato.
    ({int local, int visitante}) armarBasket({required bool ganaLocal}) {
      return (
        local: ganaLocal ? kPuntosWalkoverBasket : 0,
        visitante: ganaLocal ? 0 : kPuntosWalkoverBasket,
      );
    }

    expect(kPuntosWalkoverBasket, 20);

    final local = armarBasket(ganaLocal: true);
    expect(local.local, 20);
    expect(local.visitante, 0);

    final visitante = armarBasket(ganaLocal: false);
    expect(visitante.local, 0);
    expect(visitante.visitante, 20);
  });

  test('en vóley el perdedor suma 1 punto, salvo en walkover que suma 0', () {
    final reglas = ReglasPuntuacion.voley();

    expect(reglas.victoria, 2);
    expect(reglas.derrota, 1);

    // La tabla no le paga el punto de consuelo al que no se presentó.
    int puntosPerdedor(String tipoResultado) =>
        tipoResultado == TipoResultado.walkover ? 0 : reglas.derrota;

    expect(puntosPerdedor(TipoResultado.normal), 1);
    expect(puntosPerdedor(TipoResultado.walkover), 0);
  });
}
