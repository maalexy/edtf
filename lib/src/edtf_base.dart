// TODO: Put public facing types in this file.

import 'dart:html_common';
import 'dart:math';
import 'package:meta/meta.dart';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

/// edtf, replace

abstract class Edtf {
  Edtf._();

  factory Edtf.parse(String s) {
    if (RegExp('^[.*]\$').hasMatch(s)) {
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
    if (RegExp('..').hasMatch(s)) {
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

abstract class EdtfSet extends Edtf {
  final List<Edtf> values;
  EdtfSet._([this.values]) : super._();

  static List<Edtf> _parseDates(String s) {
    final dates = <Edtf>[];
    for (final elem in s.split(',')) {
      dates.add(Edtf._parseInner(elem));
    }
    return dates;
  }

//  @override
//  String toString() {
//    return 'ASD';
//  }
}

class EdtfEvery extends EdtfSet {
  EdtfEvery(values) : super._(values);
  static final _regExp = RegExp('^{(.*)}\$');
  factory EdtfEvery.parse(String s) {
    return EdtfEvery(EdtfSet._parseDates(_regExp.firstMatch(s).group(1)));
  }
}

class EdtfOneOf extends EdtfSet {
  EdtfOneOf(values) : super._(values);
  factory EdtfOneOf.parse(String s) {
    final _regExp = RegExp('^[(.*)]\$');
    return EdtfOneOf(
        EdtfSet._parseDates(_regExp.firstMatch(s).group(1)));
  }
}

class EdtfInterval extends Edtf {
  final EdtfDate start;
  final EdtfDate end;
  final bool openStart;
  final bool openEnd;

  EdtfInterval(this.start, this.openStart, this.end, this.openEnd) : super._();
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
}

class EdtfDate extends Edtf {
  final EdtfNumber year;
  final EdtfNumber month;
  final EdtfNumber day;
  final EdtfTime time;

  EdtfDate(this.year, [this.month, this.day, this.time]) : super._();
  factory EdtfDate.parse(String s) {
    EdtfTime etime;
    if (s.contains('T')) {
      final time = s.substring(s.indexOf('T') + 1);
      etime = EdtfTime.parse(time);
      s = s.substring(0, s.indexOf('T'));
    } else {
      etime = null;
    }
    final partReg = RegExp('(\\?|~|%)?(Y?-?\\d{4,}|\\d+)(\\?|~|%)?');
    final parts = partReg.allMatches(s).map((e) => e.group(0)).toList();
    EdtfNumber year, month, day;
    if (parts.length >= 1) {
      year = EdtfNumber.parse(parts[0]);
    }
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
}

class EdtfTime {
  final int hour;
  final int minutes;
  final int seconds;
  final int _shiftHour;
  final int _shiftMinute;
  int get shiftHour {
    switch(shiftLevel) {
      case shiftLevelUTC:
        return 0;
      case shiftLevelHour:
      case shiftLevelMinute:
        return _shiftHour;
      default: // shiftLevel == shiftLevelLocal or error
        return null;
    }
  }
  int get shiftMinute {
    switch(shiftLevel) {
      case shiftLevelUTC:
      case shiftLevelHour:
        return 0;
      case shiftLevelMinute:
        return _shiftMinute;
      default: // shiftLevel == shiftLevelLocal or error
        return null;
    }
  }

  final int shiftLevel;
  static const shiftLevelLocal = 0; // TODO shiftLocal
  static const shiftLevelUTC = 1;
  static const shiftLevelHour = 2;
  static const shiftLevelMinute = 3;

  EdtfTime(this.hour, this.minutes, this.seconds, this.shiftLevel,
      [this._shiftHour, this._shiftMinute]);

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
      final shiftTime = parts[2].substring(2).split(':');
      final shiftHour = int.parse(shiftTime[0]);
      if (shiftTime.length == 1) {
        // Has shiftHour precision
        final shiftLevel = EdtfTime.shiftLevelHour;
        return EdtfTime(hour, minutes, seconds, shiftLevel, shiftHour);
      } else {
        // Has shiftHour:shiftMinute format
        final shiftMinute = int.parse(shiftTime[1]);
        final shiftLevel = EdtfTime.shiftLevelMinute;
        return EdtfTime(
            hour, minutes, seconds, shiftLevel, shiftHour, shiftMinute);
      }
    }
  }

  @override
  String toString() {
    String ret = '';
    ret += _toFixedString(hour, 2);
    ret += ':';
    ret += _toFixedString(minutes, 2);
    ret + ':';
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
      ret += _toFixedString(_shiftMinute, 2);
      return ret;
    } else {
      throw ArgumentError('Unexpected shiftLevel');
    }
  }
}

String _toFixedString(int number, int width, {bool plusSign = false}) {
  String ret = '';
  if (plusSign && number >= 0) {
    ret += '+';
  } else if (number < 0) {
    ret += '-';
  }
  ret += number.abs().toString().padLeft(width, '0');
  return ret;
}

class EdtfNumber {
  final int value;
  final int exp;
  final int precision;
  final String unspecMask;
  final bool localApprox;
  final bool localUncert;
  final bool groupApprox;
  final bool groupUncert;

  // TODO everything final
  // TODO replace-hez hasonló

  get realValue => value * pow(10, exp);

  EdtfNumber._(
      {@required this.value,
      this.exp,
      this.precision,
      this.unspecMask,
      this.localApprox,
      this.localUncert,
      this.groupApprox,
      this.groupUncert}); // TODO named optional values

  factory EdtfNumber._addGroup(EdtfNumber target, EdtfNumber prev) {
    return EdtfNumber._(
        value: target.value,
        exp: target.exp,
        precision: target.precision,
        unspecMask: target.unspecMask,
        localApprox: target.localApprox,
        localUncert: target.localUncert,
        groupApprox: target.groupApprox | prev.groupApprox,
        groupUncert: target.groupUncert | prev.groupUncert);
  }

  factory EdtfNumber.parse(String s) {
    // Group 1: value with missing digits
    // Group 3: exp
    // Group 5: prec
    final nums = RegExp(r'(-?[\dXu]+)([Ee](\d+))?([Sp](\d+))?').firstMatch(s);
    final value = int.parse(nums.group(1).replaceAll(RegExp('[Xu]'), '0'));
    final exp = nums.group(3) != null ? int.parse(nums.group(3)) : null;
    final precision = nums.group(5) != null ? int.parse(nums.group(5)) : null;
    final unspecMask = nums.group(1).replaceAll(RegExp('\d'), '.');

    final localApprox = s.contains('~') || s.contains('%');
    final localUncert = s.contains('?') || s.contains('%');
    final groupApprox = s.endsWith('~') || s.endsWith('%');
    final groupUncert = s.endsWith('?') || s.endsWith('%');

    return EdtfNumber._(
        value: value,
        exp: exp,
        precision: precision,
        unspecMask: unspecMask,
        localApprox: localApprox,
        localUncert: localUncert,
        groupApprox: groupApprox,
        groupUncert: groupUncert);
  }
}

const edtfMonthNames = {
  21: "Spring",
  22: "Summer",
  23: "Autumn",
  24: "Winter",
  25: "Spring - Northern Hemisphere",
  26: "Summer - Northern Hemisphere",
  27: "Autumn - Northern Hemisphere",
  28: "Winter - Northern Hemisphere",
  29: "Spring - Southern Hemisphere",
  30: "Summer - Southern Hemisphere",
  31: "Autumn - Southern Hemisphere",
  32: "Winter - Southern Hemisphere",
  33: "Quarter 1 (3 months in duration)",
  34: "Quarter 2 (3 months in duration)",
  35: "Quarter 3 (3 months in duration)",
  36: "Quarter 4 (3 months in duration)",
  37: "Quadrimester 1 (4 months in duration)",
  38: "Quadrimester 2 (4 months in duration)",
  39: "Quadrimester 3 (4 months in duration)",
  40: "Semestral 1 (6 months in duration)",
  41: "Semestral 2 (6 months in duration)",
};
