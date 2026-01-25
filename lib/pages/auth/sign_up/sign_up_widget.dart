import '/backend/backend.dart';
import '/components/wrong_code_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'sign_up_model.dart';
export 'sign_up_model.dart';

/// Login Access Form
class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  static String routeName = 'SignUp';
  static String routePath = '/signUp';

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  late SignUpModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.loginAgainVrijwilliger = await queryEventRecordOnce(
        queryBuilder: (eventRecord) => eventRecord.where(
          'Vcode',
          isEqualTo: FFAppState().Event.code,
        ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      _model.loginAgainSlachtoffer = await queryEventRecordOnce(
        queryBuilder: (eventRecord) => eventRecord.where(
          'Scode',
          isEqualTo: FFAppState().Event.code,
        ),
        singleRecord: true,
      ).then((s) => s.firstOrNull);
      if (_model.loginAgainVrijwilliger?.reference != null) {
        context.pushNamed(
          HulpverlenerHomeWidget.routeName,
          extra: <String, dynamic>{
            kTransitionInfoKey: TransitionInfo(
              hasTransition: true,
              transitionType: PageTransitionType.fade,
              duration: Duration(milliseconds: 200),
            ),
          },
        );

        return;
      } else {
        if (_model.loginAgainSlachtoffer?.reference != null) {
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

          return;
        } else {
          return;
        }
      }
    });

    _model.codeTextController ??= TextEditingController();
    _model.codeFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primary,
        body: SafeArea(
          top: true,
          child: Align(
            alignment: AlignmentDirectional(0.0, 0.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Container(
                    width: 480.0,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: SvgPicture.asset(
                                'assets/images/Logo.svg',
                                width: 200.0,
                                height: 36.69,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Text(
                            'Krijg toegang tot het Redivo, enter code of scan qr code.',
                            textAlign: TextAlign.center,
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                                  color:
                                      FlutterFlowTheme.of(context).primaryText,
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.normal,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .fontStyle,
                                ),
                          ),
                          Container(
                            width: double.infinity,
                            child: TextFormField(
                              controller: _model.codeTextController,
                              focusNode: _model.codeFocusNode,
                              obscureText: false,
                              decoration: InputDecoration(
                                hintText: 'Code',
                                hintStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF686868),
                                      fontSize: 12.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFFCCCCCC),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0xFF802E2E),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color(0x00000000),
                                    width: 1.0,
                                  ),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                filled: true,
                                fillColor: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                contentPadding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 12.0, 16.0, 12.0),
                              ),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.normal,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF14181B),
                                    fontSize: 14.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.normal,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                              cursorColor: Color(0xFF802E2E),
                              validator: _model.codeTextControllerValidator
                                  .asValidator(context),
                            ),
                          ),
                          Builder(
                            builder: (context) => FFButtonWidget(
                              onPressed: () async {
                                var _shouldSetState = false;
                                _model.qrCodeData =
                                    await FlutterBarcodeScanner.scanBarcode(
                                  '#C62828', // scanning line color
                                  'Cancel', // cancel button text
                                  true, // whether to show the flash icon
                                  ScanMode.QR,
                                );

                                _shouldSetState = true;
                                if (_model.qrCodeData != '') {
                                  _model.eventListVrijwilligerQR =
                                      await queryEventRecordOnce(
                                    queryBuilder: (eventRecord) =>
                                        eventRecord.where(
                                      'Vcode',
                                      isEqualTo: _model.qrCodeData,
                                    ),
                                    singleRecord: true,
                                  ).then((s) => s.firstOrNull);
                                  _shouldSetState = true;
                                } else {
                                  Navigator.pop(context);
                                  if (_shouldSetState) safeSetState(() {});
                                  return;
                                }

                                _model.eventListSlachtofferQR =
                                    await queryEventRecordOnce(
                                  queryBuilder: (eventRecord) =>
                                      eventRecord.where(
                                    'Scode',
                                    isEqualTo: _model.qrCodeData,
                                  ),
                                  singleRecord: true,
                                ).then((s) => s.firstOrNull);
                                _shouldSetState = true;
                                if (_model.eventListVrijwilligerQR?.reference !=
                                    null) {
                                  FFAppState().Event = EventStruct(
                                    naam: _model.eventListVrijwilligerQR?.naam,
                                    locatie:
                                        _model.eventListVrijwilligerQR?.locatie,
                                    code: _model.qrCodeData,
                                    start: _model
                                        .eventListVrijwilligerQR?.startTime,
                                    end: _model.eventListVrijwilligerQR?.endTime,
                                    id: _model
                                        .eventListVrijwilligerQR?.reference,
                                  );
                                  safeSetState(() {});

                                  context.pushNamed(
                                    HulpverlenerHomeWidget.routeName,
                                    extra: <String, dynamic>{
                                      kTransitionInfoKey: TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                      ),
                                    },
                                  );
                                } else {
                                  if (_model
                                          .eventListSlachtofferQR?.reference !=
                                      null) {
                                    FFAppState().Event = EventStruct(
                                      naam: _model.eventListSlachtofferQR?.naam,
                                      locatie: _model
                                          .eventListSlachtofferQR?.locatie,
                                      code: _model.qrCodeData,
                                      start: _model
                                          .eventListSlachtofferQR?.startTime,
                                      end: _model
                                          .eventListSlachtofferQR?.endTime,
                                      id: _model
                                          .eventListSlachtofferQR?.reference,
                                    );
                                    safeSetState(() {});

                                    context.pushNamed(
                                      SlachtofferHomeWidget.routeName,
                                      extra: <String, dynamic>{
                                        kTransitionInfoKey: TransitionInfo(
                                          hasTransition: true,
                                          transitionType:
                                              PageTransitionType.fade,
                                        ),
                                      },
                                    );
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        Future.delayed(Duration(seconds: 1), () {
                                          if (Navigator.of(dialogContext)
                                              .canPop()) {
                                            Navigator.pop(dialogContext);
                                          }
                                        });
                                        return Dialog(
                                          elevation: 0,
                                          insetPadding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          alignment: AlignmentDirectional(
                                                  0.0, 0.0)
                                              .resolve(
                                                  Directionality.of(context)),
                                          child: GestureDetector(
                                            onTap: () {
                                              FocusScope.of(dialogContext)
                                                  .unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: WrongCodeWidget(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }

                                if (_shouldSetState) safeSetState(() {});
                              },
                              text: 'Scan qr code',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 48.0,
                                padding: EdgeInsets.all(8.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).textWhite,
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w300,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color:
                                          FlutterFlowTheme.of(context).primary,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w300,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderSide: BorderSide(
                                  color: Color(0xFF802E2E),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                          Builder(
                            builder: (context) => FFButtonWidget(
                              onPressed: () async {
                                var _shouldSetState = false;
                                if (_model.codeTextController.text != '') {
                                  _model.eventListVrijwilliger =
                                      await queryEventRecordOnce(
                                    queryBuilder: (eventRecord) =>
                                        eventRecord.where(
                                      'Vcode',
                                      isEqualTo: _model.codeTextController.text,
                                    ),
                                    singleRecord: true,
                                  ).then((s) => s.firstOrNull);
                                  _shouldSetState = true;
                                } else {
                                  if (_shouldSetState) safeSetState(() {});
                                  return;
                                }

                                _model.eventListSlachtoffer =
                                    await queryEventRecordOnce(
                                  queryBuilder: (eventRecord) =>
                                      eventRecord.where(
                                    'Scode',
                                    isEqualTo: _model.codeTextController.text,
                                  ),
                                  singleRecord: true,
                                ).then((s) => s.firstOrNull);
                                _shouldSetState = true;
                                if (_model.eventListVrijwilliger?.reference !=
                                    null) {
                                  FFAppState().Event = EventStruct(
                                    naam: _model.eventListVrijwilliger?.naam,
                                    locatie:
                                        _model.eventListVrijwilliger?.locatie,
                                    code: _model.codeTextController.text,
                                    start:
                                        _model.eventListVrijwilliger?.startTime,
                                    end: _model.eventListVrijwilliger?.endTime,
                                    id: _model.eventListVrijwilliger?.reference,
                                  );
                                  safeSetState(() {});

                                  context.pushNamed(
                                    HulpverlenerHomeWidget.routeName,
                                    extra: <String, dynamic>{
                                      kTransitionInfoKey: TransitionInfo(
                                        hasTransition: true,
                                        transitionType: PageTransitionType.fade,
                                      ),
                                    },
                                  );
                                } else {
                                  if (_model.eventListSlachtoffer?.reference !=
                                      null) {
                                    FFAppState().Event = EventStruct(
                                      naam: _model.eventListSlachtoffer?.naam,
                                      locatie:
                                          _model.eventListSlachtoffer?.locatie,
                                      code: _model.codeTextController.text,
                                      start: _model
                                          .eventListSlachtoffer?.startTime,
                                      end: _model.eventListSlachtoffer?.endTime,
                                      id: _model
                                          .eventListSlachtoffer?.reference,
                                    );
                                    safeSetState(() {});

                                    context.pushNamed(
                                      SlachtofferHomeWidget.routeName,
                                      extra: <String, dynamic>{
                                        kTransitionInfoKey: TransitionInfo(
                                          hasTransition: true,
                                          transitionType:
                                              PageTransitionType.fade,
                                        ),
                                      },
                                    );
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (dialogContext) {
                                        Future.delayed(Duration(seconds: 1), () {
                                          if (Navigator.of(dialogContext)
                                              .canPop()) {
                                            Navigator.pop(dialogContext);
                                          }
                                        });
                                        return Dialog(
                                          elevation: 0,
                                          insetPadding: EdgeInsets.zero,
                                          backgroundColor: Colors.transparent,
                                          alignment: AlignmentDirectional(
                                                  0.0, 0.0)
                                              .resolve(
                                                  Directionality.of(context)),
                                          child: GestureDetector(
                                            onTap: () {
                                              FocusScope.of(dialogContext)
                                                  .unfocus();
                                              FocusManager.instance.primaryFocus
                                                  ?.unfocus();
                                            },
                                            child: WrongCodeWidget(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }

                                if (_shouldSetState) safeSetState(() {});
                              },
                              text: 'Inloggen met code',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 48.0,
                                padding: EdgeInsets.all(8.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: Color(0xFF802E2E),
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w300,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w300,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 0.0,
                                borderSide: BorderSide(
                                  color: Color(0xFF802E2E),
                                  width: 1.0,
                                ),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ].divide(SizedBox(height: 24.0)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
