import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    // Check password match for sign up
    if (!_isLogin &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Passwords do not match!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // ✅ Login
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (response.user != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('✅ Login Successful!')));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardWrapper()),
          );
        }
      } else {
        // ✅ Sign Up with all fields
        final response = await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          data: {
            'name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          },
        );

        if (response.user != null) {
          // Save profile with all data
          await Supabase.instance.client.from('profiles').insert({
            'user_id': response.user!.id,
            'email': _emailController.text.trim(),
            'name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Account created! Please login.')),
          );
          setState(() {
            _isLogin = true;
            _fullNameController.clear();
            _phoneController.clear();
            _addressController.clear();
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error: ${e.toString()}')));
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.swap_horiz, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // 🔥 SIGN UP FIELDS
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Enter phone number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.home_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 📧 Email
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),

                  // 🔒 Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v!.isEmpty) return 'Enter password';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 🔐 Confirm Password (only for Sign Up)
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v!.isEmpty) return 'Confirm your password';
                        if (v != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  const SizedBox(height: 20),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            _isLogin ? 'Login' : 'Sign Up',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "Don't have an account? "
                            : "Already have an account? ",
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _fullNameController.clear();
                            _phoneController.clear();
                            _addressController.clear();
                            _emailController.clear();
                            _passwordController.clear();
                            _confirmPasswordController.clear();
                          });
                        },
                        child: Text(
                          _isLogin ? 'Sign Up' : 'Login',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
