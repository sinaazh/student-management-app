
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:school_managment_app/controllers/language_controller.dart';
import 'package:school_managment_app/controllers/settings_controller.dart';
import 'package:school_managment_app/controllers/theme_controller.dart';
import 'package:school_managment_app/models/language.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/utils/theme.dart';
import 'package:school_managment_app/widgets/dialog_lifecycle.dart';
import 'package:school_managment_app/widgets/my_base_dialog.dart';
import 'package:school_managment_app/widgets/my_drop_down.dart';
import 'package:school_managment_app/widgets/my_text_field.dart';
import 'package:school_managment_app/widgets/theme_switcher_button.dart';
import 'package:school_managment_app/widgets/my_elevated_button.dart';

/// Provides the application settings dialog.
///
/// Allows users to manage the school name, school majors, school years,
/// application theme, and display language.
class Settings extends StatelessWidget implements DialogLifecycle {
  /// Manages the application's current theme and theme switching.
  final ThemeController themeController = Get.find();

  /// Manages the available languages and language selection.
  final LanguageController langController = Get.find();

  /// Manages school-related settings, including the school name,
  /// majors, and academic years.
  final SettingsController settingsController = Get.put(SettingsController());

  Settings({super.key});

  /// No temporary form fields need to be reset when this dialog closes.
  @override
  void resetFields() {}

  /// No additional controller cleanup is performed here.
  @override
  void removeController() {}

  @override
  Widget build(BuildContext context) {
    const double maxContainerWdith = 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Updates language-related layout settings based on the available window size.
        langController.checkWindowSize(context);

        return MyBaseDialog(
          title: 'settings'.tr,
          maxContainerWdith: maxContainerWdith,
          child: Container(
            constraints: const BoxConstraints(maxWidth: maxContainerWdith),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -----------------------------------------------------------------
                // School name settings
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The label color adapts to the currently selected theme.
                    Obx(() {
                      final isDark = themeController.isDark.value;
                      return Text(
                        'school_name'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      );
                    }),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Displays the school name.
                        // Editing is enabled only when the user activates edit mode.
                        Obx(
                          () => SizedBox(
                            width: 250,
                            child: MyTextField(
                              hintText: 'School Name',
                              errorText: 'only_letters_numbers_allowed'.tr,
                              regex: RegExp(r'^[a-zA-Z0-9]*$'),
                              textController:
                                  settingsController.schoolNameController,
                              readOnly:
                                  !settingsController.isEditingSchoolName.value,
                            ),
                          ),
                        ),

                        const SizedBox(width: 5),

                        // Displays either the save/cancel controls or the edit button,
                        // depending on whether school name editing is active.
                        Obx(() {
                          if (settingsController.isEditingSchoolName.value) {
                            return Transform.translate(
                              offset: const Offset(0, -8.5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Saves the modified school name.
                                  IconButton(
                                    onPressed:
                                        settingsController.saveSchoolName,
                                    tooltip: 'Save',
                                    icon: const HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle02,
                                      size: 24,
                                      color: Colors.green,
                                    ),
                                  ),

                                  // Discards the current edit operation.
                                  IconButton(
                                    onPressed: settingsController
                                        .cancelEditingSchoolName,
                                    tooltip: 'Cancel',
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedCancelCircle,
                                      size: 24,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            // Enables editing of the school name.
                            return Transform.translate(
                              offset: const Offset(0, -8.5),
                              child: SizedBox(
                                width: 60,
                                child: MyElevatedButton(
                                  buttonText: 'edit',
                                  icon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedEdit02,
                                    size: 40,
                                  ),
                                  onPressed:
                                      settingsController.startEditingSchoolName,
                                ),
                              ),
                            );
                          }
                        }),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // School major settings
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The label color adapts to the current application theme.
                    Obx(() {
                      final isDark = themeController.isDark.value;
                      return Text(
                        'school_major'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      );
                    }),

                    // Shows the major form when adding or editing a major.
                    // Otherwise, displays the major selector and its action buttons.
                    Obx(() {
                      if (settingsController.isMajoradding.value == true ||
                          settingsController.isMajorediting.value == true) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Input field for the major name.
                            // Only English letters and spaces are allowed.
                            SizedBox(
                              width: 250,
                              child: MyTextField(
                                hintText: 'School Major',
                                errorText: 'only_letters_allowed'.tr,
                                regex: RegExp(r'^[a-zA-Z ]*$'),
                                textController:
                                    settingsController.schoolMajorController,
                              ),
                            ),

                            // Save, cancel, and optional delete actions.
                            Transform.translate(
                              offset: const Offset(0, -8.5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Saves the new or edited major.
                                  IconButton(
                                    onPressed:
                                        settingsController.saveSchoolMajor,
                                    tooltip: 'Save',
                                    icon: const HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle02,
                                      size: 24,
                                      color: Colors.green,
                                    ),
                                  ),

                                  // Cancels the current add or edit operation.
                                  IconButton(
                                    onPressed: settingsController
                                        .cancelEditingOrAddingSchoolMajor,
                                    tooltip: 'Cancel',
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedCancelCircle,
                                      size: 24,
                                      color: Colors.red,
                                    ),
                                  ),

                                  // The delete action is available only when editing
                                  // an existing major, not when adding a new one.
                                  if(settingsController.isMajorediting.value)
                                    IconButton(
                                      onPressed: settingsController
                                          .deleteSchoolMajor,
                                      tooltip: 'delete',
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedDelete01,
                                        size: 24,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dropdown for selecting an existing school major.
                            SizedBox(
                              width: 200,
                              child: Obx(
                                () => MyDropDown<Major>(
                                  hint: 'major'.tr,
                                  items: settingsController.majorDropDownItems,
                                  value: settingsController.selectedMajor.value,
                                  showItemText: (item) => item.name,
                                  maxItemListWidth: 200,
                                  fontSize: 15,
                                  onChanged: (value) {
                                    settingsController.selectedMajor.value =
                                        value;
                                  },
                                  myFocusNode: langController.myFocusNode,
                                  context: context,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            // Enters edit mode for the selected major.
                            SizedBox(
                              width: 60,
                              child: MyElevatedButton(
                                buttonText: 'edit',
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedEdit02,
                                  size: 40,
                                ),
                                onPressed: settingsController.editSchoolMajor,
                              ),
                            ),

                            const SizedBox(width: 5),

                            // Opens the form for adding a new major.
                            SizedBox(
                              width: 60,
                              child: MyElevatedButton(
                                buttonText: 'add',
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedAdd01,
                                  size: 40,
                                ),
                                onPressed: settingsController.addSchoolMajor,
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // School year settings
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // The label color adapts to the current application theme.
                    Obx(() {
                      final isDark = themeController.isDark.value;
                      return Text(
                        'school_year'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      );
                    }),

                    // Displays the school year form when adding or editing.
                    // Otherwise, displays the existing years and their actions.
                    Obx(() {
                      if (settingsController.isYearadding.value == true ||
                          settingsController.isYearediting.value == true) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Input field for the school year.
                            // Only numeric characters are allowed.
                            SizedBox(
                              width: 250,
                              child: MyTextField(
                                hintText: 'School Year',
                                errorText: 'only_numbers_allowed'.tr,
                                regex: RegExp(r'^[0-9]*$'),
                                textController:
                                    settingsController.schoolYearController,
                              ),
                            ),

                            // Save, cancel, and optional delete actions.
                            Transform.translate(
                              offset: const Offset(0, -8.5),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Saves the new or edited school year.
                                  IconButton(
                                    onPressed:
                                        settingsController.saveSchoolYear,
                                    tooltip: 'Save',
                                    icon: const HugeIcon(
                                      icon: HugeIcons
                                          .strokeRoundedCheckmarkCircle02,
                                      size: 24,
                                      color: Colors.green,
                                    ),
                                  ),

                                  // Cancels the current add or edit operation.
                                  IconButton(
                                    onPressed: settingsController
                                        .cancelEditingOrAddingSchoolYear,
                                    tooltip: 'Cancel',
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedCancelCircle,
                                      size: 24,
                                      color: Colors.red,
                                    ),
                                  ),

                                  // The delete action is available only when editing
                                  // an existing school year.
                                  if(settingsController.isYearediting.value)
                                    IconButton(
                                      onPressed: settingsController
                                          .deleteSchoolYear,
                                      tooltip: 'delete',
                                      icon: const HugeIcon(
                                        icon: HugeIcons.strokeRoundedDelete01,
                                        size: 24,
                                        color: Colors.red,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dropdown for selecting an existing school year.
                            SizedBox(
                              width: 200,
                              child: Obx(
                                () => MyDropDown<SchoolYear>(
                                  hint: 'year'.tr,
                                  items: settingsController.yearDropDownItems,
                                  value: settingsController.selectedYear.value,
                                  showItemText: (item) => item.year.toString(),
                                  maxItemListWidth: 200,
                                  fontSize: 15,
                                  onChanged: (value) {
                                    settingsController.selectedYear.value =
                                        value;
                                  },
                                  myFocusNode: langController.myFocusNode,
                                  context: context,
                                ),
                              ),
                            ),

                            const SizedBox(width: 5),

                            // Enters edit mode for the selected school year.
                            SizedBox(
                              width: 60,
                              child: MyElevatedButton(
                                buttonText: 'edit',
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedEdit02,
                                  size: 40,
                                ),
                                onPressed: settingsController.editSchoolYear,
                              ),
                            ),

                            const SizedBox(width: 5),

                            // Opens the form for adding a new school year.
                            SizedBox(
                              width: 60,
                              child: MyElevatedButton(
                                buttonText: 'add',
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedAdd01,
                                  size: 40,
                                ),
                                onPressed: settingsController.addSchoolYear,
                              ),
                            ),
                          ],
                        );
                      }
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // Application theme settings
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Theme setting label.
                    Obx(() {
                      final isDark = themeController.isDark.value;
                      return Text(
                        'theme_mode'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      );
                    }),

                    // Displays the theme switcher and updates it reactively
                    // whenever the current theme changes.
                    Obx(() {
                      return RectThemeToggle(
                        isDark: themeController.isDark.value,
                        onToggle: () => themeController.toggleTheme(),
                      );
                    }),
                  ],
                ),

                const SizedBox(height: 20),

                // -----------------------------------------------------------------
                // Application language settings
                // -----------------------------------------------------------------
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language setting label.
                    Obx(() {
                      final isDark = themeController.isDark.value;
                      return Text(
                        'language'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? darkMode.colorScheme.primary
                              : lightMode.colorScheme.primary,
                        ),
                      );
                    }),

                    // Dropdown for selecting the application language.
                    SizedBox(
                      width: 200,
                      child: Obx(
                        () => MyDropDown<Language>(
                          hint: 'language'.tr,
                          items: langController.languageDropDownItems,
                          value: langController.selectedLanguage.value,
                          showItemText: (item) => item.languageName.tr,
                          maxItemListWidth: 200,
                          fontSize: 15,
                          onChanged: (value) {
                            langController.changeLanguage(language: value!);
                          },
                          myFocusNode: langController.myFocusNode,
                          context: context,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}