class User {
  final String id;
  final String mobile;
  final String? fullname;
  final String? role;
  final String? email;
  final bool? accountStatus;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.mobile,
    this.fullname,
    this.role,
    this.email,
    this.accountStatus,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      mobile: json['mobile'],
      fullname: json['fullname'],
      role: json['role'],
      email: json['email'],
      accountStatus: json['account_status'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobile': mobile,
      if (fullname != null) 'fullname': fullname,
      if (role != null) 'role': role,
      if (email != null) 'email': email,
      if (accountStatus != null) 'account_status': accountStatus,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }
}

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      error: json['error'],
      statusCode: json['statusCode'],
    );
  }
}
