/// TEMPORAL — sacar cuando ya no haga falta.
///
/// Versión que se muestra, muy chica y descolorida, en la esquina
/// inferior derecha del pie público. No es para el usuario: sirve para
/// mirar el sitio y saber si ya está sirviendo el último deploy o si el
/// navegador sigue con una versión vieja en caché.
///
/// Se sube A MANO en cada cambio que se vaya a desplegar (normalmente
/// alcanza con mover el último número). Si lo que se ve en el sitio no
/// coincide con lo que dice acá, el deploy todavía no salió.
///
/// Para sacarlo: borrar este archivo y el bloque `_VersionDiscreta` de
/// `app_public_footer.dart`.
library;

const String kVersionApp = '1.2.1.8';
