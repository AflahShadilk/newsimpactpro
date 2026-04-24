import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/models/user_model.dart';
import '../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();

  final Rxn<User> firebaseUser = Rxn<User>();
  final Rxn<UserModel> userModel = Rxn<UserModel>();
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Bind firebaseUser to auth changes
    firebaseUser.bindStream(_authService.user);
    
    // Ever listener to handle navigation based on auth state
    ever(firebaseUser, _handleAuthChanged);
  }

  void _handleAuthChanged(User? user) async {
    if (user == null) {
      userModel.value = null;
      Get.offAllNamed(AppRoutes.login);
    } else {
      await _loadUserModel(user.uid);
      Get.offAllNamed(AppRoutes.home);
    }
  }

  Future<void> _loadUserModel(String uid) async {
    final model = await _userRepository.getUser(uid);
    if (model != null) {
      userModel.value = model;
    } else {
      // Initialize new user if not found
      final newUser = UserModel(
        uid: uid,
        email: firebaseUser.value?.email ?? '',
        displayName: firebaseUser.value?.displayName ?? 'Trader',
        photoUrl: firebaseUser.value?.photoURL ?? '',
        fcmToken: '', 
        currencies: ['USD', 'EUR', 'GBP'],
        impact: ['high', 'medium'],
        alertTime: 15,
        focusMode: false,
        timezone: 'UTC',
        notificationsEnabled: true,
      );
      await _userRepository.saveUser(newUser);
      userModel.value = newUser;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      await _authService.signInWithGoogle();
    } catch (e) {
      Get.snackbar('Login Failed', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> updateUser(Map<String, dynamic> data) async {
    if (firebaseUser.value == null) return;
    try {
      await _userRepository.updateUserFields(firebaseUser.value!.uid, data);
      // Update local model
      if (userModel.value != null) {
        final updatedData = userModel.value!.toFirestore();
        updatedData.addAll(data);
        userModel.value = UserModel.fromMap(updatedData, firebaseUser.value!.uid);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update settings: ${e.toString()}');
    }
  }
}
