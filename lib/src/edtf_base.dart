// TODO: Put public facing types in this file.

import 'dart:math';
import 'package:meta/meta.dart';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  /// TODO: delete this
  bool get isAwesome => true;
}

/// Abstract class for handling any kind of Extended Date/Time Format.
abstract class Edtf {
  Edtf._();

  /// Parses [s] to a subtype of Edtf based on the string
  factory Edtf.parse(String s) {
    if (RegExp('^\\[.*\\]\$').hasMatch(s)) {
      // OneOf
      return EdtfOneOf.parse(s);
    } else if (RegExp('^{.*}\$').hasMatch(s)) {
      // Every
      return EdtfEvery.parse(s);
    } else if (RegExp('/').hasMatch(s)) {
      // Interval
      return EdtfInterval.parse(s);
    } else {
      // Date
      return EdtfDate.parse(s);
    }
  }

  /// Inner: in enclosed dates, interval rules are different
  factory Edtf._parseInner(String s) {
    if (RegExp('\\.\\.').hasMatch(s)) {
      // Interval
      return EdtfInterval._parseInner(s);
    } else {
      // Date
      return EdtfDate.parse(s);
    }
  }

  @override
  String toString() {
    return super.toString();
  }

  String _toInnerString() {
    return toString();
  }
}

/// An abstract class for handling cases where the date can be from a set
abstract class EdtfSet extends Edtf {
  /// The set of dates which can be used in the representation.
  final List<Edtf> values;
  EdtfSet._([this.values]) : super._();

  static List<Edtf> _parseDates(String s) {
    final dates = <Edtf>[];
    for (final elem in s.split(',')) {
      dates.add(Edtf._parseInner(elem));
    }
    return dates;
  }

  @override
  String toString() {
    var ret = '';
    for (final edtf in values) {
      ret += edtf._toInnerString() + ',';
    }
    ret = ret.substring(0, ret.length - 1);
    return ret;
  }
}

/// A class for handling cases where the edtf string represents all of the dates
/// from a set.
class EdtfEvery extends EdtfSet {
  /// Constructor for directly creating an object with the given values
  EdtfEvery(List<Edtf> values) : super._(values);
  static final _regExp = RegExp('^{(.*)}\$');

  /// Parse a '{...}' like string to an EdtfEvery object
  factory EdtfEvery.parse(String s) {
    return EdtfEvery(EdtfSet._parseDates(_regExp.firstMatch(s).group(1)));
  }

  @override
  String toString() {
    return '{' + super.toString() + '}';
  }
}

/// A class for handling cases where the edtf string represents one of the dates
/// from a set
class EdtfOneOf extends EdtfSet {
  /// Constructor for directly creating an object with the given values
  EdtfOneOf(List<Edtf> values) : super._(values);

  /// Parses a '[...]' like string to an EdtfOneOf object
  factory EdtfOneOf.parse(String s) {
    final _regExp = RegExp('^\\[(.*)\\]\$');
    return EdtfOneOf(EdtfSet._parseDates(_regExp.firstMatch(s).group(1)));
  }

  @override
  String toString() {
    return '[' + super.toString() + ']';
  }
}

/// A class for handling intervals as specified by the edtf standard.
class EdtfInterval extends Edtf {
  /// Start of the interval. Can be null, if it's unknown or open
  final EdtfDate start;

  /// End of the interval. Can be null, if it's unknown or open
  final EdtfDate end;

  /// True if the start of the interval is open,
  /// false if it has a start or the start is unknown
  final bool openStart;

  /// True if the end of the interval is open,
  /// false if it has an end or the end is unknown
  final bool openEnd;

  /// Creates an object with the given parameters
  EdtfInterval(this.start, this.openStart, this.end, this.openEnd) : super._();

  /// Parses a '?/?' like string to an interval
  factory EdtfInterval.parse(String s) {
    final dates = s.split('/');
    EdtfDate start, end;
    bool openStart, openEnd;
    assert(dates.length == 2);
    if (dates[0] == '') {
      start = null;
      openStart = false;
    } else if (dates[0] == '..') {
      start = null;
      openStart = true;
    } else {
      start = EdtfDate.parse(dates[0]);
      openStart = false;
    }
    if (dates[1] == '') {
      end = null;
      openEnd = false;
    } else if (dates[1] == '..') {
      end = null;
      openEnd = true;
    } else {
      end = EdtfDate.parse(dates[1]);
      openEnd = false;
    }
    return EdtfInterval(start, openStart, end, openEnd);
  }

  /// Parses a '?..?' like string to an interval
  factory EdtfInterval._parseInner(String s) {
    final dates = s.split('..');
    EdtfDate start, end;
    bool openStart, openEnd;
    assert(dates.length == 2);
    if (dates[0] == '') {
      start = null;
      openStart = true;
    } else {
      start = EdtfDate.parse(dates[0]);
      openStart = false;
    }
    if (dates[1] == '') {
      end = null;
      openEnd = true;
    } else {
      end = EdtfDate.parse(dates[1]);
      openEnd = false;
    }
    return EdtfInterval(start, openStart, end, openEnd);
  }

  @override
  String toString() {
    var ret = '';
    if (openStart) {
      ret += '..';
    }
    if (start != null) {
      ret += start.toString();
    }
    ret += '/';
    if (end != null) {
      ret += end.toString();
    }
    if (openEnd) {
      ret += '..';
    }
    return ret;
  }

  @override
  String _toInnerString() {
    var ret = '';
    if (start != null) {
      ret += start.toString();
    }
    ret += '..';
    if (end != null) {
      ret += end.toString();
    }
    return ret;
  }
}

/// A class for handling dates according to the edtf specification.
class EdtfDate extends Edtf {
  /// The year part of the date with the modifiers
  final EdtfNumber year;

  /// The month part of the date with the modifiers. Can be null, if not given
  final EdtfNumber month;

  /// The day part of the date with the modifiers. Can be null, if not given
  final EdtfNumber day;

  /// The time part of the date. Can be null, if not given
  final EdtfTime time;

  /// Constructs a EdtfDate objects from the given parameters
  EdtfDate(this.year, [this.month, this.day, this.time]) : super._();

  /// Parses a date according to edtf specification.
  factory EdtfDate.parse(String s) {
    EdtfTime etime;
    if (s.contains('T')) {
      final time = s.substring(s.indexOf('T') + 1);
      etime = EdtfTime.parse(time);
      s = s.substring(0, s.indexOf('T'));
    } else {
      etime = null;
    }

    final numberLike = RegExp('[\\dXu]+');
    final parts = s.split('-'); // What if -1000-10-10?
    if (!parts[0].contains(numberLike)) {
      final year = parts[0] + '-' + parts[1];
      parts.removeAt(0);
      parts[0] = year;
    }
    EdtfNumber year, month, day;
    year = EdtfNumber.parse(parts[0]);
    if (parts.length >= 2) {
      month = EdtfNumber.parse(parts[1]);
      year = EdtfNumber._addGroup(year, month);
    }
    if (parts.length >= 3) {
      day = EdtfNumber.parse(parts[2]);
      month = EdtfNumber._addGroup(month, day);
      year = EdtfNumber._addGroup(year, day);
    }
    return EdtfDate(year, month, day, etime);
  }

  @override
  String toString() {
    var ret = year.toString();
    if (month != null) {
      ret += '-' + month.toString();
    }
    if (day != null) {
      ret += '-' + day.toString();
    }
    if (time != null) {
      ret += 'T' + time.toString();
    }
    return ret;
  }
}

/// A class for handling time according to the edtf specification
class EdtfTime {
  /// The hour part of the time
  final int hour;

  /// The minute part of the time
  final int minutes;

  /// The seconds part of the time
  final int seconds;
  final int _shiftHour;
  final int _shiftMinute;

  /// The hour part of the time shift. Can be null, if time is local
  int get shiftHour {
    switch (shiftLevel) {
      case shiftLevelUTC:
        return 0;
      case shiftLevelHour:
      case shiftLevelMinute:
        return _shiftHour;
      default: // shiftLevel == shiftLevelLocal or error
        return null;
    }
  }

  /// The minute part of the time shift. Can be null, if time is local
  int get shiftMinute {
    switch (shiftLevel) {
      case shiftLevelUTC:
      case shiftLevelHour:
        return 0;
      case shiftLevelMinute:
        return _shiftMinute;
      default: // shiftLevel == shiftLevelLocal or error
        return null;
    }
  }

  /// The precision of the shift where the time is stored at. Can be
  /// Local, UTC, Hour or Minute precision with the EdtfTime.shiftLevel* value.
  final int shiftLevel;

  /// Constant for representing Local shift value
  static const shiftLevelLocal = 0;

  /// Constant for representing UTC time ('Z' at the end)
  static const shiftLevelUTC = 1;

  /// Constanf for representing hour precision shifted time
  static const shiftLevelHour = 2;

  /// Constanf for representing minute precision shifted time
  static const shiftLevelMinute = 3;

  /// Constructor for creating an object from the given values
  EdtfTime(this.hour, this.minutes, this.seconds, this.shiftLevel,
      [this._shiftHour, this._shiftMinute]);

  /// Creates an EdtfTime object from a 'XX:XX:XX' + shift? like string
  factory EdtfTime.parse(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2].substring(0, 2));
    if (parts[2].length <= 2) {
      // Local time
      final shiftLevel = EdtfTime.shiftLevelLocal;
      return EdtfTime(hour, minutes, seconds, shiftLevel);
    } else if (parts[2][2] == 'Z') {
      // UTC time
      final shiftLevel = EdtfTime.shiftLevelUTC;
      return EdtfTime(hour, minutes, seconds, shiftLevel);
    } else {
      // Shift is added
      final shiftHour = int.parse(parts[2].substring(2));
      if (parts.length <= 3) {
        // Has shiftHour precision
        final shiftLevel = EdtfTime.shiftLevelHour;
        return EdtfTime(hour, minutes, seconds, shiftLevel, shiftHour);
      } else {
        // Has shiftHour:shiftMinute format
        final shiftMinute = int.parse(parts[3]);
        final shiftLevel = EdtfTime.shiftLevelMinute;
        return EdtfTime(
            hour, minutes, seconds, shiftLevel, shiftHour, shiftMinute);
      }
    }
  }

  @override
  String toString() {
    var ret = '';
    ret += _toFixedString(hour, 2);
    ret += ':';
    ret += _toFixedString(minutes, 2);
    ret += ':';
    ret += _toFixedString(seconds, 2);
    if (shiftLevel == shiftLevelLocal) {
      return ret;
    } else if (shiftLevel == shiftLevelUTC) {
      return ret + 'Z';
    } else if (shiftLevel == shiftLevelHour) {
      ret += _toFixedString(_shiftHour, 2, plusSign: true);
      return ret;
    } else if (shiftLevel == shiftLevelMinute) {
      ret += _toFixedString(_shiftHour, 2, plusSign: true);
      ret += ':';
      ret += _toFixedString(_shiftMinute, 2);
      return ret;
    } else {
      throw ArgumentError('Unexpected shiftLevel');
    }
  }
}

/// Converts a nuber to a string with leading zeroes
String _toFixedString(int number, int width, {bool plusSign = false}) {
  var ret = '';
  if (plusSign && number >= 0) {
    ret += '+';
  } else if (number < 0) {
    ret += '-';
  }
  ret += number.abs().toString().padLeft(width, '0');
  return ret;
}

/// A class for handling the number-like parts of an edtf date
class EdtfNumber {
  /// The value of the number from string,
  /// before shifting according to exp, and with '0' for unknown parts.
  final int value;

  /// The exponent of the value, from the 'E' number. Can be null, if not given
  final int exp;

  /// The significant digits in the value, from the 'S' number.
  /// Can be null, if not given
  final int significance;

  /// The mask of the unknown characters in the value, with '.' in place of
  /// 'X' (or 'u')
  final String unspecMask;

  /// True if the number has '~' or '%', so it's approximate.
  final bool localApprox;

  /// True if the number has '?' or '%' characters, stating it is uncertain
  final bool localUncert;

  /// True if the number is approximate because of a group qualifier.
  final bool groupApprox;

  /// True if the number is uncertain because of a group qualifier.
  final bool groupUncert;

  /// The real value of the number, shifted according to the exponent.
  get realValue => value * pow(10, exp);

  // TODO replace like modifier constructor
  EdtfNumber._(
      {@required this.value,
      this.exp,
      this.significance,
      this.unspecMask,
      this.localApprox,
      this.localUncert,
      this.groupApprox,
      this.groupUncert});

  factory EdtfNumber._addGroup(EdtfNumber target, EdtfNumber prev) {
    return EdtfNumber._(
        value: target.value,
        exp: target.exp,
        significance: target.significance,
        unspecMask: target.unspecMask,
        localApprox: target.localApprox,
        localUncert: target.localUncert,
        groupApprox: target.groupApprox | prev.groupApprox,
        groupUncert: target.groupUncert | prev.groupUncert);
  }

  /// Parses the number from a string
  factory EdtfNumber.parse(String s) {
    // Group 1: value with missing digits
    // Group 3: exp
    // Group 5: prec
    final nums = RegExp(r'(-?[\dXu]+)([Ee](\d+))?([Sp](\d+))?').firstMatch(s);
    final value = int.parse(nums.group(1).replaceAll(RegExp('[Xu]'), '0'));
    final exp = nums.group(3) != null ? int.parse(nums.group(3)) : null;
    final precision = nums.group(5) != null ? int.parse(nums.group(5)) : null;
    final unspecMask = nums.group(1).replaceAll(RegExp('[Xu]'), '.');

    final localApprox = s.contains('~') || s.contains('%');
    final localUncert = s.contains('?') || s.contains('%');
    final groupApprox = s.endsWith('~') || s.endsWith('%');
    final groupUncert = s.endsWith('?') || s.endsWith('%');

    return EdtfNumber._(
        value: value,
        exp: exp,
        significance: precision,
        unspecMask: unspecMask,
        localApprox: localApprox,
        localUncert: localUncert,
        groupApprox: groupApprox,
        groupUncert: groupUncert);
  }
  @override
  String toString() {
    var ret = '';
    if (value < -9999 || 9999 < value) ret += 'Y';
    ret += unspecMask.replaceAll('.', 'X');
    if (exp != null) ret += 'E' + exp.toString();
    if (significance != null) ret += 'S' + significance.toString();
    final groupchar = groupApprox ? groupUncert ? '%' : '~' : '?';
    if ((localApprox && groupApprox) || (localUncert && groupUncert)) {
      ret += groupchar;
    }
    final localchar = localApprox ? localUncert ? '%' : '~' : '?';
    if ((localApprox && !groupApprox) || (localUncert && !groupUncert)) {
      ret = localchar + ret;
    }
    return ret;
  }
}

/// The special values for months, according to the specification
const edtfMonthNames = {
  21: 'Spring',
  22: 'Summer',
  23: 'Autumn',
  24: 'Winter',
  25: 'Spring - Northern Hemisphere',
  26: 'Summer - Northern Hemisphere',
  27: 'Autumn - Northern Hemisphere',
  28: 'Winter - Northern Hemisphere',
  29: 'Spring - Southern Hemisphere',
  30: 'Summer - Southern Hemisphere',
  31: 'Autumn - Southern Hemisphere',
  32: 'Winter - Southern Hemisphere',
  33: 'Quarter 1 (3 months in duration)',
  34: 'Quarter 2 (3 months in duration)',
  35: 'Quarter 3 (3 months in duration)',
  36: 'Quarter 4 (3 months in duration)',
  37: 'Quadrimester 1 (4 months in duration)',
  38: 'Quadrimester 2 (4 months in duration)',
  39: 'Quadrimester 3 (4 months in duration)',
  40: 'Semestral 1 (6 months in duration)',
  41: 'Semestral 2 (6 months in duration)',
};
