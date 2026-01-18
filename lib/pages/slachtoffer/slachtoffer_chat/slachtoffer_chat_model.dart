import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'slachtoffer_chat_widget.dart' show SlachtofferChatWidget;
import 'package:flutter/material.dart';

class SlachtofferChatModel extends FlutterFlowModel<SlachtofferChatWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
