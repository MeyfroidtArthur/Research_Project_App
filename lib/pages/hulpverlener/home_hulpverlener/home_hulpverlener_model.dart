import '/components/navigation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import 'home_hulpverlener_widget.dart' show HomeHulpverlenerWidget;
import 'package:flutter/material.dart';

class HomeHulpverlenerModel extends FlutterFlowModel<HomeHulpverlenerWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for DropDown widget.
  String? dropDownValue;
  FormFieldController<String>? dropDownValueController;
  // Model for navigation component.
  late NavigationModel navigationModel;

  @override
  void initState(BuildContext context) {
    navigationModel = createModel(context, () => NavigationModel());
  }

  @override
  void dispose() {
    navigationModel.dispose();
  }
}
