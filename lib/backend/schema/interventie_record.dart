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

  // "teamId" field.
  DocumentReference? _teamId;
  DocumentReference? get teamId => _teamId;
  bool hasTeamId() => _teamId != null;

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

  // "time" field.
  DateTime? _time;
  DateTime? get time => _time;
  bool hasTime() => _time != null;

  // "status" field.
  Statusinterventie? _status;
  Statusinterventie? get status => _status;
  bool hasStatus() => _status != null;

  void _initializeFields() {
    _connectionId = snapshotData['connectionId'] as DocumentReference?;
    _teamId = snapshotData['teamId'] as DocumentReference?;
    _situatie = snapshotData['situatie'] as String?;
    _slachtofferDetails = snapshotData['slachtofferDetails'] is UserStruct
        ? snapshotData['slachtofferDetails']
        : UserStruct.maybeFromMap(snapshotData['slachtofferDetails']);
    _location = snapshotData['location'] as LatLng?;
    _time = snapshotData['time'] as DateTime?;
    _status = snapshotData['status'] is Statusinterventie
        ? snapshotData['status']
        : deserializeEnum<Statusinterventie>(snapshotData['status']);
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
  DocumentReference? teamId,
  String? situatie,
  UserStruct? slachtofferDetails,
  LatLng? location,
  DateTime? time,
  Statusinterventie? status,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'connectionId': connectionId,
      'teamId': teamId,
      'situatie': situatie,
      'slachtofferDetails': UserStruct().toMap(),
      'location': location,
      'time': time,
      'status': status,
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
    return e1?.connectionId == e2?.connectionId &&
        e1?.teamId == e2?.teamId &&
        e1?.situatie == e2?.situatie &&
        e1?.slachtofferDetails == e2?.slachtofferDetails &&
        e1?.location == e2?.location &&
        e1?.time == e2?.time &&
        e1?.status == e2?.status;
  }

  @override
  int hash(InterventieRecord? e) => const ListEquality().hash([
        e?.connectionId,
        e?.teamId,
        e?.situatie,
        e?.slachtofferDetails,
        e?.location,
        e?.time,
        e?.status
      ]);

  @override
  bool isValidKey(Object? o) => o is InterventieRecord;
}
