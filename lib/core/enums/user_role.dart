enum UserRole {
  client,
  individualProvider,
  companyStaff,
  broker,
  supportAgent,
  admin;

  static UserRole? fromApiValue(String? value) {
    switch (value?.toLowerCase().replaceAll('-', '_')) {
      case 'client':
        return UserRole.client;
      case 'individual_provider':
        return UserRole.individualProvider;
      case 'company_staff':
        return UserRole.companyStaff;
      case 'broker':
        return UserRole.broker;
      case 'support_agent':
        return UserRole.supportAgent;
      case 'admin':
        return UserRole.admin;
      default:
        return null;
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.client:
        return 'client';
      case UserRole.individualProvider:
        return 'individual_provider';
      case UserRole.companyStaff:
        return 'company_staff';
      case UserRole.broker:
        return 'broker';
      case UserRole.supportAgent:
        return 'support_agent';
      case UserRole.admin:
        return 'admin';
    }
  }
}
