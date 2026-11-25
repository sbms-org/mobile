import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:servicebook/l10n/generated/L10n.dart';
import 'core/theme/app_theme.dart';
import 'core/services/secure_storage_service.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/pages/phone_number_page.dart';
import 'features/auth/presentation/pages/root_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await FirebaseNotificationService.initialize();
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'ServiceBook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      localizationsDelegates: const [
        L10n.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('am')],
      home: FutureBuilder<String?>(
        future: SecureStorageService.getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: SizedBox(
                width: 80,
                child: Center(child: LinearProgressIndicator()),
              ),
            );
          }

          final hasToken = snapshot.data != null;
          return hasToken ? const RootPage() : const PhoneNumberPage();
        },
      ),
    );
  }
}
