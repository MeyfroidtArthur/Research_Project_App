import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class TeamsRecord extends FirestoreRecord {
  TeamsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "EventId" field.
  String? _eventId;
  String get eventId => _eventId ?? '';
  bool hasEventId() => _eventId != null;

  // "Naam" field.
  String? _naam;
  String get naam => _naam ?? '';
  bool hasNaam() => _naam != null;

  // "Prefix" field.
  String? _prefix;
  String get prefix => _prefix ?? '';
  bool hasPrefix() => _prefix != null;

  // "Status" field.
  String? _status;
  String get status => _status ?? '';
  bool hasStatus() => _status != null;

  // "Locatie" field.
  String? _locatie;
  String get locatie => _locatie ?? '';
  bool hasLocatie() => _locatie != null;

  void _initializeFields() {
    _eventId = snapshotData['EventId'] as String?;
    _naam = snapshotData['Naam'] as String?;
    _prefix = snapshotData['Prefix'] as String?;
    _status = snapshotData['Status'] as String?;
    _locatie = snapshotData['Locatie'] as String?;
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
  String? eventId,
  String? naam,
  String? prefix,
  String? status,
  String? locatie,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'EventId': eventId,
      'Naam': naam,
      'Prefix': prefix,
      'Status': status,
      'Locatie': locatie,
    }.withoutNulls,
  );

  return firestoreData;
}

class TeamsRecordDocumentEquality implements Equality<TeamsRecord> {
  const TeamsRecordDocumentEquality();

  @override
  bool equals(TeamsRecord? e1, TeamsRecord? e2) {
    return e1?.eventId == e2?.eventId &&
        e1?.naam == e2?.naam &&
        e1?.prefix == e2?.prefix &&
        e1?.status == e2?.status &&
        e1?.locatie == e2?.locatie;
  }

  @override
  int hash(TeamsRecord? e) => const ListEquality()
      .hash([e?.eventId, e?.naam, e?.prefix, e?.status, e?.locatie]);

  @override
  bool isValidKey(Object? o) => o is TeamsRecord;
}
