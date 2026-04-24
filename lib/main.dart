import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Services
  await Get.putAsync(() => NotificationService().init());
  Get.put(SyncService());

  // Initialize AuthController
  Get.put(AuthController());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'NewsImpact Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.login,
      getPages: AppRoutes.routes,
      defaultTransition: Transition.cupertino,
    );
  }
}
