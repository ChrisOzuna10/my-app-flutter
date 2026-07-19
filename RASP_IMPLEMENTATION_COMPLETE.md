# Implementación Integral de RASP: Bloqueo por ADB y Timeout de Sesión

## Resumen General
Se ha implementado un sistema integral de **Runtime Application Self-Protection (RASP)** en la aplicación Flutter que incluye:
1. **Bloqueo por Modo Desarrollador/ADB** (detecta y bloquea ejecución si ADB está activo)
2. **Detección de Inactividad** (cierre automático de sesión tras período sin interacción)

---

## Módulo 1: Bloqueo por Modo Desarrollador / ADB

### Ubicación de Archivos
- `lib/features/security/security_wrapper.dart` - Widget wrapper que contiene la lógica de verificación
- `android/app/src/main/kotlin/com/example/my_app/MainActivity.kt` - Código nativo que consulta Settings.Global

### Características
- ✅ Detecta `Settings.Global.ADB_ENABLED` (Depuración USB)
- ✅ Detecta `Settings.Global.DEVELOPMENT_SETTINGS_ENABLED` (Opciones de desarrollador)
- ✅ Monitoreo en tiempo real mediante ContentObserver nativo
- ✅ Sondeo periódico como respaldo (cada 1 segundo)
- ✅ Diálogo persistente (no descartable) cuando se detecta activación
- ✅ Cierre automático del diálogo al desactivar desde ajustes (sin salir de la app)

### Comportamiento Actual
**DESHABILITADO**: La verificación está comentada en `initState()` de `SecurityWrapper` para permitir desarrollo sin restricciones.

Para reactivar:
```dart
// En lib/features/security/security_wrapper.dart, línea ~30:
_checkAdbAndBlockIfNeeded();  // Descomenta esta línea
```

### Prueba en Modo Release
```bash
flutter run --release -d <device-id>
# Activa ADB en Ajustes → Opciones de desarrollador → Depuración USB
# La app bloqueará el acceso
```

---

## Módulo 2: Detección de Inactividad y Cierre de Sesión

### Ubicación de Archivos
- `lib/services/session_timeout_service.dart` - Servicio de temporizador
- `lib/widgets/global_activity_listener.dart` - Widget listener global
- `lib/main.dart` - Integración principal con Riverpod

### Características
- ✅ Monitoreo global de interacciones (taps, scrolls, teclado)
- ✅ Temporizador configurable (15 segundos para pruebas, 300 para producción)
- ✅ Reinicio automático del temporizador en cada interacción
- ✅ AlertDialog persistente notificando expiración
- ✅ Cierre limpio de sesión con `pushAndRemoveUntil` (borra historial)
- ✅ Redirección a LoginScreen

### Configuración del Timeout
En `lib/services/session_timeout_service.dart`:
```dart
static const int timeoutSeconds = 15; // Cambiar a 300 para 5 minutos
```

### Arquitectura
1. **ProviderScope** (Riverpod) envuelve la app
2. **GlobalActivityListener** escucha eventos globales
3. **SessionTimeoutWrapper** gestiona el ciclo de vida del temporizador
4. **navigatorKey** permite navegar desde callbacks

### Prueba en Modo Debug
```bash
flutter run -d <device-id>
```

1. Abre la app y accede a una pantalla cualquiera
2. No interactúes durante 15 segundos
3. Aparecerá un diálogo: "Su sesión ha expirado por inactividad"
4. Al aceptar, serás redirigido al LoginScreen sin poder usar "Atrás"

### Reinicio del Temporizador
```dart
// En global_activity_listener.dart:
final sessionTimeout = ref.read(sessionTimeoutProvider);
sessionTimeout.resetOnInteraction();  // Reinicia a 15 segundos
```

---

## Dependencias Agregadas
```yaml
flutter_riverpod: ^2.4.0
```

---

## Flujo de Seguridad Integrado

```
App Inicia
    ↓
[1] SecurityWrapper verifica ADB (comentado actualmente)
    ↓ (si ADB activo → bloquea)
    ↓ (si ADB inactivo → continúa)
[2] SessionTimeoutWrapper inicia temporizador (15 seg)
    ↓
GlobalActivityListener escucha eventos
    ↓
Usuario interactúa (tap/scroll/tecla)
    ↓
Temporizador reinicia (15 seg más)
    ↓
Si 15 segundos sin interacción:
    ↓
AlertDialog: "Sesión expirada"
    ↓
Al aceptar:
    - Historial borrado
    - Redirigido a LoginScreen
    - No puede volver con "Atrás"
```

---

## Configuración para Producción

### Seguridad de ADB (reactivar bloqueo)
En `lib/features/security/security_wrapper.dart`:
```dart
// Descomenta esta línea
_checkAdbAndBlockIfNeeded();
```

### Timeout de Sesión (aumentar a 5 minutos)
En `lib/services/session_timeout_service.dart`:
```dart
static const int timeoutSeconds = 300; // 5 minutos
```

### Build Release
```bash
flutter clean
flutter pub get
flutter build apk --release
# o
flutter build appbundle --release
```

---

## Pruebas Recomendadas

| Escenario | Pasos | Resultado Esperado |
|-----------|-------|-------------------|
| ADB Activo en Release | Ejecutar en release con ADB activo | Bloqueo inmediato |
| Desactivar ADB sin salir | Desactivar ADB mientras app abierta | Diálogo se cierra automáticamente |
| Timeout de 15 seg | No interactuar 15 segundos | Diálogo de expiración |
| Reinicio de timer | Tocar pantalla a los 10 seg | No expira (timer reiniciado) |
| Logout limpio | Expirar sesión y aceptar | No puede volver con atrás |

---

## Logs Útiles

```bash
# Ver logs de Flutter
flutter logs -d <device-id>

# Ver logs de Android nativo (ADB check)
adb logcat -s MainActivity

# Palabras clave a buscar:
# - "isDeviceInDevMode"
# - "SessionTimeoutService"
# - "onUserActivity"
```

---

## Consideraciones Finales

1. **Seguridad**: Ambos mecanismos se ejecutan sin requerer interacción del usuario
2. **UX**: El timeout de sesión es transparente hasta que expira
3. **Desarrollo**: Ambos pueden deshabilitarse comentando líneas específicas
4. **Producción**: Activar ambos para máxima protección
5. **Escalabilidad**: La arquitectura permite agregar más verificaciones sin modificar código existente

---

## Referencias Rápidas

- 📄 [ADB_BLOCKING_README.md](./ADB_BLOCKING_README.md) - Detalles del módulo ADB
- 📄 [SESSION_TIMEOUT_README.md](./SESSION_TIMEOUT_README.md) - Detalles del módulo Timeout
- 📄 [REPORTE_SEGURIDAD.md](./REPORTE_SEGURIDAD.md) - Primer reporte (módulo ADB)
- 📄 [REPORTE_SEGURIDAD.tex](./REPORTE_SEGURIDAD.tex) - Reporte en LaTeX
