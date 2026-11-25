import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/core/api/auth_api.dart';
import 'package:pm/l10n/generated/L10n.dart';
import 'package:pm/shared/widgets/app_dialogs.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'otp_page.dart';
import '../../../../shared/widgets/app_toast.dart';

class PhoneNumberPage extends ConsumerStatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  ConsumerState<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends ConsumerState<PhoneNumberPage> {
  final _phoneController = TextEditingController();

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

  void _showAboutDialog() {
    final l10n = L10n.of(context);
      AppDialogs.showContent(context, title: l10n.about, content: l10n.aboutContent, okText: l10n.ok);
  }

  void _showPrivacyDialog() {
    final l10n = L10n.of(context);
      AppDialogs.showContent(context, title: l10n.privacy, content: l10n.privacyContent, okText: l10n.ok);
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
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
