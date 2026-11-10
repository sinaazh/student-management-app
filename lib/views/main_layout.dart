
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:school_managment_app/controllers/side_bar_controller.dart';
import 'package:school_managment_app/routes/app_pages.dart';
import 'package:school_managment_app/widgets/side_bar.dart';

/// Provides the main application layout.
///
/// Keeps the sidebar visible while displaying the currently selected page
/// in the remaining available space.
class MainLayout extends StatelessWidget {
  /// Retrieves the existing [SidebarController] instance.
  ///
  /// The controller manages which page is currently selected.
  final SidebarController controller = Get.find();

  MainLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      body: Padding(
        padding: const EdgeInsets.all(0),
        child: Row(
          children: [
            // Persistent navigation sidebar on the left.
            Sidebar(),
            SizedBox(width: 1,),

            // Displays the page selected from the sidebar.
            // Obx automatically rebuilds this section when the selected route changes.
            Expanded(
              child: Obx(() {
                final selectedRoute = controller.selectedPage.value;

                // Find the corresponding page configuration in AppPages.routes.
                // If no matching route exists, use a fallback page.
                final page = AppPages.routes.firstWhere(
                  (p) => p.name == selectedRoute,
                  orElse: () => GetPage(
                    name: '/notfound',
                    page: () => Center(child: Text('Page not found')),
                  ),
                );

                // Build and display the selected page.
                return page.page();
              }),
            ),
          ],
        ),
      ),
    );
  }
}