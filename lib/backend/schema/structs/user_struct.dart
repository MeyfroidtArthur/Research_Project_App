// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class UserStruct extends FFFirebaseStruct {
  UserStruct({
    String? voornaam,
    String? achternaam,
    DateTime? geboorteDatum,
    String? gender,
    String? adres,
    String? gemeente,
    String? land,
    String? extra,
    String? noodcontact,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _voornaam = voornaam,
        _achternaam = achternaam,
        _geboorteDatum = geboorteDatum,
        _gender = gender,
        _adres = adres,
        _gemeente = gemeente,
        _land = land,
        _extra = extra,
        _noodcontact = noodcontact,
        super(firestoreUtilData);

  // "Voornaam" field.
  String? _voornaam;
  String get voornaam => _voornaam ?? '';
  set voornaam(String? val) => _voornaam = val;

  bool hasVoornaam() => _voornaam != null;

  // "Achternaam" field.
  String? _achternaam;
  String get achternaam => _achternaam ?? '';
  set achternaam(String? val) => _achternaam = val;

  bool hasAchternaam() => _achternaam != null;

  // "GeboorteDatum" field.
  DateTime? _geboorteDatum;
  DateTime? get geboorteDatum => _geboorteDatum;
  set geboorteDatum(DateTime? val) => _geboorteDatum = val;

  bool hasGeboorteDatum() => _geboorteDatum != null;

  // "Gender" field.
  String? _gender;
  String get gender => _gender ?? '';
  set gender(String? val) => _gender = val;

  bool hasGender() => _gender != null;

  // "Adres" field.
  String? _adres;
  String get adres => _adres ?? '';
  set adres(String? val) => _adres = val;

  bool hasAdres() => _adres != null;

  // "Gemeente" field.
  String? _gemeente;
  String get gemeente => _gemeente ?? '';
  set gemeente(String? val) => _gemeente = val;

  bool hasGemeente() => _gemeente != null;

  // "Land" field.
  String? _land;
  String get land => _land ?? '';
  set land(String? val) => _land = val;

  bool hasLand() => _land != null;

  // "Extra" field.
  String? _extra;
  String get extra => _extra ?? '';
  set extra(String? val) => _extra = val;

  bool hasExtra() => _extra != null;

  // "Noodcontact" field.
  String? _noodcontact;
  String get noodcontact => _noodcontact ?? '';
  set noodcontact(String? val) => _noodcontact = val;

  bool hasNoodcontact() => _noodcontact != null;

  static UserStruct fromMap(Map<String, dynamic> data) => UserStruct(
        voornaam: data['Voornaam'] as String?,
        achternaam: data['Achternaam'] as String?,
        geboorteDatum: data['GeboorteDatum'] as DateTime?,
        gender: data['Gender'] as String?,
        adres: data['Adres'] as String?,
        gemeente: data['Gemeente'] as String?,
        land: data['Land'] as String?,
        extra: data['Extra'] as String?,
        noodcontact: data['Noodcontact'] as String?,
      );

  static UserStruct? maybeFromMap(dynamic data) =>
      data is Map ? UserStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'Voornaam': _voornaam,
        'Achternaam': _achternaam,
        'GeboorteDatum': _geboorteDatum,
        'Gender': _gender,
        'Adres': _adres,
        'Gemeente': _gemeente,
        'Land': _land,
        'Extra': _extra,
        'Noodcontact': _noodcontact,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'Voornaam': serializeParam(
          _voornaam,
          ParamType.String,
        ),
        'Achternaam': serializeParam(
          _achternaam,
          ParamType.String,
        ),
        'GeboorteDatum': serializeParam(
          _geboorteDatum,
          ParamType.DateTime,
        ),
        'Gender': serializeParam(
          _gender,
          ParamType.String,
        ),
        'Adres': serializeParam(
          _adres,
          ParamType.String,
        ),
        'Gemeente': serializeParam(
          _gemeente,
          ParamType.String,
        ),
        'Land': serializeParam(
          _land,
          ParamType.String,
        ),
        'Extra': serializeParam(
          _extra,
          ParamType.String,
        ),
        'Noodcontact': serializeParam(
          _noodcontact,
          ParamType.String,
        ),
      }.withoutNulls;

  static UserStruct fromSerializableMap(Map<String, dynamic> data) =>
      UserStruct(
        voornaam: deserializeParam(
          data['Voornaam'],
          ParamType.String,
          false,
        ),
        achternaam: deserializeParam(
          data['Achternaam'],
          ParamType.String,
          false,
        ),
        geboorteDatum: deserializeParam(
          data['GeboorteDatum'],
          ParamType.DateTime,
          false,
        ),
        gender: deserializeParam(
          data['Gender'],
          ParamType.String,
          false,
        ),
        adres: deserializeParam(
          data['Adres'],
          ParamType.String,
          false,
        ),
        gemeente: deserializeParam(
          data['Gemeente'],
          ParamType.String,
          false,
        ),
        land: deserializeParam(
          data['Land'],
          ParamType.String,
          false,
        ),
        extra: deserializeParam(
          data['Extra'],
          ParamType.String,
          false,
        ),
        noodcontact: deserializeParam(
          data['Noodcontact'],
          ParamType.String,
          false,
        ),
      );

  @override
  String toString() => 'UserStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is UserStruct &&
        voornaam == other.voornaam &&
        achternaam == other.achternaam &&
        geboorteDatum == other.geboorteDatum &&
        gender == other.gender &&
        adres == other.adres &&
        gemeente == other.gemeente &&
        land == other.land &&
        extra == other.extra &&
        noodcontact == other.noodcontact;
  }

  @override
  int get hashCode => const ListEquality().hash([
        voornaam,
        achternaam,
        geboorteDatum,
        gender,
        adres,
        gemeente,
        land,
        extra,
        noodcontact
      ]);
}

UserStruct createUserStruct({
  String? voornaam,
  String? achternaam,
  DateTime? geboorteDatum,
  String? gender,
  String? adres,
  String? gemeente,
  String? land,
  String? extra,
  String? noodcontact,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    UserStruct(
      voornaam: voornaam,
      achternaam: achternaam,
      geboorteDatum: geboorteDatum,
      gender: gender,
      adres: adres,
      gemeente: gemeente,
      land: land,
      extra: extra,
      noodcontact: noodcontact,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

UserStruct? updateUserStruct(
  UserStruct? user, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    user
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addUserStructData(
  Map<String, dynamic> firestoreData,
  UserStruct? user,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (user == null) {
    return;
  }
  if (user.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields = !forFieldValue && user.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final userData = getUserFirestoreData(user, forFieldValue);
  final nestedData = userData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = user.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getUserFirestoreData(
  UserStruct? user, [
  bool forFieldValue = false,
]) {
  if (user == null) {
    return {};
  }
  final firestoreData = mapToFirestore(user.toMap());

  // Add any Firestore field values
  user.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getUserListFirestoreData(
  List<UserStruct>? users,
) =>
    users?.map((e) => getUserFirestoreData(e, true)).toList() ?? [];
