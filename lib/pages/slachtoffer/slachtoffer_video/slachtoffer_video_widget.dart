import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/background_location_service.dart';
import '/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'slachtoffer_video_model.dart';
export 'slachtoffer_video_model.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '/services/webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '/auth/firebase_auth/auth_util.dart';

/// Emergency Audio Call Interface
class SlachtofferVideoWidget extends StatefulWidget {
  const SlachtofferVideoWidget({super.key});

  static String routeName = 'SlachtofferVideo';
  static String routePath = '/slachtofferVideo';

  @override
  State<SlachtofferVideoWidget> createState() => _SlachtofferVideoWidgetState();
}

class _SlachtofferVideoWidgetState extends State<SlachtofferVideoWidget> {
  late SlachtofferVideoModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  late BackgroundLocationService _locationService;
  late NotificationService _notificationService;
  Statuscall? _previousStatus;

  // Audio renderers for playback
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final _webrtcService = WebRTCService();
  bool _isCallActive = false;
  bool _isMicrophoneMuted = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SlachtofferVideoModel());
    _locationService = BackgroundLocationService();
    _notificationService = NotificationService();
    _previousStatus = null;

    // Listen for messages from background service
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    // Start background service for chat notifications
    if (FFAppState().Call.refrence != null) {
      _locationService.startCallMode(FFAppState().Call.refrence!.path);
    }
    _initializeRenderers();
  }

  Future<void> _initializeRenderers() async {
    // Initialize audio renderers for playback
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    // Request microphone permission
    await Permission.microphone.request();
  }

  Future<void> _startWebRTCCall() async {
    if (_isCallActive) return; // Already started

    await _webrtcService.startCall(
      voornaam: currentUserDisplayName,
      achternaam: '',
      callDocRef: FFAppState().Call.refrence,
      onLocalStream: (stream) {
        print('🎤 Local audio stream started');
        if (mounted) {
          setState(() {
            _localRenderer.srcObject = stream;
          });
        }
      },
      onRemoteStream: (stream) {
        print('🔊 Remote audio stream received');
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      },
    );

    if (mounted) setState(() => _isCallActive = true);
  }

  void _onReceiveTaskData(dynamic data) {
    print('📨 Received data from background service: $data');
    if (data == 'call_accepted') {
      print('🔔 Showing loud notification for call acceptance');
      NotificationService.showNow(
        id: 1001,
        title: 'Hulp onderweg! 🚑',
        body:
            'Dispatch has accepted your call and is ready to answer your emergency',
        payload: 'call_accepted',
      );
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking(); // Stop service when leaving call page
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    _model.dispose();
    _webrtcService.hangUp();

    // Dispose audio renderers
    _localRenderer.dispose();
    _remoteRenderer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    if (FFAppState().Call.refrence == null) {
      return Scaffold(
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: Center(
          child: SizedBox(
            width: 50.0,
            height: 50.0,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                FlutterFlowTheme.of(context).primary,
              ),
            ),
          ),
        ),
      );
    }

    return StreamBuilder<ConnectionRecord>(
      stream: ConnectionRecord.getDocument(FFAppState().Call.refrence!),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Scaffold(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            body: PopScope(
              canPop: false,
              child: Center(
                child: SizedBox(
                  width: 50.0,
                  height: 50.0,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      FlutterFlowTheme.of(context).primary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        final slachtofferVideoConnectionRecord = snapshot.data!;

        print('════════════════════════════════════════');
        print('📊 SLACHTOFFER AUDIO CALL STREAM UPDATE');
        print('════════════════════════════════════════');
        print('Status: ${slachtofferVideoConnectionRecord.status}');
        print('Previous Status: $_previousStatus');
        print('FFAppState Call refrence: ${FFAppState().Call.refrence}');
        print(
            'FFAppState Call refrence path: ${FFAppState().Call.refrence?.path}');
        print(
            'StreamBuilder refrence: ${slachtofferVideoConnectionRecord.reference}');
        print(
            'StreamBuilder refrence path: ${slachtofferVideoConnectionRecord.reference.path}');
        print('════════════════════════════════════════');

        // Handle location tracking based on call status
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          print('🔔 addPostFrameCallback triggered');
          print('Current status: ${slachtofferVideoConnectionRecord.status}');
          print('Previous status: $_previousStatus');
          print(
              'Status changed: ${_previousStatus != slachtofferVideoConnectionRecord.status}');

          if (_previousStatus != slachtofferVideoConnectionRecord.status) {
            final oldStatus = _previousStatus;
            _previousStatus = slachtofferVideoConnectionRecord.status;
            print('✅ Status changed detected: $oldStatus → $_previousStatus');

            // Show notification and start WebRTC when status changes from waiting to active
            if (oldStatus == Statuscall.waiting &&
                slachtofferVideoConnectionRecord.status == Statuscall.active) {
              print('📢 Showing call accepted notification');
              try {
                await NotificationService.showNow(
                  id: 1001,
                  title: 'Hulp onderweg! 🚑',
                  body:
                      'Dispatch has accepted your call and is ready to answer your emergency',
                  payload: 'call_accepted',
                );
                print('✅ Notification shown successfully');
              } catch (e) {
                print('❌ Error showing notification: $e');
              }

              // Start WebRTC call when dispatcher accepts
              print('🎤 Starting WebRTC audio call');
              await _startWebRTCCall();
            }

            // Start tracking on both waiting and active states
            if (slachtofferVideoConnectionRecord.status == Statuscall.waiting ||
                slachtofferVideoConnectionRecord.status == Statuscall.active) {
              // Start location tracking when call is waiting or active
              final connectionRef = FFAppState().Call.refrence;
              final referencePath = connectionRef?.path ?? 'NO_PATH';
              print('🚨 Slachtoffer: Starting location tracking');
              print(
                  '🚨 Slachtoffer: Connection Reference Path: $referencePath');
              print(
                  '🚨 Slachtoffer: Connection Record Reference Path: ${slachtofferVideoConnectionRecord.reference.path}');

              if (connectionRef == null) {
                print('❌ ERROR: Connection reference is NULL!');
                return;
              }

              try {
                await _locationService.startCallMode(referencePath);
                print(
                    '✅ Slachtoffer: Call mode started for path: $referencePath');
              } catch (e) {
                print('❌ Slachtoffer: Error starting call mode: $e');
              }
            } else if (slachtofferVideoConnectionRecord.status ==
                Statuscall.ended) {
              // Stop location tracking when call ends
              print('🛑 Slachtoffer: Stopping location tracking');
              try {
                await _locationService.stopTracking();
                print('✅ Slachtoffer: Location tracking stopped');
              } catch (e) {
                print('❌ Slachtoffer: Error stopping location tracking: $e');
              }
            }
          } else {
            print('ℹ️  Status unchanged - skipping action');
          }
        });

        return PopScope(
          canPop: false,
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: Scaffold(
              key: scaffoldKey,
              backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
              body: SafeArea(
                top: true,
                child: Container(
                  width: MediaQuery.sizeOf(context).width * 1.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Dispatch',
                                        style: FlutterFlowTheme.of(context)
                                            .titleLarge
                                            .override(
                                              font: GoogleFonts.interTight(
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .titleLarge
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF222222),
                                              fontSize: 21.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.bold,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .titleLarge
                                                      .fontStyle,
                                            ),
                                      ),
                                      SizedBox(width: 8.0),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          color:
                                              slachtofferVideoConnectionRecord
                                                          .status ==
                                                      Statuscall.active
                                                  ? Color(0xFF10B981)
                                                  : Color(0xFFF59E0B),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          slachtofferVideoConnectionRecord
                                                      .status ==
                                                  Statuscall.active
                                              ? 'Actief'
                                              : 'Wachten',
                                          style: FlutterFlowTheme.of(context)
                                              .bodySmall
                                              .override(
                                                font: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                color: Colors.white,
                                                fontSize: 12.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _isMicrophoneMuted =
                                                !_isMicrophoneMuted;
                                          });
                                          // TODO: Implement actual microphone mute/unmute
                                        },
                                        child: Container(
                                          width: 40.0,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: _isMicrophoneMuted
                                                ? FlutterFlowTheme.of(context)
                                                    .error
                                                : FlutterFlowTheme.of(context)
                                                    .alternate,
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Icon(
                                            _isMicrophoneMuted
                                                ? FFIcons.kmicrophoneSlash
                                                : FFIcons.kmicrophone,
                                            size: 18.0,
                                            color: _isMicrophoneMuted
                                                ? Colors.white
                                                : FlutterFlowTheme.of(context)
                                                    .primaryText,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      InkWell(
                                        onTap: () async {
                                          context.pushNamed(
                                            SlachtofferChatWidget.routeName,
                                            extra: <String, dynamic>{
                                              kTransitionInfoKey:
                                                  TransitionInfo(
                                                hasTransition: true,
                                                transitionType:
                                                    PageTransitionType.fade,
                                                duration:
                                                    Duration(milliseconds: 200),
                                              ),
                                            },
                                          );
                                        },
                                        child: Container(
                                          width: 40.0,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Icon(
                                            FFIcons.kchatText,
                                            size: 18.0,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.0),
                                      InkWell(
                                        onTap: () async {
                                          context.pushNamed(
                                            SlachtofferHomeWidget.routeName,
                                            extra: <String, dynamic>{
                                              kTransitionInfoKey:
                                                  TransitionInfo(
                                                hasTransition: true,
                                                transitionType:
                                                    PageTransitionType.fade,
                                                duration:
                                                    Duration(milliseconds: 200),
                                              ),
                                            },
                                          );
                                          FFAppState().deleteCall();
                                          FFAppState().Call =
                                              ActiveCallStruct();
                                          safeSetState(() {});
                                        },
                                        child: Container(
                                          width: 40.0,
                                          height: 40.0,
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            borderRadius:
                                                BorderRadius.circular(20.0),
                                          ),
                                          child: Icon(
                                            FFIcons.kphoneX,
                                            size: 18.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Divider(
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFF1E293B),
                                          Color(0xFF0F172A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Audio wave animation or microphone icon
                                          Container(
                                            width: 120.0,
                                            height: 120.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  slachtofferVideoConnectionRecord
                                                              .status ==
                                                          Statuscall.active
                                                      ? Color(0xFF10B981)
                                                          .withOpacity(0.2)
                                                      : Color(0xFFF59E0B)
                                                          .withOpacity(0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _isMicrophoneMuted
                                                    ? FFIcons.kmicrophoneSlash
                                                    : FFIcons.kmicrophone,
                                                size: 60.0,
                                                color:
                                                    slachtofferVideoConnectionRecord
                                                                .status ==
                                                            Statuscall.active
                                                        ? Color(0xFF10B981)
                                                        : Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 32.0),
                                          Text(
                                            slachtofferVideoConnectionRecord
                                                        .status ==
                                                    Statuscall.active
                                                ? 'Verbonden met Dispatch'
                                                : 'Wachten op Dispatch',
                                            style: FlutterFlowTheme.of(context)
                                                .titleLarge
                                                .override(
                                                  font: GoogleFonts.interTight(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  color: Colors.white,
                                                  fontSize: 24.0,
                                                  letterSpacing: 0.0,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                          SizedBox(height: 16.0),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 32.0),
                                            child: Text(
                                              slachtofferVideoConnectionRecord
                                                          .status ==
                                                      Statuscall.active
                                                  ? 'Je bent nu verbonden met een dispatcher. Beschrijf je noodsituatie.'
                                                  : 'Een dispatcher komt zo bij je. Beantwoord ondertussen vragen in de chat.',
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font:
                                                            GoogleFonts.inter(),
                                                        color: Colors.white70,
                                                        fontSize: 14.0,
                                                        letterSpacing: 0.0,
                                                      ),
                                            ),
                                          ),
                                          if (_isMicrophoneMuted)
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(top: 16.0),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 8.0),
                                                decoration: BoxDecoration(
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .error
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8.0),
                                                  border: Border.all(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .error,
                                                    width: 1.0,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Microfoon is gedempt',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodySmall
                                                      .override(
                                                        font:
                                                            GoogleFonts.inter(),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .error,
                                                        letterSpacing: 0.0,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                        SizedBox.shrink(), // Buttons moved to header
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
