import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/core/utils/logger.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../../core/enums/user_role.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../servicebook/presentation/servicebook_home_page.dart';
import 'role_selection_page.dart';

class RootPage extends ConsumerStatefulWidget {
  const RootPage({super.key});

  @override
  ConsumerState<RootPage> createState() => _RootPageState();
}

class _RootPageState extends ConsumerState<RootPage> {
  bool _showOnboarding = false;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      AppLogger.d('RootPage: Checking onboarding...');
      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      AppLogger.d('RootPage: Has seen onboarding: $hasSeenOnboarding');
      
      if (mounted) {
        if (!hasSeenOnboarding) {
          setState(() {
            _showOnboarding = true;
          });
        } else {
          // Onboarding seen, check role
          final role = await SecureStorageService.getUserRole();
          AppLogger.d('RootPage: Got role: $role');
          setState(() {
            _role = role;
            _showOnboarding = false;
          });
        }
      }
    } catch (e, s) {
      AppLogger.e('RootPage: Error checking onboarding', e, s);
      if (mounted) {
        setState(() {
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return const OnboardingPage();
    }

    if (_role != null) {
      final role = UserRole.fromApiValue(_role);
      if (role != null) return ServiceBookHomePage(role: role);
    }

    return const RoleSelectionPage();
  }
}
