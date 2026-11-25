import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enums/user_role.dart';

class UserRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() => UserRole.client;

  void setRole(UserRole role) {
    state = role;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, UserRole>(
  UserRoleNotifier.new,
);
