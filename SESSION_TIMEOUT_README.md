# Sistema de Detección de Inactividad y Cierre de Sesión (RASP)

## Objetivo
Implementar un mecanismo global de monitoreo de inactividad que cierre automáticamente la sesión después de un período sin interacción del usuario, previniendo el secuestro de sesión (Session Hijacking).

## Archivos Implementados

### 1. `lib/services/session_timeout_service.dart`
- **SessionTimeoutService**: Clase que gestiona el temporizador de inactividad.
  - `timeoutSeconds`: Variable configurable (15 segundos para pruebas, 300 para producción).
  - `startTimer()`: Inicia el temporizador con un callback.
  - `resetOnInteraction()`: Reinicia el temporizador cuando detecta actividad.
  - `dispose()`: Limpia el temporizador.
- **sessionTimeoutProvider**: Proveedor Riverpod que expone el servicio.

### 2. `lib/widgets/global_activity_listener.dart`
- **GlobalActivityListener**: Widget que escucha eventos globales de interacción:
  - `Listener` con `onPointerDown` y `onPointerMove` para detectar toques.
  - `GestureDetector` con callbacks de tap y drag para desplazamientos.
  - `Focus` con `onKey` para detectar pulsaciones de teclado.
- Se reinicia el temporizador en cada interacción.

### 3. `lib/main.dart` (actualizado)
- **ProviderScope**: Envuelve la app para habilitar Riverpod.
- **GlobalActivityListener**: Envuelve MaterialApp para monitoreo global.
- **SessionTimeoutWrapper**: StatefulWidget que inicializa el temporizador y maneja el cierre.
- **navigatorKey**: GlobalKey para controlar la navegación al expirar la sesión.
- **_handleSessionExpired()**: Muestra un AlertDialog persistente y redirige al login.
- **_performLogout()**: Limpia el historial de navegación con `pushAndRemoveUntil`.

## Flujo de Funcionamiento

1. **Inicio**: La app inicia con `SessionTimeoutWrapper` que llama a `sessionTimeout.startTimer()`.
2. **Temporizador Activo**: Cada segundo sin interacción cuenta hacia la expiración (15 segundos por defecto).
3. **Interacción Detectada**: Cualquier toque, scroll o tecla reinicia el temporizador.
4. **Expiración**: Cuando no hay actividad durante el período configurado:
   - Se muestra un `AlertDialog` notificando la expiración.
   - Al aceptar, se limpia toda la pila de navegación.
   - El usuario es redirigido al `LoginScreen`.
5. **Logout Limpio**: La función `_performLogout()` utiliza `pushAndRemoveUntil` para borrar el historial, impidiendo navegar hacia atrás con el botón físico.

## Configuración

### Cambiar el tiempo de inactividad:
En `lib/services/session_timeout_service.dart`, modifica:
```dart
static const int timeoutSeconds = 15; // Cambiar a 300 para 5 minutos en producción
```

### Desactivar el sistema (desarrollo):
Comenta la inicialización en `lib/main.dart`:
```dart
// sessionTimeout.startTimer(_handleSessionExpired);
```

## Pruebas

### Prueba en modo debug:
```bash
flutter run -d <device-id>
```

1. Abre la app y navega a una pantalla.
2. No interactúes durante 15 segundos.
3. Aparecerá un diálogo indicando que la sesión expiró.
4. Al aceptar, serás redirigido al login sin poder regresar con "Atrás".

### Prueba de reinicio del temporizador:
1. Abre la app y espera 10 segundos.
2. Toca la pantalla (reinicia el temporizador a 15 segundos).
3. Espera 10 segundos más.
4. El diálogo no debe aparecer (el temporizador fue reiniciado).

## Consideraciones de Seguridad

- **Lógica Global**: El monitoreo es global y no requiere código adicional en cada pantalla.
- **Cierre Limpio**: La función `pushAndRemoveUntil` garantiza que el historio se borra completamente.
- **Notificación Persistente**: El `AlertDialog` es no-dismissible (`barrierDismissible: false`) para garantizar que el usuario vea la notificación.
- **Manejo de Errores**: Si falla la navegación, se capturan excepciones y se continúa de forma segura.

## Dependencias Agregadas

- **flutter_riverpod ^2.4.0**: Gestor de estado reactivo para manejar el temporizador globalmente.

## Notas Adicionales

- Para entornos de producción, se recomienda aumentar `timeoutSeconds` a 300 (5 minutos) o según requisitos de seguridad.
- El sistema puede extenderse para enviar eventos de auditoría o telemetría cuando expire una sesión.
- Se integra perfectamente con el módulo `SecurityWrapper` existente que bloquea por modo desarrollador/ADB.
