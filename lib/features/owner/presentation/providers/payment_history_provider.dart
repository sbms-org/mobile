import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/owner_api.dart';
import '../../../../core/models/api_models.dart';

final paymentHistoryProvider = FutureProvider.family<List<PaymentHistory>, String>((ref, unitId) async {
  final response = await OwnerApi.getPaymentHistory(unitId);
  if (response.success && response.data != null) {
    return response.data!;
  }
  throw Exception(response.message);
});
