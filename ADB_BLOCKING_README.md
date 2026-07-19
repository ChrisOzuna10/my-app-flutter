Prueba de bloqueo por Depuración USB (ADB)

Resumen:
Esta aplicación detecta si la Depuración USB (ADB) está activa en Android y bloquea la ejecución mostrando un diálogo obligatorio y cerrando la app.

Pasos para probar:
1. Asegúrate de ejecutar la app en modo Release o en un APK firmado. (La verificación no se aplica en `kDebugMode` a menos que la fuerces).

   - Ejecutar en release: `flutter run --release -d <device-id>`
   - Construir APK: `flutter build apk --release`

Forzar la comprobación en modo debug (útil para pruebas):

   - Ejecutar en debug forzando la comprobación: `flutter run -d <device-id> --dart-define=FORCE_ADB_CHECK=true`

   - La app lee la constante `FORCE_ADB_CHECK` y activará la verificación incluso estando en modo debug.

2. En el dispositivo Android entra a Ajustes → Opciones de desarrollador y activa "Depuración USB" o activa las "Opciones de desarrollador".
   - Nota: la app ahora bloquea si las Opciones de desarrollador están activadas o si la Depuración USB está activa.
   - Comportamiento dinámico: la app escucha cambios en la configuración del sistema. Si desactivas las Opciones de desarrollador/Depuración USB mientras la aplicación está abierta, el diálogo se cerrará automáticamente y el usuario podrá continuar sin reiniciar la app. Si activas las Opciones de desarrollador/Depuración USB mientras la app está abierta, la app mostrará el diálogo y bloqueará el acceso inmediatamente.
3. Abre la app en el dispositivo.

Resultado esperado:
- La app detectará que ADB está activo y mostrará un `AlertDialog` persistente explicando que la aplicación no puede ejecutarse con Depuración USB activada.
- Al pulsar "Cerrar aplicación" la app terminará de forma limpia.

Notas de depuración:
- Se han añadido `debugPrint` en Flutter y `Log` en Android para facilitar la observación de la comprobación cuando se ejecuta en entornos donde están disponibles los logs.
- Si la comprobación falla por cualquier excepción, la app no bloqueará por seguridad (falla abierto) para evitar denegar servicio por error.

Recomendación de seguimiento:
- Para entornos de producción, considerar reporte de auditoría o métricas cuando se produzca un bloqueo por seguridad.