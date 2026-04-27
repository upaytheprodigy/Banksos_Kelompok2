import 'package:flutter/material.dart';
import '../../models/department_model.dart';
import '../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  List<DepartmentModel> _departments = [];
  String? _selectedDeptId;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final depts = await AuthService.getDepartments();
    setState(() => _departments = depts);
  }

  Future<void> _register() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Password tidak cocok');
      return;
    }
    if (_selectedDeptId == null) {
      setState(() => _error = 'Pilih jurusan terlebih dahulu');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final err = await AuthService.register(
      name: _nameCtrl.text.trim(),
      nim: _nimCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      departmentId: _selectedDeptId!,
    );

    if (!mounted) return;

    if (err != null) {
      setState(() { _error = err; _loading = false; });
      return;
    }

    setState(() { _success = 'Akun berhasil dibuat! Silakan login.'; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _nimCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'NIM', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _passCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              )),
            const SizedBox(height: 12),
            TextField(controller: _confirmCtrl,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Password', 
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              )),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Pilih Jurusan', border: OutlineInputBorder()),
              value: _selectedDeptId,
              items: _departments.map((d) => DropdownMenuItem(
                value: d.id,
                child: Text(d.name),
              )).toList(),
              onChanged: (val) => setState(() => _selectedDeptId = val),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            if (_success != null) ...[
              const SizedBox(height: 8),
              Text(_success!, style: const TextStyle(color: Colors.green)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Daftar', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
