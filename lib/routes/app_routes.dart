import 'package:get/get.dart';
import '../modules/auth/login_screen.dart';
import '../modules/home/home_screen.dart';
import '../modules/detail/detail_screen.dart';
import '../modules/settings/settings_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String detail = '/detail';
  static const String settings = '/settings';

  static List<GetPage> routes = [
    GetPage(
      name: login,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: home,
      // NewsController is registered as permanent in main.dart — no binding needed here
      page: () => const HomeScreen(),
    ),
    GetPage(
      name: detail,
      page: () => const NewsDetailScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
  ];
}
