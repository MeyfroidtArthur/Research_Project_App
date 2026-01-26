import 'package:collection/collection.dart';

enum Statuscall {
  waiting,
  active,
  ended,
}

enum Statusinterventie {
  active,
  finished,
}

enum Uitgecheckt {
  Event,
  Thuis,
  Ziekenhuis,
}

enum TeamStatus {
  Available,
  Unavailable,
  OnDuty,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (Statuscall):
      return Statuscall.values.deserialize(value) as T?;
    case (Statusinterventie):
      return Statusinterventie.values.deserialize(value) as T?;
    case (Uitgecheckt):
      return Uitgecheckt.values.deserialize(value) as T?;
    case (TeamStatus):
      return TeamStatus.values.deserialize(value) as T?;
  }
  return null;
}
