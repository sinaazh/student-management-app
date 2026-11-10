import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:get/get.dart';

/// Controller (GetX) that creates and owns the app's SQLite database.
///
/// It opens the database file (creating it with all tables on the first run)
/// and exposes the open connection as [db]. The repositories use [db] to run
/// their queries; nothing else in the app should open the database.
///
/// The database has these tables:
/// - `school_year`: the academic years.
/// - `majors`: the majors (names are unique).
/// - `students`: the person (name, national code, student code) and a primary major.
/// - `tuition`: the tuition price for one combination of year, grade and major.
/// - `student_years`: one enrollment of a student in a year (grade, discount,
///   linked tuition). Its `id` is the "student year ID" that payments and the
///   report use. A student has at most one enrollment per year.
/// - `student_payments`: the payments made for one enrollment.
/// - `extra_costs`: an extra fee for one combination of year, grade and major.
///
/// What happens to related rows when a row is deleted (`ON DELETE`):
/// - Deleting a **school year** also deletes its tuition, enrollments, and
///   (through the enrollments) all their payments.
/// - Deleting a **student** also deletes their enrollments and payments.
/// - Deleting a **major** keeps the rows that use it but sets their `major_id`
///   to `NULL` (in `students` and `tuition`).
/// - Deleting a **tuition** record sets `tuition_id` to `NULL` in the enrollments.
class SchoolManagmentDataBaseController extends GetxController {
  /// The active database connection instance, accessible to repositories.
  /// It is a `late` field, so using it before [init] has finished throws a
  /// `LateInitializationError`.
  late Database db;

  /// Initializes the FFI bindings and opens the database connection.
  ///
  /// This method must be called asynchronously before any data repository attempts
  /// to access the database. It is typically called during app startup (e.g., in GetX Bindings).
  /// Returns this controller, so it can be used with `Get.putAsync`.
  Future<SchoolManagmentDataBaseController> init() async {
    // 1. Initialize FFI for desktop/VM environments
    // (the standard sqflite plugin does not work on desktop, so the FFI
    // version is used and set as the global database factory).
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // 2. Open the database
    db = await _initDatabase();
    return this;
  }

  /// Handles the process of locating, creating, and opening the database file.
  ///
  /// The file is `SchoolManager/my_database.db`, inside the current working
  /// directory of the app.
  Future<Database> _initDatabase() async {
    // Determine the current working directory to save the database file.
    // Note: this is the folder the app was started from, which depends on how
    // the app is launched (a shortcut can use a different folder).
    String appDir = Directory.current.path;
    final folderPath = Directory('$appDir/SchoolManager');

    // ✅ Make sure the folder exists
    if (!await folderPath.exists()) {
      await folderPath.create(recursive: true);
    }

    // Construct the full path to the database file.
    String path = join(folderPath.path, 'my_database.db');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        // The schema version. [_onCreate] only runs for a brand new database
        // file, and there is no `onUpgrade`, so changing the tables below does
        // not change a database file that already exists.
        version: 1,
        onCreate:
            _onCreate, // Call _onCreate when the database is first created.
        onOpen: (db) async {
          // Ensure foreign key constraints are enforced every time the database is opened.
          // (SQLite turns them off by default for each new connection.)
          await db.execute('PRAGMA foreign_keys = ON');
        },
      ),
    );
  }

  /// Executes SQL DDL commands to create all necessary tables when the database is initially created.
  ///
  /// It runs once, inside a transaction. If one statement fails, the whole
  /// creation is rolled back and the database cannot be opened.
  Future _onCreate(Database db, int version) async {
    await db.execute('''

    -- 1. SCHOOL YEAR TABLE (e.g., 2024, 2025)
    CREATE TABLE school_year (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      education_year INTEGER NOT NULL
    );

    -- 2. MAJORS TABLE (e.g., Science, Literature, Engineering)
    CREATE TABLE majors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(50) UNIQUE NOT NULL
    );

    -- 3. STUDENTS TABLE (Personal Information)
    CREATE TABLE students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      first_name VARCHAR(100) NOT NULL,
      last_name VARCHAR(100) NOT NULL,
      national_code VARCHAR(10) UNIQUE,
      student_code VARCHAR(20) UNIQUE,
      major_id INTEGER,   -- Primary major reference

      FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE SET NULL
    );

    -- 4. TUITION TABLE (Base cost definition per academic profile)
    CREATE TABLE tuition (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year_id INTEGER NOT NULL,
      price INTEGER NOT NULL,
      grade_level INTEGER NOT NULL,
      major_id INTEGER,

      FOREIGN KEY (year_id) REFERENCES school_year(id) ON DELETE CASCADE,
      FOREIGN KEY (major_id) REFERENCES majors(id) ON DELETE SET NULL,

      -- Ensures only one tuition price exists for a given year, grade, and major combination.
      UNIQUE (year_id, grade_level, major_id)
    );

    -- 5. STUDENT YEARS TABLE (Student Enrollment Context for a specific year)
    -- This table links a student to a specific year, grade, and financial policy (tuition/discount).
    CREATE TABLE student_years (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_id INTEGER NOT NULL,
      year_id INTEGER NOT NULL,
      tuition_id INTEGER,
      grade_level INTEGER NOT NULL,
      discount INTEGER DEFAULT 0,

      FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
      FOREIGN KEY (year_id) REFERENCES school_year(id) ON DELETE CASCADE,
      FOREIGN KEY (tuition_id) REFERENCES tuition(id) ON DELETE SET NULL,

      -- Ensures a student has only one enrollment record per year.
      UNIQUE(student_id, year_id)
    );

    -- 6. STUDENT PAYMENTS TABLE (Transaction history)
    CREATE TABLE student_payments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      student_year_id INTEGER NOT NULL, -- Foreign key to the enrollment record
      amount INTEGER NOT NULL,
      payment_date TEXT NOT NULL,
      description TEXT,

      FOREIGN KEY (student_year_id) REFERENCES student_years(id) ON DELETE CASCADE
    );

    -- 7. EXTRA COSTS TABLE (Additional fees definition)
    CREATE TABLE extra_costs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      year_id INTEGER NOT NULL,
      major_id INTEGER NOT NULL,
      grade_level INTEGER NOT NULL,
      price INTEGER NOT NULL,
      description TEXT,

      FOREIGN KEY (year_id) REFERENCES school_year(id) ON DELETE CASCADE

      -- NOTE: there is no comma after the line above, so this statement is a
      -- syntax error in SQLite. major_id also has no FOREIGN KEY here.
      -- Ensures only one extra cost record exists for a given year, grade, and major combination.
      UNIQUE (year_id, grade_level, major_id)
    );

    -- This PRAGMA is technically redundant as it's run in onOpen, but harmless to include here.
    PRAGMA foreign_keys = ON;
    ''');
  }
}
