import 'package:bcrypt/bcrypt.dart';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/department_model.dart';
import 'db_service.dart';

typedef UserLookup = Future<Map<String, dynamic>?> Function(String email);

class AuthService {
  static const _userCol = 'users';
  static const _deptCol = 'departments';
  static UserLookup? debugFindUserByEmail;

  static Future<String?> register({
    required String name,
    required String nim,
    required String email,
    required String password,
    required String departmentId,
  }) async {
    await DbService.getDb();
    final col = DbService.getCollection(_userCol);

    final existing = await col.findOne({
      '\$or': [
        {'email': email},
        {'nim': nim},
      ]
    });
    if (existing != null) return 'Email atau NIM sudah terdaftar';

    if (password.length < 8) return 'Password minimal 8 karakter';

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final user = UserModel(
      id: const Uuid().v4(),
      name: name,
      nim: nim,
      email: email,
      passwordHash: hash,
      role: 'USER',
      departmentId: departmentId,
      isActive: true,
      isSuspended: false,
      streakCount: 0,
      createdAt: DateTime.now(),
    );

    await col.insertOne(user.toMap());
    return null;
  }

  static Future<UserModel?> login(String email, String password) async {
    final doc = await _findUserByEmail(email);
    if (doc == null) return null;

    final user = UserModel.fromMap(doc);
    if (user.isSuspended || !user.isActive) return null;

    final valid = BCrypt.checkpw(password, user.passwordHash);
    if (!valid) return null;

    // simpan sesi ke Hive
    final box = Hive.box('session');
    await box.put('userId', user.id);
    await box.put('userRole', user.role);
    await box.put('userName', user.name);
    await box.put('departmentId', user.departmentId);

    return user;
  }

  static Future<Map<String, dynamic>?> _findUserByEmail(String email) async {
    if (debugFindUserByEmail != null) {
      return debugFindUserByEmail!(email);
    }

    await DbService.getDb();
    final col = DbService.getCollection(_userCol);
    return col.findOne({'email': email});
  }

  static void resetDebugOverrides() {
    debugFindUserByEmail = null;
  }

  static Future<List<DepartmentModel>> getDepartments() async {
  try {
    await DbService.getDb();
    final col = DbService.getCollection(_deptCol);
    final docs = await col.find().toList();
  print('Semua data tanpa filter: $docs');
    return docs.map((d) => DepartmentModel.fromMap(d)).toList();
  } catch (e) {
    return [];
  }
}

  static Future<void> logout() async {
    await Hive.box('session').clear();
  }
}
