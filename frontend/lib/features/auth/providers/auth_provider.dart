import 'package:flutter/foundation.dart';
import 'package:trill_covoit/exceptions/auth_exception.dart';
import 'package:trill_covoit/models/auth_session.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService;

  AuthProvider({AuthApiService? apiService})
      : _apiService = apiService ?? AuthApiService();

  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String? _pendingVerificationEmail;

  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void setPendingVerificationEmail(String? email) {
    _pendingVerificationEmail = email;
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required bool termsAccepted,
  }) async {
    _setLoading(true);
    _clearMessagesInternal();

    try {
      final msg = await _apiService.register(
        email: email,
        password: password,
        termsAccepted: termsAccepted,
      );
      _successMessage = msg;
      _pendingVerificationEmail = email;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    _setLoading(true);
    _clearMessagesInternal();

    try {
      final msg = await _apiService.verifyEmail(email: email, code: code);
      _successMessage = msg;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearMessagesInternal();

    try {
      final session = await _apiService.login(email: email, password: password);
      _currentSession = session;
      _pendingVerificationEmail = null;
      _setLoading(false);
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      if (e.statusCode == 403) {
        _pendingVerificationEmail = email;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Une erreur inattendue est survenue.';
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentSession = null;
    _clearMessagesInternal();
    _pendingVerificationEmail = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessagesInternal() {
    _errorMessage = null;
    _successMessage = null;
  }
}
