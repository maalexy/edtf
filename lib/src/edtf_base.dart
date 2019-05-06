// TODO: Put public facing types in this file.

import 'dart:math';

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

/// edtf, replace

class EDTF {
  EDTF();
  factory EDTF.parse(String s) {
    if (RegExp('^[.*]\$').hasMatch(s)) {
      // OneOf
      return null; // TODO
    } else if (RegExp('^{.*}\$').hasMatch(s)) {
      // Every
      return null; // TODO
    } else if (RegExp('/').hasMatch(s)) {
      // Interval
      return EDTFInterval.parse(s);
    } else {
      // Date
    }
    return null;
  }

  String toString() {
    return super.toString();
  }

  String toInnerString() {
    return this.toString();
  }
}

class EDTFSet extends EDTF {
  final List<EDTF> dates;
  EDTFSet([this.dates]);
  factory EDTFSet.parse() {}
}

class EDTFEvery extends EDTFSet {
  EDTFEvery(dates) : super(dates);
  factory EDTFEvery.parse(String s) {}
}

class EDTFOneOf extends EDTFSet {
  EDTFOneOf(dates) : super(dates);
  factory EDTFOneOf.parse(String s) {}
}

class EDTFInterval extends EDTF {
  EDTFDate start;
  EDTFDate end;
  bool openStart;
  bool openEnd;

  EDTFInterval(this.start, this.end, this.openStart, this.openEnd);
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
}

class EDTFDate extends EDTF {
  EDTFNumber year;
  EDTFNumber month;
  EDTFNumber day;
  EDTFTime time;

  EDTFDate(this.year, this.month, this.day, this.time);
  factory EDTFDate.parse(String s) {
    EDTFTime etime;
    if (s.contains('T')) {
      final time = s.substring(s.indexOf('T') + 1);
      etime = EDTFTime.parse(time);
      s = s.substring(0, s.indexOf('T'));
    } else {
      etime = null;
    }
    final parts = <String>[];
    for (final part in s.split('-')) {
      if (parts.last.endsWith('Y')) {
        parts.last += part;
      } else {
        parts.add(part);
      }
    }
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
  final int shiftHour;
  final int shiftMinute;

  final int shiftLevel;
  static const SHIFT_LOCAL = 0;
  static const SHIFT_UTC = 1;
  static const SHIFT_HOUR = 2;
  static const SHIFT_MINUTE = 3;

  EDTFTime(this.hour, this.minutes, this.seconds, this.shiftLevel,
      [this.shiftHour, this.shiftMinute]);

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

  get realValue => value * pow(10, exp);

  EDTFNumber(this.value,
      [this.exp,
      this.precision,
      this.unspecMask,
      this.localApprox,
      this.localUncert,
      this.groupApprox,
      this.groupUncert]);

  factory EDTFNumber._addGroup(EDTFNumber target, EDTFNumber prev) {
    return EDTFNumber(
        target.value,
        target.exp,
        target.precision,
        target.unspecMask,
        target.localApprox,
        target.localUncert,
        target.groupApprox | prev.groupApprox,
        target.groupUncert | prev.groupUncert);
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

    return EDTFNumber(value, exp, precision, unspecMask, localApprox,
        localUncert, groupApprox, groupUncert);
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
