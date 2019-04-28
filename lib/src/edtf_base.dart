// TODO: Put public facing types in this file.

/// Checks if you are awesome. Spoiler: you are.
class Awesome {
  bool get isAwesome => true;
}

class EDTF {}

class EDTFSet extends EDTF {
  List<EDTF> dates;
}

class EDTFEvery extends EDTFSet {}

class EDTFOneOf extends EDTFSet {}

class EDTFInterval extends EDTF {
  EDTFDate start;
  EDTFDate end;
  bool openStart;
  bool openEnd;
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
}

class EDTFTime {
  int hour;
  int minutes;
  int seconds;
  int shiftHour;
  int shiftMinute;

  int shiftLevel;
  static const SHIFT_LOCAL = 0;
  static const SHIFT_UTC = 1;
  static const SHIFT_HOUR = 2;
  static const SHIFT_MINUTE = 3;
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
