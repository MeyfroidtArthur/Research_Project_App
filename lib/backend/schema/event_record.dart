import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class EventRecord extends FirestoreRecord {
  EventRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "Naam" field.
  String? _naam;
  String get naam => _naam ?? '';
  bool hasNaam() => _naam != null;

  // "Locatie" field.
  String? _locatie;
  String get locatie => _locatie ?? '';
  bool hasLocatie() => _locatie != null;

  // "LocationCoordinates" field.
  LatLng? _locationCoordinates;
  LatLng? get locationCoordinates => _locationCoordinates;
  bool hasLocationCoordinates() => _locationCoordinates != null;

  // "CreatedBy" field.
  String? _createdBy;
  String get createdBy => _createdBy ?? '';
  bool hasCreatedBy() => _createdBy != null;

  // "StartTime" field.
  DateTime? _startTime;
  DateTime? get startTime => _startTime;
  bool hasStartTime() => _startTime != null;

  // "EndTime" field.
  DateTime? _endTime;
  DateTime? get endTime => _endTime;
  bool hasEndTime() => _endTime != null;

  // "Vcode" field.
  String? _vcode;
  String get vcode => _vcode ?? '';
  bool hasVcode() => _vcode != null;

  // "Dcode" field.
  String? _dcode;
  String get dcode => _dcode ?? '';
  bool hasDcode() => _dcode != null;

  // "Scode" field.
  String? _scode;
  String get scode => _scode ?? '';
  bool hasScode() => _scode != null;

  void _initializeFields() {
    _naam = snapshotData['Naam'] as String?;
    _locatie = snapshotData['Locatie'] as String?;
    _locationCoordinates = snapshotData['LocationCoordinates'] as LatLng?;
    _createdBy = snapshotData['CreatedBy'] as String?;
    _startTime = snapshotData['StartTime'] as DateTime?;
    _endTime = snapshotData['EndTime'] as DateTime?;
    _vcode = snapshotData['Vcode'] as String?;
    _dcode = snapshotData['Dcode'] as String?;
    _scode = snapshotData['Scode'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Event');

  static Stream<EventRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => EventRecord.fromSnapshot(s));

  static Future<EventRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => EventRecord.fromSnapshot(s));

  static EventRecord fromSnapshot(DocumentSnapshot snapshot) => EventRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static EventRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      EventRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'EventRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is EventRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createEventRecordData({
  String? naam,
  String? locatie,
  LatLng? locationCoordinates,
  String? createdBy,
  DateTime? startTime,
  DateTime? endTime,
  String? vcode,
  String? dcode,
  String? scode,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'Naam': naam,
      'Locatie': locatie,
      'LocationCoordinates': locationCoordinates,
      'CreatedBy': createdBy,
      'StartTime': startTime,
      'EndTime': endTime,
      'Vcode': vcode,
      'Dcode': dcode,
      'Scode': scode,
    }.withoutNulls,
  );

  return firestoreData;
}

class EventRecordDocumentEquality implements Equality<EventRecord> {
  const EventRecordDocumentEquality();

  @override
  bool equals(EventRecord? e1, EventRecord? e2) {
    return e1?.naam == e2?.naam &&
        e1?.locatie == e2?.locatie &&
        e1?.locationCoordinates == e2?.locationCoordinates &&
        e1?.createdBy == e2?.createdBy &&
        e1?.startTime == e2?.startTime &&
        e1?.endTime == e2?.endTime &&
        e1?.vcode == e2?.vcode &&
        e1?.dcode == e2?.dcode &&
        e1?.scode == e2?.scode;
  }

  @override
  int hash(EventRecord? e) => const ListEquality().hash([
        e?.naam,
        e?.locatie,
        e?.locationCoordinates,
        e?.createdBy,
        e?.startTime,
        e?.endTime,
        e?.vcode,
        e?.dcode,
        e?.scode
      ]);

  @override
  bool isValidKey(Object? o) => o is EventRecord;
}
