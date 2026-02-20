[English](#english) | [Nederlands](#nederlands)

<a name="english"></a>

# Redivo App (English)

Redivo App is a Flutter-based mobile application for managing emergency interventions, featuring real-time maps, WebRTC audio calls, and AI support.

## Getting Started

Follow these steps to set up the project on a new machine where the source code is already present.

### 1. Prerequisites (Flutter Environment)

If you haven't set up Flutter before, you need to install the following:

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Use the _stable_ channel).
- **Java Development Kit (JDK)**: Version 11 or higher (Required for Android/APK builds).
- **Android SDK & Command-line Tools**: [Install via Android Studio](https://developer.android.com/studio) to enable building for Android.
- **Visual Studio Code / Android Studio**: Recommended IDEs with Flutter/Dart extensions.

### 2. Firebase Project Settings

To ensure the project works correctly, the following services must be activated in the [Firebase Console](https://console.firebase.google.com/):

1.  **Authentication**: Enable the desired login methods (e.g., Email/Password).
2.  **Firestore Database**: Create a database in 'Production' or 'Test mode' and set the appropriate rules.
3.  **Storage**: Activate Cloud Storage for storing files.

Make sure to register an **Android app** and a **Web app** in your Firebase project settings to obtain the necessary configuration data.

### 3. Configuration & Secrets (Required)

The project requires several API keys and Firebase configurations that are **not** included in the source code for security reasons.

1. **Setting Environment Variables**:
   - Locate `.env.example` in the root directory.
   - Create a copy named `.env`.
   - Fill in all 8 required values in the `.env` file:

| Variable                       | Where to find?                                                                   |
| :----------------------------- | :------------------------------------------------------------------------------- |
| `MAPBOX_ACCESS_TOKEN`          | [Mapbox Dashboard](https://account.mapbox.com/) -> Access Tokens                 |
| `GEMINI_API_KEY`               | [Google AI Studio](https://aistudio.google.com/app/apikey) -> Get API Key        |
| `FIREBASE_API_KEY`             | Firebase Console -> Project Settings -> General -> Your apps (apiKey)            |
| `FIREBASE_AUTH_DOMAIN`         | Firebase Console -> Project Settings -> General -> Your apps (authDomain)        |
| `FIREBASE_PROJECT_ID`          | Firebase Console -> Project Settings -> General -> Your apps (projectId)         |
| `FIREBASE_STORAGE_BUCKET`      | Firebase Console -> Project Settings -> General -> Your apps (storageBucket)     |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Console -> Project Settings -> General -> Your apps (messagingSenderId) |
| `FIREBASE_APP_ID`              | Firebase Console -> Project Settings -> General -> Your apps (appId)             |

> [!TIP]
> In the Firebase Console, you can find these values under the "Web app" configuration. If no web app exists, create one to see this SDK config snippet.

```bash
# Windows (PowerShell)
copy .env.example .env
```

> [!NOTE]
> The Firebase configuration in `lib/backend/firebase/firebase_config.dart` is now safe to commit because it uses these environment variables.

2. **Firebase Native Config (Optional but recommended)**:
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase Console.
   - Place `google-services.json` in `android/app/`.
   - Place `GoogleService-Info.plist` in `ios/Runner/`.
   - _Note: These files are now ignored by Git to prevent leaks._

### 4. Final Verification

Once Firebase and the configuration files are in order, run the following commands to confirm everything is set up correctly:

```bash
flutter doctor
flutter pub get
```

### 5. Running the Application

- **Android (Emulator or Device)**:
  ```bash
  flutter run
  ```

## Building the Android APK

Follow these steps to generate an APK that you can install on Android devices.

### 1. Preparation

Ensure all secrets in `.env` are correctly filled in and that the native configuration files are present if necessary.

### 2. Generate APK

Run the following command in the root directory to create a release APK:

```powershell
flutter build apk --release
```

### 3. File Location

Once the build is complete, you can find the APK file at:
`build/app/outputs/flutter-apk/app-release.apk`

---

_Note: Make sure you are connected to the internet during the first build, as Flutter needs to download dependencies and the Android toolchain._

---

<a name="nederlands"></a>

# Redivo App (Nederlands)

Redivo App is een op Flutter gebaseerde mobiele applicatie voor het beheren van noodinterventies, met real-time kaarten, WebRTC audio-oproepen en AI-ondersteuning.

## Aan de slag

Volg deze stappen om het project op te zetten op een nieuwe machine waar de broncode al aanwezig is.

### 1. Voorvereisten (Flutter Omgeving)

Als je Flutter nog niet eerder hebt ingesteld, moet je het volgende installeren:

- **Flutter SDK**: [Installeer Flutter](https://docs.flutter.dev/get-started/install) (Gebruik het _stable_ kanaal).
- **Java Development Kit (JDK)**: Versie 11 of hoger (Vereist voor Android/APK builds).
- **Android SDK & Command-line Tools**: [Installeer via Android Studio](https://developer.android.com/studio) om bouwen voor Android mogelijk te maken.
- **Visual Studio Code / Android Studio**: Aanbevolen IDE's met Flutter/Dart extensies.

### 2. Firebase Project Instellingen

Om het project correct te laten werken, moeten de volgende services in de [Firebase Console](https://console.firebase.google.com/) zijn geactiveerd:

1.  **Authentication**: Schakel de gewenste inlogmethoden in (bijv. E-mail/Wachtwoord).
2.  **Firestore Database**: Maak een database aan in 'Productie' of 'Test mode' en stel de juiste regels in.
3.  **Storage**: Activeer Cloud Storage voor het opslaan van bestanden.

Zorg ervoor dat je zowel een **Android-app** als een **Web-app** registreert in je Firebase project instellingen om de nodige configuratiegegevens te verkrijgen.

### 3. Configuratie & Secrets (Vereist)

Het project vereist verschillende API-sleutels en Firebase-configuraties die om veiligheidsredenen **niet** in de broncode zijn opgenomen.

1. **Omgevingsvariabelen instellen**:
   - Zoek `.env.example` in de hoofdmap.
   - Maak een kopie genaamd `.env`.
   - Vul alle 8 vereiste waarden in de `.env` file in:

| Variabele                      | Waar te vinden?                                                                      |
| :----------------------------- | :----------------------------------------------------------------------------------- |
| `MAPBOX_ACCESS_TOKEN`          | [Mapbox Dashboard](https://account.mapbox.com/) -> Access Tokens                     |
| `GEMINI_API_KEY`               | [Google AI Studio](https://aistudio.google.com/app/apikey) -> Get API Key            |
| `FIREBASE_API_KEY`             | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (apiKey)            |
| `FIREBASE_AUTH_DOMAIN`         | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (authDomain)        |
| `FIREBASE_PROJECT_ID`          | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (projectId)         |
| `FIREBASE_STORAGE_BUCKET`      | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (storageBucket)     |
| `FIREBASE_MESSAGING_SENDER_ID` | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (messagingSenderId) |
| `FIREBASE_APP_ID`              | Firebase Console -> Projectinstellingen -> Algemeen -> Jouw apps (appId)             |

> [!TIP]
> In de Firebase Console vindt u deze waarden onder de "Web app" configuratie. Als er geen web app is, maak er dan een aan om deze SDK config snippet te zien.

```bash
# Windows (PowerShell)
copy .env.example .env
```

> [!NOTE]
> De Firebase configuratie in `lib/backend/firebase/firebase_config.dart` is nu veilig om te committen omdat deze gebruik maakt van deze omgevingsvariabelen.

2. **Firebase Native Config (Optioneel maar aanbevolen)**:
   - Download `google-services.json` (Android) en `GoogleService-Info.plist` (iOS) van de Firebase Console.
   - Plaats `google-services.json` in `android/app/`.
   - Plaats `GoogleService-Info.plist` in `ios/Runner/`.
   - _Opmerking: Deze bestanden worden nu genegeerd door Git om lekken te voorkomen._

### 4. Finale Controle

Zodra Firebase en de configuratiebestanden in orde zijn, voer de volgende commando's uit om te bevestigen dat alles correct is ingesteld:

```bash
flutter doctor
flutter pub get
```

### 5. De Applicatie Uitvoeren

- **Android (Emulator of Device)**:
  ```bash
  flutter run
  ```

## De Android APK Bouwen

Volg deze stappen om een APK te genereren die je op Android-toestellen kunt installeren.

### 1. Voorbereiding

Zorg ervoor dat alle secrets in `.env` correct zijn ingevuld en dat de native configuratiebestanden aanwezig zijn indien nodig.

### 2. APK Genereren

Voer het volgende commando uit in de hoofdmap om een release APK te maken:

```powershell
flutter build apk --release
```

### 3. Bestand Locatie

Zodra de build is voltooid, kun je het APK-bestand vinden op:
`build/app/outputs/flutter-apk/app-release.apk`

---

_Opmerking: Zorg ervoor dat je verbonden bent met het internet tijdens de eerste build, omdat Flutter dependencies en de Android toolchain moet downloaden._
