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

## 📏 Reglas de Programación y Desarrollo

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
   cp android/app/google-services.example.json android/app/google-services.json
   ```

2. Crea un proyecto en la [consola de Firebase](https://console.firebase.google.com/)

3. Reemplaza los valores de marcador por tus propias claves de API:
   - En `lib/firebase_options.dart`: Actualiza las opciones de configuración de Firebase
   - En `android/app/google-services.json`: Descarga este archivo de tu proyecto Firebase
   - Para iOS, descarga el archivo `GoogleService-Info.plist` desde Firebase

**Nunca compartas ni subas tus claves API a repositorios públicos.**

## 📄 Licencia

Este proyecto está bajo la licencia MIT.

---

Desarrollado con ❤️ para ayudar a los niños a crecer con confianza y autonomía.
