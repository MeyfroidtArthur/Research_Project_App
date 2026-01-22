import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '/services/notification_service.dart';

/// ------------------------------------------------------------
/// Initialize high-priority notifications callback
/// This runs in the main isolate and handles notifications from background
Future<void> initHighPriorityNotifications() async {
  // Receive messages from background isolate
  FlutterForegroundTask.addTaskDataCallback((data) async {
    if (data == 'dispatch_status_active') {
      print(
        '✅ Background callback: Dispatch status active - showing notification',
      );
      // Show the notification using NotificationService
      await NotificationService.showDispatchStatusActive(
        id: 1002,
        title: 'Dispatch Status Active 🟢',
        body: 'Dispatch is now active and ready to assist.',
        payload: 'dispatch_status_active',
      );
    }
  });
}

@pragma('vm:entry-point')
class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._internal();

  factory BackgroundLocationService() => _instance;

  BackgroundLocationService._internal();

  String? _currentTeamPath;
  bool _isInitialized = false;

  /// Initialize the foreground task service
  Future<void> initialize() async {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'hulpverlener_location_tracking',
        channelName: 'Redivo - Locatie Tracking',
        channelDescription: 'Team locatie wordt bijgewerkt in de achtergrond',
        channelImportance: NotificationChannelImportance.LOW, // 🔕 silent
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
  }

  /// Start tracking location for a specific team
  Future<void> startTracking(String teamPath) async {
    // Check and request permissions before starting service
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permissions are permanently denied');
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    _currentTeamPath = teamPath;

    await FlutterForegroundTask.saveData(key: 'teamPath', value: teamPath);

    await FlutterForegroundTask.startService(
      notificationTitle: 'Redivo - Locatie Tracking',
      notificationText: 'Team locatie wordt bijgewerkt...',
      callback: startCallback,
    );
  }

  Future<void> stopTracking() async {
    _currentTeamPath = null;
    await FlutterForegroundTask.stopService();
  }

  Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}

/// ------------------------------------------------------------
/// BACKGROUND ENTRY POINT
/// ------------------------------------------------------------
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// ------------------------------------------------------------
/// TASK HANDLER
/// ------------------------------------------------------------
class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  StreamSubscription<QuerySnapshot>? _interventionSubscription;
  DateTime? _lastUpdate;
  String? _lastKnownStatus;
  String? _lastInterventionId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    try {
      await Firebase.initializeApp();
      // Initialize notifications in background isolate
      await NotificationService.initBackground();
    } catch (_) {}

    final teamPath = await FlutterForegroundTask.getData<String>(
      key: 'teamPath',
    );

    if (teamPath == null) return;

    _setupStatusListener(teamPath);
    _setupInterventionListener(teamPath);

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          ),
        ).listen((position) async {
          await _updateLocation(position, teamPath);
        });
  }

  void _setupStatusListener(String docPath) {
    _statusSubscription = FirebaseFirestore.instance
        .doc(docPath)
        .snapshots()
        .listen((snapshot) {
          final status = snapshot.data()?['status'] as String?;

          if (_lastKnownStatus != null &&
              _lastKnownStatus != 'active' &&
              status == 'active') {
            _showCallAcceptedNotification();
          }

          _lastKnownStatus = status;
        });
  }

  void _setupInterventionListener(String teamPath) {
    // Convert team path to reference for query
    final teamRef = FirebaseFirestore.instance.doc(teamPath);

    _interventionSubscription = FirebaseFirestore.instance
        .collection('Interventie')
        .where('teamId', arrayContains: teamRef)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            // Get the most recent active intervention
            final doc = snapshot.docs.first;

            // Only notify if it's a NEW intervention we haven't seen yet
            if (_lastInterventionId != doc.id) {
              _showInterventionNotification();
              _lastInterventionId = doc.id;
            }
          }
        });
  }

  /// 🔔 Trigger HIGH priority popup for INTERVENTION
  Future<void> _showInterventionNotification() async {
    print('🚨 New Intervention Detected - waking screen');

    // 1. Show notification DIRECTLY from background isolate
    // We reuse the showDispatchStatusActive method as it has the correct channel/config
    await NotificationService.showDispatchStatusActive(
      id: 1003,
      title: 'Interventie Alert! 🚨',
      body: 'Er is een nieuwe interventie voor je team!',
      payload: 'intervention_active',
    );

    // 2. Also send signal to main thread
    FlutterForegroundTask.sendDataToMain('intervention_active');

    // 3. Update persistent notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'Redivo - Interventie!',
      notificationText: 'Nieuwe interventie actief',
    );
  }

  /// 🔔 Trigger HIGH priority popup for dispatch status change
  Future<void> _showCallAcceptedNotification() async {
    print('🔔 Dispatch status changed - sending notification signal');

    // 1. Show notification DIRECTLY from background isolate
    await NotificationService.showDispatchStatusActive(
      id: 1002,
      title: 'Dispatch Status Active 🟢',
      body: 'Dispatch is now active and ready to assist.',
      payload: 'dispatch_status_active',
    );

    // 2. Also send signal to main thread (for UI updates if app is open)
    FlutterForegroundTask.sendDataToMain('dispatch_status_active');

    // 3. Update persistent service notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'Redivo - Locatie Tracking',
      notificationText: 'Status gewijzigd naar actief',
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    final teamPath = await FlutterForegroundTask.getData<String>(
      key: 'teamPath',
    );

    if (teamPath == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await _updateLocation(position, teamPath);
    } catch (_) {}
  }

  Future<void> _updateLocation(Position position, String teamPath) async {
    final now = DateTime.now();

    if (_lastUpdate != null && now.difference(_lastUpdate!).inSeconds < 30) {
      return;
    }

    _lastUpdate = now;

    await FirebaseFirestore.instance.doc(teamPath).update({
      'Location': GeoPoint(position.latitude, position.longitude),
      'LastLocationUpdate': FieldValue.serverTimestamp(),
    });

    FlutterForegroundTask.updateService(
      notificationTitle: 'Redivo - Locatie Tracking',
      notificationText:
          'Laatste update: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _positionSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _interventionSubscription?.cancel();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
