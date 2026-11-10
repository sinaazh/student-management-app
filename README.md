# Student Management App

A Windows desktop application built with **Flutter and Dart** to simplify student administration and tuition management in schools.

The application provides an integrated solution for managing student records, tracking tuition payments, monitoring outstanding debts, and generating financial reports. By replacing time-consuming manual administrative processes with an organized digital system, it aims to significantly reduce management workload and improve efficiency in schools.

## Features

### Student Management
- **Add Students:** Register new students and maintain their information.
- **Edit Students:** Update existing student records.
- **Delete Students:** Remove student records when necessary.
- **Search and Filter:** Quickly find students and narrow down records using available filters.
- **Pagination:** Navigate through student records efficiently.

### Tuition and Financial Management
- **Yearly Tuition Management:** Set and manage tuition fees for each academic year.
- **Payment Tracking:** Record and manage student tuition payments.
- **Additional Costs:** Manage extra costs alongside tuition fees.
- **Debtor List:** View all students with outstanding tuition balances.
- **Payment Status:** Track students based on their payment status:
  - Fully Paid
  - Partially Paid
  - Debtors

### Financial Statistics and Visualization
- **Payment Distribution Chart:** Visualize the percentage of students in each payment category through an interactive pie chart, providing a quick overview of the school's financial status.

### Excel Export and Reporting
- **Debtor List Export:** Export the entire debtor list to an Excel file at once.
- **Individual Student Reports:** Select a student from the debtor list, navigate to their payment page, and export their individual payment report.
- **Excel Reporting:** Generate reports using `syncfusion_flutter_xlsio` for record keeping and further analysis.

### Screenshots

See the [screenshots](screenshots) file for preview.

## Tech Stack

| Technology |
|---|---|
| [Flutter](https://flutter.dev/) | Windows desktop application framework |
| [Dart](https://dart.dev/) | Programming language |
| [GetX](https://pub.dev/packages/get) | State management, dependency injection, and navigation |
| [SQLite](https://www.sqlite.org/) | Local database and data persistence |
| [Syncfusion Flutter XlsIO](https://pub.dev/packages/syncfusion_flutter_xlsio) | Excel file generation and export |

## Architecture

The application uses **GetX** for state management, dependency injection, and navigation.

The codebase follows **Clean Architecture principles where practical**, with an effort to separate application responsibilities across controllers, models, services, views, and reusable widgets.

This approach helps keep the application organized, maintainable, and easier to extend.

### Project Structure

The `lib/` directory is organized into the following main components:

```text
lib/
├── controllers/
├── models/
├── services/
├── views/
├── widgets/
└── main.dart
```

## Getting Started

### Prerequisites

Before running the application, make sure you have installed:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- [Git](https://git-scm.com/)
- Windows 10 or later
- Visual Studio with the **Desktop development with C++** workload.

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
```

**2. Navigate to the project directory**

```bash
cd YOUR_REPOSITORY
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Enable Windows desktop support (if necessary)**

```bash
flutter config --enable-windows-desktop
```

**5. Run the application**

```bash
flutter run -d windows
```

The application automatically initializes its SQLite database on the first launch. No external database server or manual database creation is required.

## Building for Windows

To create a Windows release build, run:

```bash
flutter build windows --release
```

The generated release files can be found in:

```text
build/windows/x64/runner/Release/
```

The release directory contains the executable and supporting files required to run the application. Distribute the complete release folder rather than the executable alone.

## Database

The application uses **SQLite** for local data storage and persistence.

Database initialization is handled automatically when the application starts for the first time, so users do not need to configure or create a database manually.

## Future Improvements

Potential areas for future development include:

- Automated database backup and restore.
- More advanced financial reporting and analytics.
- Additional reporting and filtering capabilities.
- Further improvements to application performance and usability.

*These are potential improvements, not necessarily features currently implemented.*

## License

This project is licensed under the MIT License.
See the [LICENSE](LICENSE) file for details.