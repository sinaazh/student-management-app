/// Defines the lifecycle methods that dialog classes should implement.
///
/// Implementing classes provide their own logic for resetting dialog fields
/// and removing the associated controller.
abstract class DialogLifecycle {
  /// Resets the input fields and form state when required.
  void resetFields();

  /// Removes the controller associated with the dialog.
  void removeController();
}
