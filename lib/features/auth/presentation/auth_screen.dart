import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../home/presentation/home_screen.dart';
import '../../provider/presentation/provider_dashboard_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import 'provider_registration_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() { _isLoading = true; });

    // Simulate Auth delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    final role = ref.read(registrationRoleProvider);
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    final dbSvc = ref.read(databaseServiceProvider);

    AppUser? loggedInUser;

    if (_isLogin) {
      // Login flow: match with mock accounts or retrieve/create
      if (email == 'admin@fixora.com') {
        loggedInUser = AppUser(uid: 'admin_1', email: email, name: 'Super Admin', role: UserRole.admin);
      } else if (email == 'rajesh@electrofix.com') {
        loggedInUser = AppUser(uid: 'prov_elec_1', email: email, name: 'Rajesh Sharma', role: UserRole.provider, phone: '+919876543210');
      } else if (email == 'amit@superplumb.com') {
        loggedInUser = AppUser(uid: 'prov_plumb_1', email: email, name: 'Amit Verma', role: UserRole.provider, phone: '+919811223344');
      } else {
        // Fallback or generic customer login
        loggedInUser = AppUser(
          uid: 'cust_temp',
          email: email,
          name: email.split('@').first,
          role: UserRole.customer,
          phone: '+919999999999',
        );
      }
    } else {
      // Register flow
      final uid = 'user_${DateTime.now().millisecondsSinceEpoch}';
      loggedInUser = AppUser(
        uid: uid,
        email: email,
        name: name,
        role: role,
        phone: '+918888888888',
      );
      
      // Save user record
      await dbSvc.createUser(loggedInUser);
      if (!mounted) return;

      if (role == UserRole.provider) {
        // Navigate to provider profile registration before setting user active
        setState(() { _isLoading = false; });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ProviderRegistrationScreen(user: loggedInUser!),
          ),
        );
        return;
      }
    }

    ref.read(authStateProvider.notifier).state = loggedInUser;
    
    setState(() { _isLoading = false; });

    // Navigate to appropriate home/dashboard based on role
    _navigateForRole(loggedInUser.role);
  }

  void _navigateForRole(UserRole role) {
    Widget target;
    if (role == UserRole.admin) {
      target = const AdminDashboardScreen();
    } else if (role == UserRole.provider) {
      target = const ProviderDashboardScreen();
    } else {
      target = const HomeScreen();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => target),
      (route) => false,
    );
  }

  void _autofill(String email, UserRole role) {
    ref.read(registrationRoleProvider.notifier).state = role;
    setState(() {
      _isLogin = true;
      _emailController.text = email;
      _passwordController.text = "password123";
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = ref.watch(registrationRoleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? "Sign In" : "Create Account"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Text(
                _isLogin
                    ? "Welcome back! Access your service marketplace."
                    : "Join Fixora as a ${role.name.toUpperCase()}.",
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        if (!value.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isLogin ? "Sign In" : "Sign Up"),
              ),

              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("OR MOCK LOGINS FOR TESTING", style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),

              // Mock Account shortcuts
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.person, size: 16),
                    label: const Text("Demo Customer"),
                    onPressed: () => _autofill("customer@fixora.com", UserRole.customer),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.bolt, size: 16),
                    label: const Text("Demo Electrician"),
                    onPressed: () => _autofill("rajesh@electrofix.com", UserRole.provider),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.water_drop, size: 16),
                    label: const Text("Demo Plumber"),
                    onPressed: () => _autofill("amit@superplumb.com", UserRole.provider),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.admin_panel_settings, size: 16),
                    label: const Text("Demo Admin"),
                    onPressed: () => _autofill("admin@fixora.com", UserRole.admin),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
