import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pm/core/api/auth_api.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'otp_page.dart';

class RegisterOwnerPage extends ConsumerStatefulWidget {
  const RegisterOwnerPage({super.key});

  @override
  ConsumerState<RegisterOwnerPage> createState() => _RegisterOwnerPageState();
}

class _RegisterOwnerPageState extends ConsumerState<RegisterOwnerPage> {
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      AppToast.error(context, L10n.of(context).fullNameRequired);
      return;
    }

    final validationError = AuthApi.validatePhoneNumber(phone);
    if (validationError != null) {
      AppToast.error(context, validationError);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final formatted = AuthApi.formatPhoneNumber(phone);
      final response = await AuthApi.registerOwner(formatted, name);
      if (response.success) {
        AppToast.success(context, L10n.of(context).otpSent);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              phoneNumber: formatted,
              isRegistration: true,
            ),
          ),
        );
      } else {
        AppToast.error(context, response.message);
      }
    } on PhoneValidationException catch (e) {
      AppToast.error(context, e.message);
    } on AccountException catch (e) {
      if (e.code == 'ALEARDY_EXISTS') {
        AppToast.error(context, L10n.of(context).phoneRegisteredAdmin);
      } else if (e.code == 'ACCOUNT_PENDING') {
        AppToast.error(context, L10n.of(context).yourAccountPending);
      } else if (e.code == 'ACCOUNT_INACTIVE') {
        AppToast.error(context, L10n.of(context).accountInactive);
      } else {
        AppToast.error(context, e.message);
      }
    } catch (e) {
      AppToast.error(context, L10n.of(context).genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 320,
              showBackButton: true,
              title: l10n.registerAsOwner,
              subtitle: l10n.enterDetails,
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 64,
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
                  Text(l10n.registerAsOwner, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),

                  // Full name
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: l10n.fullName,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Phone
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                          child: Text('+251', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        Container(width: 1, height: 30, color: Colors.grey.shade300),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              counterText: '',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              hintText: l10n.phoneNumberHint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: _isLoading ? const CircularProgressIndicator() : Text(l10n.sendOtp),
                    ),
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
