/// Support for doing something awesome.
///
/// More dartdocs go here.
library edtf;

import 'package:edtf/src/edtf_base.dart';

export 'src/edtf_base.dart';

EDTF parse(String s) {
  if(RegExp('^[.*]\$').hasMatch(s)) {
    // OneOf
    return null; // TODO
  }
  else if(RegExp('^{.*}\$').hasMatch(s)) {
    // Every
    return null; // TODO
  }
  else if(RegExp('/').hasMatch(s)) {
    // Interval
    final ret = EDTFInterval();
    final dates = s.split('/');
    assert(dates.length == 2);
    if(dates[0] == '') {
      ret.start = null;
      ret.openStart = false;
    } else if(dates[0] == '..') {
      ret.start = null;
      ret.openStart = true;
    } else {
      ret.start = parse(dates[0]);
      ret.openStart = false;
    }
    if(dates[1] == '') {
      ret.end = null;
      ret.openEnd = false;
    } else if(dates[1] == '..') {
      ret.end = null;
      ret.openEnd = true;
    } else {
      ret.end = parse(dates[1]);
      ret.openEnd = false;
    }
  } else {
    // Date
    final ret = EDTFDate();
    if(s.contains('T')) {
      final retTime = EDTFTime();
      final time = s.substring(s.indexOf('T') + 1);
      final parts = time.split(':');
      retTime.hour = int.parse(parts[0]);
      retTime.minutes = int.parse(parts[1]);
      retTime.seconds = int.parse(parts[2].substring(0, 2));
      if(parts[2].length <= 2) {
        // Local time
        retTime.shiftLevel = EDTFTime.SHIFT_LOCAL;
      } else if(parts[2][2] == 'Z') {
        // UTC time
        retTime.shiftHour = 0;
        retTime.shiftMinute = 0;
        retTime.shiftLevel = EDTFTime.SHIFT_UTC;
      } else {
        // Shift is added
        final shiftTime = parts[2].substring(2).split(':');
        retTime.shiftHour = int.parse(shiftTime[0]);
        if(shiftTime.length >= 2) {
          // Has shiftHour:shiftMinute format
          retTime.shiftMinute = int.parse(shiftTime[1]);
          retTime.shiftLevel = EDTFTime.SHIFT_MINUTE;
        } else {
          // Has shiftHour precision
          retTime.shiftMinute = 0;
          retTime.shiftLevel = EDTFTime.SHIFT_HOUR;
        }
      }
      s = s.substring(s.indexOf('T'));
      ret.time = retTime;
    } else {
      ret.time = null;
    }
    // TODO date parsing
    return ret;
  }
  return null;
}

// TODO: Export any libraries intended for clients of this package.
