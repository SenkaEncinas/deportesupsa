/// TEMPORAL — sacar cuando ya no haga falta.
///
/// Número de actualización que se muestra en el pie de las pantallas
/// públicas. Sirve para una sola cosa: mirar el footer y saber si lo que
/// está sirviendo Netlify ya trae el último cambio, o si el navegador
/// sigue mostrando una versión vieja de caché.
///
/// Se sube A MANO en cada cambio que se vaya a desplegar. Si el número
/// del sitio no coincide con el de acá, el deploy todavía no salió.
///
/// Para sacarlo: borrar este archivo y el bloque `_NumeroActualizacion`
/// de `app_public_footer.dart`.
library;

/// Se incrementa de a uno en cada cambio desplegado.
const int kNumeroActualizacion = 2;

/// Fecha del cambio, para ubicarlo rápido.
const String kFechaActualizacion = '21/09/2026';

/// Qué entró en esta actualización, en pocas palabras.
const String kNotaActualizacion = 'orden del cuadro corregido';
