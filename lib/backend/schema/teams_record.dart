import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TeamsRecord extends FirestoreRecord {
  TeamsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Naam" field.
  String? _naam;
  String get naam => _naam ?? '';
  bool hasNaam() => _naam != null;

  // "Prefix" field.
  String? _prefix;
  String get prefix => _prefix ?? '';
  bool hasPrefix() => _prefix != null;

  // "Locatie" field.
  String? _locatie;
  String get locatie => _locatie ?? '';
  bool hasLocatie() => _locatie != null;

  // "Status" field.
  TeamStatus? _status;
  TeamStatus? get status => _status;
  bool hasStatus() => _status != null;

  // "EventId" field.
  DocumentReference? _eventId;
  DocumentReference? get eventId => _eventId;
  bool hasEventId() => _eventId != null;

  // "Location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "LastLocationUpdate" field.
  DateTime? _lastLocationUpdate;
  DateTime? get lastLocationUpdate => _lastLocationUpdate;
  bool hasLastLocationUpdate() => _lastLocationUpdate != null;

  void _initializeFields() {
    _naam = snapshotData['Naam'] as String?;
    _prefix = snapshotData['Prefix'] as String?;
    _locatie = snapshotData['Locatie'] as String?;
    _status = snapshotData['Status'] is TeamStatus
        ? snapshotData['Status']
        : deserializeEnum<TeamStatus>(snapshotData['Status']);
    _eventId = snapshotData['EventId'] as DocumentReference?;
    _location = snapshotData['Location'] as LatLng?;
    _lastLocationUpdate = snapshotData['LastLocationUpdate'] is Timestamp
        ? (snapshotData['LastLocationUpdate'] as Timestamp).toDate()
        : snapshotData['LastLocationUpdate'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Teams');

  static Stream<TeamsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => TeamsRecord.fromSnapshot(s));

  static Future<TeamsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => TeamsRecord.fromSnapshot(s));

  static TeamsRecord fromSnapshot(DocumentSnapshot snapshot) => TeamsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static TeamsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      TeamsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'TeamsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is TeamsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createTeamsRecordData({
  String? naam,
  String? prefix,
  String? locatie,
  TeamStatus? status,
  DocumentReference? eventId,
  LatLng? location,
  DateTime? lastLocationUpdate,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Naam': naam,
      'Prefix': prefix,
      'Locatie': locatie,
      'Status': status,
      'EventId': eventId,
      'Location': location,
      'LastLocationUpdate': lastLocationUpdate,
    }.withoutNulls,
  );

  return firestoreData;
}

class TeamsRecordDocumentEquality implements Equality<TeamsRecord> {
  const TeamsRecordDocumentEquality();

  @override
  bool equals(TeamsRecord? e1, TeamsRecord? e2) {
    return e1?.naam == e2?.naam &&
        e1?.prefix == e2?.prefix &&
        e1?.locatie == e2?.locatie &&
        e1?.status == e2?.status &&
        e1?.eventId == e2?.eventId &&
        e1?.location == e2?.location &&
        e1?.lastLocationUpdate == e2?.lastLocationUpdate;
  }

  @override
  int hash(TeamsRecord? e) => const ListEquality().hash([
        e?.naam,
        e?.prefix,
        e?.locatie,
        e?.status,
        e?.eventId,
        e?.location,
        e?.lastLocationUpdate
      ]);

  @override
  bool isValidKey(Object? o) => o is TeamsRecord;
}
