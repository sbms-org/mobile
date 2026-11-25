import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pm/l10n/generated/L10n.dart';
import '../../../../shared/widgets/curved_header.dart';
import 'phone_number_page.dart';

class WaitingApprovalPage extends StatefulWidget {
  const WaitingApprovalPage({super.key});

  @override
  State<WaitingApprovalPage> createState() => _WaitingApprovalPageState();
}

class _WaitingApprovalPageState extends State<WaitingApprovalPage> {
  @override
  void initState() {
    super.initState();
    // auto-return to phone page after a short delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PhoneNumberPage()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CurvedSection(
            height: 300,
            title: L10n.of(context).appTitle,
            subtitle: L10n.of(context).pendingReview,
            child: const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Icon(Icons.hourglass_bottom_rounded, size: 64, color: Colors.white),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(L10n.of(context).yourAccountPending, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(
                  L10n.of(context).tryLoggingInLater,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const PhoneNumberPage()),
                      (r) => false,
                    ),
                    child: Text(L10n.of(context).ok),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
