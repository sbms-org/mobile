enum UserRole {
  client,
  individualProvider,
  companyStaff,
  broker,
  supportAgent,
  administrator;

  static UserRole? fromApiValue(String? value) {
    switch (value?.toLowerCase().replaceAll('-', '_')) {
      case 'client':
        return UserRole.client;
      case 'provider':
      case 'individual_provider':
      case 'service_provider':
        return UserRole.individualProvider;
      case 'company_staff':
      case 'company':
        return UserRole.companyStaff;
      case 'broker':
        return UserRole.broker;
      case 'support_agent':
      case 'support':
        return UserRole.supportAgent;
      case 'admin':
      case 'administrator':
        return UserRole.administrator;
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
      case UserRole.administrator:
        return 'administrator';
    }
  }
}
