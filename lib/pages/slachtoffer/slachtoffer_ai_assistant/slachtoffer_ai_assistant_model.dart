import '/flutter_flow/flutter_flow_util.dart';
import 'slachtoffer_ai_assistant_widget.dart' show SlachtofferAIAssistantWidget;
import 'package:flutter/material.dart';

class SlachtofferAIAssistantModel
    extends FlutterFlowModel<SlachtofferAIAssistantWidget> {
  ///  State fields for stateful widgets in this page.

  final unfocusNode = FocusNode();
  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  // Local chat history
  List<Map<String, String>> chatHistory = [];
  bool isTyping = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
