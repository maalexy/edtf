// TODO: Put public facing types in this file.

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

  int uncertLevel;
  int approxLevel;
  static const LEVEL_NONE = 0;
  static const LEVEL_YEAR = 1;
  static const LEVEL_MONTH = 2;
  static const LEVEL_DAY = 3;

  EDTFDate(this.year, this.month, this.day, this.time, this.uncertLevel,
      this.approxLevel);
  factory EDTFDate.parse(String s) {
    EDTFTime etime;
    if (s.contains('T')) {
      final time = s.substring(s.indexOf('T') + 1);
      etime = EDTFTime.parse(time);
    } else {
      etime = null;
    }
    // TODO date parsing
    return null;
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
      return EDTFTime(hour, minutes, seconds, shiftLevel, 0, 0);
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
  int value;
  int exp;
  int precision;
  String unspecMask;
  bool approx;
  bool uncert;
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
