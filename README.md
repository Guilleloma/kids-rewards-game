# Juego de Recompensas Infantil

Una aplicación móvil educativa diseñada para ayudar a los niños a adquirir hábitos, reforzar su autonomía, superar pequeños retos emocionales y construir autoestima mediante un sistema de misiones, puntos y recompensas semanales.

## 🌟 Características

- **Sistema de misiones personalizables** (Retos Diarios, Ayudas Especiales, Misiones de Valiente)
- **Recompensas y monedas** que motivan a los niños a cumplir sus objetivos
- **Ciclos semanales** para seguimiento del progreso
- **Interfaz dual**: una para padres (configuración) y otra para niños (visual y simplificada)
- **Totalmente personalizable**: imágenes propias para cada misión
- **Multiplataforma**: funciona en iOS, Android y Web

## 📱 Pantallas principales

### Para padres
- **Dashboard**: Resumen del progreso semanal
- **Gestión de misiones**: Crear, editar y organizar misiones
- **Gestión de recompensas**: Configurar premios y superpremios
- **Configuración**: Personalización de perfiles y ajustes

### Para niños
- **Página de misiones**: Visual y adaptada para niños
- **Catálogo de premios**: Muestra lo que pueden desbloquear

## 🛠️ Tecnologías utilizadas

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Gestión de estado**: Riverpod
- **Internacionalización**: easy_localization

## 🚀 Empezando

### Requisitos previos

- Flutter (última versión estable)
- Firebase CLI
- Una cuenta de Firebase

### Configuración

1. Clona este repositorio:
```bash
git clone https://github.com/tu-usuario/kids_rewards_game.git
cd kids_rewards_game
```

2. Instala las dependencias:
```bash
flutter pub get
```

3. Configura Firebase:
   - Crea un proyecto en la [consola de Firebase](https://console.firebase.google.com/)
   - Añade aplicaciones iOS, Android y Web (usa el mismo bundle ID de tu proyecto Flutter)
   - Descarga los archivos de configuración:
     - `GoogleService-Info.plist` para iOS
     - `google-services.json` para Android
     - Para Web, copia los valores de configuración al archivo `firebase_options.dart`
   - Configura Firebase en tu proyecto:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   - Para Web, asegúrate de que el archivo `web/index.html` incluya los scripts de Firebase:
   ```html
   <!-- Firebase Core JS SDK -->
   <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-app.js"></script>
   
   <!-- Add Firebase products that you want to use -->
   <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-auth.js"></script>
   <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-firestore.js"></script>
   <script src="https://www.gstatic.com/firebasejs/9.6.10/firebase-storage.js"></script>
   ```

4. Ejecuta la aplicación:
```bash
flutter run
```

## 📊 Estructura del proyecto

```
lib/
 ├─ main.dart              # Punto de entrada de la aplicación
 ├─ models/                # Modelos de datos
 ├─ providers/             # Providers de Riverpod para estado
 ├─ screens/               # Pantallas de la aplicación
 │   ├─ onboarding/        # Pantallas de inicio y registro
 │   ├─ parent/            # Pantallas para padres
 │   └─ child/             # Pantallas para niños
 ├─ services/              # Servicios (Firebase, etc.)
 ├─ widgets/               # Widgets reutilizables
 └─ l10n/                  # Archivos de internacionalización
```

## 🌐 Internacionalización

La aplicación está disponible en:
- Español
- Inglés

## 🎨 Principios UX/UI

### Principios Heurísticos de Nielsen
Este proyecto sigue las 10 heurísticas de usabilidad de Nielsen:

1. **Visibilidad del estado del sistema**: El usuario siempre debe saber qué está sucediendo a través de retroalimentación adecuada.
   - Uso de indicadores de carga
   - Mensajes de error claros y específicos
   - Confirmación de acciones exitosas

2. **Coincidencia entre el sistema y el mundo real**: La interfaz debe hablar el lenguaje del usuario y seguir convenciones del mundo real.
   - Uso de metáforas familiares para niños (monedas, premios)
   - Terminología apropiada para cada grupo de usuario (niños vs. adultos)

3. **Control y libertad del usuario**: Permitir "salidas de emergencia" para acciones no deseadas.
   - Botones de cancelar en todas las acciones importantes
   - Opción para deshacer acciones recientes

4. **Consistencia y estándares**: Seguir convenciones establecidas para no confundir al usuario.
   - Sistema de colores coherente
   - Patrones de interacción consistentes en toda la aplicación

5. **Prevención de errores**: Mejor que buenos mensajes de error es un diseño que prevenga problemas.
   - Validación de formularios en tiempo real
   - Confirmación antes de acciones destructivas

6. **Reconocimiento antes que recuerdo**: Minimizar la carga de memoria del usuario.
   - Elementos visibles y reconocibles
   - Navegación clara e intuitiva

7. **Flexibilidad y eficiencia de uso**: Aceleradores para usuarios avanzados.
   - Atajos para tareas frecuentes
   - Personalización de la experiencia

8. **Estética y diseño minimalista**: Diálogos sin información irrelevante.
   - Interfaz limpia y sin distracciones
   - Enfoque en lo esencial

9. **Ayudar a reconocer, diagnosticar y recuperarse de errores**: Mensajes de error claros.
   - Indicación exacta del problema
   - Sugerencia de solución cuando sea posible

10. **Ayuda y documentación**: Aunque es mejor que el sistema se use sin documentación, puede ser necesario proporcionar ayuda.
    - Tutoriales incorporados
    - Consejos contextuales

### Gestión de Errores para el Usuario
Todos los errores en la aplicación deben:

1. **Ser específicos**: Explicar qué ha ocurrido exactamente.
2. **Ofrecer orientación**: Indicar cómo solucionar el problema.
3. **Usar lenguaje amigable**: Evitar términos técnicos confusos.
4. **Ser visualmente claros**: Destacar sin ser alarmistas.
5. **Permitir recuperación**: Ofrecer acciones para resolver el error.

Ejemplos de implementación:
- Errores de autenticación con instrucciones claras
- Problemas de conectividad con opciones para reintentar
- Validación de formularios con retroalimentación inmediata

## 🤝 Filosofía del diseño

- **Sin etiquetas negativas**: No hay tareas "fáciles" o "difíciles"
- **Lenguaje positivo y motivador**
- **Sin castigos**: Solo refuerzos positivos
- **Personalización**: Adaptado a cada niño
- **Diseño centrado en emociones**: Para construir autoestima

## 📝 Notas para desarrolladores

### Modelo de datos

- **users**: Información del adulto y niño
- **tasks**: Misiones configuradas por categorías
- **rewards**: Premios configurados por tipos
- **weeks**: Ciclos semanales con progreso

## 📐 Reglas de Programación y Desarrollo

### 🧱 Estructura Modular del Código (Flutter)
```
lib/
├── models/     # Modelos de datos
├── screens/    # Pantallas/vistas de la aplicación
├── widgets/    # Componentes reutilizables
├── services/   # Servicios (Firebase, API, etc.)
├── providers/  # Providers de estado (Riverpod)
├── utils/      # Utilidades y helpers
├── l10n/       # Internacionalización
```

### 🌳 Estrategia Git
- **Trunk-based development**
- Ramas: `trunk`, `development`, `feature/*`
- Merges sin `--ff`
- Convenciones de commits:
  - `[Feature]`: Nueva funcionalidad
  - `[Fix]`: Corrección de errores
  - `[Docs]`: Documentación
  - `[Refactor]`: Refactorización
  - `[Test]`: Pruebas

### ♻️ Refactorización Progresiva
Refactor obligatorio cuando:
- Archivo > 300 líneas
- Clase > 200 líneas
- Función > 40 líneas o > 3 niveles de anidación
- Responsabilidad múltiple
- Duplicación de lógica o difícil testabilidad

### 🧪 Testing
- Unit tests con `flutter_test`
- Posible integración con GitHub Actions
- Código limpio, testeable y escalable

### 📐 Principios SOLID aplicados
- **S**: Separación de responsabilidades
- **O**: Extensible sin modificar código base
- **L**: Sustituibilidad sin efectos colaterales
- **I**: Interfaces específicas para cada caso
- **D**: Inyección de dependencias

### 🔍 Sistema de Logging y Depuración

El proyecto implementa un sistema de logs estructurado para facilitar la depuración y el diagnóstico de problemas:

#### Principios de Logging
1. **Logs en puntos clave**: Cada flujo importante (autenticación, operaciones de escritura/lectura, cambios de estado) debe incluir logs en puntos estratégicos.
2. **Niveles de log diferenciados**: 
   - `verbose`: Detalles extensos (solo desarrollo)
   - `debug`: Información para debugging
   - `info`: Eventos normales y significativos
   - `warning`: Situaciones no críticas pero inesperadas
   - `error`: Errores recuperables
   - `wtf`: Errores críticos/irrecuperables

#### Utilidad para Desarrolladores
- **Panel de logs (modo desarrollo)**: Interfaz visual que muestra logs en tiempo real
- **Filtrado por nivel**: Capacidad de mostrar solo los logs relevantes
- **Trazabilidad de procesos**: Cada flujo importante tiene un ID rastreable en logs

#### Buenas Prácticas
- Incluir logs ANTES y DESPUÉS de operaciones críticas
- Registrar intentos fallidos con contexto suficiente para diagnóstico
- Capturar excepciones con mensaje amigable para usuario Y detalle técnico para logs
- Mantener consistencia en el formato y estructura de los mensajes

#### Ejemplos de Implementación

```dart
// Ejemplo de logging en proceso crítico
try {
  devLogger.log("Iniciando proceso X con parámetros: $params", level: LogLevel.info);
  
  // Operación crítica
  final result = await someService.criticalOperation();
  
  devLogger.log("Proceso X completado exitosamente", level: LogLevel.info);
  return result;
} catch (e) {
  devLogger.log("Error en proceso X: $e", level: LogLevel.error);
  throw CustomException("Mensaje amigable para usuario", originalError: e);
}
```

## 🔒 Seguridad

### Archivos de configuración sensibles

Este proyecto utiliza Firebase, que requiere archivos de configuración con claves API:

- `lib/firebase_options.dart` para la configuración general
- `android/app/google-services.json` para la configuración de Android
- `ios/Runner/GoogleService-Info.plist` para la configuración de iOS

**⚠️ Estos archivos no se incluyen en el repositorio por razones de seguridad.**

### Configuración de archivos sensibles

Antes de ejecutar el proyecto:

1. Copia los archivos de ejemplo y renómbralos:
   ```bash
   cp lib/firebase_options.example.dart lib/firebase_options.dart
   cp env.example .env
   cp android/app/google-services.example.json android/app/google-services.json
   ```

2. Configura el archivo `.env` con tus credenciales de Firebase:
   ```
   FIREBASE_API_KEY=your_api_key_here
   FIREBASE_APP_ID=your_app_id_here
   FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id_here
   FIREBASE_PROJECT_ID=your_project_id_here
   FIREBASE_AUTH_DOMAIN=your_auth_domain_here
   FIREBASE_STORAGE_BUCKET=your_storage_bucket_here
   FIREBASE_MEASUREMENT_ID=your_measurement_id_here
   ```
   
   Estas variables se cargan automáticamente en la aplicación mediante el paquete `flutter_dotenv`.

3. Crea un proyecto en la [consola de Firebase](https://console.firebase.google.com/) si aún no lo has hecho.

4. Obtén las credenciales necesarias desde la consola de Firebase:
   - En la sección "Configuración del proyecto" > "Tus aplicaciones" > "Web"
   - Copia los valores de configuración a tu archivo `.env`
   - Para Android e iOS, descarga los archivos de configuración correspondientes

5. Asegúrate de que `.env` y `firebase_options.dart` estén incluidos en tu `.gitignore` para no exponer tus credenciales.

**Nunca compartas ni subas tus claves API a repositorios públicos.**

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

Desarrollado con ❤️ para ayudar a los niños a crecer con confianza y autonomía.
