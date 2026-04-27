import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:banksos/controllers/auth_controller.dart';
import 'package:banksos/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDir;
  late Box<dynamic> sessionBox;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('banksos_auth_test_');
    Hive.init(tempDir.path);
    sessionBox = await Hive.openBox('session');
  });

  tearDown(() async {
    await sessionBox.clear();
    AuthController.currentUser = null;
    AuthService.resetDebugOverrides();
  });

  tearDownAll(() async {
    await sessionBox.close();
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('TC-AUTH-01: login valid harus membuat sesi dan mengembalikan user', () async {
    final hash = BCrypt.hashpw('password123', BCrypt.gensalt());
    AuthService.debugFindUserByEmail = (_) async => {
      '_id': 'user-1',
      'name': 'User Test',
      'nim': '123456789',
      'email': 'user@example.com',
      'passwordHash': hash,
      'role': 'USER',
      'departmentId': 'dept-1',
      'isActive': true,
      'isSuspended': false,
      'streakCount': 0,
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    };

    final user = await AuthService.login('user@example.com', 'password123');

    expect(user, isNotNull);
    expect(user!.id, 'user-1');
    expect(sessionBox.get('userId'), 'user-1');
    expect(sessionBox.get('userRole'), 'USER');
  });

  test('TC-AUTH-02: login invalid harus ditolak dan tidak membuat sesi', () async {
    final hash = BCrypt.hashpw('password123', BCrypt.gensalt());
    AuthService.debugFindUserByEmail = (_) async => {
      '_id': 'user-2',
      'name': 'User Invalid',
      'nim': '987654321',
      'email': 'user@example.com',
      'passwordHash': hash,
      'role': 'USER',
      'departmentId': 'dept-1',
      'isActive': true,
      'isSuspended': false,
      'streakCount': 0,
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    };

    final user = await AuthService.login('user@example.com', 'salah-password');

    expect(user, isNull);
    expect(sessionBox.get('userId'), isNull);
    expect(sessionBox.get('userRole'), isNull);
  });

  test('TC-AUTH-03: akses tanpa sesi harus ditolak', () {
    AuthController.loadFromSession();

    expect(AuthController.isLoggedIn(), isFalse);
    expect(AuthController.currentUser, isNull);
    expect(AuthController.canAccessDepartment('dept-1'), isFalse);
  });
}