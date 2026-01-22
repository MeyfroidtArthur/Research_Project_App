import 'dart:async';

import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MapPinsRecord extends FirestoreRecord {
  MapPinsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "latitude" field.
  double? _latitude;
  double get latitude => _latitude ?? 0.0;
  bool hasLatitude() => _latitude != null;

  // "longitude" field.
  double? _longitude;
  double get longitude => _longitude ?? 0.0;
  bool hasLongitude() => _longitude != null;

  // Convenience getter
  LatLng? get location => (_latitude != null && _longitude != null)
      ? LatLng(_latitude!, _longitude!)
      : null;
  bool hasLocation() => location != null;

  // "iconType" field.
  String? _iconType;
  String get iconType => _iconType ?? '';
  bool hasIconType() => _iconType != null;

  // "eventRef" field.
  DocumentReference? _eventRef;
  DocumentReference? get eventRef => _eventRef;
  bool hasEventRef() => _eventRef != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _latitude = castToType<double>(snapshotData['latitude']);
    _longitude = castToType<double>(snapshotData['longitude']);
    _iconType = snapshotData['iconType'] as String?;
    _eventRef = snapshotData['eventRef'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('map_pins');

  static Stream<MapPinsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MapPinsRecord.fromSnapshot(s));

  static Future<MapPinsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MapPinsRecord.fromSnapshot(s));

  static MapPinsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MapPinsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MapPinsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MapPinsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MapPinsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MapPinsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMapPinsRecordData({
  String? name,
  double? latitude,
  double? longitude,
  String? iconType,
  DocumentReference? eventRef,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'iconType': iconType,
      'eventRef': eventRef,
    }.withoutNulls,
  );

  return firestoreData;
}

class MapPinsRecordDocumentEquality implements Equality<MapPinsRecord> {
  const MapPinsRecordDocumentEquality();

  @override
  bool equals(MapPinsRecord? e1, MapPinsRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.latitude == e2?.latitude &&
        e1?.longitude == e2?.longitude &&
        e1?.iconType == e2?.iconType &&
        e1?.eventRef == e2?.eventRef;
  }

  @override
  int hash(MapPinsRecord? e) => const ListEquality()
      .hash([e?.name, e?.latitude, e?.longitude, e?.iconType, e?.eventRef]);

  @override
  bool isValidKey(Object? o) => o is MapPinsRecord;
}
