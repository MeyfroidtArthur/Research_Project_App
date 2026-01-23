import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'hulpverlener_home_widget.dart' show HulpverlenerHomeWidget;
import 'package:flutter/material.dart';

class HulpverlenerHomeModel extends FlutterFlowModel<HulpverlenerHomeWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Stores action output result for [Backend Call - Read Document] action in DropDown widget.
  TeamsRecord? team;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
