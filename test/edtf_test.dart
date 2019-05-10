import 'package:edtf/edtf.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests', () {
    Awesome awesome;

    setUp(() {
      awesome = Awesome();
    });

    test('First Test', () {
      expect(awesome.isAwesome, isTrue);
    });
    test('Date parse test', () {
      ///                      Y-12019-%05-26~T15:34:06Z
      final dateParse = Edtf.parse('Y-12019-?05-26~T15:34:06Z');
      expect(dateParse.runtimeType, EdtfDate);
      EdtfDate date = dateParse;
      expect(date.year.value, -12019);
      expect(date.year.localApprox, false);
      expect(date.year.localUncert, false);
      expect(date.year.groupApprox, true);
      expect(date.year.groupUncert, false);
      expect(date.month.value, 5);
      expect(date.month.localApprox, false);
      expect(date.month.localUncert, true);
      expect(date.month.groupApprox, true);
      expect(date.month.groupUncert, false);
      expect(date.day.value, 26);
      expect(date.day.localApprox, true);
      expect(date.day.localUncert, false);
      expect(date.day.groupApprox, true);
      expect(date.day.groupUncert, false);
      expect(date.time.hour, 15);
      expect(date.time.minutes, 34);
      expect(date.time.seconds, 6);
      expect(date.time.shiftLevel, EdtfTime.shiftLevelUTC);
    });
    test('Date year parse test', () {
      final EdtfDate year1 = Edtf.parse('1234');
      assert(year1.year != null);
      assert(year1.month == null);
      assert(year1.day == null);
      assert(year1.time == null);
      expect(year1.year.value, 1234);
      expect(year1.year.exp, null);
      expect(year1.year.precision, null);
      expect(year1.year.unspecMask, '1234');
      expect(year1.year.localApprox, false);
      expect(year1.year.localUncert, false);
      expect(year1.year.groupApprox, false);
      expect(year1.year.groupUncert, false);
      final EdtfDate year2 = Edtf.parse('~-20XX?');
      assert(year2.year != null);
      assert(year2.month == null);
      assert(year2.day == null);
      assert(year2.time == null);
      expect(year2.year.value, -2000);
      expect(year2.year.exp, null);
      expect(year2.year.precision, null);
      expect(year2.year.unspecMask, '-20..');
      expect(year2.year.localApprox, true);
      expect(year2.year.localUncert, true);
      expect(year2.year.groupApprox, false);
      expect(year2.year.groupUncert, true);
      final EdtfDate year3 = Edtf.parse('-12X3E9S3%');
      assert(year3.year != null);
      assert(year3.month == null);
      assert(year3.day == null);
      assert(year3.time == null);
      expect(year3.year.value, -1203);
      expect(year3.year.exp, 9);
      expect(year3.year.precision, 3);
      expect(year3.year.unspecMask, '-12.3');
      expect(year3.year.localApprox, true);
      expect(year3.year.localUncert, true);
      expect(year3.year.groupApprox, true);
      expect(year3.year.groupUncert, true);
    });
  });
  test('Interval parse test', () {
    final EdtfInterval uninterval = Edtf.parse('/');
    expect(uninterval.start, null);
    expect(uninterval.openStart, false);
    expect(uninterval.end, null);
    expect(uninterval.openEnd, false);
    final EdtfInterval openinterval = Edtf.parse('../..');
    expect(openinterval.start, null);
    expect(openinterval.openStart, true);
    expect(openinterval.end, null);
    expect(openinterval.openEnd, true);
    final EdtfInterval ival = Edtf.parse('1900/2019');
    expect(ival.start.year.value, 1900);
    expect(ival.openStart, false);
    expect(ival.end.year.value, 2019);
    expect(ival.openEnd, false);
  });
  test('Set parse tests', () {
    final EdtfOneOf oneOf = Edtf.parse('[1999, 2000, 2013..2017, 2019..]');
    expect(oneOf.values[0].runtimeType, EdtfDate);
    expect(oneOf.values[1].runtimeType, EdtfDate);
    expect(oneOf.values[2].runtimeType, EdtfInterval);
    expect(oneOf.values[3].runtimeType, EdtfInterval);
    expect((oneOf.values[0] as EdtfDate).year.value, 1999);
    expect((oneOf.values[1] as EdtfDate).year.value, 2000);
    expect((oneOf.values[2] as EdtfInterval).start.year.value, 2013);
    expect((oneOf.values[2] as EdtfInterval).end.year.value, 2017);
    expect((oneOf.values[3] as EdtfInterval).start.year.value, 2019);
    expect((oneOf.values[3] as EdtfInterval).openEnd, true);
  });
}
