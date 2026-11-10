/// A major (course of study) that students can be enrolled in.
///
/// It is an immutable model: it is built from a database row with
/// [Major.fromMap]. The list of all majors is kept in `SharedDataService` and
/// used by the dropdowns across the app.
class Major {
  /// The unique integer identifier for the major in the database.
  ///
  /// New majors are created with the placeholder ID `0` (see `SettingsController`):
  /// the database assigns the real ID when the major is inserted.
  final int id;

  /// The human-readable name of the major (e.g., "Science", "Literature", "Computer Engineering").
  final String name;

  /// Primary constructor for creating an immutable Major object.
  Major({required this.id, required this.name});

  /// Factory constructor to create a [Major] instance from a database row map.
  ///
  /// This is used to deserialize data fetched from the database, mapping the
  /// keys 'id' and 'name' from the map to the class fields.
  /// The values are not checked, so a missing key or a `null` throws a type error.
  factory Major.fromMap(Map<String, dynamic> map) {
    return Major(
      id: map['id'],
      name: map['name'],
    );
  }
}