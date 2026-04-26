import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/kontribusi/screens/kontribusiku_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init Hive (local database)
  await Hive.initFlutter();
  // TODO: register Hive adapters
  // Hive.registerAdapter(QuestionModelAdapter());

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: SoalKuApp(),
    ),
  );
}

class SoalKuApp extends StatelessWidget {
  const SoalKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoalKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavShell(),
    );
  }
}

/// Bottom nav shell — nanti setiap tab diisi dengan screen masing-masing anggota
class MainNavShell extends StatefulWidget {
  const MainNavShell({super.key});

  @override
  State<MainNavShell> createState() => _MainNavShellState();
}

class _MainNavShellState extends State<MainNavShell> {
  int _selectedIndex = 2; // default ke tab Kontribusiku (bagian Seruni)

  final List<Widget> _screens = [
    const _PlaceholderScreen(
        label: 'Beranda',
        icon: Icons.home_rounded,
        description: 'Modul: Revaldi (Streak & Bank Soal)'),
    const _PlaceholderScreen(
        label: 'Bank Soal',
        icon: Icons.library_books_rounded,
        description: 'Modul: Revaldi (Browse & Kerjakan Soal)'),
    const KontribusikuScreen(), // <-- Bagian Seruni
    const _PlaceholderScreen(
        label: 'Profil',
        icon: Icons.person_rounded,
        description: 'Modul: Adjie (Sync & Auth)'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primaryLight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppTheme.primaryDark),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon:
                Icon(Icons.library_books_rounded, color: AppTheme.primaryDark),
            label: 'Bank Soal',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon:
                Icon(Icons.edit_note_rounded, color: AppTheme.primaryDark),
            label: 'Kontribusiku',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon:
                Icon(Icons.person_rounded, color: AppTheme.primaryDark),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

/// Placeholder untuk modul anggota lain yang belum dikerjakan
class _PlaceholderScreen extends StatelessWidget {
  final String label;
  final IconData icon;
  final String description;

  const _PlaceholderScreen({
    required this.label,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        backgroundColor: AppTheme.primaryDark,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Under Development',
                style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}