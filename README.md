# Redivo App

Redivo App is een op Flutter gebaseerde mobiele applicatie voor het beheren van noodinterventies, met real-time kaarten, WebRTC audio-oproepen en AI-ondersteuning.

## Aan de slag

Volg deze stappen om het project op te zetten op een nieuwe machine waar de broncode al aanwezig is.

### 1. Voorvereisten (Flutter Omgeving)

Als je Flutter nog niet eerder hebt ingesteld, moet je het volgende installeren:
- **Flutter SDK**: [Installeer Flutter](https://docs.flutter.dev/get-started/install) (Gebruik het *stable* kanaal).
- **Java Development Kit (JDK)**: Versie 11 of hoger (Vereist voor Android/APK builds).
- **Android SDK & Command-line Tools**: [Installeer via Android Studio](https://developer.android.com/studio) om bouwen voor Android mogelijk te maken.
- **Visual Studio Code / Android Studio**: Aanbevolen IDE's met Flutter/Dart extensies.

### 2. Firebase Project Instellingen

Om het project correct te laten werken, moeten de volgende services in de [Firebase Console](https://console.firebase.google.com/) zijn geactiveerd:

1.  **Authentication**: Schakel de gewenste inlogmethoden in (bijv. E-mail/Wachtwoord).
2.  **Firestore Database**: Maak een database aan in 'Productie' of 'Test mode' en stel de juiste regels in.
3.  **Storage**: Activeer Cloud Storage voor het opslaan van bestanden.

Zorg ervoor dat je een **Android app** registreert in je Firebase project instellingen om de juiste configuratiegegevens te verkrijgen.

### 3. Configuratie & Secrets (Vereist)

Het project vereist verschillende API-sleutels en Firebase-configuraties die om veiligheidsredenen **niet** in de broncode zijn opgenomen. Je moet deze handmatig aanmaken met behulp van de meegeleverde sjablonen.

1. **Omgevingsvariabelen**:
   - Zoek `.env.example` in de hoofdmap.
   - Maak een kopie genaamd `.env`.
   - Vul je `MAPBOX_ACCESS_TOKEN` ([Haal hier je Mapbox token op](https://account.mapbox.com/)) en `GEMINI_API_KEY` ([Haal hier je Google AI Studio sleutel op](https://aistudio.google.com/app/apikey)) in.
   ```bash
   # Windows (PowerShell)
   copy .env.example .env
   ```

2. **Firebase Configuratie**:
   - Navigeer naar `lib/backend/firebase/`.
   - Kopieer `firebase_config_example.dart` naar een nieuw bestand genaamd `firebase_config.dart`.
   - Werk de plaatshouderwaarden bij met de configuratie van je Firebase-project.

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
Zorg ervoor dat alle secrets in `.env` en `firebase_config.dart` correct zijn ingevuld.

### 2. APK Genereren
Voer het volgende commando uit in de hoofdmap om een release APK te maken:
```powershell
flutter build apk --release
```

### 3. Bestand Locatie
Zodra de build is voltooid, kun je het APK-bestand vinden op:
`build/app/outputs/flutter-apk/app-release.apk`

---
*Opmerking: Zorg ervoor dat je verbonden bent met het internet tijdens de eerste build, omdat Flutter dependencies en de Android toolchain moet downloaden.*
