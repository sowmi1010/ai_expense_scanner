import 'package:shared_preferences/shared_preferences.dart';

class AuthUser {
  final String name;
  final String email;
  final String password;

  const AuthUser({
    required this.name,
    required this.email,
    required this.password,
  });
}

class SignInResult {
  final AuthUser? user;
  final String? errorMessage;

  const SignInResult._({this.user, this.errorMessage});

  bool get isSuccess => user != null;

  factory SignInResult.success(AuthUser user) => SignInResult._(user: user);

  factory SignInResult.failure(String message) =>
      SignInResult._(errorMessage: message);
}

class AuthLocalService {
  static const _nameKey = 'auth_user_name';
  static const _emailKey = 'auth_user_email';
  static const _passwordKey = 'auth_user_password';
  static const _isLoggedInKey = 'auth_is_logged_in';

  Future<AuthUser?> getRegisteredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_nameKey);
    final email = prefs.getString(_emailKey);
    final password = prefs.getString(_passwordKey);

    if (name == null || email == null || password == null) return null;

    return AuthUser(name: name, email: email, password: password);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_emailKey, email.trim().toLowerCase());
    await prefs.setString(_passwordKey, password);
    await prefs.setBool(_isLoggedInKey, false);
  }

  Future<SignInResult> signIn({
    required String email,
    required String password,
  }) async {
    final registeredUser = await getRegisteredUser();

    if (registeredUser == null) {
      return SignInResult.failure('No account found. Please sign up first.');
    }

    final normalizedEmail = email.trim().toLowerCase();
    final isEmailMatch = registeredUser.email == normalizedEmail;
    final isPasswordMatch = registeredUser.password == password;

    if (!isEmailMatch || !isPasswordMatch) {
      return SignInResult.failure('Invalid email or password.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);

    return SignInResult.success(registeredUser);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, false);
  }
}
