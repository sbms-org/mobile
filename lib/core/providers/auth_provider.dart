import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api_models.dart';
import '../api/auth_api.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _loadUser();
    return AuthState();
  }

  Future<void> _loadUser() async {
    final user = await AuthApi.getCurrentUser();
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  Future<bool> sendOtp(String mobile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await AuthApi.sendOtp(mobile);
      state = state.copyWith(isLoading: false);
      return response.success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> verifyOtp(String mobile, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await AuthApi.verifyOtp(mobile, otp);
      if (response.success && response.data != null) {
        final user = User.fromJson(response.data!['user']);
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      state = state.copyWith(isLoading: false, error: response.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await AuthApi.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
