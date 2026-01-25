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
  String? _selectedLanguage;

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
      'message':
          '👋 Welkom! Kies uw taal / Choisissez votre langue / Welcome! Choose your language:\n1. Nederlands 🇳🇱\n2. Français 🇫🇷\n3. English 🇬🇧'
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
        1. CRITICAL EMERGENCY: If you identify a life-threatening situation (e.g., severe bleeding, unconsciousness, not breathing, heart attack) OR if you feel faint, feel like falling, or feel like losing consciousness (EVEN IF you can walk), you MUST immediately output exactly 
           [[EMERGENCY_ACTION]] but if you are not sure ask questions to get more information.
           and then give short advice on what to do while help is on the way.
        
        2. NO MEDICINE: You are NOT a doctor. If you are asked for medicine, painkillers, or prescriptions, you must answer "We as red cross cant give any medication, please contact a doctor or go to the nearest hospital."
        
        3. SCOPE: Answer only First Aid (EHBO) questions. If the topic is not about safety or medical aid, politely refuse.
        
        4. TONE: Be calm, concise, and give instructions in steps. ALWAYS address the user directly as 'you' in their language. NEVER refer to 'the person' or 'the patient' unless they explicitly mention helping someone else.

        5. LANGUAGE: Automatically detect the language of the user's message (English, Dutch, or French). You MUST reply in that same language.

        6. LOCATION: 
           - If asked for where ehbo post or personel is you MUST output exactly: [[NAVIGATE_MAP]]
           - If asked for where a toilet is you MUST output exactly: [[NAVIGATE_TOILET]]
        
        7. UNLIMITED SUPPORT: The user can ask as many questions as they need. Provide the most thorough, accurate, and helpful First Aid advice possible for every query.
"""),
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

  Future<MapPinsRecord?> _getNearestPin(String iconType) async {
    try {
      // Get user's current location
      final position = await Geolocator.getCurrentPosition();
      final userLat = position.latitude;
      final userLng = position.longitude;

      // Query pins by iconType
      final querySnapshot = await MapPinsRecord.collection
          .where('iconType', isEqualTo: iconType)
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
        final text = userMessage.toLowerCase().trim();
        String? newLanguage;

        // Check for language change request
        bool isLanguageRequest = text.contains('verander naar') ||
            text.contains('switch to') ||
            text.contains('change to') ||
            text.contains('change naar');

        if (_selectedLanguage == null || isLanguageRequest) {
          if (text == '1' ||
              text.contains('nederlands') ||
              text.contains('dutch')) {
            newLanguage = 'Dutch';
          } else if (text == '2' ||
              text.contains('français') ||
              text.contains('french') ||
              text.contains('francais')) {
            newLanguage = 'French';
          } else if (text == '3' || text.contains('english')) {
            newLanguage = 'English';
          }
        }

        if (newLanguage != null && newLanguage != _selectedLanguage) {
          _selectedLanguage = newLanguage;
          // Prompt AI to acknowledge change in the new language
          final response = await _chatSession!.sendMessage(Content.text(
              "I have switched the language to $_selectedLanguage. Please introduce yourself as EHBO assistant in $_selectedLanguage and ask me 'How can I help you?' in that language."));
          aiResponse = response.text ??
              "Language switched to $_selectedLanguage. How can I help?";
        } else {
          // Standard message with language context if selected
          String prompt = userMessage;
          if (_selectedLanguage != null) {
            prompt =
                "User said: '$userMessage'. Please respond in $_selectedLanguage.";
          }
          final response =
              await _chatSession!.sendMessage(Content.text(prompt));
          aiResponse =
              response.text ?? "I'm sorry, I couldn't understand that.";
        }

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
            final nearestRedCross = await _getNearestPin('red_cross');

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
                        onPressed: () =>
                            Navigator.pop(alertDialogContext, true),
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
                SlachtofferMapWidget.shouldStartNavigation = true;
                SlachtofferMapWidget.targetLat = nearestRedCross.latitude;
                SlachtofferMapWidget.targetLng = nearestRedCross.longitude;
                SlachtofferMapWidget.targetName = nearestRedCross.name;

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

        if (aiResponse.contains('[[NAVIGATE_TOILET]]')) {
          setState(() {
            _model.isTyping = false;
          });

          if (mounted) {
            // Find nearest Toilet location
            final nearestToilet = await _getNearestPin('toilet');

            if (nearestToilet != null) {
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
                      'Navigate to Toilet?',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      'I found the nearest toilet: ${nearestToilet.name}. Would you like to navigate there on the map?',
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
                        onPressed: () =>
                            Navigator.pop(alertDialogContext, true),
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
                SlachtofferMapWidget.shouldStartNavigation = true;
                SlachtofferMapWidget.targetLat = nearestToilet.latitude;
                SlachtofferMapWidget.targetLng = nearestToilet.longitude;
                SlachtofferMapWidget.targetName = nearestToilet.name;

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
              // Show dialog if no Toilet found
              bool? shouldNavigate = await showDialog<bool>(
                context: context,
                builder: (alertDialogContext) {
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    title: const Text(
                      'No Toilets Found',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    content: const Text(
                      'No toilets are available in the current database. Would you like to view the map anyway?',
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
            .replaceAll('[[NAVIGATE_TOILET]]', '')
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
                            'EHBO Assistant',
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
                                final String senderName = isUser
                                    ? ((FFAppState().User.voornaam +
                                                ' ' +
                                                FFAppState().User.achternaam)
                                            .trim()
                                            .isEmpty
                                        ? 'ANONYMOUS'
                                        : (FFAppState().User.voornaam +
                                                ' ' +
                                                FFAppState().User.achternaam)
                                            .trim())
                                    : 'EHBO Assistant';

                                return Align(
                                  alignment: isUser
                                      ? AlignmentDirectional.centerEnd
                                      : AlignmentDirectional.centerStart,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: isUser
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          senderName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: isUser
                                              ? FlutterFlowTheme.of(context)
                                                  .primary
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Text(
                                          chatItem['message'] ?? '',
                                          style: TextStyle(
                                            color: isUser
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
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
                              'EHBO Assistant is typing...',
                              style: FlutterFlowTheme.of(context)
                                  .bodySmall
                                  .override(
                                      font: GoogleFonts.inter(),
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _model.textController,
                              focusNode: _model.textFieldFocusNode,
                              autofocus: false,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: Colors.grey[100],
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).primary,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: FlutterFlowTheme.of(context).error,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(24.0),
                                ),
                                contentPadding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 12.0),
                              ),
                              style: TextStyle(color: Colors.black),
                              cursorColor: Colors.black,
                              onFieldSubmitted: (_) => _handleSend(),
                            ),
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            onPressed: _handleSend,
                            icon: Icon(
                              Icons.send,
                              color: FlutterFlowTheme.of(context).primary,
                              size: 24.0,
                            ),
                          ),
                        ],
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
