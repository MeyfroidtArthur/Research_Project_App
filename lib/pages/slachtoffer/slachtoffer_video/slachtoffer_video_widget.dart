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
import 'package:geolocator/geolocator.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'slachtoffer_video_model.dart';
export 'slachtoffer_video_model.dart';
import '/services/webrtc_service.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isProcessingDispatchMessage = false;
  String? _selectedLanguage;
  bool _hasLocationPermission = true; // Default to true to avoid flicker
  final WebRTCService _webrtcService = WebRTCService();
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    _requestMicrophonePermission();
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
      // Suppress notifications while on this page
      FlutterForegroundTask.sendDataToTask('chat_opened');

      // Immediate location sync and permission check
      _syncLocationImmediately();
    }
  }

  Future<void> _syncLocationImmediately() async {
    // Check permissions
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() => _hasLocationPermission = false);
      // Try to request
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.always ||
          requested == LocationPermission.whileInUse) {
        setState(() => _hasLocationPermission = true);
      } else {
        return; // Still no permission
      }
    } else {
      setState(() => _hasLocationPermission = true);
    }

    // Immediate push to Firestore
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (FFAppState().Call.refrence != null) {
        await FFAppState().Call.refrence!.update({
          'Location': GeoPoint(position.latitude, position.longitude),
          'LastLocationUpdate': FieldValue.serverTimestamp(),
        });
        print('📍 Immediate location sync successful');
      }
    } catch (e) {
      print('❌ Error during immediate location sync: $e');
    }
  }

  Future<void> _requestMicrophonePermission() async {
    await Permission.microphone.request();
  }

  Future<void> _initializeGemini() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey != null && apiKey.isNotEmpty) {
      final generativeModel = GenerativeModel(
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,
        systemInstruction: Content.system(
          """You are an emergency triage assistant for the Red Cross. Your job is to help assess your situation while you wait for dispatch.
          
IMPORTANT: In EVERY response, you must:
1. ALWAYS address the user directly as 'you' in the chosen language (e.g., 'Heb jij pijn?', 'Kun jij ademen?', 'As-tu mal?', 'Are you in pain?'). NEVER refer to 'the person' or 'the patient' unless you explicitly know they are helping someone else.
2. Provide specific options if the problem isn't clear, and number them. The categories are: 1. Bleeding (Bloeden), 2. Breathing (Ademhaling), 3. Walking (Lopen), 4. Intoxication (Intoxicatie), 5. Allergy (Allergie), 6. Pain (Pijn), 7. Other (Andere).
3. Ask clarifying questions in a calm, supportive manner about YOUR symptoms like: bleeding, inability to walk, breathing difficulty, unconsciousness, chest pain, severe allergic reaction, poisoning.
4. If you describe something that MIGHT be Level 3 (critical/life-threatening), ask MORE follow-up questions to confirm before assessing as Level 3
5. Only assess as Level 3 after you have enough information to be confident it's truly life-threatening
6. Continuously assess the severity based on all information you provide
7. ALWAYS include your current severity assessment at the END of your message in BOTH formats:
   - Text format: [SEVERITY: X] where X is 1, 2, or 3
   - Tag format: [[levelX]] where X is 1, 2, or 3


Severity Levels:
- Level 3 (CRITICAL): Life-threatening emergency. RULE: Use Level 3 if you CANNOT walk AND has life-threatening symptoms (bleeding, breathing difficulty, etc.), OR if you feel faint, feel like falling, or feel like losing consciousness (EVEN IF you can walk) = [[level3]]
- Level 2 (URGENT): 
  - You CANNOT walk but is stable (thinking clearly, no faintness, stable breathing).
  - Walking is hard or painful but there is NO faintness or feeling of falling.
  = [[level2]]
- Level 1 (NON-EMERGENCY): Needs help but not urgent. You can walk and think normally (minor injuries, first aid advice, support needed) = [[level1]]

IMPORTANT: Automatically detect the language of YOUR message (English, Dutch, or French) and reply in that same language unless a specific language has been selected.

IMPORTANT RULE: If you mention something serious (like "can't breathe", "bleeding", "unconscious", "feeling faint"), ask clarifying follow-up questions FIRST before assessing as Level 3 or 2. Only use Level 3 after you're confident based on multiple confirmations of the condition.

If you have asked enough questions and you are confident in your assessment, you can stop askign questions and say "I have enough information for the dispatcher, they will be with you as soon as possible."

8. After addressing the immediate symptoms, ask about YOUR history: 'Have you experienced this before?', 'Do you have any existing health issues?', or 'Are you taking any medication?'. 
   - IMPORTANT: DO NOT give any medication advice. If medication is mentioned, explicitly state: 'I cannot provide advice on medication.'
   - This information is for help assessment only and will not be saved permanently.

9. STRICT PRIVACY: You MUST NOT save, record, or remember any personal or medical information beyond the current triage assessment. Explicitly inform the user if they ask: "Your medical information is only used for this immediate assessment by the dispatcher and will not be stored in your permanent profile."

10. QUESTION LIMIT: Keep track of how many questions you ask. You are allowed a maximum of 10 questions. At the 10th question, you must stop asking new questions and say exactly: "Ok, ik heb genoeg vragen gesteld. De dispatch zal dadelijk bij jou zijn. Als je nog vragen hebt, vraag maar." (or the equivalent in the detected language).
EXAMPLE RESPONSE FORMAT:
"Can you tell me if you are breathing normally? Are you bleeding severely? [SEVERITY: 2] [[level2]]"

Always be compassionate and reassuring. Keep responses short and clear. NEVER forget to include BOTH the [SEVERITY: X] and [[levelX]] tags at the end of every message.""",
        ),
      );
      _chatSession = generativeModel.startChat();

      // Send initial welcome message
      try {
        await ChatsRecord.createDoc(FFAppState().Call.refrence!)
            .set(createChatsRecordData(
          sender: 'AI',
          message:
              '👋 Welkom! Kies uw taal / Choisissez votre langue / Welcome! Choose your language:\n1. Nederlands 🇳🇱\n2. Français 🇫🇷\n3. English 🇬🇧',
          timestamp: getCurrentTimestamp,
        ));
      } catch (e) {
        print('Error sending initial message: $e');
      }
    } else {
      print('Gemini API Key not found');
    }
  }

  Future<void> _sendAIMessage(String userMessage,
      {bool isSilent = false}) async {
    if (_chatSession == null) return;

    try {
      // Add language context to the prompt
      String prompt = userMessage;
      if (_selectedLanguage != null) {
        prompt =
            "User said: '$userMessage'. Please respond in $_selectedLanguage. IMPORTANT: You MUST still include the [SEVERITY: X] and [[levelX]] tags exactly as specified in your system instructions, in English.";
      }

      // Get AI response
      final response = await _chatSession!.sendMessage(Content.text(prompt));
      final aiResponse =
          response.text ?? "I couldn't process that. Can you tell me more?";

      // Clean response for display (remove tags)
      final cleanResponse = aiResponse
          .replaceAll(RegExp(r'\[\[level\d\]\]', caseSensitive: false), '')
          .replaceAll(RegExp(r'\[SEVERITY:\s*\d\]', caseSensitive: false), '')
          .trim();

      // Save AI message to database (without tags) if not silent
      if (!isSilent) {
        await ChatsRecord.createDoc(FFAppState().Call.refrence!)
            .set(createChatsRecordData(
          sender: 'AI',
          message: cleanResponse,
          timestamp: getCurrentTimestamp,
        ));
      }

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
    // Resume notifications when leaving the page
    FlutterForegroundTask.sendDataToTask('chat_closed');
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    if (FFAppState().Call.refrence != null) {
      _webrtcService.hangUp(FFAppState().Call.refrence!);
    }
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

              // Prevent duplicate execution if already processing
              if (!_isProcessingDispatchMessage) {
                _isProcessingDispatchMessage = true;

                // Send dispatch takeover message
                try {
                  // Check if message already exists to prevent duplicates
                  final existingMessages = await FFAppState()
                      .Call
                      .refrence!
                      .collection('chats')
                      .where('message',
                          isEqualTo:
                              '✅ Dispatch is here! You are now connected.')
                      .get();

                  if (existingMessages.docs.isEmpty) {
                    await ChatsRecord.createDoc(FFAppState().Call.refrence!)
                        .set(createChatsRecordData(
                      sender: 'AI',
                      message: '✅ Dispatch is here! You are now connected.',
                      timestamp: getCurrentTimestamp,
                    ));
                  }
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
              } // End of _isProcessingDispatchMessage check

              print('📞 Starting WebRTC Call');
              _webrtcService.startCall(FFAppState().Call.refrence!);
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
          child: Stack(
            children: [
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  FocusManager.instance.primaryFocus?.unfocus();
                },
                child: Scaffold(
                  key: scaffoldKey,
                  backgroundColor:
                      FlutterFlowTheme.of(context).secondaryBackground,
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
                                color: slachtofferVideoConnectionRecord
                                            .status ==
                                        Statuscall.active
                                    ? Color(0xFF4CAF50) // Green for active
                                    : Color(0xFFFF9800), // Orange for waiting
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slachtofferVideoConnectionRecord
                                                      .status ==
                                                  Statuscall.active
                                              ? "DISPATCHED ACCEPTED"
                                              : "EHBO ASSISTANT",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        ValueListenableBuilder<String>(
                                          valueListenable:
                                              _webrtcService.connectionState,
                                          builder: (context, connState, _) {
                                            return ValueListenableBuilder<
                                                String>(
                                              valueListenable:
                                                  _webrtcService.iceState,
                                              builder: (context, iceState, _) {
                                                return Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      slachtofferVideoConnectionRecord
                                                                  .status ==
                                                              Statuscall.active
                                                          ? "Voice connected. Dispatcher is listening."
                                                          : "You can chat with the dispatcher below.",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),
                                                    ),
                                                    if (slachtofferVideoConnectionRecord
                                                            .status ==
                                                        Statuscall.active)
                                                      Text(
                                                        "DEBUG: Conn: $connState | ICE: $iceState",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .yellowAccent,
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        )
                                      ],
                                    ),
                                  ),
                                  if (slachtofferVideoConnectionRecord.status ==
                                      Statuscall.active)
                                    IconButton(
                                      icon: Icon(
                                        _isMuted ? Icons.mic_off : Icons.mic,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        _webrtcService.toggleMute();
                                        setState(() {
                                          _isMuted = !_isMuted;
                                        });
                                      },
                                    ),
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
                                      final isMe =
                                          message.sender == 'Slachtoffer';

                                      return Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              message.sender,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: isMe
                                                    ? FlutterFlowTheme.of(
                                                            context)
                                                        .primary
                                                    : Colors.grey[200],
                                                borderRadius:
                                                    BorderRadius.circular(16),
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
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            // Input Area
                            Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _model.textController,
                                      style: TextStyle(color: Colors.black),
                                      decoration: InputDecoration(
                                        hintText: 'Type your message...',
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 2,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(24),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        filled: true,
                                        fillColor: Colors.grey[100],
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(Icons.send,
                                        color: FlutterFlowTheme.of(context)
                                            .primary),
                                    onPressed: () async {
                                      final messageText =
                                          _model.textController?.text.trim();
                                      if (messageText == null ||
                                          messageText.isEmpty) return;

                                      // Clear text field IMMEDIATELY to prevent double sends
                                      final textToSend = messageText;
                                      _model.textController?.clear();
                                      safeSetState(() {});

                                      // Always save user message to database
                                      await ChatsRecord.createDoc(
                                              FFAppState().Call.refrence!)
                                          .set(createChatsRecordData(
                                        sender: 'Slachtoffer',
                                        message: textToSend,
                                        timestamp: getCurrentTimestamp,
                                      ));

                                      // Check if we're still waiting for dispatch
                                      if (slachtofferVideoConnectionRecord
                                              .status ==
                                          Statuscall.waiting) {
                                        // Note: AI is already initialized in initState

                                        // Check if message is a language selection or change request
                                        final text =
                                            textToSend.toLowerCase().trim();
                                        String? newLanguage;

                                        // Check for "verander naar" or direct selection
                                        bool isLanguageRequest =
                                            text.contains('verander naar') ||
                                                text.contains('switch to') ||
                                                text.contains('change to') ||
                                                text.contains('change naar');

                                        if (_selectedLanguage == null ||
                                            isLanguageRequest) {
                                          if (text == '1' ||
                                              text.contains('nederlands') ||
                                              text.contains('dutch')) {
                                            newLanguage = 'Dutch';
                                          } else if (text == '2' ||
                                              text.contains('français') ||
                                              text.contains('french') ||
                                              text.contains('francais')) {
                                            newLanguage = 'French';
                                          } else if (text == '3' ||
                                              text.contains('english')) {
                                            newLanguage = 'English';
                                          }
                                        }

                                        if (newLanguage != null &&
                                            newLanguage != _selectedLanguage) {
                                          _selectedLanguage = newLanguage;
                                          // Language selected/changed, send a confirmation
                                          await _sendAIMessage(
                                              "I have switched the language to $_selectedLanguage. Please introduce yourself as EHBO triage assistant, address me directly as 'you', and ask me what the problem is by providing exactly these numbered options in $_selectedLanguage: 1. Bleeding, 2. Breathing, 3. Walking, 4. Intoxication, 5. Allergy, 6. Pain, 7. Other.",
                                              isSilent: false);
                                          return;
                                        }

                                        // Route to AI triage assistant
                                        await _sendAIMessage(textToSend,
                                            isSilent: false);
                                      } else {
                                        // Run AI in background to update level but don't show reply
                                        _sendAIMessage(textToSend,
                                            isSilent: true);
                                      }
                                    },
                                  ),
                                ],
                              ),
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
                      ),
                    ),
                  ),
                ),
              ),
              if (!_hasLocationPermission)
                Container(
                  color: Colors.black.withOpacity(0.85),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Colors.white,
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Locatie Toestemming Vereist',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .override(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Om u zo snel mogelijk te kunnen helpen, hebben we uw locatie nodig. Accepteer de toestemming om door te gaan.',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  fontFamily: 'Readex Pro',
                                  color: Colors.white70,
                                  letterSpacing: 0.0,
                                ),
                          ),
                          SizedBox(height: 24),
                          FFButtonWidget(
                            onPressed: () async {
                              await _syncLocationImmediately();
                            },
                            text: 'Toestemming Geven',
                            options: FFButtonOptions(
                              width: double.infinity,
                              height: 50,
                              padding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              iconPadding:
                                  EdgeInsetsDirectional.fromSTEB(0, 0, 0, 0),
                              color: FlutterFlowTheme.of(context).primary,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    fontFamily: 'Readex Pro',
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                  ),
                              elevation: 2,
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
