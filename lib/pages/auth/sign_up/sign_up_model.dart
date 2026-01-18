import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'sign_up_widget.dart' show SignUpWidget;
import 'package:flutter/material.dart';

class SignUpModel extends FlutterFlowModel<SignUpWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Firestore Query - Query a collection] action in SignUp widget.
  EventRecord? loginAgainVrijwilliger;
  // Stores action output result for [Firestore Query - Query a collection] action in SignUp widget.
  EventRecord? loginAgainSlachtoffer;
  // State field(s) for Code widget.
  FocusNode? codeFocusNode;
  TextEditingController? codeTextController;
  String? Function(BuildContext, String?)? codeTextControllerValidator;
  var qrCodeData = '';
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EventRecord? eventListVrijwilligerQR;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EventRecord? eventListSlachtofferQR;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EventRecord? eventListVrijwilliger;
  // Stores action output result for [Firestore Query - Query a collection] action in Button widget.
  EventRecord? eventListSlachtoffer;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    codeFocusNode?.dispose();
    codeTextController?.dispose();
  }
}
