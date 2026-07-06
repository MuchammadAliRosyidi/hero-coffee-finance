import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.onLogin});

  final Future<void> Function(String username, String password) onLogin;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEFF4FF), Color(0xFFF5F7FB), Color(0xFFFDF7F2)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(20, 24, 20, 24 + viewInsets.bottom),
                child: ConstrainedBox(
                  constraints:
                      BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: Center(
                    child: Container(
                      width: 360,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 30,
                            offset: Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.coffee_rounded,
                              size: 42, color: Color(0xFF2F6DDE)),
                          const SizedBox(height: 10),
                          const Text(
                            'Hero Coffee Finance',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Masuk untuk lanjut kelola operasional',
                            style: TextStyle(color: Color(0xFF6B7280)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _usernameController,
                            decoration:
                                const InputDecoration(labelText: 'Username'),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration:
                                const InputDecoration(labelText: 'Password'),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _loading
                                  ? null
                                  : () async {
                                      setState(() => _loading = true);
                                      await widget.onLogin(
                                        _usernameController.text,
                                        _passwordController.text,
                                      );
                                      if (mounted) {
                                        setState(() => _loading = false);
                                      }
                                    },
                              child: Text(_loading ? 'Memproses...' : 'Masuk'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Demo akun: owner/owner123 atau admin/admin123',
                            style:
                                TextStyle(color: Colors.white60, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
