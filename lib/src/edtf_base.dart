// TODO: Put public facing types in this file.

import 'dart:html_common';
import 'dart:math';
import 'package:meta/meta.dart';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

/// edtf, replace

abstract class EDTF {
  EDTF._();

  factory EDTF.parse(String s) {
    if (RegExp('^[.*]\$').hasMatch(s)) {
      // OneOf
      return EDTFOneOf.parse(s);
    } else if (RegExp('^{.*}\$').hasMatch(s)) {
      // Every
      return EDTFEvery.parse(s);
    } else if (RegExp('/').hasMatch(s)) {
      // Interval
      return EDTFInterval.parse(s);
    } else {
      // Date
      return EDTFDate.parse(s);
    }
  }

  /// Inner: in enclosed dates, interval rules are different
  factory EDTF._parseInner(String s) {
    if (RegExp('..').hasMatch(s)) {
      // Interval
      return EDTFInterval._parseInner(s);
    } else {
      // Date
      return EDTFDate.parse(s);
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

abstract class EDTFSet extends EDTF {
  final List<EDTF> values;
  EDTFSet._([this.values]) : super._();

  static List<EDTF> _parseDates(String s) {
    final dates = <EDTF>[];
    for (final elem in s.split(',')) {
      dates.add(EDTF._parseInner(elem));
    }
    return dates;
  }

  @override
  String toString() {
    return 'ASD';
  }
}

class EDTFEvery extends EDTFSet {
  EDTFEvery(values) : super._(values);
  static final _regExp = RegExp('^{(.*)}\$');
  factory EDTFEvery.parse(String s) {
    return EDTFEvery(EDTFSet._parseDates(_regExp.firstMatch(s).group(1)));
  }
}

class EDTFOneOf extends EDTFSet {
  EDTFOneOf(values) : super._(values);
  factory EDTFOneOf.parse(String s) {
    final _regExp = RegExp('^[(.*)]\$');
    return EDTFOneOf(
        EDTFSet._parseDates(_regExp.firstMatch(s).group(1)));
  }
}

class EDTFInterval extends EDTF {
  final EDTFDate start;
  final EDTFDate end;
  final bool openStart;
  final bool openEnd;

  EDTFInterval(this.start, this.end, this.openStart, this.openEnd) : super._();
  factory EDTFInterval.parse(String s) {
    final dates = s.split('/');
    EDTFDate start, end;
    bool openStart, openEnd;
    assert(dates.length == 2);
    if (dates[0] == '') {
      start = null;
      openStart = false;
    } else if (dates[0] == '..') {
      start = null;
      openStart = true;
    } else {
      start = EDTFDate.parse(dates[0]);
      openStart = false;
    }
    if (dates[1] == '') {
      end = null;
      openEnd = false;
    } else if (dates[1] == '..') {
      end = null;
      openEnd = true;
    } else {
      end = EDTFDate.parse(dates[1]);
      openEnd = false;
    }
    return EDTFInterval(start, end, openStart, openEnd);
  }
  factory EDTFInterval._parseInner(String s) {
    final dates = s.split('..');
    EDTFDate start, end;
    bool openStart, openEnd;
    assert(dates.length == 2);
    if (dates[0] == '') {
      start = null;
      openStart = true;
    } else {
      start = EDTFDate.parse(dates[0]);
      openStart = false;
    }
    if (dates[1] == '') {
      end = null;
      openEnd = true;
    } else {
      end = EDTFDate.parse(dates[1]);
      openEnd = false;
    }
    return EDTFInterval(start, end, openStart, openEnd);
  }
}

class EDTFDate extends EDTF {
  final EDTFNumber year;
  final EDTFNumber month;
  final EDTFNumber day;
  final EDTFTime time;

  EDTFDate(this.year, this.month, this.day, this.time) : super._();
  factory EDTFDate.parse(String s) {
    EDTFTime etime;
    if (s.contains('T')) {
      final time = s.substring(s.indexOf('T') + 1);
      etime = EDTFTime.parse(time);
      s = s.substring(0, s.indexOf('T'));
    } else {
      etime = null;
    }
    final partReg = RegExp('(\\?|~|%)?(Y?-?\\d{4,}|\\d+)(\\?|~|%)?');
    final parts = partReg.allMatches(s).map((e) => e.group(0)).toList();
    EDTFNumber year, month, day;
    if (parts.length >= 1) {
      year = EDTFNumber.parse(parts[0]);
    }
    if (parts.length >= 2) {
      month = EDTFNumber.parse(parts[1]);
      year = EDTFNumber._addGroup(year, month);
    }
    if (parts.length >= 3) {
      day = EDTFNumber.parse(parts[2]);
      month = EDTFNumber._addGroup(month, day);
      year = EDTFNumber._addGroup(year, day);
    }
    return EDTFDate(year, month, day, etime);
  }
}

class EDTFTime {
  final int hour;
  final int minutes;
  final int seconds;
  final int _shiftHour;
  final int _shiftMinute;
  int get shiftHour {
    switch(shiftLevel) {
      case SHIFT_UTC:
        return 0;
      case SHIFT_HOUR:
      case SHIFT_MINUTE:
        return _shiftHour;
      default: // shiftLevel == SHIFT_LOCAL
        return null;
    }
  }
  int get shiftMinute {
    switch(shiftLevel) {
      case SHIFT_UTC:
      case SHIFT_HOUR:
        return 0;
      case SHIFT_MINUTE:
        return _shiftMinute;
      default: // shiftLevel == SHIFT_LOCAL
        return null;
    }
  }

  final int shiftLevel;
  static const SHIFT_LOCAL = 0; // TODO shiftLocal
  static const SHIFT_UTC = 1;
  static const SHIFT_HOUR = 2;
  static const SHIFT_MINUTE = 3;

  EDTFTime(this.hour, this.minutes, this.seconds, this.shiftLevel,
      [this._shiftHour, this._shiftMinute]);

  factory EDTFTime.parse(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2].substring(0, 2));
    if (parts[2].length <= 2) {
      // Local time
      final shiftLevel = EDTFTime.SHIFT_LOCAL;
      return EDTFTime(hour, minutes, seconds, shiftLevel);
    } else if (parts[2][2] == 'Z') {
      // UTC time
      final shiftLevel = EDTFTime.SHIFT_UTC;
      return EDTFTime(hour, minutes, seconds, shiftLevel);
    } else {
      // Shift is added
      final shiftTime = parts[2].substring(2).split(':');
      final shiftHour = int.parse(shiftTime[0]);
      if (shiftTime.length == 1) {
        // Has shiftHour precision
        final shiftLevel = EDTFTime.SHIFT_HOUR;
        return EDTFTime(hour, minutes, seconds, shiftLevel, shiftHour);
      } else {
        // Has shiftHour:shiftMinute format
        final shiftMinute = int.parse(shiftTime[1]);
        final shiftLevel = EDTFTime.SHIFT_MINUTE;
        return EDTFTime(
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
    if (shiftLevel == SHIFT_LOCAL) {
      return ret;
    } else if (shiftLevel == SHIFT_UTC) {
      return ret + 'Z';
    } else if (shiftLevel == SHIFT_HOUR) {
      ret += _toFixedString(_shiftHour, 2, plusSign: true);
      return ret;
    } else if (shiftLevel == SHIFT_MINUTE) {
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

class EDTFNumber {
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

  EDTFNumber._(
      {@required this.value,
      this.exp,
      this.precision,
      this.unspecMask,
      this.localApprox,
      this.localUncert,
      this.groupApprox,
      this.groupUncert}); // TODO named optional values

  factory EDTFNumber._addGroup(EDTFNumber target, EDTFNumber prev) {
    return EDTFNumber._(
        value: target.value,
        exp: target.exp,
        precision: target.precision,
        unspecMask: target.unspecMask,
        localApprox: target.localApprox,
        localUncert: target.localUncert,
        groupApprox: target.groupApprox | prev.groupApprox,
        groupUncert: target.groupUncert | prev.groupUncert);
  }

  factory EDTFNumber.parse(String s) {
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

    return EDTFNumber._(
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
