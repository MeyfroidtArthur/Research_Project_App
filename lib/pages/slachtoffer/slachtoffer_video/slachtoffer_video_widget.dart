import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import '/services/background_location_service.dart';
import '/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'slachtoffer_video_model.dart';
export 'slachtoffer_video_model.dart';

/// Emergency Call Interface
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
        print('📊 SLACHTOFFER VIDEO STREAM UPDATE');
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

            // Show notification when status changes from waiting to active
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
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
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
                                    ].divide(SizedBox(width: 8.0)),
                                  ),
                                ],
                              ),
                              Divider(
                                thickness: 2.0,
                                color: FlutterFlowTheme.of(context).alternate,
                              ),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    if (slachtofferVideoConnectionRecord
                                            .status ==
                                        Statuscall.active)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.all(16.0),
                                          child: Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            height: MediaQuery.sizeOf(context)
                                                    .width *
                                                1.0,
                                            decoration: BoxDecoration(
                                              color: Color(0xFFDADEE0),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Align(
                                              alignment: AlignmentDirectional(
                                                  0.0, 0.0),
                                              child: Text(
                                                'D',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .displayLarge
                                                        .override(
                                                          font: GoogleFonts
                                                              .interTight(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .displayLarge
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .displayLarge
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .displayLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .displayLarge
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (slachtofferVideoConnectionRecord
                                            .status !=
                                        Statuscall.active)
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Waiting...',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .titleSmall
                                                  .override(
                                                    font:
                                                        GoogleFonts.interTight(
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                                    letterSpacing: 0.0,
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleSmall
                                                            .fontStyle,
                                                  ),
                                            ),
                                            Text(
                                              'A dispatcher will come soon, answer in the mean time some question in the chat',
                                              textAlign: TextAlign.center,
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ].divide(SizedBox(height: 16.0)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () {
                                      print('Button pressed ...');
                                    },
                                    text: '',
                                    icon: Icon(
                                      FFIcons.kcamera,
                                      size: 15.0,
                                    ),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 40.0,
                                      padding: EdgeInsets.all(8.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FFButtonWidget(
                                    onPressed: () async {
                                      context.pushNamed(
                                        SlachtofferChatWidget.routeName,
                                        extra: <String, dynamic>{
                                          kTransitionInfoKey: TransitionInfo(
                                            hasTransition: true,
                                            transitionType:
                                                PageTransitionType.fade,
                                            duration:
                                                Duration(milliseconds: 200),
                                          ),
                                        },
                                      );
                                    },
                                    text: '',
                                    icon: Icon(
                                      FFIcons.kchatText,
                                      size: 15.0,
                                    ),
                                    options: FFButtonOptions(
                                      width: double.infinity,
                                      height: 40.0,
                                      padding: EdgeInsets.all(8.0),
                                      iconPadding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              0.0, 0.0, 0.0, 0.0),
                                      color: FlutterFlowTheme.of(context)
                                          .alternate,
                                      textStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 12.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                      elevation: 0.0,
                                      borderRadius: BorderRadius.circular(24.0),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 16.0)),
                            ),
                            FFButtonWidget(
                              onPressed: () async {
                                context.pushNamed(
                                  SlachtofferHomeWidget.routeName,
                                  extra: <String, dynamic>{
                                    kTransitionInfoKey: TransitionInfo(
                                      hasTransition: true,
                                      transitionType: PageTransitionType.fade,
                                      duration: Duration(milliseconds: 200),
                                    ),
                                  },
                                );

                                FFAppState().deleteCall();
                                FFAppState().Call = ActiveCallStruct();

                                safeSetState(() {});
                              },
                              text: '',
                              icon: Icon(
                                FFIcons.kphoneX,
                                size: 15.0,
                              ),
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 40.0,
                                padding: EdgeInsets.all(8.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
                                textStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                            ),
                          ].divide(SizedBox(height: 12.0)),
                        ),
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
