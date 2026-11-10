/// A student (for one school year) who owes money, with the full cost breakdown.
///
/// This is a read-only model: it is built from a database query result with
/// [Debtor.fromMap] and shown in the debtor list. All amounts are whole numbers.
///
/// The amounts are related like this:
/// - [totalRequiredPayment] = [tuition] + [extraCost] - [discount]
/// - [remainingAmount] = [totalRequiredPayment] - [totalPaid]
class Debtor {
  /// The unique identifier for the student or the student-year enrollment record.
  ///
  /// It is read from the `student_id` column. The debtor list passes it on as
  /// the "student year" ID (for the payment dialog and the Excel report), so it
  /// must be the ID of the enrollment record, not only of the student.
  final int? id;

  /// The student's full name.
  final String fullName;

  /// The ID referencing the student's major or course of study.
  final int majorId;

  /// The ID referencing the academic school year the data pertains to.
  final int yearId;

  /// The student's grade level (e.g., 10, 11, 12).
  final int grade;

  /// The base tuition cost for this student's enrollment parameters.
  final int tuition;

  /// The total amount of any additional fees or extra costs.
  final int extraCost;

  /// The total discount amount applied to the student's tuition and fees.
  final int discount;

  /// The total required payment for the student (Tuition + ExtraCost - Discount).
  final int totalRequiredPayment;

  /// The sum of all payments made by the student to date.
  final int totalPaid;

  /// The outstanding balance (Total Required Payment - Total Paid).
  /// A positive value indicates debt.
  final int remainingAmount;

  /// Primary constructor for creating an immutable Debtor object.
  /// Only [id] is optional; all other values are required.
  Debtor({
    this.id,
    required this.fullName,
    required this.majorId,
    required this.yearId,
    required this.grade,
    required this.tuition,
    required this.extraCost,
    required this.discount,
    required this.totalRequiredPayment,
    required this.totalPaid,
    required this.remainingAmount,
  });

  /// Factory constructor to create a [Debtor] instance from a database row map.
  ///
  /// This method maps specific database column names (snake_case) to the
  /// corresponding class fields (camelCase).
  ///
  /// The query must return every column used below. The values are not checked,
  /// so a missing key or a `null` value (for example a sum with no rows, such as
  /// `total_paid` for a student without payments, unless the query replaces it
  /// with 0) throws a type error here.
  factory Debtor.fromMap(Map<String, dynamic> map) {
    return Debtor(
      id: map['student_id'],
      fullName: map['full_name'],
      majorId: map['major_id'],
      yearId: map['year_id'],
      grade: map['grade_level'],
      tuition: map['tuition_price'],
      extraCost: map['extra_cost_amount'],
      discount: map['discount_amount'],
      totalRequiredPayment: map['total_required'],
      totalPaid: map['total_paid'],
      remainingAmount: map['remaining_amount'],
    );
  }

  /// Provides a string representation of the Debtor object for logging and debugging.
  @override
  String toString() {
    return {
      'id': id,
      'fullName': fullName,
      'major': majorId,
      'year': yearId,
      'grade': grade,
      'discount': discount,
      'tuition': tuition,
      'extraCost': extraCost,
      'totalRequiredPayment': totalRequiredPayment,
      'totalPaid': totalPaid,
      'remainingAmount': remainingAmount,
    }.toString();
  }
}