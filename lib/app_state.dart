import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:csv/csv.dart';
import 'package:synchronized/synchronized.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    secureStorage = FlutterSecureStorage();
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_User') != null) {
        try {
          final serializedData =
              await secureStorage.getString('ff_User') ?? '{}';
          _User = UserStruct.fromSerializableMap(jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_Event') != null) {
        try {
          final serializedData =
              await secureStorage.getString('ff_Event') ?? '{}';
          _Event = EventStruct.fromSerializableMap(jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      if (await secureStorage.read(key: 'ff_Call') != null) {
        try {
          final serializedData =
              await secureStorage.getString('ff_Call') ?? '{}';
          _Call =
              ActiveCallStruct.fromSerializableMap(jsonDecode(serializedData));
        } catch (e) {
          print("Can't decode persisted data type. Error: $e.");
        }
      }
    });
    await _safeInitAsync(() async {
      _TeamId = (await secureStorage.getString('ff_TeamId'))?.ref ?? _TeamId;
    });
    await _safeInitAsync(() async {
      _TeamLabel = await secureStorage.getString('ff_TeamLabel') ?? _TeamLabel;
    });
    await _safeInitAsync(() async {
      _StartTime = await secureStorage.read(key: 'ff_StartTime') != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (await secureStorage.getInt('ff_StartTime'))!)
          : _StartTime;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late FlutterSecureStorage secureStorage;

  UserStruct _User = UserStruct.fromSerializableMap(jsonDecode('{}'));
  UserStruct get User => _User;
  set User(UserStruct value) {
    _User = value;
    secureStorage.setString('ff_User', value.serialize());
  }

  void deleteUser() {
    secureStorage.delete(key: 'ff_User');
  }

  void updateUserStruct(Function(UserStruct) updateFn) {
    updateFn(_User);
    secureStorage.setString('ff_User', _User.serialize());
  }

  EventStruct _Event = EventStruct();
  EventStruct get Event => _Event;
  set Event(EventStruct value) {
    _Event = value;
    secureStorage.setString('ff_Event', value.serialize());
  }

  void deleteEvent() {
    secureStorage.delete(key: 'ff_Event');
  }

  void updateEventStruct(Function(EventStruct) updateFn) {
    updateFn(_Event);
    secureStorage.setString('ff_Event', _Event.serialize());
  }

  ActiveCallStruct _Call = ActiveCallStruct();
  ActiveCallStruct get Call => _Call;
  set Call(ActiveCallStruct value) {
    _Call = value;
    secureStorage.setString('ff_Call', value.serialize());
  }

  void deleteCall() {
    secureStorage.delete(key: 'ff_Call');
  }

  void updateCallStruct(Function(ActiveCallStruct) updateFn) {
    updateFn(_Call);
    secureStorage.setString('ff_Call', _Call.serialize());
  }

  DocumentReference? _TeamId;
  DocumentReference? get TeamId => _TeamId;
  set TeamId(DocumentReference? value) {
    _TeamId = value;
    value != null
        ? secureStorage.setString('ff_TeamId', value.path)
        : secureStorage.remove('ff_TeamId');
  }

  void deleteTeamId() {
    secureStorage.delete(key: 'ff_TeamId');
  }

  String _TeamLabel = 'Select...';
  String get TeamLabel => _TeamLabel;
  set TeamLabel(String value) {
    _TeamLabel = value;
    secureStorage.setString('ff_TeamLabel', value);
  }

  void deleteTeamLabel() {
    secureStorage.delete(key: 'ff_TeamLabel');
  }

  DateTime? _StartTime;
  DateTime? get StartTime => _StartTime;
  set StartTime(DateTime? value) {
    _StartTime = value;
    value != null
        ? secureStorage.setInt('ff_StartTime', value.millisecondsSinceEpoch)
        : secureStorage.remove('ff_StartTime');
  }

  void deleteStartTime() {
    secureStorage.delete(key: 'ff_StartTime');
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}

extension FlutterSecureStorageExtensions on FlutterSecureStorage {
  static final _lock = Lock();

  Future<void> writeSync({required String key, String? value}) async =>
      await _lock.synchronized(() async {
        await write(key: key, value: value);
      });

  void remove(String key) => delete(key: key);

  Future<String?> getString(String key) async => await read(key: key);
  Future<void> setString(String key, String value) async =>
      await writeSync(key: key, value: value);

  Future<bool?> getBool(String key) async => (await read(key: key)) == 'true';
  Future<void> setBool(String key, bool value) async =>
      await writeSync(key: key, value: value.toString());

  Future<int?> getInt(String key) async =>
      int.tryParse(await read(key: key) ?? '');
  Future<void> setInt(String key, int value) async =>
      await writeSync(key: key, value: value.toString());

  Future<double?> getDouble(String key) async =>
      double.tryParse(await read(key: key) ?? '');
  Future<void> setDouble(String key, double value) async =>
      await writeSync(key: key, value: value.toString());

  Future<List<String>?> getStringList(String key) async =>
      await read(key: key).then((result) {
        if (result == null || result.isEmpty) {
          return null;
        }
        return CsvToListConverter()
            .convert(result)
            .first
            .map((e) => e.toString())
            .toList();
      });
  Future<void> setStringList(String key, List<String> value) async =>
      await writeSync(key: key, value: ListToCsvConverter().convert([value]));
}
