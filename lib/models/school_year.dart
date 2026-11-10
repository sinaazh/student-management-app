/// A school (academic) year that students are enrolled in.
///
/// It is an immutable model: it is built from a database row with
/// [SchoolYear.fromMap]. The list of all school years is kept in
/// `SharedDataService` and used by the dropdowns across the app.
class SchoolYear {
  /// The unique integer identifier for the school year record in the database.
  ///
  /// New years are created with the placeholder ID `0` (see `SettingsController`):
  /// the database assigns the real ID when the year is inserted.
  final int id;

  /// The integer value representing the academic year (e.g., 2024 for the 2023-2024 academic cycle).
  /// The database column is expected to be named 'education_year'.
  final int year;

  /// Primary constructor for creating an immutable SchoolYear object.
  SchoolYear({required this.id, required this.year});

  /// Factory constructor to create a [SchoolYear] instance from a database row map.
  ///
  /// This is used to deserialize data fetched from the database, mapping the
  /// key 'education_year' to the class field `year`.
  /// The values are not checked, so a missing key or a `null` throws a type error.
  factory SchoolYear.fromMap(Map<String, dynamic> map) {
    return SchoolYear(
      id: map['id'],
      year: map['education_year'],
    );
  }

  /// Provides a string representation of the SchoolYear object for logging and debugging.
  @override
  String toString() {
    return {
      'id': id,
      'year': year,
    }.toString();
  }
}