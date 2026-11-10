import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    primary: Colors.black,
    secondary: Colors.white,
    
  ),

  // ---------------- TextField Theme ----------------
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey[200],
    hintStyle: TextStyle(color: Colors.grey[600]),
    prefixStyle: TextStyle(color: Colors.grey[600]),
    errorStyle: TextStyle(color: Colors.red.shade700),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade400),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 46, 45, 45),
    primary: const Color.fromARGB(255, 255, 255, 255),
    secondary: const Color.fromARGB(255, 140, 138, 138),
  ),

  // ---------------- TextField Theme ----------------
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF242424),
    hintStyle: TextStyle(color: Colors.grey[400]),
    prefixStyle: TextStyle(color: Colors.grey[400]),
    errorStyle: TextStyle(color: Colors.red.shade300),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: Colors.grey.shade700),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: const Color(0xFF7F22DB), width: 2),
    ),
  ),
);


extension MyColorScheme on ColorScheme {

  // ---------------- DropDown Theme ----------------
  Color get dropdownButtonColor => brightness == Brightness.light ? Colors.grey.shade100 : const Color(0xFF242424);
  Color get dropdownBackgroundColor => brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);
  Color get dropdownTextColor => brightness == Brightness.light ? Colors.black87 : Colors.white;
  Color get dropdownHintColor => brightness == Brightness.light ? Colors.grey : Colors.grey.shade400;

  // ---------------- Main layout background Theme ----------------
  Color get mainLayoutBackgroundColor => brightness == Brightness.light ? const Color.fromARGB(255, 238, 240, 240) : Colors.grey.shade800;

  // ---------------- Containers Theme ----------------
  Color get containerBackgroundColor => brightness == Brightness.light ? Colors.white : const Color.fromARGB(255, 46, 45, 45);

  // ---------------- Data Table Row Theme ----------------
  Color get dataTableRowColor => brightness == Brightness.light ? Colors.deepPurple.shade50 : const Color.fromARGB(255, 91, 50, 162);

  // ---------------- Elevated button theme for dark mode Theme ----------------
  LinearGradient? get elevatedButtonGradient {
    if (brightness == Brightness.dark) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.fromARGB(255, 87, 197, 214),
          Color.fromARGB(255, 86, 132, 181),
        ],
      );
    }
    return null;
  }

  // ---------------- Side bar options Theme ----------------
  Color get buttonColor => brightness == Brightness.light ? const Color.fromARGB(255, 113, 113, 113) : const Color.fromARGB(255, 188, 188, 188);
  Color get selectedSubItemBackgroundColor => brightness == Brightness.light ? const Color.fromARGB(255, 247, 223, 250) : const Color.fromARGB(255, 72, 58, 78);

  // ---------------- Side bar options Theme ----------------
  Color get studentPaymentBackgroundColor => brightness == Brightness.light ? Colors.white : Colors.grey[800]!;
}