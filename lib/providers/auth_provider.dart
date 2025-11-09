import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

final appAuthServiceProvider = Provider<AppAuthService>((ref) {
  return AppAuthService(FirebaseAuth.instance);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final service = ref.watch(appAuthServiceProvider);
  return service.authStateChanges();
});

class AuthFlowState {
  const AuthFlowState({
    this.isLoading = false,
    this.errorMessage,
    this.codeSent = false,
    this.verificationId,
    this.resendToken,
    this.isPhoneVerified = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool codeSent;
  final String? verificationId;
  final int? resendToken;
  final bool isPhoneVerified;

  AuthFlowState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? codeSent,
    String? verificationId,
    int? resendToken,
    bool? isPhoneVerified,
  }) {
    return AuthFlowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      codeSent: codeSent ?? this.codeSent,
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
    );
  }

  static AuthFlowState initial() => const AuthFlowState();
}

class AuthController extends StateNotifier<AuthFlowState> {
  AuthController(this._ref) : super(AuthFlowState.initial());

  final Ref _ref;

  AppAuthService get _service => _ref.read(appAuthServiceProvider);

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential =
          await _service.signInWithEmail(email: email, password: password);
      await _ensureUserProfile(
        credential.user,
        fallbackName: email.split('@').first,
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Не удалось выполнить вход. Попробуйте ещё раз.',
      );
    }
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential =
          await _service.registerWithEmail(email: email, password: password);
      await _ensureUserProfile(
        credential.user,
        fallbackName: email.split('@').first,
      );
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Не удалось зарегистрироваться. Попробуйте ещё раз.',
      );
    }
  }

  Future<void> sendPhoneCode(String phoneNumber) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final normalized = phoneNumber.trim();
    try {
      await _service.verifyPhoneNumber(
        phoneNumber: normalized,
        forceResendingToken: state.resendToken,
        verificationCompleted: (credential) async {
          final result =
              await _service.instance.signInWithCredential(credential);
          await _ensureUserProfile(
            result.user,
            fallbackName: result.user?.phoneNumber,
          );
          state = state.copyWith(isLoading: false, isPhoneVerified: true);
        },
        verificationFailed: (error) {
          state = state.copyWith(
            isLoading: false,
            errorMessage: error.message ?? 'Не удалось отправить код.',
          );
        },
        codeSent: (verificationId, resendToken) {
          state = state.copyWith(
            isLoading: false,
            codeSent: true,
            verificationId: verificationId,
            resendToken: resendToken,
          );
        },
        codeAutoRetrievalTimeout: (verificationId) {
          state = state.copyWith(
            verificationId: verificationId,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка при отправке кода. Попробуйте ещё раз.',
      );
    }
  }

  Future<void> verifySmsCode(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null) {
      state = state.copyWith(
        errorMessage: 'Сначала отправьте код подтверждения.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final credential = await _service.verifySmsCode(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      await _ensureUserProfile(
        credential.user,
        fallbackName: credential.user?.phoneNumber,
      );
      state = state.copyWith(
        isLoading: false,
        isPhoneVerified: true,
      );
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapFirebaseAuthError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Неверный код. Повторите попытку.',
      );
    }
  }

  Future<void> signOut() => _service.signOut();

  void resetPhoneFlow() {
    state = state.copyWith(
      codeSent: false,
      verificationId: null,
      resendToken: null,
      isPhoneVerified: false,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(errorMessage: null);
    }
  }


  Future<void> _ensureUserProfile(
    User? user, {
    String? fallbackName,
  }) async {
    if (user == null) return;
    await UserService.ensureUserProfile(
      user: user,
      fallbackName: fallbackName,
    );
  }

  String _mapFirebaseAuthError(FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Неверный формат email.';
      case 'user-not-found':
        return 'Пользователь не найден.';
      case 'wrong-password':
        return 'Неверный пароль.';
      case 'email-already-in-use':
        return 'Email уже зарегистрирован.';
      case 'weak-password':
        return 'Пароль должен содержать не менее 6 символов.';
      case 'too-many-requests':
        return 'Слишком много запросов. Повторите позже.';
      case 'invalid-verification-code':
        return 'Неверный код подтверждения.';
      default:
        return exception.message ?? 'Произошла ошибка. Попробуйте ещё раз.';
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFlowState>(
  (ref) => AuthController(ref),
);
