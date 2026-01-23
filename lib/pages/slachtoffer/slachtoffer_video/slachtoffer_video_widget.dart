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
                        // Status Banner
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          margin: EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: slachtofferVideoConnectionRecord.status ==
                                    Statuscall.active
                                ? Color(0xFF4CAF50) // Green for active
                                : Color(0xFFFF9800), // Orange for waiting
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                slachtofferVideoConnectionRecord.status ==
                                        Statuscall.active
                                    ? "DISPATCHED ACCEPTED"
                                    : "WAITING FOR HELP...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                slachtofferVideoConnectionRecord.status ==
                                        Statuscall.active
                                    ? "A dispatcher is viewing your location."
                                    : "You can chat with the dispatcher below.",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              )
                            ],
                          ),
                        ),

                        // Chat Area
                        Expanded(
                          child: StreamBuilder<List<ChatsRecord>>(
                            stream: queryChatsRecord(
                              parent: FFAppState().Call.refrence,
                              queryBuilder: (chatsRecord) => chatsRecord
                                  .orderBy('timestamp', descending: true),
                            ),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return Center(
                                    child: CircularProgressIndicator());
                              }
                              final messages = snapshot.data!;

                              if (messages.isEmpty) {
                                return Center(
                                  child: Text(
                                    "No messages yet. Type below to talk to dispatch.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return ListView.separated(
                                reverse: true,
                                itemCount: messages.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final message = messages[index];
                                  final isMe = message.sender == 'Slachtoffer';

                                  return Align(
                                    alignment: isMe
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    child: Container(
                                      padding: EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isMe
                                            ? FlutterFlowTheme.of(context)
                                                .primary
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        message.message,
                                        style: TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 10),

                        // Input Area and End Call
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _model.textController,
                                    focusNode: _model.textFieldFocusNode,
                                    style: TextStyle(
                                        color: Colors.black), // Fix text color
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(24),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                    ),
                                    onFieldSubmitted: (_) async {
                                      if (_model.textController?.text.isEmpty ??
                                          true) return;
                                      await ChatsRecord.createDoc(
                                              FFAppState().Call.refrence!)
                                          .set(createChatsRecordData(
                                        sender: 'Slachtoffer',
                                        message: _model.textController!.text,
                                        timestamp: getCurrentTimestamp,
                                      ));
                                      _model.textController?.clear();
                                      safeSetState(() {});
                                    },
                                  ),
                                ),
                                SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.send,
                                      color:
                                          FlutterFlowTheme.of(context).primary),
                                  onPressed: () async {
                                    if (_model.textController?.text.isEmpty ??
                                        true) return;
                                    await ChatsRecord.createDoc(
                                            FFAppState().Call.refrence!)
                                        .set(createChatsRecordData(
                                      sender: 'Slachtoffer',
                                      message: _model.textController!.text,
                                      timestamp: getCurrentTimestamp,
                                    ));
                                    _model.textController?.clear();
                                    safeSetState(() {});
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
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

                                // Reset AppState
                                FFAppState().deleteCall();
                                FFAppState().Call = ActiveCallStruct();

                                // Stop tracking
                                await _locationService.stopTracking();

                                safeSetState(() {});
                              },
                              text: 'End Call', // Added text for clarity
                              icon: Icon(
                                FFIcons.kphoneX,
                                size: 15.0,
                              ),
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 44.0,
                                color: FlutterFlowTheme.of(context)
                                    .primary, // Use primary color
                                textStyle: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                                elevation: 0.0,
                                borderRadius: BorderRadius.circular(24.0),
                              ),
                            ),
                          ],
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
