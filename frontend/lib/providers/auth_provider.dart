import 'package:flutter/foundation.dart';
import 'package:trill_covoit/exceptions/api_exception.dart';
import 'package:trill_covoit/models/auth_session.dart';
import 'package:trill_covoit/services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthApiService _apiService;

  AuthProvider({required AuthApiService apiService}) : _apiService = apiService;

  AuthSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic>? _fieldErrors;
  String? _pendingVerificationEmail;
  int _operationToken = 0;

  AuthSession? get currentSession => _currentSession;
  bool get isAuthenticated => _currentSession != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  Map<String, dynamic>? get fieldErrors => _fieldErrors;
  String? get pendingVerificationEmail => _pendingVerificationEmail;

  void clearMessages() {
    _clearMessagesInternal();
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
    if (_isLoading) return false;

    final token = ++_operationToken;
    _clearMessagesInternal();
    _setLoading(true);

    try {
      final msg = await _apiService.register(
        email: email,
        password: password,
        termsAccepted: termsAccepted,
      );
      if (token != _operationToken) return false;

      _successMessage = msg;
      _pendingVerificationEmail = email;
      return true;
    } on ApiException catch (e) {
      if (token != _operationToken) return false;
      _errorMessage = e.message;
      _fieldErrors = e.fieldErrors;
      return false;
    } catch (_) {
      if (token != _operationToken) return false;
      _errorMessage = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      if (token == _operationToken) {
        _setLoading(false);
      }
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    if (_isLoading) return false;

    final token = ++_operationToken;
    _clearMessagesInternal();
    _setLoading(true);

    try {
      final msg = await _apiService.verifyEmail(email: email, code: code);
      if (token != _operationToken) return false;

      _successMessage = msg;
      return true;
    } on ApiException catch (e) {
      if (token != _operationToken) return false;
      _errorMessage = e.message;
      _fieldErrors = e.fieldErrors;
      return false;
    } catch (_) {
      if (token != _operationToken) return false;
      _errorMessage = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      if (token == _operationToken) {
        _setLoading(false);
      }
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    final token = ++_operationToken;
    _clearMessagesInternal();
    _setLoading(true);

    try {
      final session = await _apiService.login(email: email, password: password);
      if (token != _operationToken) return false;

      _currentSession = session;
      _pendingVerificationEmail = null;
      return true;
    } on ApiException catch (e) {
      if (token != _operationToken) return false;
      _errorMessage = e.message;
      _fieldErrors = e.fieldErrors;
      if (e.statusCode == 403) {
        _pendingVerificationEmail = email;
      }
      return false;
    } catch (_) {
      if (token != _operationToken) return false;
      _errorMessage = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      if (token == _operationToken) {
        _setLoading(false);
      }
    }
  }

  void logout() {
    _operationToken++;
    _currentSession = null;
    _clearMessagesInternal();
    _pendingVerificationEmail = null;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessagesInternal() {
    _errorMessage = null;
    _successMessage = null;
    _fieldErrors = null;
  }
}
