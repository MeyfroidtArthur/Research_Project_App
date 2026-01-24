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
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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
  ChatSession? _chatSession;
  bool _hasInitializedAI = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SlachtofferVideoModel());

    // Initialize text controller for chat input
    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _locationService = BackgroundLocationService();
    _notificationService = NotificationService();
    _previousStatus = null;

    // Initialize Gemini AI for severity assessment
    _initializeGemini();

    // Listen for messages from background service
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);

    // Start background service for chat notifications
    if (FFAppState().Call.refrence != null) {
      _locationService.startCallMode(FFAppState().Call.refrence!.path);
    }
  }

  Future<void> _initializeGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey != null && apiKey.isNotEmpty) {
      final generativeModel = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        systemInstruction: Content.system(
          """You are an emergency triage assistant for the Red Cross. Your job is to help assess the severity of the situation while the user waits for dispatch.
          
IMPORTANT: In EVERY response, you must:
1. Ask clarifying questions in a calm, supportive manner about symptoms like: bleeding, inability to walk, breathing difficulty, unconsciousness, chest pain, severe allergic reaction, poisoning
2. If the user describes something that MIGHT be Level 3 (critical/life-threatening), ask MORE follow-up questions to confirm before assessing as Level 3
3. Only assess as Level 3 after you have enough information to be confident it's truly life-threatening
4. Continuously assess the severity based on all information provided
5. ALWAYS include your current severity assessment at the END of your message in BOTH formats:
   - Text format: [SEVERITY: X] where X is 1, 2, or 3
   - Tag format: [[levelX]] where X is 1, 2, or 3

Severity Levels:
- Level 3 (CRITICAL): Life-threatening emergency (severe injury, poisoning, inability to breathe, unconsciousness, severe bleeding, etc.) = [[level3]]
- Level 2 (URGENT): Important but person can wait (severe injuries that aren't immediately life-threatening, significant trauma, moderate bleeding) = [[level2]]
- Level 1 (NON-EMERGENCY): Needs help but not urgent (minor injuries, first aid advice, support needed) = [[level1]]

IMPORTANT RULE: If someone mentions something serious (like "can't breathe", "bleeding", "unconscious"), ask clarifying follow-up questions FIRST before assessing as Level 3. Only use Level 3 after you're confident based on multiple confirmations.

EXAMPLE RESPONSE FORMAT:
"Can you tell me if the person is breathing normally? Is there any severe bleeding? [SEVERITY: 2] [[level2]]"

Always be compassionate and reassuring. Keep responses short and clear. NEVER forget to include BOTH the [SEVERITY: X] and [[levelX]] tags at the end of every message.""",
        ),
      );
      _chatSession = generativeModel.startChat();

      // Send initial welcome message
      try {
        await ChatsRecord.createDoc(FFAppState().Call.refrence!)
            .set(createChatsRecordData(
          sender: 'Dispatch',
          message:
              '👋 Hello! I\'m an AI triage assistant from the Red Cross. I\'m here to help assess your situation. Can you tell me what happened and what symptoms or injuries are involved? (e.g., bleeding, can\'t walk, breathing difficulty, chest pain, unconscious)',
          timestamp: getCurrentTimestamp,
        ));
      } catch (e) {
        print('Error sending initial message: $e');
      }
    } else {
      print('Gemini API Key not found');
    }
  }

  Future<void> _sendAIMessage(String userMessage) async {
    if (_chatSession == null) return;

    try {
      // Save user message to database
      await ChatsRecord.createDoc(FFAppState().Call.refrence!)
          .set(createChatsRecordData(
        sender: 'Slachtoffer',
        message: userMessage,
        timestamp: getCurrentTimestamp,
      ));

      // Get AI response
      final response =
          await _chatSession!.sendMessage(Content.text(userMessage));
      final aiResponse =
          response.text ?? "I couldn't process that. Can you tell me more?";

      // Clean response for display (remove tags)
      final cleanResponse = aiResponse
          .replaceAll(RegExp(r'\[\[level\d\]\]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\[SEVERITY:\s*\d\]', caseSensitive: false), '')
          .trim();

      // Save AI message to database (without tags)
      await ChatsRecord.createDoc(FFAppState().Call.refrence!)
          .set(createChatsRecordData(
        sender: 'Dispatch',
        message: cleanResponse,
        timestamp: getCurrentTimestamp,
      ));

      // Check if response contains severity level and update ermergencyLevel
      int? detectedLevel;
      final lowerResponse = aiResponse.toLowerCase();

      // Debug: print the response for testing
      print('📊 AI Response for level detection: $aiResponse');

      // First, look for [[levelX]] tags
      if (aiResponse.contains('[[level3]]') ||
          aiResponse.contains('[[LEVEL3]]')) {
        detectedLevel = 3;
        print('✅ Detected severity level from [[level3]] tag');
      } else if (aiResponse.contains('[[level2]]') ||
          aiResponse.contains('[[LEVEL2]]')) {
        detectedLevel = 2;
        print('✅ Detected severity level from [[level2]] tag');
      } else if (aiResponse.contains('[[level1]]') ||
          aiResponse.contains('[[LEVEL1]]')) {
        detectedLevel = 1;
        print('✅ Detected severity level from [[level1]] tag');
      } else {
        // Fallback: look for [SEVERITY: X] pattern
        final severityPattern =
            RegExp(r'\[SEVERITY:\s*(\d)\]', caseSensitive: false);
        final severityMatch = severityPattern.firstMatch(aiResponse);

        if (severityMatch != null) {
          final levelStr = severityMatch.group(1);
          detectedLevel = int.tryParse(levelStr ?? '');
          print(
              '✅ Detected severity level from [SEVERITY: X] tag: $detectedLevel');
        } else {
          // Final fallback: check for keywords if tags not found
          if (lowerResponse.contains('level 3') ||
              lowerResponse.contains('critical') ||
              lowerResponse.contains('life-threatening') ||
              lowerResponse.contains('severe') ||
              lowerResponse.contains('unconscious') ||
              lowerResponse.contains('breathing') ||
              lowerResponse.contains('poison')) {
            detectedLevel = 3;
          } else if (lowerResponse.contains('level 2') ||
              lowerResponse.contains('urgent') ||
              lowerResponse.contains('important') ||
              lowerResponse.contains('significant trauma')) {
            detectedLevel = 2;
          } else if (lowerResponse.contains('level 1') ||
              lowerResponse.contains('non-emergency') ||
              lowerResponse.contains('minor') ||
              lowerResponse.contains('first aid')) {
            detectedLevel = 1;
          }
          if (detectedLevel != null) {
            print('✅ Detected severity level from keywords: $detectedLevel');
          }
        }
      }

      // Update emergency level if detected
      if (detectedLevel != null && FFAppState().Call.refrence != null) {
        print('🚨 Emergency Level Detected: Level $detectedLevel');
        try {
          await FFAppState().Call.refrence!.update(createConnectionRecordData(
                ermergencyLevel: detectedLevel,
              ));
          print('✅ Emergency Level Updated Successfully to: $detectedLevel');
        } catch (updateError) {
          print('❌ Error updating emergency level: $updateError');
        }
      } else {
        print('⚠️ Could not detect level from response or missing reference');
      }

      // Clear text field
      _model.textController?.clear();
    } catch (e) {
      print('Error in AI conversation: $e');
      await ChatsRecord.createDoc(FFAppState().Call.refrence!)
          .set(createChatsRecordData(
        sender: 'Dispatch',
        message: 'I encountered an error. Please describe your situation.',
        timestamp: getCurrentTimestamp,
      ));
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

              // Send dispatch takeover message
              try {
                await ChatsRecord.createDoc(FFAppState().Call.refrence!)
                    .set(createChatsRecordData(
                  sender: 'System',
                  message: '✅ Dispatch is here! You are now connected.',
                  timestamp: getCurrentTimestamp,
                ));
              } catch (e) {
                print('Error sending dispatch takeover message: $e');
              }

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
                                        true) {
                                      print(_model.textController?.text);
                                      return;
                                    }

                                    final messageText =
                                        _model.textController!.text;

                                    // Check if we're still waiting for dispatch
                                    if (FFAppState().Call.status ==
                                        Statuscall.waiting) {
                                      // Initialize AI on first message if not done
                                      if (!_hasInitializedAI) {
                                        _initializeGemini();
                                        _hasInitializedAI = true;
                                      }
                                      // Route to AI triage assistant
                                      await _sendAIMessage(messageText);
                                    } else {
                                      // Send regular message to dispatch
                                      await ChatsRecord.createDoc(
                                              FFAppState().Call.refrence!)
                                          .set(createChatsRecordData(
                                        sender: 'Slachtoffer',
                                        message: messageText,
                                        timestamp: getCurrentTimestamp,
                                      ));
                                      _model.textController?.clear();
                                    }

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
