import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../../core/theme/logo.dart';
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

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUid', loggedInUser.uid);
    } catch (e) {
      debugPrint("Failed to save login UID: $e");
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isLogin ? "Sign In" : "Create Account"),
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // App logo
                  const Center(
                    child: FixoraLogo(size: 80),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    _isLogin
                        ? "Welcome back! Access your service marketplace."
                        : "Join Fixora as a ${role.name.toUpperCase()}.",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(duration: 400.ms),
                  
                  const SizedBox(height: 32),

                  // Glass Card Form
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _nameController,
                              style: const TextStyle(color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
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
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                            ),
                            validator: (value) => value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0, curve: Curves.easeOutQuad),

                  const SizedBox(height: 24),

                  // Gradient Submit Button
                  GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: role == UserRole.customer
                              ? [AppTheme.primaryColor, AppTheme.secondaryColor]
                              : role == UserRole.provider
                                  ? [AppTheme.secondaryColor, const Color(0xFFC084FC)]
                                  : [AppTheme.warningColor, const Color(0xFFFDBA74)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (role == UserRole.customer
                                    ? AppTheme.primaryColor
                                    : role == UserRole.provider
                                        ? AppTheme.secondaryColor
                                        : AppTheme.warningColor)
                                .withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                _isLogin ? "Sign In" : "Sign Up",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  )
                      .animate()
                      .scale(begin: const Offset(0.98, 0.98), duration: 150.ms),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                      });
                    },
                    child: Text(
                      _isLogin ? "Don't have an account? Sign Up" : "Already have an account? Sign In",
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // Mock accounts header
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white12)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "OR MOCK LOGINS FOR TESTING",
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, letterSpacing: 1),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white12)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Mock Account shortcuts
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildMockChip("Demo Customer", () => _autofill("customer@fixora.com", UserRole.customer), Icons.person, AppTheme.primaryColor),
                      _buildMockChip("Demo Electrician", () => _autofill("rajesh@electrofix.com", UserRole.provider), Icons.bolt, AppTheme.secondaryColor),
                      _buildMockChip("Demo Plumber", () => _autofill("amit@superplumb.com", UserRole.provider), Icons.water_drop, AppTheme.secondaryColor),
                      _buildMockChip("Demo Admin", () => _autofill("admin@fixora.com", UserRole.admin), Icons.admin_panel_settings, AppTheme.warningColor),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMockChip(String label, VoidCallback onPressed, IconData icon, Color color) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: AppTheme.darkCard.withOpacity(0.4),
      side: BorderSide(color: Colors.white.withOpacity(0.08), width: 1.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onPressed: onPressed,
    );
  }
}

