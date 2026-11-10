/// An additional fee (for example a lab fee or uniform cost) that applies to
/// one combination of major, school year and grade level.
///
/// It is an immutable model: it is built from a database row with
/// [ExtraCost.fromMap], or created in the form before it is saved.
/// A new record has no [id] yet; the database assigns it when the record is inserted.
class ExtraCost {
  /// The unique identifier for the extra cost record in the database.
  /// It is `null` for a record that has not been saved yet.
  final int? id;

  /// The ID referencing the **Major** or course of study this fee applies to.
  final int majorId;

  /// The ID referencing the **School Year** this fee is active for.
  final int yearId;

  /// The **Grade Level** (e.g., 10, 11, 12) this fee applies to.
  final int grade;

  // --- Cost Details ---

  /// The monetary amount of the extra cost (a whole number).
  final int price;

  /// An optional human-readable description explaining what the extra cost is for
  /// (e.g., "Lab Fee", "Uniform Cost").
  final String? description;

  /// Primary constructor for creating an immutable ExtraCost object.
  /// [id] and [description] are optional; everything else is required.
  ExtraCost({
    this.id,
    required this.majorId,
    required this.yearId,
    required this.grade,
    required this.price,
    this.description,
  });

  /// Factory constructor to create an [ExtraCost] instance from a database row map.
  ///
  /// This method maps specific database column names (snake_case, e.g., 'major_id')
  /// to the corresponding class fields (camelCase). Note that the column
  /// `grade_level` is stored in the field [grade].
  ///
  /// The values are not checked, so a missing key or a `null` in a required
  /// column throws a type error. Only `id` and `description` may be `null`.
  factory ExtraCost.fromMap(Map<String, dynamic> map) {
    return ExtraCost(
      id: map['id'],
      majorId: map['major_id'],
      yearId: map['year_id'],
      grade: map['grade_level'],
      price: map['price'],
      description: map['description'],
    );
  }

  /// Provides a string representation of the ExtraCost object for logging and debugging.
  @override
  String toString() {
    return {
      'id': id,
      'major': majorId,
      'year': yearId,
      'grade': grade,
      'price': price,
      'description': description,
    }.toString();
  }
}