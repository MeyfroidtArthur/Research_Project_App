import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' show sqrt, cos, sin, atan2, pi;
import 'slachtoffer_ai_assistant_model.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/structs/index.dart';
import '/index.dart';

import '/pages/slachtoffer/slachtoffer_map/slachtoffer_map_widget.dart';

// SlachtofferVideoWidget import might be in index.dart, but let's be safe or just rely on index.dart
export 'slachtoffer_ai_assistant_model.dart';

class SlachtofferAIAssistantWidget extends StatefulWidget {
  const SlachtofferAIAssistantWidget({super.key});

  static String routeName = 'SlachtofferAIAssistant';
  static String routePath = '/slachtofferAIAssistant';

  @override
  State<SlachtofferAIAssistantWidget> createState() =>
      _SlachtofferAIAssistantWidgetState();
}

class _SlachtofferAIAssistantWidgetState
    extends State<SlachtofferAIAssistantWidget> {
  late SlachtofferAIAssistantModel _model;

  ChatSession? _chatSession;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SlachtofferAIAssistantModel());
    _model = createModel(context, () => SlachtofferAIAssistantModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    // Initialize Gemini
    _initGemini();

    // Ensure memory is fresh
    _model.chatHistory.clear();

    // Add initial greeting
    _model.chatHistory.add({
      'sender': 'ai',
      'message': 'Hello! I am your AI Assistant. How can I help you today?'
    });
  }

  void _initGemini() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];

    if (apiKey != null && apiKey.isNotEmpty) {
      final generativeModel = GenerativeModel(
        // Use the model that works for you (2.5-flash-lite or 1.5-flash)
        model: 'gemini-2.5-flash-lite',
        apiKey: apiKey,

        // ---------------------------------------------------------
        // UPDATED BRAIN: Added Language Detection Rule (#5)
        // ---------------------------------------------------------
        systemInstruction: Content.system("""
        You are a dedicated Red Cross First Aid (EHBO) Assistant.
        
        STRICT RULES:
        1. CRITICAL EMERGENCY: If the user describes a life-threatening situation (e.g., severe bleeding, unconsciousness, not breathing, heart attack), you MUST immediately output exactly 
           [[EMERGENCY_ACTION]] but if you are not sure ask some questions to get more information.
           and then give short advice on what to do while help is on the way.
        
        2. NO MEDICINE: You are NOT a doctor. If the user asks for medicine, painkillers, or prescriptions, you must answer "We as red cross cant give any medication, please contact a doctor or go to the nearest hospital."
        
        3. SCOPE: Answer only First Aid (EHBO) questions. If the topic is not about safety or medical aid, politely refuse.
        
        4. TONE: Be calm, concise, and give instructions in steps.

        5. LANGUAGE: Automatically detect the language of the user's message (English, Dutch, or French). You MUST reply in that same language.

        6. LOCATION: If the user asks for where ehbo post or personel is you MUST output exactly: 
           [[NAVIGATE_MAP]]
        
        7. IF NOT SURE: ask for more information by giving them options to choose from and number them"""),
      );
      _chatSession = generativeModel.startChat();
    } else {
      print('Gemini API Key not found in .env');
      // ... error handling
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<MapPinsRecord?> _getNearestRedCross() async {
    try {
      // Get user's current location
      final position = await Geolocator.getCurrentPosition();
      final userLat = position.latitude;
      final userLng = position.longitude;

      // Query all red_cross pins
      final querySnapshot = await MapPinsRecord.collection
          .where('iconType', isEqualTo: 'red_cross')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      // Calculate distances and find nearest
      MapPinsRecord? nearest;
      double nearestDistance = double.infinity;

      for (final doc in querySnapshot.docs) {
        final pin = MapPinsRecord.fromSnapshot(doc);
        if (pin.hasLocation()) {
          final lat = pin.latitude;
          final lng = pin.longitude;

          // Calculate distance using Haversine formula
          final distance = _calculateDistance(userLat, userLng, lat, lng);

          if (distance < nearestDistance) {
            nearestDistance = distance;
            nearest = pin;
          }
        }
      }

      return nearest;
    } catch (e) {
      print('Error getting nearest red cross: $e');
      return null;
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusKm = 6371;
    final double dLat = _toRadian(lat2 - lat1);
    final double dLng = _toRadian(lng2 - lng1);
    final double a = sqrt(sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadian(lat1)) *
            cos(_toRadian(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2));
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadian(double degree) {
    return degree * 3.14159265359 / 180;
  }

  Future<void> _handleSend() async {
    if (_model.textController == null ||
        _model.textController!.text.trim().isEmpty) return;

    final userMessage = _model.textController!.text;
    setState(() {
      _model.chatHistory.insert(0, {'sender': 'user', 'message': userMessage});
      _model.textController?.clear();
      _model.isTyping = true;
    });

    String aiResponse;

    if (_chatSession != null) {
      try {
        final response =
            await _chatSession!.sendMessage(Content.text(userMessage));
        aiResponse = response.text ?? "I'm sorry, I couldn't understand that.";

        if (aiResponse.contains('[[EMERGENCY_ACTION]]')) {
          setState(() {
            _model.isTyping = false;
          });

          if (mounted) {
            bool? shouldCall = await showDialog<bool>(
              context: context,
              builder: (alertDialogContext) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  title: const Text(
                    'EMERGENCY DETECTED',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  content: const Text(
                    'Do you want to call emergency services immediately?',
                    style: TextStyle(color: Colors.black),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(alertDialogContext, false),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: FlutterFlowTheme.of(context).primary,
                          width: 1.0,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: FlutterFlowTheme.of(context).primary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(alertDialogContext, true),
                      style: TextButton.styleFrom(
                        backgroundColor: FlutterFlowTheme.of(context).primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'CALL NOW',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );

            if (shouldCall == true && mounted) {
              // Create emergency call record
              var connectionRecordReference = ConnectionRecord.collection.doc();
              await connectionRecordReference.set(createConnectionRecordData(
                status: Statuscall.waiting,
                voornaam: FFAppState().User.voornaam,
                achternaam: FFAppState().User.achternaam,
                geboortedatum: FFAppState().User.geboorteDatum,
                gender: FFAppState().User.gender,
                adres: FFAppState().User.adres,
                gemeente: FFAppState().User.gemeente,
                land: FFAppState().User.land,
                extraInfo: FFAppState().User.extra,
                emergencyContact: FFAppState().User.noodcontact,
                ermergencyLevel: 1,
                eventId: FFAppState().Event.id,
              ));

              // Update AppState
              FFAppState().Call = ActiveCallStruct(
                status: Statuscall.waiting,
                refrence: connectionRecordReference,
              );

              if (mounted) {
                context.pushNamed(
                  SlachtofferVideoWidget.routeName,
                  extra: <String, dynamic>{
                    kTransitionInfoKey: TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 200),
                    ),
                  },
                );
              }
            }
          }
        }

        if (aiResponse.contains('[[NAVIGATE_MAP]]')) {
          setState(() {
            _model.isTyping = false;
          });

          if (mounted) {
            // Find nearest Red Cross location
            final nearestRedCross = await _getNearestRedCross();

            if (nearestRedCross != null) {
              // Ask user before navigating
              bool? shouldNavigate = await showDialog<bool>(
                context: context,
                builder: (alertDialogContext) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: const Text(
                      'Navigate to Red Cross?',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'I found the nearest Red Cross First Aid post: ${nearestRedCross.name}. Would you like to navigate there on the map?',
                      style: const TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(alertDialogContext, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(alertDialogContext, true),
                        style: TextButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'Navigate',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (shouldNavigate == true && mounted) {
                // Set static flags for navigation
                SlachtofferMapWidget.shouldStartNavigationToRedCross = true;
                SlachtofferMapWidget.targetRedCrossLat = nearestRedCross.latitude;
                SlachtofferMapWidget.targetRedCrossLng = nearestRedCross.longitude;
                SlachtofferMapWidget.targetRedCrossName = nearestRedCross.name;
                
                // Navigate to map
                context.pushNamed(
                  SlachtofferMapWidget.routeName,
                  extra: <String, dynamic>{
                    kTransitionInfoKey: TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 200),
                    ),
                  },
                );
              }
            } else {
              // Show dialog if no Red Cross found
              bool? shouldNavigate = await showDialog<bool>(
                context: context,
                builder: (alertDialogContext) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: const Text(
                      'No Red Cross Posts Found',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'No Red Cross First Aid posts are available in this area. Would you like to view the map anyway?',
                      style: TextStyle(color: Colors.black),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(alertDialogContext, false),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: FlutterFlowTheme.of(context).primary,
                            width: 1.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: FlutterFlowTheme.of(context).primary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(alertDialogContext, true),
                        style: TextButton.styleFrom(
                          backgroundColor: FlutterFlowTheme.of(context).primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'View Map',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );

              if (shouldNavigate == true && mounted) {
                context.pushNamed(
                  SlachtofferMapWidget.routeName,
                  extra: <String, dynamic>{
                    kTransitionInfoKey: TransitionInfo(
                      hasTransition: true,
                      transitionType: PageTransitionType.fade,
                      duration: Duration(milliseconds: 200),
                    ),
                  },
                );
              }
            }
          }
        }
      } catch (e) {
        aiResponse = "Error communicating with AI: $e";
      }
    } else {
      // Fallback if no API key
      await Future.delayed(const Duration(seconds: 1));
      final lowerMsg = userMessage.toLowerCase();
      if (lowerMsg.contains("help") || lowerMsg.contains("nood")) {
        aiResponse =
            "If this is an emergency, please return to the home screen and press the red button!";
      } else {
        aiResponse =
            "Gemini API is not configured. Please add GEMINI_API_KEY to .env file.";
      }
    }

    if (mounted) {
      setState(() {
        String displayResponse = aiResponse
            .replaceAll('[[EMERGENCY_ACTION]]', '')
            .replaceAll('[[NAVIGATE_MAP]]', '')
            .trim();

        if (displayResponse.isNotEmpty) {
          _model.chatHistory
              .insert(0, {'sender': 'ai', 'message': displayResponse});
        }
        _model.isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Header
                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Color(0xFF222222)),
                            onPressed: () {
                              context.safePop();
                            },
                          ),
                          Text(
                            'AI Assistant',
                            style: FlutterFlowTheme.of(context)
                                .titleLarge
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  color: Color(0xFF222222),
                                  fontSize: 21.0,
                                  fontWeight: FontWeight.bold,
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

                  // Chat Area
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
                      child: _model.chatHistory.isEmpty
                          ? Center(
                              child: Text(
                                'Ask me anything!',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: Color(0xFF5E5E5E),
                                    ),
                              ),
                            )
                          : ListView.separated(
                              padding: EdgeInsets.zero,
                              reverse: true,
                              itemCount: _model.chatHistory.length,
                              separatorBuilder: (_, __) =>
                                  SizedBox(height: 16.0),
                              itemBuilder: (context, index) {
                                final chatItem = _model.chatHistory[index];
                                final isUser = chatItem['sender'] == 'user';
                                return Align(
                                  alignment: isUser
                                      ? AlignmentDirectional.centerEnd
                                      : AlignmentDirectional.centerStart,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? FlutterFlowTheme.of(context).primary
                                          : FlutterFlowTheme.of(context)
                                              .secondaryBackground,
                                      borderRadius: BorderRadius.circular(16.0),
                                      border: Border.all(
                                        color: isUser
                                            ? Colors.transparent
                                            : FlutterFlowTheme.of(context)
                                                .primary,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Text(
                                        chatItem['message'] ?? '',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight: FontWeight.bold,
                                              ),
                                              color: isUser
                                                  ? Colors.white
                                                  : FlutterFlowTheme.of(context)
                                                      .primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Input Area
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      if (_model.isTyping)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'AI is typing...',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                      font: GoogleFonts.inter(),
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          borderRadius: BorderRadius.circular(100.0),
                          border: Border.all(
                            color: Color(0xFFC6C6C6),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _model.textController,
                                focusNode: _model.textFieldFocusNode,
                                autofocus: false,
                                decoration: InputDecoration(
                                  hintText: 'Type your question...',
                                  hintStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.inter(),
                                        color: Color(0xFF343330),
                                        fontSize: 12.0,
                                      ),
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding:
                                      EdgeInsetsDirectional.fromSTEB(
                                          16.0, 12.0, 16.0, 12.0),
                                ),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: Color(0xFF343330),
                                      fontSize: 12.0,
                                    ),
                                cursorColor: Color(0xFF343330),
                                onFieldSubmitted: (_) => _handleSend(),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 16.0, 0.0),
                              child: InkWell(
                                onTap: _handleSend,
                                child: Icon(
                                  Icons
                                      .send, // Using standard icon if FFIcons not found easily
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  size: 24.0,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
