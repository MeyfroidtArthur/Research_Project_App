import 'package:latlong2/latlong.dart' as latlong;

/// Simple container for a calculated route.
class RouteResult {
  RouteResult({required this.points, required this.etaText});

  final List<latlong.LatLng> points;
  final String etaText;
}
