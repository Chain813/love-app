import 'package:get_it/get_it.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/location/providers/location_provider.dart';
import '../../features/settings/providers/theme_provider.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Initialize the service locator with all app dependencies.
/// Must be called after Hive.initFlutter() and before runApp().
///
/// Currently registers Providers (ChangeNotifier instances).
/// Services (LeanCloudService, etc.) use static methods for now
/// and will be migrated to instance-based DI in a later step.
Future<void> initServiceLocator() async {
  // Providers — created once, shared across the app
  sl.registerLazySingleton<AuthProvider>(() => AuthProvider());
  sl.registerLazySingleton<LocationProvider>(() => LocationProvider());
  sl.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
}
