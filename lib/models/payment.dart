/// One payment made by a student towards their tuition and fees.
///
/// It is an immutable model: it is built from a database row with
/// [StudentPayment.fromMap], or created in the payment form before it is saved.
/// A new payment has no [id] yet; the database assigns it when the payment is inserted.
class StudentPayment {
  /// The unique integer identifier for the payment record in the database.
  /// It is `null` for a payment that has not been saved yet.
  final int? id;

  /// The foreign key referencing the student's enrollment record for a specific year.
  /// This links the payment to the correct student and academic context.
  ///
  /// It is read from the `student_year_id` column, so it holds the ID of the
  /// enrollment record (the same ID as `studentId` in `StudentPaymentController`),
  /// not only the ID of the student.
  final int? studentID;

  /// The monetary amount recorded in this payment transaction (a whole number).
  final int paymentAmount;

  /// The date the payment was made (stored as a string, e.g., "YYYY-MM-DD").
  ///
  /// Keep this exact format: the Excel report converts it with `DateTime.parse`,
  /// which throws for other formats, and in this format the text also sorts in
  /// date order.
  final String paymentDate;

  /// An optional note or description regarding the payment (e.g., "Partial payment", "Bank transfer reference").
  final String? paymentDescription;

  /// Primary constructor for creating an immutable StudentPayment object.
  /// [paymentAmount] and [paymentDate] are required; the rest are optional.
  StudentPayment({
    this.id, 
    this.studentID,
    required this.paymentAmount, 
    required this.paymentDate, 
    this.paymentDescription,
  });

  /// Factory constructor to create a [StudentPayment] instance from a database row map.
  ///
  /// This maps specific database column names (snake_case, e.g., 'student_year_id')
  /// to the corresponding class fields (camelCase). Note that the column
  /// `amount` is stored in [paymentAmount] and `description` in [paymentDescription].
  ///
  /// The values are not checked, so a missing key or a `null` in a required
  /// column (`amount`, `payment_date`) throws a type error.
  factory StudentPayment.fromMap(Map<String, dynamic> map) {
    return StudentPayment(
      id: map['id'],
      studentID: map['student_year_id'],
      paymentAmount: map['amount'], 
      paymentDate: map['payment_date'], 
      paymentDescription: map['description'],
    );
  }

  /// Provides a string representation of the StudentPayment object for logging and debugging.
  @override
  String toString() {
    return {
      'id': id,
      'Payment amount': paymentAmount,
      'Payment date': paymentDate,
      'Payment description': paymentDescription,
      'studentID': studentID,
    }.toString();
  }
}