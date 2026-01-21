import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class InterventieRecord extends FirestoreRecord {
  InterventieRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "connectionId" field.
  DocumentReference? _connectionId;
  DocumentReference? get connectionId => _connectionId;
  bool hasConnectionId() => _connectionId != null;

  // "situatie" field.
  String? _situatie;
  String get situatie => _situatie ?? '';
  bool hasSituatie() => _situatie != null;

  // "slachtofferDetails" field.
  UserStruct? _slachtofferDetails;
  UserStruct get slachtofferDetails => _slachtofferDetails ?? UserStruct();
  bool hasSlachtofferDetails() => _slachtofferDetails != null;

  // "location" field.
  LatLng? _location;
  LatLng? get location => _location;
  bool hasLocation() => _location != null;

  // "status" field.
  Statusinterventie? _status;
  Statusinterventie? get status => _status;
  bool hasStatus() => _status != null;

  // "teamId" field.
  List<DocumentReference>? _teamId;
  List<DocumentReference> get teamId => _teamId ?? const [];
  bool hasTeamId() => _teamId != null;

  // "uitgecheckt" field.
  Uitgecheckt? _uitgecheckt;
  Uitgecheckt? get uitgecheckt => _uitgecheckt;
  bool hasUitgecheckt() => _uitgecheckt != null;

  // "StartTime" field.
  DateTime? _startTime;
  DateTime? get startTime => _startTime;
  bool hasStartTime() => _startTime != null;

  // "EndTime" field.
  DateTime? _endTime;
  DateTime? get endTime => _endTime;
  bool hasEndTime() => _endTime != null;

  // "eventId" field.
  DocumentReference? _eventId;
  DocumentReference? get eventId => _eventId;
  bool hasEventId() => _eventId != null;

  // "verslag" field.
  String? _verslag;
  String get verslag => _verslag ?? '';
  bool hasVerslag() => _verslag != null;

  void _initializeFields() {
    _connectionId = snapshotData['connectionId'] as DocumentReference?;
    _situatie = snapshotData['situatie'] as String?;
    _slachtofferDetails = snapshotData['slachtofferDetails'] is UserStruct
        ? snapshotData['slachtofferDetails']
        : UserStruct.maybeFromMap(snapshotData['slachtofferDetails']);
    _location = snapshotData['location'] as LatLng?;
    _status = snapshotData['status'] is Statusinterventie
        ? snapshotData['status']
        : deserializeEnum<Statusinterventie>(snapshotData['status']);
    _teamId = getDataList(snapshotData['teamId']);
    _uitgecheckt = snapshotData['uitgecheckt'] is Uitgecheckt
        ? snapshotData['uitgecheckt']
        : deserializeEnum<Uitgecheckt>(snapshotData['uitgecheckt']);
    _startTime = snapshotData['StartTime'] as DateTime?;
    _endTime = snapshotData['EndTime'] as DateTime?;
    _eventId = snapshotData['eventId'] as DocumentReference?;
    _verslag = snapshotData['verslag'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Interventie');

  static Stream<InterventieRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => InterventieRecord.fromSnapshot(s));

  static Future<InterventieRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => InterventieRecord.fromSnapshot(s));

  static InterventieRecord fromSnapshot(DocumentSnapshot snapshot) =>
      InterventieRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static InterventieRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      InterventieRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'InterventieRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is InterventieRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createInterventieRecordData({
  DocumentReference? connectionId,
  String? situatie,
  UserStruct? slachtofferDetails,
  LatLng? location,
  Statusinterventie? status,
  Uitgecheckt? uitgecheckt,
  DateTime? startTime,
  DateTime? endTime,
  DocumentReference? eventId,
  String? verslag,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'connectionId': connectionId,
      'situatie': situatie,
      'slachtofferDetails': UserStruct().toMap(),
      'location': location,
      'status': status,
      'uitgecheckt': uitgecheckt,
      'StartTime': startTime,
      'EndTime': endTime,
      'eventId': eventId,
      'verslag': verslag,
    }.withoutNulls,
  );

  // Handle nested data for "slachtofferDetails" field.
  addUserStructData(firestoreData, slachtofferDetails, 'slachtofferDetails');

  return firestoreData;
}

class InterventieRecordDocumentEquality implements Equality<InterventieRecord> {
  const InterventieRecordDocumentEquality();

  @override
  bool equals(InterventieRecord? e1, InterventieRecord? e2) {
    const listEquality = ListEquality();
    return e1?.connectionId == e2?.connectionId &&
        e1?.situatie == e2?.situatie &&
        e1?.slachtofferDetails == e2?.slachtofferDetails &&
        e1?.location == e2?.location &&
        e1?.status == e2?.status &&
        listEquality.equals(e1?.teamId, e2?.teamId) &&
        e1?.uitgecheckt == e2?.uitgecheckt &&
        e1?.startTime == e2?.startTime &&
        e1?.endTime == e2?.endTime &&
        e1?.eventId == e2?.eventId &&
        e1?.verslag == e2?.verslag;
  }

  @override
  int hash(InterventieRecord? e) => const ListEquality().hash([
        e?.connectionId,
        e?.situatie,
        e?.slachtofferDetails,
        e?.location,
        e?.status,
        e?.teamId,
        e?.uitgecheckt,
        e?.startTime,
        e?.endTime,
        e?.eventId,
        e?.verslag
      ]);

  @override
  bool isValidKey(Object? o) => o is InterventieRecord;
}
