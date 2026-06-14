import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable auth state surfaced to the UI.
class AuthState {
  final bool isInitialized;
  final bool isLoading;

  /// Mirrors the original API shape: `{ 'user': { ... } }`.
  final Map<String, dynamic>? user;

  const AuthState({
    this.isInitialized = false,
    this.isLoading = false,
    this.user,
  });

  bool get isLoggedIn => user != null;

  AuthState copyWith({
    bool? isInitialized,
    bool? isLoading,
    Map<String, dynamic>? user,
    bool clearUser = false,
  }) {
    return AuthState(
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : (user ?? this.user),
    );
  }
}

/// Blank/offline auth.
///
/// There is no backend: any non-empty credential pair is accepted and a fake
/// user profile is synthesized from the email. The session flag and the email
/// are persisted in [SharedPreferences] so a relaunch keeps the user signed in.
class AuthViewModel extends Notifier<AuthState> {
  static const _kLoggedIn = 'auth_logged_in';
  static const _kEmail = 'auth_email';

  @override
  AuthState build() {
    _restoreSession();
    return const AuthState();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool(_kLoggedIn) ?? false;
    final email = prefs.getString(_kEmail);

    if (loggedIn && email != null) {
      state = state.copyWith(
        isInitialized: true,
        user: _buildUser(email),
      );
    } else {
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Accepts any credentials. No network call is made.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);

    // Simulate a brief auth round-trip so the spinner is visible.
    await Future.delayed(const Duration(milliseconds: 400));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kEmail, email);

    state = state.copyWith(isLoading: false, user: _buildUser(email));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLoggedIn);
    await prefs.remove(_kEmail);
    state = state.copyWith(clearUser: true);
  }

  Map<String, dynamic> _buildUser(String email) {
    final namePart = email.contains('@') ? email.split('@').first : email;
    final fullName = namePart.isEmpty
        ? 'Quiz User'
        : namePart[0].toUpperCase() + namePart.substring(1);

    return {
      'user': {
        'fullName': fullName,
        'email': email,
        'role': 'Player',
        'status': 'Active',
        'profileImg': '',
      },
    };
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
