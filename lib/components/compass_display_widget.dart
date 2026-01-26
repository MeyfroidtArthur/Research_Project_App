import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CompassDisplayWidget extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destinationLocation;

  const CompassDisplayWidget({
    Key? key,
    required this.currentLocation,
    required this.destinationLocation,
  }) : super(key: key);

  @override
  _CompassDisplayWidgetState createState() => _CompassDisplayWidgetState();
}

class _CompassDisplayWidgetState extends State<CompassDisplayWidget> {
  double? _direction;
  double _bearing = 0.0;
  String _distanceText = '';

  @override
  void initState() {
    super.initState();
    _calculateBearing();
    _calculateDistance();
    _startCompass();
  }

  void _calculateBearing() {
    final bearing = Geolocator.bearingBetween(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
      widget.destinationLocation.latitude,
      widget.destinationLocation.longitude,
    );
    setState(() {
      _bearing = bearing;
    });
  }

  void _calculateDistance() {
    final distance = Geolocator.distanceBetween(
      widget.currentLocation.latitude,
      widget.currentLocation.longitude,
      widget.destinationLocation.latitude,
      widget.destinationLocation.longitude,
    );
    setState(() {
      if (distance < 1000) {
        _distanceText = '${distance.toStringAsFixed(0)} m';
      } else {
        _distanceText = '${(distance / 1000).toStringAsFixed(1)} km';
      }
    });
  }

  void _startCompass() {
    FlutterCompass.events!.listen((event) {
      if (mounted) {
        setState(() {
          _direction = event.heading;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // If direction is null, we can't show the compass properly
    if (_direction == null) {
      return Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: FlutterFlowTheme.of(context).primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Calibrating Compass...',
                style: FlutterFlowTheme.of(context).bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Calculate the rotation angle for the arrow
    // Bearing is the direction to the target (e.g. 90 degrees for East)
    // Direction is the device's current heading (e.g. 0 degrees for North)
    // We want the arrow to point to the target.
    // If we are facing North (0), and target is East (90), arrow should rotate 90.
    // If we are facing East (90), and target is East (90), arrow should rotate 0.
    // Formula: (Bearing - Heading)
    // We need to normalize it for display logic if needed, but Transform.rotate takes radians.

    // Convert to radians
    final rotation = (_bearing - _direction!) * (math.pi / 180);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 300,
        height: 350,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Destination',
              style: FlutterFlowTheme.of(context).headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _distanceText,
              style: FlutterFlowTheme.of(context).displaySmall.copyWith(
                    color: FlutterFlowTheme.of(context).primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 30),
            Stack(
              alignment: Alignment.center,
              children: [
                // Compass Rose Background (Static)
                Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FlutterFlowTheme.of(context).alternate,
                        width: 2,
                      ),
                    ),
                    child: Stack(children: [
                      Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text("N",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text("E",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text("S",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                              padding: EdgeInsets.all(4),
                              child: Text("W",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)))),
                    ])),
                // Rotating Arrow
                Transform.rotate(
                  angle: rotation,
                  child: Icon(
                    Icons.navigation,
                    size: 100,
                    color: FlutterFlowTheme.of(context).primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Follow the arrow',
              style: FlutterFlowTheme.of(context).bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
