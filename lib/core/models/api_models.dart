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

class Building {
  final String id;
  final String name;
  final String propertyType;
  final String? address;
  final String? city;
  final String? stateOrProvince;
  final String? country;
  final int? totalFloors;
  final int totalUnits;
  final String status;
  final String? propertyDeedUrl;
  final String? certificateOfTitleUrl;
  final String? businessTinNumberUrl;
  final String? rejectionReason;
  final int? paymentCycleMonths;
  final DateTime createdAt;
  final DateTime updatedAt;

  Building({
    required this.id,
    required this.name,
    required this.propertyType,
    this.address,
    this.city,
    this.stateOrProvince,
    this.country,
    this.totalFloors,
    required this.totalUnits,
    required this.status,
    this.propertyDeedUrl,
    this.certificateOfTitleUrl,
    this.businessTinNumberUrl,
    this.rejectionReason,
    this.paymentCycleMonths,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse DateTime
    DateTime? parseDateTime(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    return Building(
      id: json['id']?.toString() ?? '',   // fallback to empty string
      name: json['name'] ?? json['building_name'] ?? '',
      propertyType: json['property_type'] ?? 'Residential',
      address: json['address'] ?? json['street_address'],
      city: json['city'],
      stateOrProvince: json['state_or_province'] ?? json['stateOrProvince'],
      country: json['country'],
      totalFloors: json['total_floors'] ?? json['totalFloors'] ?? json['number_of_floors'],
      totalUnits: json['total_units'] ?? json['totalUnits'] ?? json['total_rental_units'] ?? 0,
      status: json['status'] ?? 'PENDING_REVIEW',
      propertyDeedUrl: json['property_deed_url'] ?? json['propertyDeedUrl'],
      certificateOfTitleUrl: json['certificate_of_title_url'] ?? json['certificateOfTitleUrl'],
      businessTinNumberUrl: json['business_tin_number_url'] ?? json['businessTinNumberUrl'],
      rejectionReason: json['rejection_reason'] ?? json['rejectionReason'],
      paymentCycleMonths: json['payment_cycle_months'] ?? json['paymentCycleMonths'],
      createdAt: parseDateTime(json['created_at']) ?? parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updated_at']) ?? parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class Unit {
  final String id;
  final String? assignmentId;
  final String unitNumber;
  final int? floor;
  final double? monthlyRent;
  final double rentAmount;
  final String? size;
  final String? description;
  final String status;
  final String? tenantId;
  final Tenant? tenant;
  final DateTime? nextRentDueDate;
  final int paymentCycleMonths;
  final bool isRentDue;
  final String buildingId;
  final Building? building;

  Unit({
    required this.id,
    this.assignmentId,
    required this.unitNumber,
    required this.rentAmount,
    this.floor,
    this.monthlyRent,
    this.size,
    this.description,
    required this.status,
    this.tenantId,
    this.tenant,
    this.nextRentDueDate,
    required this.paymentCycleMonths,
    required this.isRentDue,
    required this.buildingId,
    required this.building,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    // Helper to safely parse double
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    // Helper to parse DateTime safely
    DateTime? parseDateTime(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    // Extract fields with fallbacks
    String id = json['id']?.toString() ?? '';  // fallback to empty string
    String? assignmentId = json['assignmentId']?.toString() ?? json['assignment_id']?.toString();
    String unitNumber = json['unit_number']?.toString() ?? json['unitNumber']?.toString() ?? '';
    double rentAmount = parseDouble(json['total_rent_amount']) ?? parseDouble(json['rentAmount']) ?? 0.0;
    double? monthlyRent = parseDouble(json['rent_amount']) ?? parseDouble(json['monthlyRent']);
    int? floor = json['floor'] as int?;
    String? size = json['size']?.toString();
    String? description = json['description']?.toString();
    String status = json['status']?.toString() ?? 'vacant';
    String? tenantId = json['tenant_id']?.toString() ?? json['tenantId']?.toString();
    DateTime? nextRentDueDate = parseDateTime(json['next_rent_due_date']) ?? parseDateTime(json['nextRentDueDate']);
    int paymentCycleMonths = json['payment_cycle_months'] as int? ?? json['paymentCycleMonths'] as int? ?? 3;
    bool isRentDue = json['is_rent_due'] as bool? ?? json['isRentDue'] as bool? ?? false;
    
    // buildingId might come from building.id or directly
    String buildingId = '';
    Building? building;
    if (json['building'] != null) {
      building = Building.fromJson(json['building']);
      buildingId = building?.id ?? '';
    } else {
      buildingId = json['building_id']?.toString() ?? json['buildingId']?.toString() ?? '';
    }

    // Tenant from json['tenant'] if present
    Tenant? tenant;
    if (json['tenant'] != null) {
      tenant = Tenant.fromJson(json['tenant']);
    }

    return Unit(
      id: id,
      assignmentId: assignmentId,
      unitNumber: unitNumber,
      floor: floor,
      rentAmount: rentAmount,
      monthlyRent: monthlyRent,
      size: size,
      description: description,
      status: status,
      tenantId: tenantId,
      tenant: tenant,
      nextRentDueDate: nextRentDueDate,
      paymentCycleMonths: paymentCycleMonths,
      isRentDue: isRentDue,
      buildingId: buildingId,
      building: building,
    );
  }
}

class Tenant {
  final String id;
  final String fullname;
  final String mobile;
  final String? email;

  Tenant({
    required this.id,
    required this.fullname,
    required this.mobile,
    this.email,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id']?.toString() ?? '',
      fullname: json['fullname']?.toString() ?? json['name']?.toString() ?? 'Unknown',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
    );
  }
}

class Receipt {
  final String id;
  final String receiptUrl;
  final String status;
  final String? notes;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Tenant? tenant;
  final Unit? unit;

  Receipt({
    required this.id,
    required this.receiptUrl,
    required this.status,
    this.notes,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
    this.tenant,
    this.unit,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    // Helper to parse DateTime safely
    DateTime? parseDateTime(String? value) {
      if (value == null) return null;
      return DateTime.tryParse(value);
    }

    return Receipt(
      id: json['id']?.toString() ?? '',
      receiptUrl: json['receiptUrl']?.toString() ?? json['receipt_url']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDING',
      notes: json['notes']?.toString(),
      rejectionReason: json['rejectionReason']?.toString() ?? json['rejection_reason']?.toString(),
      createdAt: parseDateTime(json['createdAt']) ?? parseDateTime(json['created_at']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? parseDateTime(json['updated_at']),
      tenant: json['tenant'] != null ? Tenant.fromJson(json['tenant']) : null,
      unit: json['unit'] != null ? Unit.fromJson(json['unit']) : null,
    );
  }
}

class PaymentHistory {
  final String id;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String? paymentMethod;
  final String? receiptUrl;
  final String? notes;
  final Tenant tenant;
  final PaymentUnit unit;
  final PaymentBuilding building;

  PaymentHistory({
    required this.id,
    required this.amount,
    required this.dueDate,
    required this.paidDate,
    this.paymentMethod,
    this.receiptUrl,
    this.notes,
    required this.tenant,
    required this.unit,
    required this.building,
  });

  // factory PaymentHistory.fromJson(Map<String, dynamic> json) {
  //   return PaymentHistory(
  //     id: json['id'],
  //     amount: double.tryParse(json['amount'].toString()) ?? 0.0,
  //     dueDate: DateTime.parse(json['due_date']),
  //     paidDate: DateTime.parse(json['paid_date']),
  //     paymentMethod: json['payment_method'],
  //     receiptUrl: json['receipt_url'],
  //     notes: json['notes'],
  //     tenant: Tenant.fromJson(json['tenant']),
  //     unit: PaymentUnit.fromJson(json['unit']),
  //     building: PaymentBuilding.fromJson(json['building']),
  //   );
  // }

  factory PaymentHistory.fromJson(Map<String, dynamic> json) {
  return PaymentHistory(
    id: json['id']?.toString() ?? '', // Safe string conversion
    amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
    dueDate: json['due_date'] != null 
        ? DateTime.parse(json['due_date']) 
        : DateTime.now(), // Fallback for required DateTime
    paidDate: json['paid_date'] != null 
        ? DateTime.parse(json['paid_date']) 
        : null,
    paymentMethod: json['payment_method'], // Already nullable String?
    receiptUrl: json['receipt_url'],       // Already nullable String?
    notes: json['notes'],                 // Already nullable String?
    // Safe nested parsing:
    tenant: Tenant.fromJson(json['tenant'] ?? {}), 
    unit: PaymentUnit.fromJson(json['unit'] ?? {}),
    building: PaymentBuilding.fromJson(json['building'] ?? {}),
  );
}

}

class PaymentUnit {
  final String id;
  final String unitNumber;
  final double rentAmount;
  final int paymentCycleMonths;

  PaymentUnit({
    required this.id,
    required this.unitNumber,
    required this.rentAmount,
    required this.paymentCycleMonths,
  });

  // factory PaymentUnit.fromJson(Map<String, dynamic> json) {
  //   return PaymentUnit(
  //     id: json['id'],
  //     unitNumber: json['unit_number'],
  //     rentAmount: (json['rent_amount'] as num).toDouble(),
  //     paymentCycleMonths: json['payment_cycle_months'] ?? 3,
  //   );
  // }

  factory PaymentUnit.fromJson(Map<String, dynamic> json) {
  return PaymentUnit(
    // 1. Ensure String conversion and provide fallback for nulls
    id: json['id']?.toString() ?? '', 
    unitNumber: json['unit_number']?.toString() ?? 'N/A',
    
    // 2. Safe num parsing (handles both "100" and 100)
    rentAmount: double.tryParse(json['rent_amount']?.toString() ?? '0') ?? 0.0,
    
    // 3. Int fallback
    paymentCycleMonths: json['payment_cycle_months'] ?? 3,
  );
}
}

class PaymentBuilding {
  final String name;

  PaymentBuilding({required this.name});

  factory PaymentBuilding.fromJson(Map<String, dynamic> json) {
    return PaymentBuilding(name: json['name']?.toString() ?? 'Unnamed Building');
  }
}

class TenantSummary {
  final String id;
  final String? fullname;
  final String? mobile;
  final String? email;
  final int unitCount;
  final double totalUnitsRent;
  final double totalRent;
  final int paymentCycle;
  final bool hasDueRent;
  final List<TenantUnit>? units;

  TenantSummary({
    required this.id,
    this.fullname,
    this.mobile,
    this.email,
    required this.unitCount,
    required this.totalRent,
    required this.totalUnitsRent,
    required this.paymentCycle,
    required this.hasDueRent,
   this.units,
  });

  factory TenantSummary.fromJson(Map<String, dynamic> json) {
    return TenantSummary(
      id: json['id'],
      fullname: json['fullname'] ?? 'Unknown Tenant',
      mobile: json['mobile'] ?? 'N/A',
      email: json['email'],
      unitCount: json['unitCount'] ?? 0,
      totalUnitsRent: (json['totalUnitsRent'] as num? ?? 0.0).toDouble(),
      totalRent: (json['totalRent'] as num? ?? 0.0).toDouble(),
      paymentCycle: json['paymentCycle'] ?? (json['payment_cycle_months'] ?? 0),
      hasDueRent: json['hasDueRent'] ?? false,
      units: json['units'] == null 
        ? [] 
        : (json['units'] as List).map((e) => TenantUnit.fromJson(e)).toList(),
    );
  }
}

class TenantUnit {
  final String id;
  final String unitNumber;
  final String buildingName;
  final double? rentAmount;
  final DateTime? nextRentDueDate;

  TenantUnit({
    required this.id,
    required this.unitNumber,
    required this.buildingName,
    this.rentAmount,
    this.nextRentDueDate,
  });

  factory TenantUnit.fromJson(Map<String, dynamic> json) {
    return TenantUnit(
      id: json['id'] ?? '',
      unitNumber: json['unit_number'] ?? 'N/A',
      buildingName: json['building'] != null 
        ? json['building']['name'] ?? 'Unknown Building' 
        : 'Unknown Building',
      rentAmount: json['rent_amount'] != null
          ? (json['rent_amount'] as num).toDouble()
          : null,
      nextRentDueDate: json['next_rent_due_date'] != null
          ? DateTime.parse(json['next_rent_due_date'])
          : null,
    );
  }
}

class PropertyManager {
  final String id;
  final String fullname;
  final String mobile;
  final String? email;
  final String status;
  final List<PropertyManagerAssignment>? assignments;

  PropertyManager({
    required this.id,
    required this.fullname,
    required this.mobile,
    this.email,
    required this.status,
    this.assignments,
  });

  factory PropertyManager.fromJson(Map<String, dynamic> json) {
    return PropertyManager(
      id: json['id'],
      fullname: json['fullname'] ?? '',
      mobile: json['mobile'],
      email: json['email'],
      status: json['status'] ?? 'ACTIVE',
      assignments: json['assignments'] != null
          ? (json['assignments'] as List)
                .map((e) => PropertyManagerAssignment.fromJson(e))
                .toList()
          : null,
    );
  }
}

class PropertyManagerAssignment {
  final String buildingId;
  final String buildingName;
  final Map<String, bool> permissions;

  PropertyManagerAssignment({
    required this.buildingId,
    required this.buildingName,
    required this.permissions,
  });

  factory PropertyManagerAssignment.fromJson(Map<String, dynamic> json) {
    return PropertyManagerAssignment(
      buildingId: json['buildingId'],
      buildingName: json['buildingName'],
      permissions: Map<String, bool>.from(json['permissions'] ?? {}),
    );
  }
}

/// Dashboard statistics returned by /owner/dashboard or /pm/dashboard
class DashboardStats {
  final int totalBuildings;
  final int totalUnits;
  final int occupiedUnits;
  final int vacantUnits;
  final int maintenanceUnits;
  final double occupancyRate;
  final int pendingReceipts;
  final double totalRevenue;
  final double collectedThisMonth;
  final int overduePayments;
  final double overdueAmount;

  DashboardStats({
    required this.totalBuildings,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.vacantUnits,
    required this.maintenanceUnits,
    required this.occupancyRate,
    required this.pendingReceipts,
    required this.totalRevenue,
    required this.collectedThisMonth,
    required this.overduePayments,
    required this.overdueAmount,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalBuildings: json['totalBuildings'] ?? 0,
      totalUnits: json['totalUnits'] ?? 0,
      occupiedUnits: json['occupiedUnits'] ?? 0,
      vacantUnits: json['vacantUnits'] ?? 0,
      maintenanceUnits: json['maintenanceUnits'] ?? 0,
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      pendingReceipts: json['pendingReceipts'] ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      collectedThisMonth: (json['collectedThisMonth'] as num?)?.toDouble() ?? 0.0,
      overduePayments: json['overduePayments'] ?? 0,
      overdueAmount: (json['overdueAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory DashboardStats.empty() => DashboardStats(
    totalBuildings: 0,
    totalUnits: 0,
    occupiedUnits: 0,
    vacantUnits: 0,
    maintenanceUnits: 0,
    occupancyRate: 0,
    pendingReceipts: 0,
    totalRevenue: 0,
    collectedThisMonth: 0,
    overduePayments: 0,
    overdueAmount: 0,
  );
}

/// A single building-permission pair that a PM sees in their profile
class PmBuildingPermission {
  final String buildingId;
  final String buildingName;
  final String buildingType;
  final bool canViewDashboard;
  final bool canManageUnits;
  final bool canManageTenants;
  final bool canManageReceipts;
  final bool canExportReports;

  PmBuildingPermission({
    required this.buildingId,
    required this.buildingName,
    required this.buildingType,
    required this.canViewDashboard,
    required this.canManageUnits,
    required this.canManageTenants,
    required this.canManageReceipts,
    required this.canExportReports,
  });

  factory PmBuildingPermission.fromJson(Map<String, dynamic> json) {
    final perms = (json['permissions'] as Map<String, dynamic>?) ?? {};
    return PmBuildingPermission(
      buildingId: json['buildingId'] ?? '',
      buildingName: json['buildingName'] ?? '',
      buildingType: json['buildingType'] ?? 'Residential',
      canViewDashboard: perms['can_view_dashboard'] ?? true,
      canManageUnits: perms['can_manage_units'] ?? true,
      canManageTenants: perms['can_manage_tenants'] ?? true,
      canManageReceipts: perms['can_manage_receipts'] ?? true,
      canExportReports: perms['can_export_reports'] ?? true,
    );
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
