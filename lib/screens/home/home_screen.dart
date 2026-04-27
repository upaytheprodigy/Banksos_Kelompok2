import 'package:flutter/material.dart';
// import '../../controllers/auth_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthController.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Banksos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              AuthController.currentUser = null;
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.library_books_outlined, color: Color(0xFF1A237E), size: 64),
            const SizedBox(height: 16),
            Text('Selamat datang, ${user?.name}!',
              textAlign:TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold) 
            ),
            const SizedBox(height: 8),
            Text('Role: ${user?.role}',
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
            Text('Jurusan: ${user?.departmentId}',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
