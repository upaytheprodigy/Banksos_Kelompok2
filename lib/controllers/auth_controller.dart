import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

class AuthController {
  static UserModel? currentUser;

  static void loadFromSession() {
    final box = Hive.box('session');
    final userId = box.get('userId');
    if (userId == null) return;
    // data minimal dari Hive untuk RBAC offline
    currentUser = UserModel(
      id: userId,
      name: box.get('userName') ?? '',
      nim: '',
      email: '',
      passwordHash: '',
      role: box.get('userRole') ?? 'User',
      departmentId: box.get('departmentId') ?? '',
      isActive: true,
      isSuspended: false,
      streakCount: 0,
      createdAt: DateTime.now(),
    );
  }

  static bool isLoggedIn() => Hive.box('session').get('userId') != null;

  static bool canReview() =>
      ['Reviewer', 'Dept_Admin', 'Super_Admin'].contains(currentUser?.role);

  static bool canManageDepartment() =>
      ['Dept_Admin', 'Super_Admin'].contains(currentUser?.role);

  static bool isSuperAdmin() => currentUser?.role == 'Super_Admin';

  static bool canAccessDepartment(String departmentId) {
    if (isSuperAdmin()) return true;
    return currentUser?.departmentId == departmentId;
  }
}