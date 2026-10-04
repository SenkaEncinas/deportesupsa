import '../models/campeonato_model.dart';
import '../models/equipo_model.dart';
import '../models/partido_model.dart';
import '../models/ranking_goleador_model.dart';
import '../models/tabla_posicion_model.dart';
import '../utils/stream_compartido.dart';
import 'public_home_service.dart';

/// Todo lo que muestra la página pública de un campeonato, con una sola
/// conexión por dato: el campeonato, sus equipos, sus partidos y el
/// ranking. La tabla, los próximos partidos y los últimos resultados se
/// calculan a partir de esas mismas fuentes.
///
/// Antes cada sección abría sus propias consultas (los partidos, cinco
/// veces), y cada redibujado las reabría. La pantalla crea uno de estos
/// al abrirse y lo cierra al salir.
class DatosCampeonato {
  DatosCampeonato(PublicHomeService service, String campeonatoId)
    : _campeonato = StreamCompartido(
        () => service.streamCampeonato(campeonatoId),
      ),
      _equipos = StreamCompartido(() => service.streamEquipos(campeonatoId)),
      _partidos = StreamCompartido(() => service.streamPartidos(campeonatoId)),
      _ranking = StreamCompartido(
        () => service.streamRankingGoleadores(campeonatoId),
      );

  final StreamCompartido<CampeonatoModel?> _campeonato;
  final StreamCompartido<List<EquipoModel>> _equipos;
  final StreamCompartido<List<PartidoModel>> _partidos;
  final StreamCompartido<List<RankingGoleadorModel>> _ranking;

  late final StreamCompartido<List<TablaPosicionModel>> _tabla =
      StreamCompartido(
        () => PublicHomeService.tablaDesde(
          _campeonato.stream,
          _equipos.stream,
          _partidos.stream,
        ),
      );

  Stream<List<EquipoModel>> get equipos => _equipos.stream;
  Stream<List<PartidoModel>> get partidos => _partidos.stream;
  Stream<List<RankingGoleadorModel>> get ranking => _ranking.stream;
  Stream<List<TablaPosicionModel>> get tabla => _tabla.stream;

  late final Stream<List<PartidoModel>> proximos = partidos.map(
    (lista) => PublicHomeService.proximos(lista, DateTime.now()),
  );

  late final Stream<List<PartidoModel>> ultimosResultados = partidos.map(
    PublicHomeService.ultimosResultados,
  );

  Future<void> cerrar() async {
    await _tabla.cerrar();
    await _campeonato.cerrar();
    await _equipos.cerrar();
    await _partidos.cerrar();
    await _ranking.cerrar();
  }
}
