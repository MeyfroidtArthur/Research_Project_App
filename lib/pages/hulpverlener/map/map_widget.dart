import '/backend/schema/enums/enums.dart';
import '/backend/backend.dart';

import '/components/navigation_banner.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/services/background_location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:http/http.dart' as http;
import 'map_model.dart';
import '/backend/schema/map_pins_record.dart';
import '/utils/map_utils.dart';
import '/utils/route_result.dart';
import 'dart:async'; // For StreamSubscription
import 'dart:convert';
import 'dart:math' show pi;

export 'map_model.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  static String routeName = 'Map';
  static String routePath = '/map';

  // Static flag to trigger navigation when opening the map
  static bool shouldStartNavigationToIntervention = false;

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late MapModel _model;
  final MapController _mapController = MapController();

  // Location tracking for distance calculation
  latlong.LatLng? currentUserLocation;
  // Use a nullable subscription to cancel it properly
  StreamSubscription<Position>? _positionStreamSubscription;
  StreamSubscription<CompassEvent>? _compassSubscription;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  String? mapboxAccessToken;
  String? _mapboxError;

  List<latlong.LatLng>? _routePoints;
  latlong.LatLng? _destinationLocation;
  String? _routeTargetName;
  String? _routeEtaText;
  bool _isFetchingRoute = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MapModel());
    _loadMapboxRx();
    _startLocationUpdates();
    _startCompassUpdates();

    // Check if we should auto-start navigation to intervention
    if (MapWidget.shouldStartNavigationToIntervention) {
      MapWidget.shouldStartNavigationToIntervention = false; // Reset flag
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndStartInterventionNavigation();
      });
    }
  }

  double currentHeading = 0.0;
  DateTime? _lastCompassUpdate;

  void _startCompassUpdates() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (mounted && event.heading != null) {
        // Throttle updates to max once per 100ms to reduce UI load
        final now = DateTime.now();
        if (_lastCompassUpdate == null ||
            now.difference(_lastCompassUpdate!).inMilliseconds > 100) {
          _lastCompassUpdate = now;
          setState(() {
            currentHeading = event.heading!;
          });
        }
      }
    });
  }

  void _startLocationUpdates() {
    // Listen to location changes to update distance calculations in real-time
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          currentUserLocation = latlong.LatLng(
            position.latitude,
            position.longitude,
          );
        });
      }
    });
  }

  Future<void> _loadMapboxRx() async {
    String? token;
    try {
      if (!dotenv.isInitialized) {
        await dotenv.load(fileName: ".env");
      }
      token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    } catch (e) {
      print('Mapbox token load failed: $e');
    }

    token ??= const String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

    if (!mounted) return;

    setState(() {
      mapboxAccessToken = token;
      _mapboxError = token == null
          ? 'MAPBOX_ACCESS_TOKEN missing. Add it to .env or pass --dart-define=MAPBOX_ACCESS_TOKEN=...'
          : null;
    });
  }

  Future<void> _centerOnUser() async {
    // Use the location we already have from the stream - instant!
    if (currentUserLocation != null) {
      _mapController.move(currentUserLocation!, 15.0);
      return;
    }

    // Only if we don't have a location yet, try to get last known position (fast)
    try {
      Position? position = await Geolocator.getLastKnownPosition();

      if (position != null && mounted) {
        setState(() {
          currentUserLocation = latlong.LatLng(
            position.latitude,
            position.longitude,
          );
        });

        _mapController.move(
          latlong.LatLng(position.latitude, position.longitude),
          15.0,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available yet')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location not available')),
        );
      }
    }
  }

  Future<void> _startNavigation(MapPinsRecord record) async {
    if (!record.hasLocation()) return;

    final userLoc = currentUserLocation;
    if (userLoc == null) {
      print('⚠️ No user location available yet');
      // Don't block - just trigger location fetch and return
      _centerOnUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      return;
    }

    final destination = latlong.LatLng(
      record.location!.latitude,
      record.location!.longitude,
    );

    setState(() {
      _isFetchingRoute = true;
      _routeTargetName = record.name;
      _routePoints = null;
      _destinationLocation = destination;
      _routeEtaText = null;
    });

    // Fetch route in background
    _fetchRoute(userLoc, destination).then((result) {
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isFetchingRoute = false;
          _routeTargetName = null;
          _routePoints = null;
          _routeEtaText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to build route right now.')),
        );
        return;
      }

      setState(() {
        _isFetchingRoute = false;
        _routePoints = result.points;
        _routeEtaText = result.etaText;
      });

      _fitRouteBounds(result.points);
    });
  }

  Future<RouteResult?> _fetchRoute(
    latlong.LatLng from,
    latlong.LatLng to,
  ) async {
    if (mapboxAccessToken == null) {
      print('❌ No Mapbox token available');
      return null;
    }

    final url = Uri.parse(
      'https://api.mapbox.com/directions/v5/mapbox/walking/${from.longitude},${from.latitude};${to.longitude},${to.latitude}?geometries=geojson&overview=full&access_token=$mapboxAccessToken',
    );

    print(
        '🗺️ Fetching route from ${from.latitude},${from.longitude} to ${to.latitude},${to.longitude}');

    try {
      final response = await http.get(url);
      print('📡 Mapbox response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('❌ Mapbox API error: ${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = (data['routes'] as List?) ?? [];

      if (routes.isEmpty) {
        print('❌ No routes found in response');
        return null;
      }

      final route = routes.first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>?;
      final coordinates = (geometry?['coordinates'] as List?) ?? [];

      final points = coordinates
          .map<latlong.LatLng>((coord) => latlong.LatLng(
                (coord[1] as num).toDouble(),
                (coord[0] as num).toDouble(),
              ))
          .toList();

      final durationSeconds = (route['duration'] as num?)?.toDouble();
      if (durationSeconds == null || points.isEmpty) {
        print('❌ Invalid route data');
        return null;
      }

      print(
          '✅ Route fetched: ${points.length} points, ${_formatDuration(durationSeconds)}');

      return RouteResult(
        points: points,
        etaText: _formatDuration(durationSeconds),
      );
    } catch (e) {
      print('❌ Route fetch error: $e');
      return null;
    }
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '$hours h';
    return '$hours h $remainingMinutes min';
  }

  void _clearRoute() {
    setState(() {
      _routePoints = null;
      _destinationLocation = null;
      _routeTargetName = null;
      _routeEtaText = null;
      _isFetchingRoute = false;
    });
  }

  void _fitRouteBounds(List<latlong.LatLng> points) {
    if (points.isEmpty) return;
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
    );
  }

  Future<void> _checkAndStartInterventionNavigation() async {
    // Wait a bit for location to be available
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Query for active intervention
    final interventions = await queryInterventieRecord(
      queryBuilder: (q) => q
          .where('teamId', arrayContains: FFAppState().TeamId)
          .where('status', isEqualTo: Statusinterventie.active.serialize()),
      limit: 1,
    ).first;

    if (interventions.isEmpty) return;

    final intervention = interventions.first;
    if (intervention.connectionId == null) return;

    // Get connection location
    final connection =
        await ConnectionRecord.getDocumentOnce(intervention.connectionId!);
    if (!connection.hasLocation()) return;

    final destination = latlong.LatLng(
      connection.location!.latitude,
      connection.location!.longitude,
    );

    // Start navigation
    if (mounted) {
      _startNavigationToPoint(destination, 'Interventie Locatie');
    }
  }

  Future<void> _startNavigationToPoint(
      latlong.LatLng destination, String name) async {
    final userLoc = currentUserLocation;

    // If we don't have user location yet, try to get it once
    if (userLoc == null) {
      _centerOnUser();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Getting your location...')),
      );
      return;
    }

    setState(() {
      _isFetchingRoute = true;
      _routeTargetName = name;
      _routePoints = null;
      _destinationLocation = destination;
      _routeEtaText = null;
    });

    // Fetch route in background
    _fetchRoute(currentUserLocation!, destination).then((result) {
      if (!mounted) return;

      if (result == null) {
        setState(() {
          _isFetchingRoute = false;
          _routeTargetName = null;
          _routePoints = null;
          _routeEtaText = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to build route right now.')),
        );
        return;
      }

      setState(() {
        _isFetchingRoute = false;
        _routePoints = result.points;
        _routeEtaText = result.etaText;
      });

      _fitRouteBounds(result.points);
    });
  }

  @override
  void dispose() {
    _model.dispose();
    _positionStreamSubscription?.cancel();
    _compassSubscription?.cancel();
    print('🛑 Map disposed - stopped location and compass updates');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we have an Event Reference to listen to
    final eventRef = FFAppState().Event.id;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          title: ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: SvgPicture.asset(
              'assets/images/LogoWhite.svg',
              fit: BoxFit.contain,
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 16.0, 0.0),
              child: InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                   // Update team status and stop location tracking before logout
                   if (FFAppState().TeamId != null) {
                     await FFAppState().TeamId!.update(createTeamsRecordData(
                       status: TeamStatus.Unavailable,
                     ));
                   }
                   final locationService = BackgroundLocationService();
                   await locationService.stopTracking();

                  context.pushNamed(
                    SignUpWidget.routeName,
                    extra: <String, dynamic>{
                      kTransitionInfoKey: TransitionInfo(
                        hasTransition: true,
                        transitionType: PageTransitionType.fade,
                      ),
                    },
                  );

                  FFAppState().deleteEvent();
                  FFAppState().Event = EventStruct();

                  FFAppState().deleteTeamLabel();
                  FFAppState().TeamLabel = 'Select...';

                  FFAppState().deleteTeamId();
                  FFAppState().TeamId = null;

                  safeSetState(() {});
                },
                child: Icon(FFIcons.ksignOut, color: Colors.white, size: 24.0),
              ),
            ),
          ],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: _mapboxError != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _mapboxError!,
                                  textAlign: TextAlign.center,
                                  style:
                                      FlutterFlowTheme.of(context).bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadMapboxRx,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : mapboxAccessToken == null
                            ? Center(child: CircularProgressIndicator())
                            : StreamBuilder<EventRecord>(
                                stream: eventRef != null
                                    ? EventRecord.getDocument(eventRef)
                                    : null,
                                builder: (context, snapshot) {
                                  // Default location (Netherlands)
                                  latlong.LatLng centerLocation =
                                      latlong.LatLng(
                                    52.1326,
                                    5.2913,
                                  );
                                  bool hasLocation = false;

                                  if (snapshot.hasData &&
                                      snapshot.data!.hasLocationCoordinates()) {
                                    centerLocation = latlong.LatLng(
                                      snapshot
                                          .data!.locationCoordinates!.latitude,
                                      snapshot
                                          .data!.locationCoordinates!.longitude,
                                    );
                                    hasLocation = true;
                                  } else if (FFAppState()
                                      .Event
                                      .hasLocationCoordinates()) {
                                    // Fallback to AppState if stream has no data yet but AppState does
                                    centerLocation = latlong.LatLng(
                                      FFAppState()
                                          .Event
                                          .locationCoordinates!
                                          .latitude,
                                      FFAppState()
                                          .Event
                                          .locationCoordinates!
                                          .longitude,
                                    );
                                    hasLocation = true;
                                  }

                                  return StreamBuilder<List<InterventieRecord>>(
                                    stream: queryInterventieRecord(
                                      queryBuilder: (q) => q
                                          .where(
                                            'teamId',
                                            arrayContains: FFAppState().TeamId,
                                          )
                                          .where(
                                            'status',
                                            isEqualTo: Statusinterventie.active
                                                .serialize(),
                                          ),
                                      limit: 1,
                                    ),
                                    builder: (context, interventionSnapshot) {
                                      final activeIntervention =
                                          interventionSnapshot.hasData &&
                                                  interventionSnapshot
                                                      .data!.isNotEmpty
                                              ? interventionSnapshot.data!.first
                                              : null;

                                      return StreamBuilder<ConnectionRecord>(
                                        stream:
                                            activeIntervention?.connectionId !=
                                                    null
                                                ? ConnectionRecord.getDocument(
                                                    activeIntervention!
                                                        .connectionId!)
                                                : null,
                                        builder: (context, connectionSnapshot) {
                                          latlong.LatLng?
                                              activeInterventionLocation;
                                          if (connectionSnapshot.hasData &&
                                              connectionSnapshot.data!
                                                  .hasLocation()) {
                                            activeInterventionLocation =
                                                latlong.LatLng(
                                              connectionSnapshot
                                                  .data!.location!.latitude,
                                              connectionSnapshot
                                                  .data!.location!.longitude,
                                            );
                                          }

                                          return StreamBuilder<
                                              List<MapPinsRecord>>(
                                            stream: queryMapPinsRecord(
                                              queryBuilder: eventRef != null
                                                  ? (q) => q.where('eventRef',
                                                      isEqualTo: eventRef)
                                                  : null,
                                            ),
                                            builder: (context, pinsSnapshot) {
                                              if (!pinsSnapshot.hasData) {
                                                return Center(
                                                  child: SizedBox(
                                                    width: 50.0,
                                                    height: 50.0,
                                                    child:
                                                        CircularProgressIndicator(
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                              Color>(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primary,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }

                                              List<MapPinsRecord>
                                                  mapPinsRecordList =
                                                  pinsSnapshot.data!;

                                              // Calculate distances if user location is known
                                              final userLoc =
                                                  currentUserLocation;
                                              if (userLoc != null) {
                                                mapPinsRecordList.sort((a, b) {
                                                  if (!a.hasLocation() ||
                                                      !b.hasLocation())
                                                    return 0;
                                                  final distA = Geolocator
                                                      .distanceBetween(
                                                    userLoc.latitude,
                                                    userLoc.longitude,
                                                    a.location!.latitude,
                                                    a.location!.longitude,
                                                  );
                                                  final distB = Geolocator
                                                      .distanceBetween(
                                                    userLoc.latitude,
                                                    userLoc.longitude,
                                                    b.location!.latitude,
                                                    b.location!.longitude,
                                                  );
                                                  return distA.compareTo(distB);
                                                });
                                              }

                                              return Stack(
                                                children: [
                                                  FlutterMap(
                                                    mapController:
                                                        _mapController,
                                                    options: MapOptions(
                                                      initialCenter:
                                                          centerLocation,
                                                      initialZoom: 13.0,
                                                      onMapReady: () {
                                                        _centerOnUser();
                                                      },
                                                    ),
                                                    children: [
                                                      TileLayer(
                                                        urlTemplate:
                                                            'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken',
                                                        additionalOptions: {
                                                          'accessToken':
                                                              mapboxAccessToken!,
                                                        },
                                                      ),
                                                      if (_routePoints != null)
                                                        PolylineLayer(
                                                          polylines: [
                                                            Polyline(
                                                              points:
                                                                  _routePoints!,
                                                              strokeWidth: 5,
                                                              color: Colors
                                                                  .blueAccent,
                                                            ),
                                                          ],
                                                        ),
                                                      MarkerLayer(
                                                        markers: [
                                                          ...mapPinsRecordList
                                                              .map(
                                                                  (mapPinsRecord) {
                                                                return mapPinsRecord
                                                                        .hasLocation()
                                                                    ? Marker(
                                                                        width:
                                                                            50.0,
                                                                        height:
                                                                            50.0,
                                                                        point: latlong
                                                                            .LatLng(
                                                                          mapPinsRecord
                                                                              .location!
                                                                              .latitude,
                                                                          mapPinsRecord
                                                                              .location!
                                                                              .longitude,
                                                                        ),
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            _showPinDetails(
                                                                                context,
                                                                                mapPinsRecord,
                                                                                userLoc);
                                                                          },
                                                                          child:
                                                                              MapUtils.getMarkerIcon(mapPinsRecord.iconType),
                                                                        ),
                                                                      )
                                                                    : null;
                                                              })
                                                              .where((marker) =>
                                                                  marker !=
                                                                  null)
                                                              .cast<Marker>()
                                                              .toList(),
                                                        ],
                                                      ),
                                                      if (_routePoints != null)
                                                        PolylineLayer(
                                                          polylines: [
                                                            Polyline(
                                                              points:
                                                                  _routePoints!,
                                                              strokeWidth: 5,
                                                              color: Colors
                                                                  .blueAccent,
                                                            ),
                                                          ],
                                                        ),
                                                      CurrentLocationLayer(
                                                        style:
                                                            LocationMarkerStyle(
                                                          marker:
                                                              DefaultLocationMarker(
                                                            color: Colors.blue,
                                                            child: Transform
                                                                .rotate(
                                                              angle:
                                                                  currentHeading *
                                                                      (pi /
                                                                          180),
                                                              child: Icon(
                                                                Icons
                                                                    .navigation,
                                                                color: Colors
                                                                    .white,
                                                                size: 16,
                                                              ),
                                                            ),
                                                          ),
                                                          markerSize:
                                                              const Size(
                                                                  40, 40),
                                                          accuracyCircleColor:
                                                              Colors.blue
                                                                  .withOpacity(
                                                                      0.1),
                                                          headingSectorColor:
                                                              Colors
                                                                  .blue
                                                                  .withOpacity(
                                                                      0.25),
                                                          headingSectorRadius:
                                                              120,
                                                        ),
                                                        alignPositionOnUpdate:
                                                            AlignOnUpdate.never,
                                                        alignDirectionOnUpdate:
                                                            AlignOnUpdate.never,
                                                      ),
                                                      if (activeInterventionLocation !=
                                                          null)
                                                        MarkerLayer(
                                                          markers: [
                                                            Marker(
                                                              width: 40.0,
                                                              height: 40.0,
                                                              point:
                                                                  activeInterventionLocation,
                                                              child: Container(
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: Colors
                                                                      .red,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                  border: Border
                                                                      .all(
                                                                    color: Colors
                                                                        .white,
                                                                    width: 2.0,
                                                                  ),
                                                                  boxShadow: [
                                                                    BoxShadow(
                                                                      color: Colors
                                                                          .black26,
                                                                      blurRadius:
                                                                          4,
                                                                      offset:
                                                                          Offset(
                                                                              0,
                                                                              2),
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: Icon(
                                                                  Icons
                                                                      .priority_high_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24.0,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                    ],
                                                  ),
                                                  DraggableScrollableSheet(
                                                    initialChildSize: 0.15,
                                                    minChildSize: 0.15,
                                                    maxChildSize: 0.6,
                                                    builder: (BuildContext
                                                            context,
                                                        ScrollController
                                                            scrollController) {
                                                      return Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .secondaryBackground,
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .vertical(
                                                                  top: Radius
                                                                      .circular(
                                                                          20)),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              blurRadius: 10,
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.1),
                                                              spreadRadius: 2,
                                                            )
                                                          ],
                                                        ),
                                                        child: Column(
                                                          children: [
                                                            Center(
                                                              child: Container(
                                                                margin: const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        12),
                                                                width: 40,
                                                                height: 4,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .alternate,
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              2),
                                                                ),
                                                              ),
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      bottom:
                                                                          12.0),
                                                              child: Text(
                                                                'LOCATIONS',
                                                                style: FlutterFlowTheme.of(
                                                                        context)
                                                                    .labelMedium
                                                                    .override(
                                                                      fontFamily:
                                                                          'Inter',
                                                                      letterSpacing:
                                                                          1.5,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                    ),
                                                              ),
                                                            ),
                                                            Expanded(
                                                              child: ListView
                                                                  .separated(
                                                                controller:
                                                                    scrollController,
                                                                padding:
                                                                    EdgeInsets
                                                                        .zero,
                                                                itemCount:
                                                                    mapPinsRecordList
                                                                        .length,
                                                                separatorBuilder: (context,
                                                                        index) =>
                                                                    Divider(
                                                                        height:
                                                                            1,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .alternate),
                                                                itemBuilder:
                                                                    (context,
                                                                        index) {
                                                                  final record =
                                                                      mapPinsRecordList[
                                                                          index];
                                                                  final dist = userLoc !=
                                                                              null &&
                                                                          record
                                                                              .hasLocation()
                                                                      ? (Geolocator.distanceBetween(
                                                                                userLoc.latitude,
                                                                                userLoc.longitude,
                                                                                record.location!.latitude,
                                                                                record.location!.longitude,
                                                                              ) /
                                                                              1000)
                                                                          .toStringAsFixed(1)
                                                                      : null;

                                                                  return ListTile(
                                                                    leading:
                                                                        Column(
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        MapUtils.getMarkerIcon(
                                                                            record
                                                                                .iconType,
                                                                            size:
                                                                                30),
                                                                      ],
                                                                    ),
                                                                    title: Text(
                                                                      record
                                                                          .name,
                                                                      style: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .override(
                                                                            fontFamily:
                                                                                'Inter',
                                                                            fontWeight:
                                                                                FontWeight.w600,
                                                                          ),
                                                                    ),
                                                                    subtitle: dist !=
                                                                            null
                                                                        ? Text(
                                                                            '$dist km',
                                                                            style:
                                                                                FlutterFlowTheme.of(context).bodySmall,
                                                                          )
                                                                        : null,
                                                                    onTap: () {
                                                                      if (record
                                                                          .hasLocation()) {
                                                                        _mapController.move(
                                                                            latlong.LatLng(record.location!.latitude,
                                                                                record.location!.longitude),
                                                                            15);
                                                                      }
                                                                    },
                                                                    trailing:
                                                                        IconButton(
                                                                      icon: const Icon(
                                                                          Icons
                                                                              .navigation),
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primary,
                                                                      onPressed:
                                                                          () {
                                                                        print(
                                                                            '🔘 Navigation button pressed for: ${record.name}');
                                                                        _startNavigation(
                                                                            record);
                                                                      },
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
              Align(
                alignment: const AlignmentDirectional(0.9, 0.8),
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
                  child: FloatingActionButton(
                    heroTag: 'centerHulpverlener',
                    onPressed: () async {
                      await _centerOnUser();
                    },
                    backgroundColor: FlutterFlowTheme.of(context).primary,
                    elevation: 8.0,
                    child: Icon(
                      Icons.my_location,
                      color: FlutterFlowTheme.of(context).info,
                      size: 24.0,
                    ),
                  ),
                ),
              ),
              if (_routeTargetName != null)
                Align(
                  alignment: const AlignmentDirectional(0.0, -0.95),
                  child: NavigationBanner(
                    targetName: _routeTargetName!,
                    isCalculating: _isFetchingRoute,
                    etaText: _routeEtaText,
                    onClose: _clearRoute,
                    currentHeading: currentHeading,
                    bearing: (currentUserLocation != null &&
                            _destinationLocation != null)
                        ? MapUtils.calculateBearing(
                            currentUserLocation!.latitude,
                            currentUserLocation!.longitude,
                            _destinationLocation!.latitude,
                            _destinationLocation!.longitude,
                          )
                        : null,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPinDetails(
      BuildContext context, MapPinsRecord record, latlong.LatLng? userLoc) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dist = userLoc != null && record.hasLocation()
            ? (Geolocator.distanceBetween(
                      userLoc.latitude,
                      userLoc.longitude,
                      record.location!.latitude,
                      record.location!.longitude,
                    ) /
                    1000)
                .toStringAsFixed(1)
            : null;

        return Container(
          padding: const EdgeInsets.all(24),
          color: FlutterFlowTheme.of(context).secondaryBackground,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                record.name,
                style: FlutterFlowTheme.of(context).headlineMedium,
              ),
              const SizedBox(height: 8),
              if (dist != null)
                Text(
                  '$dist km away',
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Inter',
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
