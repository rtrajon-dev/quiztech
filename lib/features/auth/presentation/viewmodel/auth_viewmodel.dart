import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Firebase-backed auth.
///
/// State is driven by Firebase's own [FirebaseAuth.authStateChanges] stream:
/// it fires once on launch with the restored (cached) session, and again on
/// every sign-in / sign-out. Firebase persists the session itself, so no
/// SharedPreferences flag is needed anymore.
class AuthViewModel extends Notifier<AuthState> {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  AuthState build() {
    final sub = _auth.authStateChanges().listen(_onAuthChanged);
    ref.onDispose(sub.cancel);
    return const AuthState();
  }

  void _onAuthChanged(User? user) {
    state = state.copyWith(
      isInitialized: true,
      user: user == null ? null : _buildUser(user),
      clearUser: user == null,
    );
  }

  /// Sign in an existing account. Throws [FirebaseAuthException] on failure.
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // No manual state set: authStateChanges() pushes the user for us.
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Create a new account. Throws [FirebaseAuthException] on failure.
  Future<void> register(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Send a password-reset email. Throws [FirebaseAuthException] on failure.
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> logout() async {
    await _auth.signOut(); // authStateChanges() clears the user.
  }

  /// Maps a Firebase [User] into the existing `{ 'user': { ... } }` shape so
  /// ProfileScreen and the rest of the app keep working without edits.
  Map<String, dynamic> _buildUser(User user) {
    final email = user.email ?? '';
    final namePart = email.contains('@') ? email.split('@').first : email;
    final fullName = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : (namePart.isEmpty
            ? 'Quiz User'
            : namePart[0].toUpperCase() + namePart.substring(1));

    return {
      'user': {
        'fullName': fullName,
        'email': email,
        'role': 'Player',
        'status': 'Active',
        'profileImg': user.photoURL ?? '',
      },
    };
  }
}

final authViewModelProvider =
    NotifierProvider<AuthViewModel, AuthState>(AuthViewModel.new);
