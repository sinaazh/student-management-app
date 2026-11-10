/// A student enrolled for one school year.
///
/// One record holds both the person's details (name, codes) and the enrollment
/// data (major, school year, grade, discount). It is an immutable model: it is
/// built from a database row with [Student.fromMap], or created in the add/edit
/// forms before it is saved. A new student has no [id] yet; the database
/// assigns it when the student is inserted.
class Student {
  /// The unique integer identifier for the student record in the database.
  /// This ID typically refers to the student's enrollment for a specific year and is used as a foreign key.
  /// (The payments of a student are linked through this ID.)
  final int? id;

  /// The student's first name.
  final String firstName;

  /// The student's last name (surname).
  final String lastName;

  /// Optional national identification number (can be null).
  /// It is stored as text, so leading zeros are kept.
  final String? nationalCode;

  /// Optional school-assigned student identifier (can be null).
  final String? studentCode;

  /// The ID referencing the student's academic **Major** or course of study.
  final int majorId;

  /// The ID referencing the **School Year** (e.g., 2024) this enrollment record belongs to.
  final int yearId;

  /// The student's current **grade level** (e.g., 10, 11, 12).
  final int grade;

  /// The percentage discount applied to the student's total required payment (e.g., 10 for 10% off).
  /// (Can be null. Note: `Debtor` and the report call the discount an amount,
  /// not a percentage, so make sure the whole app uses the same meaning.)
  final int? discount;

  /// Primary constructor for creating an immutable Student object.
  /// Only [id] can be left out. [nationalCode], [studentCode] and [discount]
  /// must be passed, but can be `null`.
  Student({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.nationalCode,
    required this.studentCode,
    required this.majorId,
    required this.yearId,
    required this.grade,
    required this.discount,
  });

  /// Factory constructor to create a [Student] instance from a database row map.
  ///
  /// This method maps specific database column names (snake_case) to the
  /// corresponding class fields (camelCase). Note that the column
  /// `grade_level` is stored in the field [grade].
  ///
  /// The values are not checked, so a missing key or a `null` in a required
  /// column (names, `major_id`, `year_id`, `grade_level`) throws a type error.
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      firstName: map['first_name'],
      lastName: map['last_name'],
      nationalCode: map['national_code'],
      studentCode: map['student_code'],
      majorId: map['major_id'],
      yearId: map['year_id'],
      grade: map['grade_level'],
      discount: map['discount'],
    );
  }

  /// Provides a string representation of the Student object for logging and debugging.
  /// (It does not include [studentCode].)
  @override
  String toString() {
    return {
      'id': id,
      'name': firstName,
      'lastName': lastName,
      'nationalCode': nationalCode,
      'major': majorId,
      'year': yearId,
      'grade': grade,
      'discount': discount,
    }.toString();
  }
}