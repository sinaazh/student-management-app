import 'package:get/get.dart';
import 'package:school_managment_app/models/major.dart';
import 'package:school_managment_app/models/school_year.dart';
import 'package:school_managment_app/services/create_data_base.dart';
import 'package:school_managment_app/services/school_repository.dart';

/// Service responsible for loading and caching application-wide data that rarely changes (like years and majors).
///
/// By extending GetxService, it remains in memory throughout the app's lifecycle (unlike a controller)
/// and can be accessed globally via Get.find().
///
/// The controllers copy these lists into their dropdowns and listen to them with
/// `ever(...)`, so after [loadData] runs every dropdown in the app updates by
/// itself. The settings page calls [loadData] after each change to years or majors.
class SharedDataService extends GetxService {
  // `Get.find()` only works if the database controller was registered (and
  // initialized) before this service is created. Otherwise it throws.

  /// Finds and injects the database controller instance.
  final SchoolManagmentDataBaseController dbController = Get.find();

  /// Repository instance used to fetch data from the database.
  /// `late` because it needs [dbController], so it is created in [init].
  /// Without calling [init], using [loadData] throws.
  late final SchoolRepository repository;

  /// Reactive list holding all available academic school year objects.
  /// The other controllers listen to it and rebuild their dropdowns when it changes.
  RxList<SchoolYear> yearItems = <SchoolYear>[].obs;

  /// Reactive list holding all available academic major objects.
  /// The other controllers listen to it and rebuild their dropdowns when it changes.
  RxList<Major> majorItems = <Major>[].obs;

  /// Initializes the service. This method should be called inside a GetX Bindings class
  /// using `putAsync` to ensure data is loaded before the application starts using it.
  /// Returns this service, so it can be used with `Get.putAsync`.
  Future<SharedDataService> init() async{
    repository = SchoolRepository(dbController);
    await loadData();
    return this;
  }

  /// Fetches all required data (years and majors) from the database and updates the reactive lists.
  ///
  /// `assignAll` replaces the content of each list with **new objects** and
  /// notifies the listeners every time, even if the data did not change.
  Future<void> loadData() async {
    // Fetch and cache all school years
    final years = await repository.getYears();
    yearItems.assignAll(years);

    // Fetch and cache all majors.
    final majors = await repository.getMajors();
    majorItems.assignAll(majors);
  }
}