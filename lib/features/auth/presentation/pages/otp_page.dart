import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../core/api/auth_api.dart';
import '../../../../shared/widgets/curved_header.dart';
import '../../../../core/constants/app_colors.dart';
import 'root_page.dart';
import '../../../../shared/widgets/app_toast.dart';
import 'waiting_approval_page.dart';

class OtpPage extends ConsumerStatefulWidget {
  final String phoneNumber;
  final bool isRegistration;
  const OtpPage({super.key, required this.phoneNumber, this.isRegistration = false});

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    
    if (otp.length != 6) {
      AppToast.error(context, L10n.of(context).otpLengthError);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthApi.verifyOtp(widget.phoneNumber, otp);
      
      if (mounted && response.success) {
        // Small delay to ensure storage is written
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const RootPage()),
            (route) => false,
          );
        }
      }
      // else if (mounted && response.code == 'ACCOUNT_PENDING') {
      //   // Small delay to ensure storage is written
      //   await Future.delayed(const Duration(milliseconds: 100));
        
      //   if (mounted) {
      //     Navigator.pushAndRemoveUntil(
      //       context,
      //       MaterialPageRoute(builder: (context) => const WaitingApprovalPage()),
      //       (route) => false,
      //     );
      //   }
      // }
       else {
        if (mounted) {
          AppToast.error(context, response.message);
        }
      }
    } on OtpValidationException catch (e) {
      if (mounted) {
        if (e.code == 'INVALID_OTP') {
          AppToast.error(context, L10n.of(context).invalidOtp);
        } else if (e.code == 'OTP_EXPIRED') {
          AppToast.error(context, L10n.of(context).otpExpired);
        } else {
          AppToast.error(context, e.message);
        }
      }
    } on AccountException catch (e) {
      if (mounted) {
        // pending approval -> show waiting page then return to phone screen
        if (e.code == 'ACCOUNT_PENDING') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const WaitingApprovalPage()),
          );
          return;
        }

        // inactive accounts get a special message
        if (e.code == 'ACCOUNT_INACTIVE') {
          AppToast.error(context, L10n.of(context).accountInactive);
        } else {
          AppToast.error(context, e.message);
        }
      }
    } catch (e) {
      if (mounted) AppToast.error(context, L10n.of(context).genericError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CurvedSection(
              height: 380,
              showBackButton: true,
              title: widget.isRegistration ? l10n.registerAsOwner : l10n.verification,
              subtitle: l10n.otpSent,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Icon(
                    widget.isRegistration ? Icons.person_add_alt_1_rounded : Icons.security_rounded,
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
                    l10n.otpSent,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.enterOtp} ${widget.phoneNumber}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (widget.isRegistration) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.otpRegistrationInfo,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  Center(
                    child: Pinput(
                      length: 6,
                      controller: _otpController,
                      defaultPinTheme: defaultPinTheme,
                      enabled: !_isLoading,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: AppColors.primary),
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: Colors.red),
                        ),
                      ),
                      onCompleted: (_) => _verifyOtp(),
                    ),
                  ),
                  // errors shown via AppToast for better UX
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      child: _isLoading
                          ? Center(
                            child: const SizedBox(
                                height: 20,
                                width: 20,
                                child: LinearProgressIndicator(),
                              ),
                          )
                          : Text(l10n.verify),
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
