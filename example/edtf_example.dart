import 'package:edtf/edtf.dart';

main() {
  /// Parse a date in the EDTF format
  final date = EdtfDate.parse('1985-05%-13?');

  /// Check that the year is an approximation.
  if (date.year.approx) {
    /// If it is an approximation, then print it
    print(date.toString());
  }

  /// Parse an EDTF formatted interval
  final interval = EdtfInterval.parse('../2012');

  /// If the interval is open started and the end is a known date...
  if (interval.openStart || interval.end != null) {
    /// ... print the end date.
    print(interval.end.toString());
  }

  /// Parse a set of EDTF dates/intervals, where the real date is one of them.
  final oneOf = EdtfOneOf.parse('[1981, 1982-~04, 1983-1987]');

  /// Iterate through the dates/intervals
  for (final elem in oneOf.values) {
    /// If the elem is a date print it in this format
    if (elem is EdtfDate) {
      print('Date: ' + elem.toString());
    }

    /// If the elem is an interval just print the start date
    if (elem is EdtfInterval) {
      print('Interval start date: ' +
          (elem.openStart ? 'open' : elem.start.toString()));
      // An interval either has an known start date or open started
    }
  }
}
