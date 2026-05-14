import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_routes.dart';
import 'controllers/auth_controller.dart';
import 'controllers/news_controller.dart';
import 'controllers/analysis_controller.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase must be first — everything depends on it
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Infrastructure services (FCM permissions, token)
  await Get.putAsync(() => NotificationService().init());

  // 3. Data services — SyncService is a GetxService (stays alive for app lifetime)
  Get.put(SyncService());

  // 4. Global controllers — registered here so they survive route changes
  Get.put(NewsController(), permanent: true);
  Get.put(AuthController(), permanent: true);
  Get.put(AnalysisController(), permanent: true);

  // 5. Kick off initial sync in background — don't await, let UI load first
  Get.find<SyncService>().syncLiveNewsData();

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
