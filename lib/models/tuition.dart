/// The tuition fee for one combination of major, school year and grade level.
///
/// It is an immutable model: it is built from a database row with
/// [Tuition.fromMap], or created in the tuition form before it is saved.
/// A new record has no [id] yet; the database assigns it when the record is inserted.
/// The amount is added to a student's extra costs and reduced by the discount
/// to get the total they have to pay (see `Debtor`).
class Tuition {
  /// The unique identifier for the tuition record in the database.
  /// It is `null` for a record that has not been saved yet.
  final int? id;

  /// The ID referencing the **Major** or course of study this tuition applies to.
  final int majorId;

  /// The ID referencing the **School Year** this tuition is active for.
  final int yearId;

  /// The **Grade Level** (e.g., 10, 11, 12) this tuition applies to.
  final int grade;

  /// The tuition amount for this major, year and grade (a whole number).
  final int price;

  /// Primary constructor for creating an immutable Tuition object.
  /// Only [id] is optional; all other values are required.
  Tuition({
    this.id,
    required this.majorId,
    required this.yearId,
    required this.grade,
    required this.price,
  });

  /// Factory constructor to create a [Tuition] instance from a database row map.
  ///
  /// This method maps specific database column names (snake_case, e.g., 'grade_level')
  /// to the corresponding class fields (camelCase). Note that the column
  /// `grade_level` is stored in the field [grade].
  ///
  /// The values are not checked, so a missing key or a `null` in a required
  /// column throws a type error.
  factory Tuition.fromMap(Map<String, dynamic> map) {
    return Tuition(
      id: map['id'],
      majorId: map['major_id'],
      yearId: map['year_id'],
      grade: map['grade_level'],
      price: map['price'],
    );
  }

  /// Provides a string representation of the Tuition object for logging and debugging.
  @override
  String toString() {
    return {
      'id': id,
      'major': majorId,
      'year': yearId,
      'grade': grade,
      'price': price,
    }.toString();
  }
}