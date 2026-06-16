import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme.dart';
import 'core/providers/global_providers.dart';
import 'core/models/models.dart';
import 'features/auth/presentation/role_selection_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'features/provider/presentation/provider_dashboard_screen.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Fixora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically matches the system theme (Light/Dark)
      home: _getLandingPage(currentUser),
    );
  }

  Widget _getLandingPage(AppUser? user) {
    if (user == null) {
      return const RoleSelectionScreen();
    }
    
    // Redirect according to active user role
    switch (user.role) {
      case UserRole.customer:
        return const HomeScreen();
      case UserRole.provider:
        return const ProviderDashboardScreen();
      case UserRole.admin:
        return const AdminDashboardScreen();
    }
  }
}
