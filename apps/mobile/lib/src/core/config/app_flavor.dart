/// Build flavor for the app.
enum AppFlavor { dev, staging, prod }

extension AppFlavorX on AppFlavor {
  String get name => toString().split('.').last;
}
