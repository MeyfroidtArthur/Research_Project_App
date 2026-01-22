# Background Location Tracking for Hulpverlener Teams

## Overview

This implementation adds background location tracking for hulpverlener (helper) teams. When a team is selected, the app will automatically update the team's location in Firebase Firestore every 30 seconds, even when the app is in the background or the phone screen is off.

## Features Implemented

### 1. Background Location Service (`lib/services/background_location_service.dart`)

- Runs as a foreground service on Android (displays a notification)
- Updates team location every 30 seconds
- Works even when app is minimized or phone is locked
- **Automatically requests location permissions when you select a team**
- Only tracks when a team is selected (no team = no tracking)
- Stops when team is deselected or user logs out

### 2. Updated Teams Schema

The `TeamsRecord` schema now includes two new fields:

- `Location` (LatLng): Current GPS coordinates of the team
- `LastLocationUpdate` (DateTime): Timestamp of the last location update

### 3. Integration Points

Location tracking automatically:

- **Starts** when a team is selected in the hulpverlener home page
- **Stops** when:
  - User switches to a different team
  - User logs out from any hulpverlener page (Home, Map, Berichten)
  - App is closed

## Firebase Firestore Configuration

### Required Firestore Security Rules

Add these rules to your `firestore.rules` file to allow teams to update their own location:

```javascript
match /Teams/{teamId} {
  // Allow team members to update their team's location
  allow update: if request.auth != null
    && request.resource.data.keys().hasOnly(['Location', 'LastLocationUpdate']);

  // Your existing team rules...
  allow read: if request.auth != null;
}
```

### Firestore Data Structure

The Teams collection will now store:

```javascript
{
  "Naam": "Team Alpha",
  "Prefix": "TA",
  "Locatie": "HQ Location",
  "Status": "Available",
  "EventId": DocumentReference,
  "Location": GeoPoint(latitude, longitude),  // NEW
  "LastLocationUpdate": Timestamp             // NEW
}
```

## Android Permissions

The following permissions are already configured in `AndroidManifest.xml`:

- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `ACCESS_BACKGROUND_LOCATION`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_LOCATION`

## iOS Permissions

For iOS, you need to update the `Info.plist` file with location usage descriptions:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track your team's position during interventions.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>We need your location to track your team's position even when the app is in the background.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>We need your location to track your team's position during interventions.</string>
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

## How It Works

### When NO team is selected:

- ❌ Location is NOT tracked
- ❌ No Firebase updates
- ❌ No battery drain from location services
- ❌ No background service running

### When a team IS selected:

1. ✅ Permission prompt appears immediately (if not already granted)
2. ✅ Background service starts
3. ✅ Location updates every 30 seconds to Firebase
4. ✅ Foreground notification shows on Android
5. ✅ Works even with phone locked/app minimized

### Permission Flow:

1. **First dialog**: "Allow [App] to access your location?"
   - Choose "While using the app" or **"Always allow"**
2. **Second dialog** (Android 11+): Informational dialog about background tracking
   - Click "Doorgaan" (Continue)
3. **Third permission request**: Android system asks for background location
   - **Select "Allow all the time"** for continuous background tracking
4. **If all granted**: Tracking starts with a green success message
5. **If denied**: Error message shown and no tracking occurs

## Testing the Feature

1. **Build and run the app:**

   ```bash
   flutter run
   ```

2. **Login as a hulpverlener**

3. **Select a team** from the dropdown on the home page
   - The app will immediately ask for location permissions
   - **First dialog**: "Allow Redivo App to access this device's location?"
   - Choose "While using the app" or **"Always allow"** (required for background tracking)

4. **On Android 11+, grant background location permission**:
   - You'll see an informational dialog about background tracking
   - Click "Doorgaan" (Continue)
   - Android system will ask again for permission
   - **Select "Allow all the time"** to enable background tracking

5. **Verify tracking started:**
   - You should see a green message: "Locatie tracking actief voor [Team Name]"
   - On Android, check the notification tray - you'll see "Redivo - Locatie Tracking"

6. **Verify in Firebase Console:**
   - Open Firebase Console → Firestore Database
   - Navigate to the Teams collection
   - Find your selected team document
   - You should see the `Location` and `LastLocationUpdate` fields updating every 30 seconds

7. **Test background tracking:**
   - Minimize the app or lock the phone
   - Wait 1-2 minutes
   - Check Firebase - the location should still be updating

8. **Test stopping:**
   - Open the app and logout
   - Verify that location updates stop in Firebase

## Displaying Team Locations on the Map

To display team locations on the map, you can query the Teams collection and show markers for active teams:

```dart
StreamBuilder<List<TeamsRecord>>(
  stream: queryTeamsRecord(
    queryBuilder: (teamsRecord) => teamsRecord
        .where('EventId', isEqualTo: FFAppState().Event.id)
        .where('Status', isEqualTo: TeamStatus.Available.serialize()),
  ),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();

    final teams = snapshot.data!;

    return FlutterMap(
      children: [
        // Your existing map layers...

        // Add team markers
        MarkerLayer(
          markers: teams
              .where((team) => team.hasLocation())
              .map((team) => Marker(
                    point: latlong.LatLng(
                      team.location!.latitude,
                      team.location!.longitude,
                    ),
                    child: Icon(Icons.group, color: Colors.blue),
                  ))
              .toList(),
        ),
      ],
    );
  },
)
```

## Troubleshooting

### Location not updating?

1. Check if location permissions are granted
2. Verify location services are enabled on the device
3. Check Firebase Console for any security rule errors
4. Look at the app logs for error messages

### Background service stops?

1. On Android, check battery optimization settings
2. Some manufacturers (Xiaomi, Huawei) have aggressive battery optimization - may need to whitelist the app
3. Check if the notification is still visible

### High battery usage?

The service is configured to update every 30 seconds with high accuracy. If battery usage is a concern:

- Increase the update interval in `background_location_service.dart` (change `Duration(seconds: 30)`)
- Lower location accuracy (change `LocationAccuracy.high` to `LocationAccuracy.medium`)

## Next Steps

Consider adding:

1. **Visual indicator** on the map showing last update time for each team
2. **History tracking** - store location history for reviewing team movements
3. **Geofencing** - alert when teams enter/exit specific areas
4. **Distance calculations** - show distance between teams and interventions
5. **Battery optimization** - reduce update frequency when device is stationary

## Support

For issues or questions about this implementation, check:

- Flutter logs: `flutter logs`
- Android logs: `adb logcat | grep BackgroundLocationService`
- Firebase Console: Firestore Database and Authentication tabs
