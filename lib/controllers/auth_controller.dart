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
      role: box.get('userRole') ?? 'USER',
      departmentId: box.get('departmentId') ?? '',
      isActive: true,
      isSuspended: false,
      streakCount: 0,
      createdAt: DateTime.now(),
    );
  }

  static bool isLoggedIn() => Hive.box('session').get('userId') != null;

  static bool canReview() =>
      ['REVIEWER', 'DEPT_ADMIN', 'SUPER_ADMIN'].contains(currentUser?.role);

  static bool canManageDepartment() =>
      ['DEPT_ADMIN', 'SUPER_ADMIN'].contains(currentUser?.role);

  static bool isSuperAdmin() => currentUser?.role == 'SUPER_ADMIN';

  static bool canAccessDepartment(String departmentId) {
    if (isSuperAdmin()) return true;
    return currentUser?.departmentId == departmentId;
  }
}