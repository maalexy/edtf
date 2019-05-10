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
    test('Date test', () {
      ///                      Y-12019-%05-06~T15:34:06Z
      final date = Edtf.parse('Y-12019-?05-06~T15:34:06Z');
      expect(date.runtimeType, EdtfDate);
      EdtfDate date2 = date;
      expect(date2.year.value, -12019);
      expect(date2.month.localUncert, true);
      expect(date2.month.localApprox, false);
      expect(date2.month.groupUncert, false);
      expect(date2.month.groupApprox, true);
      expect(date2.day.groupApprox, true);
      expect(date2.time.shiftLevel, EdtfTime.shiftLevelUTC);
      expect(date2.time.seconds, 6);
    });
  });
}
