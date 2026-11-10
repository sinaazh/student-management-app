import 'package:school_managment_app/models/debtor.dart';
import 'package:school_managment_app/models/extra_cost.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/pie_cahrt.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/models/student.dart';
import 'package:school_managment_app/models/payment.dart';
import 'package:school_managment_app/models/tuition.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:sqflite/sqflite.dart';
import 'package:get/get.dart';

/// Data access layer: every database query of the app is written here.
///
/// Each method runs SQL through `dbController.db` and returns model objects, or
/// a result map. Methods that change data return a `Map<String, dynamic>`:
/// `{'status': true}` on success, or `{'status': false, 'error': message}` on
/// failure (the year and major methods return no `error` key). The controllers
/// show that message in a toast.
///
/// Things to know about the data:
/// - `student_years.id` is the **enrollment ID**. `Student.id`, `Debtor.id` and
///   `StudentPayment.studentID` all hold this ID, not `students.id`.
/// - Balance: required = tuition price + extra costs - discount (the discount
///   is an amount, not a percentage); remaining = required - payments.
///   This formula is written separately in several queries below.
/// - The major is stored on the student (`students.major_id`), not on the
///   enrollment, and it is used to find the matching extra costs.
class SchoolRepository {
  final SchoolManagmentDataBaseController dbController;

  /// Initializes the repository by injecting the database connection controller.
  /// This grants access to the active `Database` instance for executing queries.
  SchoolRepository(this.dbController);

  // ... (Data access methods follow)

  // ============================================================
  // SCHOOL YEARS
  // ============================================================

  /// Fetches all records from the 'school_year' table.
  ///
  /// This is typically used to populate dropdowns or configuration settings
  /// with a list of available academic years. The order is not specified.
  ///
  /// Returns a list of [SchoolYear] objects.
  Future<List<SchoolYear>> getYears() async {
    // 1. Execute the query against the 'school_year' table.
    final result = await dbController.db.query('school_year');

    // 2. Map the raw list of database maps (List<Map<String, dynamic>>)
    //    into a typed list of SchoolYear objects using the fromMap factory constructor.
    return result.map((e) => SchoolYear.fromMap(e)).toList();
  }

  /// Inserts a new school year. The ID of [year] is ignored: the database
  /// creates it.
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> insertYear({required SchoolYear year}) async {
    try{
      await dbController.db.insert(
        "school_year",
        {
          "education_year": year.year
        }
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  /// Changes the year value of the school year with the ID of [year].
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> updateYear({required SchoolYear year}) async {
    try{
      await dbController.db.update(
        "school_year",
        {
          "education_year": year.year
        },
        where: "id = ?",
        whereArgs: [year.id],
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  /// Deletes the school year with the ID of [year].
  ///
  /// Because of `ON DELETE CASCADE`, this also deletes the tuition records and
  /// the student enrollments of that year, and through them all their payments.
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> deleteYear({required SchoolYear year}) async {
    try{
      await dbController.db.delete(
        "school_year",
        where: "id = ?",
        whereArgs: [year.id],
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  // ============================================================
  // MAJORS
  // ============================================================

  /// Fetches all records from the 'majors' table.
  ///
  /// This is essential for populating major selection controls and linking
  /// students and financial records to an academic discipline.
  /// The order is not specified.
  ///
  /// Returns a list of [Major] objects.
  Future<List<Major>> getMajors() async {
    // 1. Execute a simple SELECT query to retrieve all rows from the 'majors' table.
    final result = await dbController.db.query('majors');

    // 2. Map the raw database results (List<Map<String, dynamic>>)
    //  into a typed list of [Major] objects using the fromMap factory constructor.
    return result.map((e) => Major.fromMap(e)).toList();
  }

  /// Inserts a new major. The ID of [major] is ignored: the database creates it.
  /// It fails if a major with the same name already exists (the name is unique).
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> insertMajor({required Major major}) async {
    try{
      await dbController.db.insert(
        "majors",
        {
          "name": major.name
        }
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  /// Changes the name of the major with the ID of [major].
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> updateMajor({required Major major}) async {
    try{
      await dbController.db.update(
        "majors",
        {
          "name": major.name,
        },
        where: "id = ?",
        whereArgs: [major.id],
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  /// Deletes the major with the ID of [major] (only the ID is used).
  ///
  /// The delete is not blocked by students or tuition that use the major: their
  /// `major_id` is set to `NULL` (`ON DELETE SET NULL`).
  ///
  /// Returns `{'status': true}` or `{'status': false}` (no `error` message).
  Future<Map<String, dynamic>> deleteMajor({required Major major}) async {
    try{
      await dbController.db.delete(
        "majors",
        where: "id = ?",
        whereArgs: [major.id],
      );
      return {'status': true};
    } catch(e){
      return {'status': false};
    }
  }

  // ============================================================
  // STUDENTS
  // ============================================================

  /// 🧑‍🎓 Fetches one page of enrolled student records based on specific filters.
  ///
  /// This method performs a JOIN between the `students` (personal data) and
  /// `student_years` (enrollment context) tables.
  ///
  /// The returned [Student] object's `id` field corresponds to the
  /// **enrollment ID** (`student_years.id`), not the core student ID.
  ///
  /// [firstName] and [lastName] are search terms (partial match). [majorId],
  /// [gradLevel] and [yearId] filter by major, grade level and school year.
  /// A `null` filter means "don't filter by this". [limit] and [offset] select
  /// the page.
  ///
  /// Returns a record with the students of the page (`students`) and the total
  /// number of students matching the filters (`totalStudentsCount`).
  ///
  /// NOTE: with `COALESCE(?, column)`, a row whose column is `NULL` never
  /// matches (`NULL = NULL` is not true). So a student whose major was deleted
  /// (`major_id` is `NULL`) does not appear in the list at all. Also, the
  /// order is only by first name, so students with the same first name can
  /// switch places between pages.
  Future<({List<Student> students, int totalStudentsCount})> getAllStudents({
    String? firstName,
    String? lastName,
    int? majorId,
    int? gradLevel,
    int? yearId,
    int limit = 10,
    int offset = 0,
  }) async {
    // First query: how many students match (for the page count).
    final countAllStudents = await dbController.db.rawQuery(
      '''
      SELECT 
          COUNT(*) AS total
      FROM student_years
      JOIN students ON student_years.student_id = students.id
      LEFT JOIN majors ON students.major_id = majors.id
      WHERE 1=1
        AND (students.first_name LIKE '%' || COALESCE(?, students.first_name) || '%')
        AND (students.last_name LIKE '%' || COALESCE(?, students.last_name) || '%')
        AND (students.major_id = COALESCE(?, students.major_id))
        AND (student_years.grade_level = COALESCE(?, student_years.grade_level))
        AND (student_years.year_id = COALESCE(?, student_years.year_id));
    ''',
      [
        firstName,
        lastName,
        majorId,
        gradLevel,
        yearId,
      ],
    );

    final totalCount = countAllStudents.first['total'] as int;

    // Second query: the rows of the requested page.
    final result = await dbController.db.rawQuery(
      '''
      SELECT 
          student_years.id,
          students.first_name,
          students.last_name,
          students.national_code,
          students.student_code,
          year_id,
          students.major_id,
          student_years.grade_level,
          student_years.discount
      FROM student_years
      JOIN students ON student_years.student_id = students.id
      LEFT JOIN majors ON students.major_id = majors.id
      WHERE 1=1
        AND (students.first_name LIKE '%' || COALESCE(?, students.first_name) || '%')
        AND (students.last_name LIKE '%' || COALESCE(?, students.last_name) || '%')
        AND (students.major_id = COALESCE(?, students.major_id))
        AND (student_years.grade_level = COALESCE(?, student_years.grade_level))
        AND (student_years.year_id = COALESCE(?, student_years.year_id))
      ORDER BY students.first_name ASC
      LIMIT ? OFFSET ?
    ''',
      [
        firstName,
        lastName,
        majorId,
        gradLevel,
        yearId,
        limit, offset,
      ],
    );

    final students = result.map((e) => Student.fromMap(e)).toList();

    // Map the raw database rows to the [Student] model objects.
    return (students: students, totalStudentsCount: totalCount);
  }

  /// 🆕 Inserts a new student enrollment record into the database using a transaction.
  ///
  /// This operation is executed within a database transaction to ensure atomicity
  /// (either both tables are updated, or neither is).
  ///
  /// The logic performs these steps:
  /// 1. **Student Check:** It checks if the core student already exists in the `students`
  ///    table using their unique `national_code` or `student_code`. If they exist,
  ///    the existing ID is used (the names and major typed in the form are then
  ///    ignored); otherwise, a new row is inserted into `students`.
  /// 2. **Tuition Lookup:** It looks for the tuition record of the year, grade and major.
  /// 3. **Enrollment Insert:** It then inserts the enrollment details (year, grade, discount)
  ///    into the `student_years` table, linking the tuition found in step 2 (or `NULL`).
  ///
  /// [student] contains the personal and enrollment details.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. A student who is already enrolled for that year gives the
  /// message `student_already_enrolled_for_year` (translated).
  Future<Map<String, dynamic>> insertStudent({required Student student}) async {
    try {
      // Start a database transaction to ensure all inserts/lookups are atomic.
      await dbController.db.transaction((txn) async {

        // 1. CHECK FOR CORE STUDENT RECORD
        final existing = await txn.rawQuery('''
          SELECT id FROM students
          WHERE national_code = ? OR student_code = ?
          LIMIT 1
        ''', [student.nationalCode, student.studentCode]);

        final int studentId;
        if (existing.isNotEmpty){
          // Student exists: Use the existing student ID.
          studentId = existing.first['id'] as int;
        } else{
          // Student is new: Insert into the core 'students' table.
          // The returned value is the new row's primary key (ID).
          studentId = await txn.insert('students', {
            'first_name': student.firstName,
            'last_name': student.lastName,
            'national_code': student.nationalCode,
            'student_code': student.studentCode,
            'major_id': student.majorId,
          });
        }
        
        // 2. LOOKUP TUITION FEE
        
        // Find the base tuition fee ID for this specific year, grade, and major.
        // It prioritizes a major-specific tuition but falls back if major_id is NULL.
        // NOTE: there is no ORDER BY, so if both a major-specific and a NULL-major
        // tuition exist, either one can be returned.
        final tuitionResult = await txn.rawQuery(
          '''
            SELECT id FROM tuition
            WHERE year_id = ?
              AND grade_level = ?
              AND (major_id = ? OR major_id IS NULL)
            LIMIT 1
          ''',
          [student.yearId, student.grade, student.majorId],
        );

        // Extract the tuition ID, or set to null if no matching tuition is found.
        final tuitionId = tuitionResult.isNotEmpty
            ? tuitionResult.first['id'] as int
            : null;

        // 3. INSERT ENROLLMENT RECORD
        await txn.insert('student_years', {
          'student_id': studentId,
          'year_id': student.yearId,
          'grade_level': student.grade,
          'tuition_id': tuitionId, // Link found tuition fee
          'discount': student.discount,
        });
      });

      // Transaction successful
      return {'status':true};
    } on DatabaseException catch (e) {
      // Handle known SQLite constraint errors
      if (e.isUniqueConstraintError()){
        return {'status': false, 'error' : 'student_already_enrolled_for_year'.tr};
      }
      // Handle other database-specific errors
      return {'status': false, 'error' : 'unexpected_database_error'.tr};
    } catch (e) {
      // Catch any unexpected exceptions
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// ✏️ Updates both the core student's personal details and their year-specific enrollment details (discount).
  ///
  /// This operation is executed within a **database transaction** to ensure both
  /// the `students` table and the `student_years` table are updated atomically.
  ///
  /// The process involves three steps:
  /// 1. Look up the core `student_id` using the provided enrollment ID (`student.id`).
  /// 2. Update the core student details (names, codes, major_id) in the `students` table.
  /// 3. Update the enrollment-specific data (discount) in the `student_years` table.
  ///
  /// [student] contains the updated data, where `student.id` is the `student_years.id`.
  ///
  /// NOTE: only the discount is saved in `student_years`. The grade and year of
  /// [student] are ignored, and the linked tuition (`tuition_id`) is not
  /// recalculated, even if the major changed in step 2.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. All failures (including a national code or student code that
  /// already exists) give the same `unexpected_error` message.
  Future<Map<String, dynamic>> updateStudent({required Student student}) async {
    try {
      await dbController.db.transaction((txn) async {
        
        // 1. Find the core student ID (students.id) associated with the enrollment ID (student_years.id).
        final studentId = await txn.query(
          'student_years',
          columns: ['student_id'],
          where: 'id = ?',
          whereArgs: [student.id], // student.id is the enrollment ID (student_years.id)
          limit: 1,
        );

        // 2. Update the permanent student data in the 'students' table.
        await txn.update('students',{
        'first_name': student.firstName,
        'last_name': student.lastName,
        'national_code': student.nationalCode,
        'student_code': student.studentCode,
        'major_id': student.majorId,
        },
        where: 'id = ?',
        whereArgs: [int.parse(studentId.first['student_id'].toString())] // Use the core student ID for this update
        );

        // 3. Update the year-specific enrollment data (discount) in the 'student_years' table.
        await txn.update(
          'student_years',
          {
            'discount': student.discount,
          },
          where: 'id = ?',
          whereArgs: [student.id], // Use the enrollment ID for this update
        );

      });

      // Transaction successful
      return {'status':true};
    } catch (e) {
      // Catch any exception during the transaction or SQL execution.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// 🗑️ Deletes a student's enrollment record, conditionally deleting the core student.
  ///
  /// This method performs a crucial database operation within a **transaction** to
  /// maintain data integrity:
  /// 1. It checks how many enrollment records (`student_years` rows) exist for the
  ///    core student identified by the provided `student.id` (which is the enrollment ID).
  /// 2. If the count is **1** (meaning the record being deleted is the student's *last* enrollment),
  ///    it deletes the corresponding row from the **`students`** table.
  /// 3. Otherwise (if the count is > 1), it only deletes the record from the
  ///    **`student_years`** table, preserving the core student data for other years.
  ///
  /// In both cases the payments of the deleted enrollment are deleted too
  /// (`ON DELETE CASCADE`).
  ///
  /// [student] contains the enrollment ID (`student.id`) to delete.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> deleteStudent({required Student student}) async {
    try {
      await dbController.db.transaction((txn) async {
        
        // Step 1: Count how many enrollments (student_years) the core student has.
        final studentCount = await txn.rawQuery(
          '''
          SELECT COUNT(*) AS student_count
          FROM student_years
          WHERE student_id = (
              SELECT student_id
              FROM student_years
              WHERE id = ?)
          ''',
          [student.id], // Use the enrollment ID (student_years.id)
        );

        // Step 2: Conditional Deletion Logic
        if (int.parse(studentCount.first['student_count'].toString()) == 1) {
          // If this is the LAST enrollment record, delete the core student record.
          await txn.rawQuery(
            '''
            DELETE FROM students
            WHERE id = (
              SELECT student_id
              FROM student_years
              WHERE id = ?
            )
            ''',
            [student.id],
          );
        } else {
          // If the student has other enrollment years, only delete the specific enrollment year record.
          await txn.rawQuery(
            '''
            DELETE FROM student_years
            WHERE id = ?
            ''',
            [student.id],
          );
        }
      });
      // Transaction successful
      return {'status':true};
    } catch (e) {
      // Catch any unexpected exceptions during the transaction.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  // ============================================================
  // PAYMENTS
  // ============================================================

  /// 💳 Retrieves one page of the payments of a specific student enrollment.
  ///
  /// This method queries the `student_payments` table to find the recorded payments
  /// linked to a student's enrollment ID (`student_years.id`), ordered by payment date.
  ///
  /// [studentYearId] is the enrollment ID (ID from the `student_years` table).
  /// [limit] and [offset] select the page.
  ///
  /// Returns a record with the payments of the page (`payments`) and the total
  /// number of payments of the enrollment (`totalPaymentsCount`).
  Future<({List<StudentPayment> payments, int totalPaymentsCount})> getAllStudentPayments({
    required int studentYearId,
    int limit = 10,
    int offset = 0,
    }) async {
    final countAllStudents = await dbController.db.rawQuery(
      '''
      SELECT 
          COUNT(*) AS total
      FROM student_payments
      WHERE student_year_id = ?
    ''',
      [studentYearId],
    );

    final totalCount = countAllStudents.first['total'] as int;

    final result = await dbController.db.query(
      'student_payments',
      where: 'student_year_id = ?',
      whereArgs: [studentYearId],
      orderBy: "payment_date ASC", // Orders the payments chronologically.
      limit: limit,
      offset: offset,
    );

    // Maps the raw database results into a list of typed [StudentPayment] objects.
    final payments = result.map((e) => StudentPayment.fromMap(e)).toList();
    
    return (payments: payments, totalPaymentsCount: totalCount);
  }

  /// 💰 Calculates the tuition amounts and the remaining balance for a specific student enrollment.
  ///
  /// The calculation is performed in these steps:
  /// 1. **Check Tuition Link:** Ensures the enrollment has a linked `tuition_id`.
  /// 2. **Calculate Total Required:** Reads the base tuition price, the extra costs
  ///    (matched by the tuition's year, grade and major) and subtracts the discount.
  /// 3. **Calculate Total Paid:** Sums all recorded payments for the enrollment.
  /// 4. **Final Balance:** (Total Required - Total Paid). It is negative if the student overpaid.
  ///
  /// [studentYearId] is the enrollment ID (ID from the `student_years` table).
  ///
  /// Returns a map with the keys `tuition` (base price), `extra_costs` (their
  /// total) and `remaining_tuition` (the balance). All three are 0 if the
  /// enrollment is not found, has no tuition linked, or any error happens (so
  /// an error looks like a fully paid student).
  Future<Map<String,int>> getremainingTuition({required int studentYearId}) async {
    try{
      // Step 1: Check if a tuition fee is linked to the student's enrollment record.
      final hasTuition = await dbController.db.rawQuery('''
        SELECT tuition_id FROM student_years WHERE id = ?
        ''',
        [studentYearId]
      );

      // If no enrollment record is found or no tuition is assigned, the balance is 0.
      if (hasTuition.isEmpty || hasTuition.first["tuition_id"] == null) {
        return {
          "tuition": 0,
          "extra_costs": 0,
          "remaining_tuition": 0,
        };
      }

      // Step 2: Calculate the Total Required Tuition (Base Tuition + Extra Costs - Discount).
      // Note: the extra costs are matched with the major of the tuition record
      // (tuition.major_id), while getDebtorsList uses the major of the student.
      final tuitionAmount = await dbController.db.rawQuery('''
        SELECT
          tuition.price as tuition,
          SUM(COALESCE(extra_costs.price, 0)) as extra_costs,
          (tuition.price + SUM(COALESCE(extra_costs.price, 0)) - COALESCE(student_years.discount, 0)) AS remaining_tuition
        FROM tuition
        LEFT JOIN student_years ON student_years.tuition_id = tuition.id
        LEFT JOIN extra_costs 
            ON tuition.major_id = extra_costs.major_id
            AND tuition.year_id = extra_costs.year_id
            AND tuition.grade_level = extra_costs.grade_level
        WHERE student_years.id = ?;
        ''',
        [studentYearId] // The enrollment ID: the query finds its tuition through the join.
      );
      
      // Step 3: Calculate the Total Amount Paid by the student for this enrollment.
      final totalStudentPayment = await dbController.db.rawQuery('''
        SELECT SUM(amount) AS total_payment FROM student_payments WHERE student_year_id = ?
        ''',
        [studentYearId]
      );

      // Extract values, safely handling null results with the ?? 0 operator.
      final totalPayment = (totalStudentPayment.first["total_payment"] as int?) ?? 0;
      // (Despite its name, this is the total required: tuition + extra costs - discount.)
      final tuitionPrice = (tuitionAmount.first["remaining_tuition"] as int?) ?? 0;
      
      // Step 4: Calculate and return the final remaining balance.
      return {
        "tuition": tuitionAmount.first["tuition"] as int,
        "extra_costs": tuitionAmount.first["extra_costs"] as int,
        "remaining_tuition": tuitionPrice - totalPayment,
      };
      // return tuitionPrice - totalPayment;
    } catch (e) {
      // Return 0 if any database error or unexpected exception occurs during the calculation.
      return {
        "tuition": 0,
        "extra_costs": 0,
        "remaining_tuition": 0,
      };
    }
  }

  /// 💳 Inserts a new payment record into the `student_payments` table.
  ///
  /// This method includes **financial validation** to prevent overpayment:
  /// 1. **Tuition Check:** Confirms that the student enrollment has a linked tuition record.
  /// 2. **Balance Check:** Calculates the total required (tuition + extra costs - discount)
  ///    and the total already paid, and blocks the new payment if the paid total
  ///    already meets or exceeds the required amount.
  ///
  /// Note: the amount of the new payment is not part of the check, so a payment
  /// larger than the remaining balance is still accepted while something is left to pay.
  ///
  /// [payment] contains the payment details and the `studentID` (enrollment ID).
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. Some of the messages are hard-coded English text.
  Future<Map<String, dynamic>> insertStudentPayment({required StudentPayment payment}) async {
    try {
      // Step 1: Check if a tuition fee is linked to the student's enrollment record.
      final hasTuition = await dbController.db.rawQuery('''
        SELECT tuition_id FROM student_years WHERE id = ?
        ''',
        [payment.studentID] // studentID corresponds to student_years.id
      );
      if (hasTuition.isEmpty || hasTuition.first["tuition_id"] == null) {
        return {'status': false, 'error' : 'Please assign a tuition before inserting a payment.'};
      }

      // Step 2: Retrieve the total required amount (tuition + extra costs - discount).
      // NOTE: the query filters on `student_years.id`, but the value passed is the
      // tuition ID (hasTuition.first["tuition_id"]), not the enrollment ID.
      final tuitionAmount = await dbController.db.rawQuery('''
        SELECT
          (
          tuition.price + COALESCE(extra_costs.price, 0) - COALESCE(student_years.discount, 0)
          ) AS remaining_tuition
        FROM tuition
        LEFT JOIN student_years ON student_years.tuition_id = tuition.id
        LEFT JOIN extra_costs 
          ON tuition.major_id = extra_costs.major_id
          AND tuition.year_id = extra_costs.year_id
          AND tuition.grade_level = extra_costs.grade_level
        WHERE student_years.id = ?;
        ''',
        [hasTuition.first["tuition_id"]]
      );

      // Step 3: Calculate the total amount the student has already paid.
      final totalStudentPayment = await dbController.db.rawQuery('''
        SELECT COALESCE(SUM(amount),0) AS total_payment FROM student_payments WHERE student_year_id = ?
        ''',
        [payment.studentID]
      );

      // NOTE: the query above returns only the column `remaining_tuition`, so
      // reading the key "price" gives `null` and `as int` throws. The catch
      // block below then returns `unexpected_error` before anything is inserted.
      final tuitionPrice = tuitionAmount.first["price"] as int;
      final totalPayment = totalStudentPayment.first["total_payment"] as int;

      // Step 4: Validate against overpayment.
      // If the currently paid amount is already >= the required amount, block the new payment.
      if (totalPayment >= tuitionPrice) {
        return {'status': false, 'error' : 'This payment would exceed the student’s tuition balance.'};
      }

      // Step 5: Insert the new payment record.
      await dbController.db.insert(
        'student_payments',
        {
          'student_year_id': payment.studentID,
          'amount': payment.paymentAmount,
          'payment_date': payment.paymentDate,
          'description': payment.paymentDescription,

        }
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// ✏️ Updates an existing payment record in the `student_payments` table.
  ///
  /// This method performs **financial validation** to ensure that the updated
  /// payment amount does not cause the student's total paid amount to exceed
  /// the total required amount (tuition + extra costs - discount).
  ///
  /// [payment] contains the updated data, where `payment.id` is the payment ID
  /// and `payment.studentID` is the enrollment ID. Only the amount, date and
  /// description are changed.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. Some of the messages are hard-coded English text.
  Future<Map<String, dynamic>> updateStudentPayment({required StudentPayment payment}) async {
    try {
      // Step 1: Retrieve the total required amount for the student's enrollment.
      final tuitionAmount = await dbController.db.rawQuery('''
        SELECT
          (
            tuition.price + COALESCE(extra_costs.price, 0) - COALESCE(student_years.discount, 0)
          ) AS remaining_tuition
        FROM tuition
        LEFT JOIN student_years ON student_years.tuition_id = tuition.id
        LEFT JOIN extra_costs 
            ON tuition.major_id = extra_costs.major_id
            AND tuition.year_id = extra_costs.year_id
            AND tuition.grade_level = extra_costs.grade_level
        WHERE student_years.id = ?;
        ''',
        [payment.studentID] // Use the enrollment ID to find the linked tuition price
      );

      // Step 2: Calculate the total amount the student has already paid.
      // NOTE: this sums ALL payments, including the payment being updated, so
      // the old amount of that payment is counted again together with the new one.
      final totalStudentPayment = await dbController.db.rawQuery('''
        SELECT COALESCE(SUM(amount),0) AS total_payment FROM student_payments WHERE student_year_id = ?
        ''',
        [payment.studentID]
      );
      
      // NOTE: the query in step 1 returns only the column `remaining_tuition`, so
      // reading the key "price" gives `null` and `as int` throws. The catch
      // block below then returns `unexpected_error`.
      final tuitionPrice = tuitionAmount.first["price"] as int;
      final totalPayment = totalStudentPayment.first["total_payment"] as int;

      // Step 3: Validate against overpayment.
      // Check if the previously paid amount PLUS the new/updated payment amount reaches the required amount.
      // (With `>=`, a payment that exactly pays off the remaining balance is also blocked.)
      if ( (totalPayment + payment.paymentAmount) >= tuitionPrice) {
        return {'status': false, 'error' : 'The updated amount exceeds the remaining tuition.'};
      }

      // Step 4: Perform the update operation.
      await dbController.db.update(
        'student_payments',
        {
          'amount': payment.paymentAmount,
          'payment_date': payment.paymentDate,
          'description': payment.paymentDescription,

        },
        where: 'id = ?',
        whereArgs: [payment.id] // Use the payment ID to identify the row to update
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// 🗑️ Deletes a specific student payment record.
  ///
  /// This performs a simple DELETE operation on the `student_payments` table,
  /// targeting the row identified by the unique primary key, `payment.id`.
  ///
  /// Note: Unlike other financial updates/inserts, this method does not perform
  /// pre-validation on the remaining balance, as deleting a payment will always
  /// decrease the total paid amount.
  ///
  /// [payment] contains the ID of the payment record to delete.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> deleteStudentPayment({required StudentPayment payment}) async {
    try {
      // Execute the DELETE query against the 'student_payments' table.
      await dbController.db.delete(
        'student_payments',
        where: 'id = ?',
        whereArgs: [payment.id] // Use the payment's unique ID for deletion.
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  // ============================================================
  // TUITION
  // ============================================================

  /// 💰 Retrieves one page of the defined tuition records based on optional filtering criteria.
  ///
  /// This method queries the **`tuition`** table, allowing the results to be filtered
  /// by academic major, grade level, and/or school year. It uses the SQLite
  /// `COALESCE` function to handle optional, nullable parameters dynamically.
  ///
  /// [majorId], [grade] and [yearId] are optional filters (`null` = no filter).
  /// [limit] and [offset] select the page. The records are ordered by year only.
  ///
  /// Returns a record with the tuition records of the page (`tuitions`) and the
  /// total number matching the filters (`totalTuitionsCount`). As in
  /// [getAllStudents], a record whose `major_id` is `NULL` never matches.
  Future<({List<Tuition> tuitions, int totalTuitionsCount})> getAllTuitions({
    int? majorId,
    int? grade,
    int? yearId,
    int limit = 10,
    int offset = 0,
  }) async {
    final countAllTuitons = await dbController.db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM tuition
      WHERE 
        (major_id = COALESCE(?, major_id)) AND
        (year_id = COALESCE(?, year_id)) AND
        (grade_level = COALESCE(?, grade_level))
      ORDER BY year_id ASC;
      ''',
      [majorId, yearId, grade],
    );

    final totalCount = countAllTuitons.first['total'] as int;

    final result = await dbController.db.rawQuery(
      '''
      SELECT *
      FROM tuition
      WHERE 
        (major_id = COALESCE(?, major_id)) AND
        (year_id = COALESCE(?, year_id)) AND
        (grade_level = COALESCE(?, grade_level))
      ORDER BY year_id ASC
      LIMIT ? OFFSET ?
      ''',
      // The parameter order must match the COALESCE placeholders in the query.
      [majorId, yearId, grade, limit, offset,],
    );

    // Maps the raw database rows into a list of typed [Tuition] objects.
    final tuitions = result.map((e) => Tuition.fromMap(e)).toList();
    
    return (tuitions: tuitions, totalTuitionsCount: totalCount);
  }

  /// 💰 Inserts a new tuition fee record and automatically links it to existing students.
  ///
  /// This operation is executed within a **database transaction** to ensure both
  /// the new tuition is created and all matching unassigned students are updated
  /// atomically.
  ///
  /// The process involves two critical steps:
  /// 1. **Insertion:** A new row is inserted into the `tuition` table with the
  ///    specified year, grade, major, and price. The new primary key (`tuitionId`) is captured.
  /// 2. **Auto-Assignment:** All existing students in the `student_years` table
  ///    that match the new tuition's year, grade, and major, and who currently have
  ///    a `tuition_id IS NULL`, are automatically updated to link to the new `tuitionId`.
  ///
  /// [tuition] contains the new fee structure details.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. A year/grade/major combination that already has a tuition gives
  /// the message `tuition_already_set_for_year_grade_major` (translated).
  Future<Map<String, dynamic>> insertTuition({required Tuition tuition}) async {
    try {
      await dbController.db.transaction((txn) async {

        // 1. Insert the tuition record into the 'tuition' table and retrieve its ID.
        final tuitionId = await txn.insert(
          'tuition',
          {
            'year_id': tuition.yearId,
            'grade_level': tuition.grade,
            'major_id': tuition.majorId,
            'price': tuition.price,
          }
        );

        // 2. Update all existing student enrollment records that meet the criteria
        //    (year, grade, major) and do not yet have an assigned tuition.
        await txn.rawQuery('''
          UPDATE student_years
          SET tuition_id = ?
          WHERE year_id = ?
            AND grade_level = ?
            AND tuition_id IS NULL
            AND student_id IN (
              SELECT id FROM students WHERE major_id = ?
            );
        ''',
        [tuitionId, tuition.yearId, tuition.grade, tuition.majorId]
      );
      });
      return {'status':true};
    } on DatabaseException catch (e) {
      // Handle known SQLite constraint errors (likely a UNIQUE constraint violation).
      if (e.isUniqueConstraintError()){
        return {'status': false, 'error' : 'tuition_already_set_for_year_grade_major'.tr};
      }
      // Handle other database-specific errors.
      return {'status': false, 'error' : 'unexpected_database_error'.tr};
    } catch (e) {
      // Catch any unexpected exceptions.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// ✏️ Updates the price of an existing tuition fee record.
  ///
  /// This method performs a direct UPDATE operation on the **`tuition`** table,
  /// targeting the specific record identified by the unique `tuition.id`.
  ///
  /// **Note:** This update only changes the **price** field. Other defining attributes
  /// (year, grade, major) are considered immutable once the tuition record is created,
  /// so any change to them in [tuition] is ignored. This operation does **not**
  /// automatically update any linked student payments or remaining balances;
  /// those calculations are handled dynamically by other methods.
  ///
  /// [tuition] contains the ID of the record to update and the new `price`.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> updateTuition({required Tuition tuition}) async {
    try {
      // Execute the UPDATE query against the 'tuition' table.
      await dbController.db.update(
        'tuition',
        {
          'price': tuition.price, // Only the price is updated here.
        },
        where: 'id = ?',
        whereArgs: [tuition.id]
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// 🗑️ Deletes a specific tuition fee record.
  ///
  /// This method performs a direct DELETE operation on the **`tuition`** table,
  /// targeting the row identified by the unique primary key, `tuition.id`.
  ///
  /// **Important:** with the current table definition (`ON DELETE SET NULL` on
  /// `student_years.tuition_id`), the delete is not blocked. The students linked to
  /// this tuition keep their enrollment, but their tuition becomes `NULL`, so
  /// their balance is calculated without tuition (and payments are refused)
  /// until a new tuition is added for the same year, grade and major
  /// ([insertTuition] links such enrollments again).
  ///
  /// [tuition] contains the ID of the record to delete.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> deleteTuition({required Tuition tuition}) async {
    try {
      // Execute the DELETE query against the 'tuition' table.
      await dbController.db.delete(
        'tuition',
        where: 'id = ?',
        whereArgs: [tuition.id]
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly (e.g., foreign key violation).
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  // ============================================================
  // EXTRA COSTS
  // ============================================================

  /// 💲 Retrieves one page of the defined extra cost records based on optional filtering criteria.
  ///
  /// This method queries the **`extra_costs`** table, which holds fees separate from
  /// the base tuition (e.g., lab fees, resource costs). It allows filtering by
  /// academic major, grade level, and/or school year. It uses the SQLite
  /// `COALESCE` function to enable dynamic, optional filtering.
  ///
  /// [majorId], [grade] and [yearId] are optional filters (`null` = no filter).
  /// [limit] and [offset] select the page. The records are ordered by year only.
  ///
  /// Returns a record with the extra costs of the page (`extraCosts`) and the
  /// total number matching the filters (`totalExtraCostsCount`).
  Future<({List<ExtraCost> extraCosts, int totalExtraCostsCount})> getAllExtraCosts({
    int? majorId,
    int? grade,
    int? yearId,
    int limit = 10,
    int offset = 0,
  }) async {
    final countAllExtraCosts = await dbController.db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM extra_costs
      WHERE 
        (major_id = COALESCE(?, major_id)) AND
        (year_id = COALESCE(?, year_id)) AND
        (grade_level = COALESCE(?, grade_level))
      ORDER BY year_id ASC;
      ''',
      [majorId, yearId, grade],
    );

    final totalCount = countAllExtraCosts.first['total'] as int;

    final result = await dbController.db.rawQuery(
      '''
      SELECT *
      FROM extra_costs
      WHERE 
        (major_id = COALESCE(?, major_id)) AND
        (year_id = COALESCE(?, year_id)) AND
        (grade_level = COALESCE(?, grade_level))
      ORDER BY year_id ASC
      LIMIT ? OFFSET ?;
      ''',
      [majorId, yearId, grade, limit, offset],
    );
    
    // Maps the raw database rows into a list of typed [ExtraCost] objects.
    final extraCosts = result.map((e) => ExtraCost.fromMap(e)).toList();

    return (extraCosts: extraCosts, totalExtraCostsCount: totalCount);
  }

  /// 💲 Inserts a new extra cost record into the database.
  ///
  /// This method defines a specific extra fee (like a lab or resource fee) that is
  /// applicable based on a student's **year, grade, and major**.
  ///
  /// The insertion is handled directly using the database controller. Error handling
  /// specifically checks for a **Unique Constraint** violation, which occurs if an
  /// extra cost for the exact same combination (year, grade, and major) already exists.
  ///
  /// **Note:** Unlike `insertTuition`, this operation does **not** automatically update
  /// existing student enrollment records (`student_years`), but the new cost will be
  /// included in the dynamic calculation of remaining tuition via `getremainingTuition`.
  ///
  /// [extraCost] contains the details of the new fee.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}`
  /// on failure. A combination that already has an extra cost gives the message
  /// `extra_cost_already_set_for_year_grade_major` (translated).
  Future<Map<String, dynamic>> insertExtraCost({required ExtraCost extraCost}) async {
    try {
      // Execute the INSERT operation directly.
      await dbController.db.insert(
        'extra_costs',
          {
            'year_id': extraCost.yearId,
            'grade_level': extraCost.grade,
            'major_id': extraCost.majorId,
            'price': extraCost.price,
            'description': extraCost.description
          }
      );
      return {'status':true};
    } on DatabaseException catch (e) {
      // Handle known SQLite unique constraint errors.
      if (e.isUniqueConstraintError()){
        return {'status': false, 'error' : 'extra_cost_already_set_for_year_grade_major'.tr};
      }
      // Handle other database-specific errors.
      return {'status': false, 'error' : 'unexpected_database_error'.tr};
    } catch (e) {
      // Catch any unexpected exceptions.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// ✏️ Updates the price and description of an existing extra cost record.
  ///
  /// This method performs a direct **UPDATE** operation on the **`extra_costs`** table,
  /// targeting the specific record identified by the unique `extraCost.id`.
  ///
  /// **Note:** This update modifies the **`price`** and **`description`** fields. The defining
  /// academic criteria (year, grade, major) are not changed, so any change to them
  /// in [extraCost] is ignored. Since extra costs are included in the dynamic
  /// calculation of remaining tuition, changing the price here will immediately
  /// affect the calculated balance for all matched students.
  ///
  /// [extraCost] contains the ID of the record to update and the new details.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> updateExtraCost({required ExtraCost extraCost}) async {
    try {
      // Execute the UPDATE query against the 'extra_costs' table.
      await dbController.db.update(
        'extra_costs',
        {
          'price': extraCost.price,
          'description': extraCost.description
        },
        where: 'id = ?',
        whereArgs: [extraCost.id]
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  /// 🗑️ Deletes a specific extra cost record.
  ///
  /// This method performs a direct **DELETE** operation on the **`extra_costs`** table,
  /// targeting the row identified by the unique primary key, `extraCost.id`.
  ///
  /// **Note:** Since extra costs are included in the dynamic calculation of
  /// a student's remaining tuition balance, deleting this record will automatically
  /// **reduce the total required tuition** for all students who were subject to this fee.
  /// No explicit update to student records is necessary.
  ///
  /// [extraCost] contains the ID of the record to delete.
  ///
  /// Returns `{'status': true}` on success, or `{'status': false, 'error': message}` on failure.
  Future<Map<String, dynamic>> deleteExtraCost({required ExtraCost extraCost}) async {
    try {
      // Execute the DELETE query against the 'extra_costs' table.
      await dbController.db.delete(
        'extra_costs',
        where: 'id = ?',
        whereArgs: [extraCost.id]
        );
      return {'status':true};
    } catch (e) {
      // Catch and return a generic error if the operation fails unexpectedly.
      return {'status': false, 'error' : 'unexpected_error'.tr};
    }
  }

  // ============================================================
  // REPORTS AND STATISTICS
  // ============================================================

  /// ⚠️ Retrieves one page of the students with an outstanding financial balance (debtors).
  ///
  /// This is a complex aggregation query that joins `student_years`, `students`,
  /// `tuition`, and two summary subqueries (extra costs per year/major/grade, and
  /// payments per enrollment) to calculate the full amount due, the amount paid,
  /// and the final remaining balance for each enrollment record.
  ///
  /// Only enrollments with a remaining balance greater than 0 are returned. The
  /// condition is repeated in the `WHERE` clause (there is no `HAVING`).
  /// Dynamic filtering on major, grade, and year is enabled via `COALESCE`.
  ///
  /// [majorId], [grade] and [yearId] are optional filters (`null` = no filter).
  /// [limit] and [offset] select the page.
  ///
  /// Returns a record with the debtors of the page (`debtors`) and the total
  /// number of debtors matching the filters (`totalDebtorsCount`). The `id` of
  /// each [Debtor] is `student_years.id` (the enrollment ID), although the column
  /// is named `student_id` here.
  ///
  /// NOTE: the query has no `ORDER BY`, so the order between pages is not
  /// guaranteed. A student with `major_id` `NULL` never matches the major filter
  /// expression, so such a student is not listed.
  Future<({List<Debtor> debtors, int totalDebtorsCount})> getDebtorsList({
    int? majorId,
    int? grade,
    int? yearId,
    int limit = 10,
    int offset = 0,
  }) async {
    // First query: how many debtors match (for the page count).
    final countAllDebtors = await dbController.db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total
      FROM
        student_years
        JOIN students ON students.id = student_years.student_id
        LEFT JOIN tuition ON tuition.id = student_years.tuition_id
        LEFT JOIN (SELECT year_id, major_id, grade_level, SUM(price) AS extra_cost_amount FROM extra_costs GROUP BY year_id, major_id, grade_level) AS extra_totals ON extra_totals.year_id = student_years.year_id 
        AND extra_totals.major_id = students.major_id 
        AND extra_totals.grade_level = student_years.grade_level
        LEFT JOIN (SELECT student_year_id, SUM(amount) AS total_paid FROM student_payments GROUP BY student_year_id) AS payment_totals ON payment_totals.student_year_id = student_years.id 
      WHERE
        (students.major_id = COALESCE(?, students.major_id)) 
        AND (student_years.year_id = COALESCE(?, student_years.year_id)) 
        AND (student_years.grade_level = COALESCE(?, student_years.grade_level)) 
        AND (COALESCE(tuition.price, 0) + COALESCE(extra_totals.extra_cost_amount, 0) - COALESCE(student_years.discount, 0) - COALESCE(payment_totals.total_paid, 0)) > 0;
    ''',
      [majorId, yearId, grade],
    );

    final totalCount = countAllDebtors.first['total'] as int;

    // Second query: the debtors of the requested page, with all the amounts.
    final result = await dbController.db.rawQuery(
      '''
      SELECT
        student_years.id AS student_id,
        students.first_name || ' ' || students.last_name AS full_name,
        students.major_id,
        student_years.year_id,
        student_years.grade_level,
        COALESCE(tuition.price, 0) AS tuition_price,
        COALESCE(extra_totals.extra_cost_amount, 0) AS extra_cost_amount,
        COALESCE(student_years.discount, 0) AS discount_amount,
        (COALESCE(tuition.price, 0) + COALESCE(extra_totals.extra_cost_amount, 0) - COALESCE(student_years.discount, 0)) AS total_required,
        COALESCE(payment_totals.total_paid, 0) AS total_paid,
        (
        COALESCE(tuition.price, 0) + COALESCE(extra_totals.extra_cost_amount, 0) - COALESCE(student_years.discount, 0) - COALESCE(payment_totals.total_paid, 0)) AS remaining_amount 
      FROM
        student_years
        JOIN students ON students.id = student_years.student_id
        LEFT JOIN tuition ON tuition.id = student_years.tuition_id
        LEFT JOIN (SELECT year_id, major_id, grade_level, SUM(price) AS extra_cost_amount FROM extra_costs GROUP BY year_id, major_id, grade_level) AS extra_totals ON extra_totals.year_id = student_years.year_id 
        AND extra_totals.major_id = students.major_id 
        AND extra_totals.grade_level = student_years.grade_level
        LEFT JOIN (SELECT student_year_id, SUM(amount) AS total_paid FROM student_payments GROUP BY student_year_id) AS payment_totals ON payment_totals.student_year_id = student_years.id 
      WHERE
        (students.major_id = COALESCE(?, students.major_id)) 
        AND (student_years.year_id = COALESCE(?, student_years.year_id)) 
        AND (student_years.grade_level = COALESCE(?, student_years.grade_level)) 
        AND (COALESCE(tuition.price, 0) + COALESCE(extra_totals.extra_cost_amount, 0) - COALESCE(student_years.discount, 0) - COALESCE(payment_totals.total_paid, 0)) > 0
      LIMIT ? OFFSET ?;
      ''',
      [majorId, yearId, grade, limit, offset],
    );

    // Maps the aggregated results into a list of typed [Debtor] objects.
    final debtors = result.map((e) => Debtor.fromMap(e)).toList();

    return (debtors: debtors, totalDebtorsCount: totalCount);
  }

  /// 📊 Retrieves aggregated financial status percentages for a specified student cohort.
  ///
  /// This method executes a multi-layered SQL query designed to output the data
  /// required for a payment status **Pie Chart** .
  ///
  /// The query performs a cascading calculation:
  /// 1. **Innermost Subquery (payment_status_table):** Calculates the `total_tuition`
  ///    (Tuition + Extra Costs - Discount) and `total_paid` (SUM of payments) for
  ///    every single student enrollment record matching the filters.
  /// 2. **Middle Subquery (Unnamed):** Uses `COUNT(*)` to find `total_students` and
  ///    uses `SUM(CASE ...)` logic to classify each student into one of three buckets:
  ///    `fully_paid`, `partially_paid`, or `not_paid`.
  /// 3. **Outermost Query (final):** Calculates the final percentages by dividing
  ///    each count by the `total_students` count and rounds the result to two decimal places.
  ///
  /// The percentages are on a 0-100 scale. When no student matches the filters,
  /// they are all `0.0` (the division by zero is handled by `NULLIF` and `COALESCE`).
  /// A student with no tuition who has paid something is in none of the three
  /// groups, so the three percentages may not add up to 100.
  ///
  /// [majorId], [grade] and [yearId] are optional filters (`null` = no filter).
  /// Unlike the other queries, this one uses `:name IS NULL OR column = :name`,
  /// so a student with major `NULL` is counted when no major is chosen.
  ///
  /// Returns a single [PieCahrt] object with the calculated percentages.
  Future<PieCahrt> getStudentPaymentPercentages({
    int? majorId,
    int? grade,
    int? yearId,
  }) async {
    final result = await dbController.db.rawQuery(
      '''
      SELECT 
          COALESCE(
              ROUND(100.0 * fully_paid / NULLIF(total_students, 0), 2),
              0.0
          ) AS fully_paid_percentage,

          COALESCE(
              ROUND(100.0 * partially_paid / NULLIF(total_students, 0), 2),
              0.0
          ) AS partially_paid_percentage,

          COALESCE(
              ROUND(100.0 * not_paid / NULLIF(total_students, 0), 2),
              0.0
          ) AS not_paid_percentage,

          total_students

      FROM (
          SELECT
              COUNT(*) AS total_students,

              SUM(
                  CASE
                      WHEN total_paid >= total_tuition
                          AND total_tuition > 0
                      THEN 1 ELSE 0
                  END
              ) AS fully_paid,

              SUM(
                  CASE
                      WHEN total_paid > 0
                          AND total_paid < total_tuition
                      THEN 1 ELSE 0
                  END
              ) AS partially_paid,

              SUM(
                  CASE
                      WHEN total_paid = 0
                      THEN 1 ELSE 0
                  END
              ) AS not_paid

          FROM (
              SELECT
                  student_years.id,

                  (
                      COALESCE(tuition.price, 0)
                      + COALESCE(extra_totals.extra_cost_amount, 0)
                      - COALESCE(student_years.discount, 0)
                  ) AS total_tuition,

                  COALESCE(payment_totals.total_paid, 0) AS total_paid

              FROM student_years

              JOIN students
                  ON students.id = student_years.student_id

              LEFT JOIN tuition
                  ON tuition.id = student_years.tuition_id

              LEFT JOIN (
                  SELECT
                      year_id,
                      major_id,
                      grade_level,
                      SUM(price) AS extra_cost_amount
                  FROM extra_costs
                  GROUP BY year_id, major_id, grade_level
              ) AS extra_totals
                  ON extra_totals.year_id = student_years.year_id
                  AND extra_totals.major_id = students.major_id
                  AND extra_totals.grade_level = student_years.grade_level

              LEFT JOIN (
                  SELECT
                      student_year_id,
                      SUM(amount) AS total_paid
                  FROM student_payments
                  GROUP BY student_year_id
              ) AS payment_totals
                  ON payment_totals.student_year_id = student_years.id

              WHERE
                  (:major_id IS NULL OR students.major_id = :major_id)
                  AND (:year_id IS NULL OR student_years.year_id = :year_id)
                  AND (:grade_level IS NULL OR student_years.grade_level = :grade_level)

          ) AS payment_status_table
      ) AS final;
      ''',
      // The three values are matched to the three named parameters in the
      // order in which each name first appears in the query.
      [majorId, yearId, grade],
    );

    // The query result is a single row containing the aggregated percentages and total count.
    final row = result.first;
    return PieCahrt.fromMap(row);
  }

  /// 📄 Loads everything the Excel report of one student needs, in one call.
  ///
  /// [studentYearId] is the enrollment ID (`student_years.id`).
  ///
  /// Returns a record with:
  /// - `studentInfo`: the student's details as a [Student].
  /// - `studentPayments`: **all** payments of the enrollment (no paging, and no
  ///   `ORDER BY`, so they are not necessarily in date order).
  /// - `studentRemainingPayment`: a map with `tuition`, `extra_costs` and
  ///   `remaining_tuition` (the same values as [getremainingTuition]).
  /// - `studentTotalPayment`: the sum of all payments.
  ///
  /// [limit] and [offset] are not used by any query in this method.
  ///
  /// NOTE: unlike [getremainingTuition], there is no check for a missing
  /// tuition. If the enrollment has no tuition linked, reading the `tuition`
  /// and `extra_costs` values (`as int`) throws.
  Future<({Student studentInfo, List<StudentPayment> studentPayments, Map<String,int> studentRemainingPayment, int studentTotalPayment})> getStudentInfoForReport({
    required int studentYearId,
    int limit = 10,
    int offset = 0,
    }) async {
    // The student's details (one row).
    final studentInfo = await dbController.db.rawQuery(
      '''
      SELECT
        student_years.id,
        students.first_name,
        students.last_name,
        students.national_code,
        students.student_code,
        year_id,
        students.major_id,
        student_years.grade_level,
        student_years.discount 
      FROM
        student_years
        JOIN students ON student_years.student_id = students.id
        LEFT JOIN majors ON students.major_id = majors.id 
      WHERE
        student_years.id = ?;
      ''',
      [studentYearId],
    );

    // All payments of the enrollment.
    final studentPayments = await dbController.db.rawQuery(
      '''
      SELECT * FROM student_payments WHERE student_year_id = ?;
      ''',
      [studentYearId],
    );

    // Tuition, extra costs and the amount required after the discount.
    final studentRemainingPayment = await dbController.db.rawQuery(
      '''
      SELECT
        tuition.price AS tuition,
        SUM(COALESCE(extra_costs.price, 0)) AS extra_costs,
        (tuition.price + SUM(COALESCE(extra_costs.price, 0)) - COALESCE(student_years.discount, 0)) AS remaining_tuition 
      FROM
        tuition
        LEFT JOIN student_years ON student_years.tuition_id = tuition.id
        LEFT JOIN extra_costs ON tuition.major_id = extra_costs.major_id 
        AND tuition.year_id = extra_costs.year_id 
        AND tuition.grade_level = extra_costs.grade_level 
      WHERE
        student_years.id = ?;
      ''',
      [studentYearId],
    );

    // The sum of all payments.
    final studentTotalPayment = await dbController.db.rawQuery(
      '''
      SELECT SUM(amount) AS total_payment FROM student_payments WHERE student_year_id = ?;
      ''',
      [studentYearId],
    );

    final student = Student.fromMap(studentInfo.first);

    final payment = studentPayments.map((e) => StudentPayment.fromMap(e)).toList();

    final totalPayment = (studentTotalPayment.first["total_payment"] as int?) ?? 0;

    // (Despite its name, this is the total required: tuition + extra costs - discount.)
    final tuitionPrice = (studentRemainingPayment.first["remaining_tuition"] as int?) ?? 0;

    
    return (
      studentInfo: student,

      studentPayments: payment,

      studentRemainingPayment: {
        "tuition": studentRemainingPayment.first["tuition"] as int,
        "extra_costs": studentRemainingPayment.first["extra_costs"] as int,
        "remaining_tuition": tuitionPrice - totalPayment,
      },

      studentTotalPayment: totalPayment,
    );
  }
}