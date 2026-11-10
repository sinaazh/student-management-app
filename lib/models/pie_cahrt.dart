/// Summary of how many students have paid, for the payment status pie chart.
///
/// It holds the total number of students and the share of students in each of
/// the three groups: fully paid, partially paid and not paid.
/// It is an immutable model built with [PieCahrt.fromMap] from the result of an
/// aggregation query. (The name "PieCahrt" is a typo of "PieChart".)
class PieCahrt {
  /// Number of students included in the calculation (all students, or only
  /// those matching the filters).
  final int totalStudents;

  /// Percentage of students who have paid everything they owe.
  /// (The scale, 0-100 or 0-1, is defined by the database query.)
  final double fullyPaidPercentage;

  /// Percentage of students who have paid only part of what they owe.
  final double partiallyPaidPercentage;

  /// Percentage of students who have not paid.
  final double notPaidPercentage;

  /// Primary constructor for creating an immutable PieCahrt object.
  /// All values are required.
  PieCahrt({
    required this.totalStudents, 
    required this.fullyPaidPercentage, 
    required this.partiallyPaidPercentage, 
    required this.notPaidPercentage
  });

  /// Factory constructor to create a [PieCahrt] instance from a data map.
  ///
  /// This is used to deserialize the summary results returned from a database query
  /// that performs the necessary aggregation and percentage calculation.
  ///
  /// The percentages are read directly as `double`, so each value must really
  /// be a decimal number. A whole number (e.g. `0`) or a `null` (e.g. when the
  /// query divides by zero because no student matches) throws a type error here.
  factory PieCahrt.fromMap(Map<String, dynamic> map) {
    return PieCahrt(
      totalStudents: map["total_students"],
      fullyPaidPercentage: map["fully_paid_percentage"],
      partiallyPaidPercentage: map["partially_paid_percentage"],
      notPaidPercentage: map["not_paid_percentage"],
    );
  }

  /// Provides a string representation of the PieCahrt object for logging and debugging.
  @override
  String toString() {
    return {
      'totalStudents': totalStudents,
      'fullyPaidPercentage': fullyPaidPercentage,
      'partiallyPaidPercentage': partiallyPaidPercentage,
      'notPaidPercentage': notPaidPercentage,
    }.toString();
  }
}