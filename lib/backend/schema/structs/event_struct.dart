// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';

import '/flutter_flow/flutter_flow_util.dart';

class EventStruct extends FFFirebaseStruct {
  EventStruct({
    String? naam,
    String? locatie,
    String? code,
    DateTime? start,
    DateTime? end,
    DocumentReference? id,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _naam = naam,
        _locatie = locatie,
        _code = code,
        _start = start,
        _end = end,
        _id = id,
        super(firestoreUtilData);

  // "Naam" field.
  String? _naam;
  String get naam => _naam ?? '';
  set naam(String? val) => _naam = val;

  bool hasNaam() => _naam != null;

  // "Locatie" field.
  String? _locatie;
  String get locatie => _locatie ?? '';
  set locatie(String? val) => _locatie = val;

  bool hasLocatie() => _locatie != null;

  // "Code" field.
  String? _code;
  String get code => _code ?? '';
  set code(String? val) => _code = val;

  bool hasCode() => _code != null;

  // "Start" field.
  DateTime? _start;
  DateTime? get start => _start;
  set start(DateTime? val) => _start = val;

  bool hasStart() => _start != null;

  // "End" field.
  DateTime? _end;
  DateTime? get end => _end;
  set end(DateTime? val) => _end = val;

  bool hasEnd() => _end != null;

  // "id" field.
  DocumentReference? _id;
  DocumentReference? get id => _id;
  set id(DocumentReference? val) => _id = val;

  bool hasId() => _id != null;

  static EventStruct fromMap(Map<String, dynamic> data) => EventStruct(
        naam: data['Naam'] as String?,
        locatie: data['Locatie'] as String?,
        code: data['Code'] as String?,
        start: data['Start'] as DateTime?,
        end: data['End'] as DateTime?,
        id: data['id'] as DocumentReference?,
      );

  static EventStruct? maybeFromMap(dynamic data) =>
      data is Map ? EventStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'Naam': _naam,
        'Locatie': _locatie,
        'Code': _code,
        'Start': _start,
        'End': _end,
        'id': _id,
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'Naam': serializeParam(
          _naam,
          ParamType.String,
        ),
        'Locatie': serializeParam(
          _locatie,
          ParamType.String,
        ),
        'Code': serializeParam(
          _code,
          ParamType.String,
        ),
        'Start': serializeParam(
          _start,
          ParamType.DateTime,
        ),
        'End': serializeParam(
          _end,
          ParamType.DateTime,
        ),
        'id': serializeParam(
          _id,
          ParamType.DocumentReference,
        ),
      }.withoutNulls;

  static EventStruct fromSerializableMap(Map<String, dynamic> data) =>
      EventStruct(
        naam: deserializeParam(
          data['Naam'],
          ParamType.String,
          false,
        ),
        locatie: deserializeParam(
          data['Locatie'],
          ParamType.String,
          false,
        ),
        code: deserializeParam(
          data['Code'],
          ParamType.String,
          false,
        ),
        start: deserializeParam(
          data['Start'],
          ParamType.DateTime,
          false,
        ),
        end: deserializeParam(
          data['End'],
          ParamType.DateTime,
          false,
        ),
        id: deserializeParam(
          data['id'],
          ParamType.DocumentReference,
          false,
          collectionNamePath: ['Event'],
        ),
      );

  @override
  String toString() => 'EventStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is EventStruct &&
        naam == other.naam &&
        locatie == other.locatie &&
        code == other.code &&
        start == other.start &&
        end == other.end &&
        id == other.id;
  }

  @override
  int get hashCode =>
      const ListEquality().hash([naam, locatie, code, start, end, id]);
}

EventStruct createEventStruct({
  String? naam,
  String? locatie,
  String? code,
  DateTime? start,
  DateTime? end,
  DocumentReference? id,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    EventStruct(
      naam: naam,
      locatie: locatie,
      code: code,
      start: start,
      end: end,
      id: id,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

EventStruct? updateEventStruct(
  EventStruct? event, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    event
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addEventStructData(
  Map<String, dynamic> firestoreData,
  EventStruct? event,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (event == null) {
    return;
  }
  if (event.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && event.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final eventData = getEventFirestoreData(event, forFieldValue);
  final nestedData = eventData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = event.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getEventFirestoreData(
  EventStruct? event, [
  bool forFieldValue = false,
]) {
  if (event == null) {
    return {};
  }
  final firestoreData = mapToFirestore(event.toMap());

  // Add any Firestore field values
  event.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getEventListFirestoreData(
  List<EventStruct>? events,
) =>
    events?.map((e) => getEventFirestoreData(e, true)).toList() ?? [];
