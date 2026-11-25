class OwnerPaymentMethod {
  final String id;
  final String paymentMethodId;
  final String paymentMethodName;
  final String paymentMethodType;
  final String? bankName;
  final String? accountNumber;
  final String? accountName;
  final String? mobileNumber;
  final String? additionalInfo;
  final bool isActive;
  final DateTime createdAt;

  OwnerPaymentMethod({
    required this.id,
    required this.paymentMethodId,
    required this.paymentMethodName,
    required this.paymentMethodType,
    this.bankName,
    this.accountNumber,
    this.accountName,
    this.mobileNumber,
    this.additionalInfo,
    required this.isActive,
    required this.createdAt,
  });

  factory OwnerPaymentMethod.fromJson(Map<String, dynamic> json) {
    return OwnerPaymentMethod(
      id: json['id'] ?? '',
      paymentMethodId: json['paymentMethodId'] ?? '',
      paymentMethodName: json['paymentMethodName'] ?? json['name'] ?? '',
      paymentMethodType: json['paymentMethodType'] ?? json['type'] ?? '',
      bankName: json['bankName'] ?? json['bank_name'],
      accountNumber: json['accountNumber'] ?? json['account_number'],
      accountName: json['accountName'] ?? json['account_name'],
      mobileNumber: json['mobileNumber'] ?? json['mobile_number'],
      additionalInfo: json['additionalInfo'] ?? json['instructions'],
      isActive: json['isActive'] is bool
          ? json['isActive']
          : json['isActive'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'paymentMethodType': paymentMethodType,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'mobileNumber': mobileNumber,
      'additionalInfo': additionalInfo,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AvailablePaymentMethod {
  final String id;
  final String name;
  final String type;
  final String? bankName;
  final String? provider;
  final String? instructions;
  final String? accountNumberHint;
  final String? accountNameHint;
  final String? mobileNumberHint;
  final String? accountNumber;
  final String? accountName;
  final String? mobileNumber;
  final bool isActive;

  AvailablePaymentMethod({
    required this.id,
    required this.name,
    required this.type,
    this.bankName,
    this.provider,
    this.instructions,
    this.accountNumberHint,
    this.accountNameHint,
    this.mobileNumberHint,
    this.accountNumber,
    this.accountName,
    this.mobileNumber,
    required this.isActive,
  });

  factory AvailablePaymentMethod.fromJson(Map<String, dynamic> json) {
    return AvailablePaymentMethod(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      bankName: json['bankName'] ?? json['bank_name'],
      provider: json['provider'],
      instructions: json['instructions'],
      accountNumberHint:
          json['accountNumberHint'] ?? json['account_number_hint'],
      accountNameHint: json['accountNameHint'] ?? json['account_name_hint'],
      mobileNumberHint: json['mobileNumberHint'] ?? json['mobile_number_hint'],
      accountNumber: json['accountNumber'],
      accountName: json['accountName'],
      mobileNumber: json['mobileNumber'],
      isActive: json['isActive'] ?? json['is_active'] ?? true,
    );
  }
}
