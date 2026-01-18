// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ActiveCallStruct extends FFFirebaseStruct {
  ActiveCallStruct({
    Statuscall? status,
    DocumentReference? refrence,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _status = status,
        _refrence = refrence,
        super(firestoreUtilData);

  // "status" field.
  Statuscall? _status;
  Statuscall get status => _status ?? Statuscall.waiting;
  set status(Statuscall? val) => _status = val;

  bool hasStatus() => _status != null;

  // "refrence" field.
  DocumentReference? _refrence;
  DocumentReference? get refrence => _refrence;
  set refrence(DocumentReference? val) => _refrence = val;

  bool hasRefrence() => _refrence != null;

  static ActiveCallStruct fromMap(Map<String, dynamic> data) =>
      ActiveCallStruct(
        status: data['status'] is Statuscall
            ? data['status']
            : deserializeEnum<Statuscall>(data['status']),
        refrence: data['refrence'] as DocumentReference?,
      );

  static ActiveCallStruct? maybeFromMap(dynamic data) => data is Map
      ? ActiveCallStruct.fromMap(data.cast<String, dynamic>())
      : null;

  Map<String, dynamic> toMap() => {
        'status': _status?.serialize(),
        'refrence': _refrence,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'status': serializeParam(
          _status,
          ParamType.Enum,
        ),
        'refrence': serializeParam(
          _refrence,
          ParamType.DocumentReference,
        ),
      }.withoutNulls;

  static ActiveCallStruct fromSerializableMap(Map<String, dynamic> data) =>
      ActiveCallStruct(
        status: deserializeParam<Statuscall>(
          data['status'],
          ParamType.Enum,
          false,
        ),
        refrence: deserializeParam(
          data['refrence'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['connection'],
        ),
      );

  @override
  String toString() => 'ActiveCallStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is ActiveCallStruct &&
        status == other.status &&
        refrence == other.refrence;
  }

  @override
  int get hashCode => const ListEquality().hash([status, refrence]);
}

ActiveCallStruct createActiveCallStruct({
  Statuscall? status,
  DocumentReference? refrence,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    ActiveCallStruct(
      status: status,
      refrence: refrence,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

ActiveCallStruct? updateActiveCallStruct(
  ActiveCallStruct? activeCall, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    activeCall
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addActiveCallStructData(
  Map<String, dynamic> firestoreData,
  ActiveCallStruct? activeCall,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (activeCall == null) {
    return;
  }
  if (activeCall.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && activeCall.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final activeCallData = getActiveCallFirestoreData(activeCall, forFieldValue);
  final nestedData = activeCallData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = activeCall.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getActiveCallFirestoreData(
  ActiveCallStruct? activeCall, [
  bool forFieldValue = false,
]) {
  if (activeCall == null) {
    return {};
  }
  final firestoreData = mapToFirestore(activeCall.toMap());

  // Add any Firestore field values
  activeCall.firestoreUtilData.fieldValues
      .forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getActiveCallListFirestoreData(
  List<ActiveCallStruct>? activeCalls,
) =>
    activeCalls?.map((e) => getActiveCallFirestoreData(e, true)).toList() ?? [];
