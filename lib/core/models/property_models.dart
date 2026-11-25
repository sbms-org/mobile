class Building {
  final String id;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final String? country;
  final int? totalFloors;
  final int totalUnits;
  final int paymentCycleMonths;
  final double? defaultRentAmount;
  final String status;
  final bool isActive;

  Building({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.country,
    this.totalFloors,
    required this.totalUnits,
    this.paymentCycleMonths = 3,
    this.defaultRentAmount,
    this.status = 'APPROVED',
    this.isActive = true,
  });
}

class Unit {
  final String id;
  final String unitNumber;
  final int? floor;
  final double? rentAmount;
  final String? size;
  final String? description;
  final String status; // 'vacant', 'occupied', 'maintenance'
  final String? tenantId;
  final String? tenantName;
  final String? tenantPhone;
  final DateTime? nextRentDueDate;
  final int paymentCycleMonths;
  final String buildingId;

  Unit({
    required this.id,
    required this.unitNumber,
    this.floor,
    this.rentAmount,
    this.size,
    this.description,
    this.status = 'vacant',
    this.tenantId,
    this.tenantName,
    this.tenantPhone,
    this.nextRentDueDate,
    this.paymentCycleMonths = 3,
    required this.buildingId,
  });

  bool get isRentDue {
    if (nextRentDueDate == null) return false;
    return DateTime.now().isAfter(nextRentDueDate!);
  }
}
