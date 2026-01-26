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

    await FlutterForegroundTask.saveData(key: 'teamPath', value: teamPath);

    await FlutterForegroundTask.startService(
      notificationTitle: 'Redivo - Locatie Tracking',
      notificationText: 'Team locatie wordt bijgewerkt...',
      callback: startCallback,
    );
  }

  /// Start background service for Slachtoffer Call (Chat notifications)
  Future<void> startCallMode(String callPath) async {
    if (!_isInitialized) {
      await initialize();
    }

    // MANDATORY: Even if we only want chat notifications, the Android Service is declared
    // with 'foregroundServiceType="location"'. This means starting the service crashes
    // if we don't have location permission.
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print(
            '❌ Location permissions are denied (Required for background service)');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permissions are permanently denied');
      return;
    }

    await FlutterForegroundTask.saveData(key: 'callPath', value: callPath);
    // Ensure teamPath is cleared so we don't accidentally run team logic
    await FlutterForegroundTask.removeData(key: 'teamPath');

    await FlutterForegroundTask.startService(
      notificationTitle: 'Noodoproep Actief',
      notificationText: 'Verbomden met dispatch...',
      callback: startCallback,
    );
    print('🚀 startCallMode: Service start request sent');
  }

  Future<void> stopTracking() async {
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
  StreamSubscription<DocumentSnapshot>? _teamSubscription;
  StreamSubscription<DocumentSnapshot>? _statusSubscription;
  StreamSubscription<QuerySnapshot>? _interventionSubscription;
  StreamSubscription<QuerySnapshot>? _messageSubscription;
  DateTime? _lastUpdate;
  String? _lastKnownStatus;
  String? _lastInterventionId;
  bool _isOnChatPage = false;

  @override
  void onReceiveData(Object data) {
    if (data == 'chat_opened') {
      _isOnChatPage = true;
    } else if (data == 'chat_closed') {
      _isOnChatPage = false;
    }
  }

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

    final callPath = await FlutterForegroundTask.getData<String>(
      key: 'callPath',
    );

    if (teamPath != null) {
      _setupTeamListener(teamPath);
      _setupInterventionListener(teamPath);
      _setupMessageListener(teamPath);

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) async {
        await _updateLocation(position, teamPath);
      });
    } else if (callPath != null) {
      print('✅ onStart: Starting Call Mode logic for path: $callPath');
      _setupStatusListener(callPath); // Still needed for call mode
      _setupChatListener(callPath);

      // Start location tracking for SLACHTOFFER in call mode
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) async {
        await _updateCallLocation(position, callPath);
      });
    }
  }

  void _setupTeamListener(String teamPath) {
    print('📡 Setting up Team Listener for path: $teamPath');

    _teamSubscription = FirebaseFirestore.instance
        .doc(teamPath)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists) {
        print('⚠️ Team document MISSING at $teamPath');
        return;
      }

      final data = snapshot.data();
      if (data == null) {
        print('⚠️ Team data is NULL');
        return;
      }

      // 1. Handle Status Change (Dispatch accepted call)
      final status = data['status'] as String? ?? data['Status'] as String?;
      if (_lastKnownStatus != null &&
          _lastKnownStatus != 'active' &&
          (status == 'active' || status == 'Active')) {
        _showCallAcceptedNotification();
      }
      _lastKnownStatus = status;
    });
  }

  void _setupChatListener(String callPath) {
    print('📞 _setupChatListener: Listening for chats at $callPath/chats');
    final startTimestamp = Timestamp.now();

    _messageSubscription = FirebaseFirestore.instance
        .doc(callPath)
        .collection('chats')
        .where('timestamp', isGreaterThan: startTimestamp)
        .snapshots()
        .listen((snapshot) {
      print(
          '📨 Chat listener triggered. Docs count: ${snapshot.docChanges.length}');
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          print('📨 New chat document: $data');
          final sender = data['sender'] as String?;

          print(
              '🧐 Checking conditions: Sender=$sender, IsOnChatPage=$_isOnChatPage');

          if (sender == 'Dispatch' && !_isOnChatPage) {
            final message = data['message'] as String? ?? 'Nieuw bericht';
            print('🔔 Conditions met! Showing notification for: $message');
            _showMessageNotification(message);
          } else {
            print(
                '🔕 Notification skipped. Sender match? ${sender == 'Dispatch'} | Page match? ${!_isOnChatPage}');
          }
        }
      }
    });
  }

  void _setupStatusListener(String docPath) {
    _statusSubscription =
        FirebaseFirestore.instance.doc(docPath).snapshots().listen((snapshot) {
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

  void _setupMessageListener(String teamPath) {
    // Only listen for messages arriving AFTER the service started (using Timestamp.now())
    final startTimestamp = Timestamp.now();

    _messageSubscription = FirebaseFirestore.instance
        .doc(teamPath)
        .collection('messages')
        .where('Time', isGreaterThan: startTimestamp)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final message = data['Message'] as String? ?? 'Nieuw bericht';
          _showMessageNotification(message);
        }
      }
    });
  }

  /// 🔔 Trigger notification for NEW MESSAGE
  Future<void> _showMessageNotification(String message) async {
    await NotificationService.showNow(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: 'Nieuw bericht 💬',
      body: message,
      payload: 'new_message',
    );
  }

  /// 🔔 Trigger HIGH priority popup for INTERVENTION
  Future<void> _showInterventionNotification() async {
    print('🚨 New Intervention Detected - waking screen');

    // Show notification DIRECTLY from background isolate
    await NotificationService.showDispatchStatusActive(
      id: 1003,
      title: 'Interventie Alert! 🚨',
      body: 'Er is een nieuwe interventie voor je team!',
      payload: 'intervention_active',
    );

    // 2. Also send signal to main thread
    FlutterForegroundTask.sendDataToMain('intervention_active');
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
    final callPath = await FlutterForegroundTask.getData<String>(
      key: 'callPath',
    );

    if (teamPath == null && callPath == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (teamPath != null) {
        await _updateLocation(position, teamPath);
      } else if (callPath != null) {
        await _updateCallLocation(position, callPath);
      }
    } catch (_) {}
  }

  Future<void> _updateLocation(Position position, String teamPath) async {
    final now = DateTime.now();

    if (_lastUpdate != null && now.difference(_lastUpdate!).inSeconds < 30) {
      return;
    }

    _lastUpdate = now;

    try {
      await FirebaseFirestore.instance.doc(teamPath).update({
        'Location': GeoPoint(position.latitude, position.longitude),
        'LastLocationUpdate': FieldValue.serverTimestamp(),
      });

      FlutterForegroundTask.updateService(
        notificationTitle: 'Redivo - Locatie Tracking',
        notificationText:
            'Laatste update: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      print('❌ Error updating team location: $e');
    }
  }

  Future<void> _updateCallLocation(Position position, String callPath) async {
    final now = DateTime.now();

    if (_lastUpdate != null && now.difference(_lastUpdate!).inSeconds < 30) {
      return;
    }

    _lastUpdate = now;

    try {
      await FirebaseFirestore.instance.doc(callPath).update({
        'Location': GeoPoint(position.latitude, position.longitude),
        'LastLocationUpdate': FieldValue.serverTimestamp(),
      });

      FlutterForegroundTask.updateService(
        notificationTitle: 'Noodoproep Actief',
        notificationText:
            'Locatie update: ${now.hour}:${now.minute.toString().padLeft(2, '0')}',
      );

      print(
          '📍 Call location updated: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Error updating call location: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _positionSubscription?.cancel();
    await _teamSubscription?.cancel();
    await _statusSubscription?.cancel();
    await _interventionSubscription?.cancel();
    await _messageSubscription?.cancel();
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
