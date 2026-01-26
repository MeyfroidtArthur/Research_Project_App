import 'dart:async';
import 'package:collection/collection.dart';
import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';
import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ConnectionRecord extends FirestoreRecord {
  ConnectionRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "voornaam" field.
  String? _voornaam;
  String get voornaam => _voornaam ?? '';
  bool hasVoornaam() => _voornaam != null;

  // "achternaam" field.
  String? _achternaam;
  String get achternaam => _achternaam ?? '';
  bool hasAchternaam() => _achternaam != null;

  // "geboortedatum" field.
  DateTime? _geboortedatum;
  DateTime? get geboortedatum => _geboortedatum;
  bool hasGeboortedatum() => _geboortedatum != null;

  // "gender" field.
  String? _gender;
  String get gender => _gender ?? '';
  bool hasGender() => _gender != null;

  // "adres" field.
  String? _adres;
  String get adres => _adres ?? '';
  bool hasAdres() => _adres != null;

  // "gemeente" field.
  String? _gemeente;
  String get gemeente => _gemeente ?? '';
  bool hasGemeente() => _gemeente != null;

  // "land" field.
  String? _land;
  String get land => _land ?? '';
  bool hasLand() => _land != null;

  // "extraInfo" field.
  String? _extraInfo;
  String get extraInfo => _extraInfo ?? '';
  bool hasExtraInfo() => _extraInfo != null;

  // "emergencyContact" field.
  String? _emergencyContact;
  String get emergencyContact => _emergencyContact ?? '';
  bool hasEmergencyContact() => _emergencyContact != null;

  // "status" field.
  Statuscall? _status;
  Statuscall? get status => _status;
  bool hasStatus() => _status != null;

  // "ermergencyLevel" field.
  int? _ermergencyLevel;
  int get ermergencyLevel => _ermergencyLevel ?? 0;
  bool hasErmergencyLevel() => _ermergencyLevel != null;

  // "eventId" field.
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
    _voornaam = snapshotData['voornaam'] as String?;
    _achternaam = snapshotData['achternaam'] as String?;
    _geboortedatum = snapshotData['geboortedatum'] is Timestamp
        ? (snapshotData['geboortedatum'] as Timestamp).toDate()
        : snapshotData['geboortedatum'] as DateTime?;
    _gender = snapshotData['gender'] as String?;
    _adres = snapshotData['adres'] as String?;
    _gemeente = snapshotData['gemeente'] as String?;
    _land = snapshotData['land'] as String?;
    _extraInfo = snapshotData['extraInfo'] as String?;
    _emergencyContact = snapshotData['emergencyContact'] as String?;
    _status = snapshotData['status'] is Statuscall
        ? snapshotData['status']
        : deserializeEnum<Statuscall>(snapshotData['status']);
    _ermergencyLevel = castToType<int>(snapshotData['ermergencyLevel']);
    _eventId = snapshotData['eventId'] is DocumentReference
        ? snapshotData['eventId'] as DocumentReference?
        : snapshotData['eventId'] is String
            ? FirebaseFirestore.instance.doc(snapshotData['eventId'] as String)
            : null;
    _location = snapshotData['Location'] as LatLng?;
    _lastLocationUpdate = snapshotData['LastLocationUpdate'] is Timestamp
        ? (snapshotData['LastLocationUpdate'] as Timestamp).toDate()
        : snapshotData['LastLocationUpdate'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('connection');

  static Stream<ConnectionRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ConnectionRecord.fromSnapshot(s));

  static Future<ConnectionRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ConnectionRecord.fromSnapshot(s));

  static ConnectionRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ConnectionRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ConnectionRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ConnectionRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ConnectionRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ConnectionRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createConnectionRecordData({
  String? voornaam,
  String? achternaam,
  DateTime? geboortedatum,
  String? gender,
  String? adres,
  String? gemeente,
  String? land,
  String? extraInfo,
  String? emergencyContact,
  Statuscall? status,
  int? ermergencyLevel,
  DocumentReference? eventId,
  LatLng? location,
  DateTime? lastLocationUpdate,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'voornaam': voornaam,
      'achternaam': achternaam,
      'geboortedatum': geboortedatum,
      'gender': gender,
      'adres': adres,
      'gemeente': gemeente,
      'land': land,
      'extraInfo': extraInfo,
      'emergencyContact': emergencyContact,
      'status': status,
      'ermergencyLevel': ermergencyLevel,
      'eventId': eventId,
      'Location': location,
      'LastLocationUpdate': lastLocationUpdate,
    }.withoutNulls,
  );

  return firestoreData;
}

class ConnectionRecordDocumentEquality implements Equality<ConnectionRecord> {
  const ConnectionRecordDocumentEquality();

  @override
  bool equals(ConnectionRecord? e1, ConnectionRecord? e2) {
    return e1?.voornaam == e2?.voornaam &&
        e1?.achternaam == e2?.achternaam &&
        e1?.geboortedatum == e2?.geboortedatum &&
        e1?.gender == e2?.gender &&
        e1?.adres == e2?.adres &&
        e1?.gemeente == e2?.gemeente &&
        e1?.land == e2?.land &&
        e1?.extraInfo == e2?.extraInfo &&
        e1?.emergencyContact == e2?.emergencyContact &&
        e1?.status == e2?.status &&
        e1?.ermergencyLevel == e2?.ermergencyLevel &&
        e1?.eventId == e2?.eventId &&
        e1?.location == e2?.location &&
        e1?.lastLocationUpdate == e2?.lastLocationUpdate;
  }

  @override
  int hash(ConnectionRecord? e) => const ListEquality().hash([
        e?.voornaam,
        e?.achternaam,
        e?.geboortedatum,
        e?.gender,
        e?.adres,
        e?.gemeente,
        e?.land,
        e?.extraInfo,
        e?.emergencyContact,
        e?.status,
        e?.ermergencyLevel,
        e?.eventId,
        e?.location,
        e?.lastLocationUpdate
      ]);

  @override
  bool isValidKey(Object? o) => o is ConnectionRecord;
}
