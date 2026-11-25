import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/onboarding_service.dart';
import '../../../auth/presentation/pages/phone_number_page.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  Future<void> _continue(BuildContext context) async {
    await OnboardingService.setOnboardingSeen();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PhoneNumberPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAmharic = Localizations.localeOf(context).languageCode == 'am';
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.78),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.handyman_outlined,
                  size: 88,
                  color: Colors.white,
                ),
                const SizedBox(height: 32),
                Text(
                  isAmharic
                      ? 'ServiceBook አገልግሎቶችን ያገናኛል'
                      : 'Find trusted local services',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isAmharic
                      ? 'በአቅራቢያ አገልግሎት ያግኙ፣ ቦታ ይያዙ እና የስራ ጥያቄዎን በፈቃድዎ ያጋሩ።'
                      : 'Discover nearby providers, manage bookings and share work requests with your consent.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.94),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: () => _continue(context),
                    child: Text(isAmharic ? 'ጀምር' : 'Get started'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
