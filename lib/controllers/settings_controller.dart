import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';
import 'package:school_managment_app/services/settings_manager.dart';
import 'package:school_managment_app/services/shared_data_service.dart';
import 'package:school_managment_app/widgets/my_snack_bar.dart';

/// Controller (GetX) for the settings page.
///
/// It manages three things:
/// 1. The school name (stored in the app settings).
/// 2. The list of majors (stored in the database): add, edit, delete.
/// 3. The list of school years (stored in the database): add, edit, delete.
///
/// Majors and years work the same way:
/// - The user picks an item in a dropdown ([selectedMajor] / [selectedYear]).
/// - "Add" or "Edit" shows a text field and sets the matching `...adding` /
///   `...editing` flag. "Save" writes to the database, "Cancel" closes the field.
/// - After every successful change, [SharedDataService.loadData] reloads the
///   shared lists, so every dropdown in the app updates.
class SettingsController extends GetxController {
  // --- Dependency Injection ---
  // `Get.find()` only works if these objects were registered earlier
  // (e.g. with `Get.put` in a binding or in main). Otherwise it throws.

  /// Reads and writes the saved app settings (here: the school name).
  final SettingsManager appSettings = Get.find();

  /// App-wide shared data (the lists of majors and school years).
  final SharedDataService dataService = Get.find();

  /// Low-level database controller; passed to [repository] in [onInit].
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// Handles the actual database operations (insert, update, delete).
  /// `late` because it needs [dbController], so it is created in [onInit].
  late final SchoolRepository repository;

  // --- School name ---

  /// Controller of the school name text field.
  TextEditingController schoolNameController = TextEditingController();

  /// Not used anywhere in this controller (the name is kept in
  /// [schoolNameController]). [loadSchoolName] also has a local variable
  /// with the same name.
  RxString schoolName = ''.obs;

  /// `true` if a school name was already saved when the page was loaded.
  /// [cancelEditingSchoolName] uses it to decide whether to clear the field.
  /// It is only set in [loadSchoolName], not after saving.
  bool alreadyHadSchoolName = false;

  /// `true` while the school name field is in edit mode (set by the view).
  final RxBool isEditingSchoolName = false.obs;

  // --- Majors ---
  // Anything marked `.obs` / `Rx` rebuilds the `Obx` widgets that read it.

  /// Items shown in the major dropdown.
  RxList<Major> majorDropDownItems = <Major>[].obs;

  /// The major currently selected in the dropdown, or `null` if none is selected.
  Rx<Major?> selectedMajor = Rx<Major?>(null);

  /// `true` while the user is adding a new major.
  final RxBool isMajoradding = false.obs;

  /// `true` while the user is editing the selected major.
  final RxBool isMajorediting = false.obs;

  /// Controller of the text field used to type the major name when adding/editing.
  TextEditingController schoolMajorController = TextEditingController();

  // --- Years ---

  /// Items shown in the school year dropdown.
  RxList<SchoolYear> yearDropDownItems = <SchoolYear>[].obs;

  /// The school year currently selected in the dropdown, or `null` if none is selected.
  Rx<SchoolYear?> selectedYear = Rx<SchoolYear?>(null);

  /// `true` while the user is adding a new school year.
  final RxBool isYearadding = false.obs;

  /// `true` while the user is editing the selected school year.
  final RxBool isYearediting = false.obs;

  /// Controller of the text field used to type the year when adding/editing.
  TextEditingController schoolYearController = TextEditingController();

  /// Called by GetX right after the controller is created.
  /// Sets up the repository, fills the dropdowns and loads the school name.
  @override
  void onInit() {
    super.onInit();

    // The repository needs the database controller, so it is created here
    // instead of in the field initializer.
    repository = SchoolRepository(dbController);

    // Copy the shared lists into this controller's own reactive lists.
    // `assignAll` replaces the content and triggers a single UI update.
    majorDropDownItems.assignAll(dataService.majorItems);
    yearDropDownItems.assignAll(dataService.yearItems);

    // Keep the dropdowns up to date when the shared lists change
    // (this happens after every add/edit/delete below).
    ever(dataService.majorItems, (majors) {
      majorDropDownItems.assignAll(majors);
    });

    ever(dataService.yearItems, (years) {
      yearDropDownItems.assignAll(years);
    });

    loadSchoolName();
  }

  //--------------------------------------------
  // school name
  //--------------------------------------------

  /// Reads the saved school name and shows it in [schoolNameController].
  /// Also remembers whether a name existed ([alreadyHadSchoolName]).
  void loadSchoolName() async {
    String schoolName = await appSettings.readSchoolName();

    if (schoolName == "") {
      schoolNameController.clear();
    } else {
      schoolNameController.text = schoolName;
      alreadyHadSchoolName = true;
    }
  }

  /// Called when the user starts editing the school name.
  ///
  /// Currently it only reloads the shared data. The line that would set
  /// [isEditingSchoolName] to `true` is commented out, so the view must set
  /// the flag itself.
  void startEditingSchoolName()async {
    // isEditingSchoolName.value = true;
    await dataService.loadData();
  }

  /// Leaves edit mode. If no name had been saved before, the text field is
  /// also cleared, so anything typed and not saved disappears.
  void cancelEditingSchoolName() {
    isEditingSchoolName.value = false;
    if(alreadyHadSchoolName == false){
      schoolNameController.clear();
    }
  }

  /// Saves the typed school name (trimmed) in the app settings and leaves
  /// edit mode. An empty name is saved as an empty string.
  void saveSchoolName() async {
    final schoolName = schoolNameController.text.trim();

    if (schoolName.isEmpty) {
      await appSettings.saveSchoolName("");
    }

    // Show the trimmed text in the field, then save it.
    schoolNameController.text = schoolName;
    await appSettings.saveSchoolName(schoolName);
    isEditingSchoolName.value = false;
  }

  //--------------------------------------------
  // school major
  //--------------------------------------------

  /// Switches to "add major" mode: clears the text field and the selection.
  void addSchoolMajor() {
    isMajoradding.value = true;
    isMajorediting.value = false;
    schoolMajorController.clear();
    selectedMajor.value = null;
  }

  /// Switches to "edit major" mode for the selected major and shows its name
  /// in the text field. Shows a warning toast if no major is selected.
  void editSchoolMajor() {
    if (selectedMajor.value == null) {
      return RightSideToast.show(
        title: "Error",
        message: "select_a_major_first".tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68), // amber = warning
        duration: Duration(seconds: 3),
      );
    }
    isMajorediting.value = true;
    isMajoradding.value = false;
    schoolMajorController.text = selectedMajor.value!.name;
  }

  /// Leaves add/edit mode and clears the selection.
  void cancelEditingOrAddingSchoolMajor() {
    isMajoradding.value = false;
    isMajorediting.value = false;
    selectedMajor.value = null;
  }

  /// Saves the typed major name, depending on the current mode:
  /// - Edit mode (and a major selected): updates the selected major.
  /// - Add mode: inserts a new major.
  ///
  /// On success a toast is shown and the shared data is reloaded so all
  /// dropdowns update. On failure an error toast is shown. At the end it always
  /// leaves add/edit mode, whether the save worked or not.
  void saveSchoolMajor() async {
    if(isMajorediting.value == true && isMajoradding.value == false && selectedMajor.value != null){
      final result = await repository.updateMajor(
        major: Major(
          id: selectedMajor.value!.id, 
          name: schoolMajorController.text.trim()
        )
      );
      if(result["status"]){
        RightSideToast.show(
          title: 'success'.tr,
          message: "major_updated_successfully".tr,
          messageColor: Colors.green,
        );
        await dataService.loadData();
      } else{
        RightSideToast.show(
          title: 'error'.tr,
          message: "major_couldnt_be_updated".tr,
          messageColor: Colors.red,
        );
      }
    } else if(isMajoradding.value == true){
      // The ID 0 is only a placeholder: the database creates the real ID.
      final result = await repository.insertMajor(
        major: Major(
          id: 0, 
          name: schoolMajorController.text.trim()
        )
      );
      if(result["status"]){
        RightSideToast.show(
          title: 'success'.tr,
          message: "major_added_successfully".tr,
          messageColor: Colors.green,
        );
        await dataService.loadData();
      } else{
        RightSideToast.show(
          title: 'error'.tr,
          message: "major_couldnt_be_added".tr,
          messageColor: Colors.red,
        );
      }
    }
    cancelEditingOrAddingSchoolMajor();
  }

  /// Deletes the selected major. Shows a warning toast if none is selected.
  ///
  /// The repository only needs the ID, so the name is left empty.
  /// On success the shared data is reloaded. The delete can fail, for example
  /// if students or costs still use this major.
  void deleteSchoolMajor() async {
    if (selectedMajor.value == null) {
      return RightSideToast.show(
        title: "Error",
        message: "select_a_major_first".tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
    }

    final result = await repository.deleteMajor(
      major: Major(
        id: selectedMajor.value!.id, 
        name: ""
      )
    );

    if(result["status"]){
      RightSideToast.show(
        title: 'success'.tr,
        // NOTE: this is the "added" message, probably copied from saveSchoolMajor.
        // It should be a "major deleted" message.
        message: "major_added_successfully".tr,
        messageColor: Colors.green,
      );
      await dataService.loadData();
    } else{
      RightSideToast.show(
        title: 'error'.tr,
        message: "major_couldnt_be_deleted".tr,
        messageColor: Colors.red,
      );
    }
    cancelEditingOrAddingSchoolMajor();
  }

  //--------------------------------------------
  // school year
  //--------------------------------------------

  /// Switches to "add year" mode: clears the text field and the selection.
  void addSchoolYear() {
    isYearadding.value = true;
    isYearediting.value = false;
    schoolYearController.clear();
    selectedYear.value = null;
  }

  /// Switches to "edit year" mode for the selected year and shows it in the
  /// text field. Shows a warning toast if no year is selected.
  void editSchoolYear() {
    if (selectedYear.value == null) {
      return RightSideToast.show(
        title: "Error",
        message: "select_a_year_first".tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68), // amber = warning
        duration: Duration(seconds: 3),
      );
    }
    isYearediting.value = true;
    isYearadding.value = false;
    schoolYearController.text = selectedYear.value!.year.toString();
  }

  /// Leaves add/edit mode and clears the selection.
  void cancelEditingOrAddingSchoolYear() {
    isYearadding.value = false;
    isYearediting.value = false;
    selectedYear.value = null;
  }

  /// Saves the typed year, depending on the current mode:
  /// - Edit mode (and a year selected): updates the selected year.
  /// - Add mode: inserts a new year.
  ///
  /// The text is converted with `int.parse`, so it throws if it is empty or
  /// not a whole number. On success a toast is shown and the shared data is
  /// reloaded so all dropdowns update. On failure an error toast is shown.
  /// At the end it always leaves add/edit mode.
  void saveSchoolYear() async {
    if(isYearadding.value == false && isYearediting.value == true && selectedYear.value != null){
      final result = await repository.updateYear(
        year: SchoolYear(
          id: selectedYear.value!.id, 
          year: int.parse(schoolYearController.text.trim())
        )
      );
      if(result["status"]){
        RightSideToast.show(
          title: 'success'.tr,
          message: "year_updated_successfully".tr,
          messageColor: Colors.green,
        );
        await dataService.loadData();
      } else{
        RightSideToast.show(
          title: 'error'.tr,
          message: "year_couldnt_be_updated".tr,
          messageColor: Colors.red,
        );
      }
    } else if(isYearadding.value == true){
      // The ID 0 is only a placeholder: the database creates the real ID.
      final result = await repository.insertYear(
        year: SchoolYear(
          id: 0, 
          year: int.parse(schoolYearController.text.trim())
        )
      );
      if(result["status"]){
        RightSideToast.show(
          title: 'success'.tr,
          message: "year_added_successfully".tr,
          messageColor: Colors.green,
        );
        await dataService.loadData();
      } else{
        RightSideToast.show(
          title: 'error'.tr,
          message: "year_couldnt_be_added".tr,
          messageColor: Colors.red,
        );
      }
    }
    cancelEditingOrAddingSchoolYear();
  }

  /// Deletes the selected year. Shows a warning toast if none is selected.
  ///
  /// The repository only needs the ID, so the year value is set to 0.
  /// On success the shared data is reloaded. The delete can fail, for example
  /// if students or costs still use this year.
  void deleteSchoolYear() async {
    if (selectedYear.value == null) {
      return RightSideToast.show(
        title: "Error",
        message: "select_a_year_first".tr,
        messageColor: const Color.fromARGB(255, 233, 181, 68),
        duration: Duration(seconds: 3),
      );
    }

    final result = await repository.deleteYear(
      year: SchoolYear(
        id: selectedYear.value!.id, 
        year: 0
      )
    );

    if(result["status"]){
      RightSideToast.show(
        title: 'success'.tr,
        message: "year_deleted_successfully".tr,
        messageColor: Colors.green,
      );
      await dataService.loadData();
    } else{
      RightSideToast.show(
        title: 'error'.tr,
        message: "year_couldnt_be_deleted".tr,
        messageColor: Colors.red,
      );
    }
    cancelEditingOrAddingSchoolYear();
  }
}