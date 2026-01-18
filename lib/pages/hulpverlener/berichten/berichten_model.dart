import '/components/navigation_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'berichten_widget.dart' show BerichtenWidget;
import 'package:flutter/material.dart';

class BerichtenModel extends FlutterFlowModel<BerichtenWidget> {
  ///  State fields for stateful widgets in this page.

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
