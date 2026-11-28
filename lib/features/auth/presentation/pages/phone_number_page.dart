import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servicebook/core/api/auth_api.dart';
import 'package:servicebook/l10n/generated/L10n.dart';
import 'package:servicebook/shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'otp_page.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/sbms_dump_service.dart';
import '../../../servicebook/presentation/servicebook_home_page.dart';

class PhoneNumberPage extends ConsumerStatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  ConsumerState<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends ConsumerState<PhoneNumberPage> {
  final _phoneController = TextEditingController();
  List<Map<String, dynamic>> _demoAccounts = [];
  String? _demoAccountsError;
  bool _testLoginInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadDemoAccounts();
  }

  Future<void> _loadDemoAccounts() async {
    if (!AppConfig.enableTestTools) return;
    try {
      final response = await AuthApi.getDemoAccounts();
      final accounts = response['users'];
      if (!mounted) return;
      setState(() {
        _demoAccounts = response['demoMode'] == true && accounts is List
            ? accounts.whereType<Map>().map((account) {
                return account.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }).toList()
            : [];
      });
    } catch (_) {
      if (AppConfig.enableTestTools && mounted) {
        try {
          final accounts = await SbmsDumpService.users();
          setState(() => _demoAccounts = accounts);
        } catch (error) {
          setState(() => _demoAccountsError = error.toString());
        }
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final l10n = L10n.of(context);
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      AppToast.error(context, l10n.invalidPhoneNumber);
      return;
    }

    // Use AuthApi validation
    final validationError = AuthApi.validatePhoneNumber(phone);
    if (validationError != null) {
      AppToast.error(context, validationError);
      return;
    }

    // clear previous errors (we show errors via AppToast)

    try {
      // Show loading
      // if (!mounted) return;
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (context) => const Center(child: LinearProgressIndicator()),
      // );

      // Format and send OTP
      final formattedPhone = AuthApi.formatPhoneNumber(phone);
      final response = await AuthApi.sendOtp(formattedPhone);

      if (!mounted) return;
      if (response.success) {
        // Navigate to OTP page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpPage(phoneNumber: formattedPhone),
          ),
        );
      } else {
        AppToast.error(context, response.message);
      }
    } on PhoneValidationException catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.message);
    } on AccountException catch (e) {
      if (!mounted) return;
      if (e.code == 'ACCOUNT_PENDING') {
        AppToast.error(context, l10n.yourAccountPending);
      } else if (e.code == 'ACCOUNT_INACTIVE') {
        AppToast.error(context, l10n.accountInactive);
      } else {
        AppToast.error(context, e.message);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, l10n.genericError);
    }
  }

  Future<void> skipLoginForTesting() async {
    final account = _demoAccounts.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['role'] == 'client',
      orElse: () => _demoAccounts.isEmpty ? null : _demoAccounts.first,
    );
    final mobile = account?['mobile']?.toString();
    if (mobile == null || mobile.isEmpty) {
      AppToast.error(context, 'No demo account is available for testing.');
      return;
    }

    final role = UserRole.fromApiValue(account?['role']?.toString());
    if (role == null) {
      AppToast.error(context, 'The demo account has an unsupported role.');
      return;
    }

    setState(() => _testLoginInProgress = true);
    try {
      final response = await AuthApi.verifyOtp(mobile, '123456');
      if (!mounted) return;
      if (!response.success) {
        AppToast.error(context, response.message);
        return;
      }

      ref.read(userRoleProvider.notifier).setRole(role);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => ServiceBookHomePage(role: role)),
        (_) => false,
      );
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _testLoginInProgress = false);
    }
  }

  void _showAboutDialog() {
    final l10n = L10n.of(context);
    AppDialogs.showContent(
      context,
      title: l10n.about,
      content: l10n.aboutContent,
      okText: l10n.ok,
    );
  }

  void _showPrivacyDialog() {
    final l10n = L10n.of(context);
    AppDialogs.showContent(
      context,
      title: l10n.privacy,
      content: l10n.privacyContent,
      okText: l10n.ok,
    );
  }

  void _showLanguageDialog() {
    AppDialogs.showLanguageSelector(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 380,
              title: 'ServiceBook',
              subtitle: l10n.welcome,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Icon(
                    Icons.handyman_outlined,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcome,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.enterPhoneNumber,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_demoAccounts.isNotEmpty ||
                      _demoAccountsError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DF),
                        border: Border.all(color: const Color(0xFFE6D49B)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Localizations.localeOf(context).languageCode == 'am'
                                ? 'የሙከራ መለያ ይምረጡ'
                                : 'Choose a demo role',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            Localizations.localeOf(context).languageCode == 'am'
                                ? 'የማረጋገጫ ኮድ: 123456'
                                : 'Demo verification code: 123456',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_demoAccounts.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: _demoAccounts.map((account) {
                                final name =
                                    account['fullname']?.toString() ??
                                    'ServiceBook user';
                                final role =
                                    account['role']?.toString().replaceAll(
                                      '_',
                                      ' ',
                                    ) ??
                                    '';
                                final mobile =
                                    account['mobile']?.toString() ?? '';
                                return ActionChip(
                                  label: Text('$name · $role'),
                                  onPressed: () {
                                    _phoneController.text = mobile.replaceFirst(
                                      '+251',
                                      '',
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                          if (_demoAccountsError != null)
                            Text(
                              Localizations.localeOf(context).languageCode ==
                                      'am'
                                  ? 'የሙከራ መለያዎችን ማግኘት አልተቻለም። ${_demoAccountsError!}'
                                  : 'Demo accounts could not be loaded: ${_demoAccountsError!}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),

                  // Phone Input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Country Code
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Text(
                            '+251',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: Colors.grey.shade300,
                        ),

                        // Phone Input
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                            decoration: InputDecoration(
                              hintText: l10n.phoneNumberHint,
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                              counterText: '',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // errors shown with AppToast for better UX
                  const SizedBox(height: 12),
                  Text(
                    l10n.phoneHelper,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),

                  const SizedBox(height: 32),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        l10n.sendOtp,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (AppConfig.enableTestTools) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _testLoginInProgress
                            ? null
                            : skipLoginForTesting,
                        icon: const Icon(Icons.skip_next_outlined),
                        label: Text(
                          _testLoginInProgress
                              ? (Localizations.localeOf(context).languageCode ==
                                        'am'
                                    ? 'በመግባት ላይ…'
                                    : 'Signing in…')
                              : (Localizations.localeOf(context).languageCode ==
                                        'am'
                                    ? 'ለሙከራ ዝለል'
                                    : 'Skip login for testing'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  Center(
                    child: Text(
                      Localizations.localeOf(context).languageCode == 'am'
                          ? 'ለአዲስ መለያ አስተዳዳሪዎን ያነጋግሩ።'
                          : 'For a new account, contact your SBMS administrator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Footer Links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: _showLanguageDialog,
                        icon: const Icon(Icons.language, size: 18),
                        label: Text(l10n.language),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      TextButton.icon(
                        onPressed: _showPrivacyDialog,
                        icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                        label: Text(l10n.privacy),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                      Text('•', style: TextStyle(color: Colors.grey.shade400)),
                      TextButton.icon(
                        onPressed: _showAboutDialog,
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: Text(l10n.about),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
