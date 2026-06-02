import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

/// Email verification service - OTP через Firebase
class EmailVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send verification email with OTP
  static Future<bool> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        appLogger.w('No user signed in for email verification');
        return false;
      }

      // В Firebase это встроено - отправит письмо на email
      await user.sendEmailVerification();
      appLogger.i('Verification email sent to: ${user.email}');
      return true;
    } catch (e) {
      appLogger.e('Error sending verification email', error: e);
      return false;
    }
  }

  /// Check if email is verified
  static Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      return user.emailVerified;
    } catch (e) {
      appLogger.e('Error checking email verification', error: e);
      return false;
    }
  }

  /// Wait for email verification (with timeout)
  static Future<bool> waitForEmailVerification({
    Duration timeout = const Duration(minutes: 5),
  }) async {
    try {
      final startTime = DateTime.now();

      while (true) {
        await Future.delayed(const Duration(seconds: 2));

        final user = _auth.currentUser;
        if (user == null) return false;

        await user.reload();

        if (user.emailVerified) {
          appLogger.i('Email verified successfully');
          return true;
        }

        if (DateTime.now().difference(startTime) > timeout) {
          appLogger.w('Email verification timeout');
          return false;
        }
      }
    } catch (e) {
      appLogger.e('Error waiting for email verification', error: e);
      return false;
    }
  }
}

/// Phone verification service - SMS OTP
class PhoneVerificationService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Send SMS code to phone number
  static Future<String?> sendSmsCode({
    required String phoneNumber,
  }) async {
    try {
      String? verificationId;

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          appLogger.i('SMS verification completed automatically');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          appLogger.e('SMS verification failed: ${e.code}', error: e);
          throw e;
        },
        codeSent: (String vId, int? resendToken) {
          verificationId = vId;
          appLogger.i('SMS code sent to: $phoneNumber');
        },
        codeAutoRetrievalTimeout: (String vId) {
          verificationId = vId;
          appLogger.i('Auto-retrieval timeout for SMS code');
        },
      );

      return verificationId;
    } catch (e) {
      appLogger.e('Error sending SMS code', error: e);
      return null;
    }
  }

  /// Verify SMS code
  static Future<bool> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      await _auth.signInWithCredential(credential);
      appLogger.i('Phone verified successfully');
      return true;
    } catch (e) {
      appLogger.e('Error verifying SMS code', error: e);
      return false;
    }
  }
}

/// Auth state management with verification requirements
class AuthFlowStateV2 {
  const AuthFlowStateV2({
    this.currentStatus = AuthStatus.initial,
    this.isLoading = false,
    this.errorMessage,
    this.verificationId,
    this.email,
    this.phoneNumber,
  });

  final AuthStatus currentStatus;
  final bool isLoading;
  final String? errorMessage;
  final String? verificationId;
  final String? email;
  final String? phoneNumber;

  AuthFlowStateV2 copyWith({
    AuthStatus? currentStatus,
    bool? isLoading,
    String? errorMessage,
    String? verificationId,
    String? email,
    String? phoneNumber,
  }) {
    return AuthFlowStateV2(
      currentStatus: currentStatus ?? this.currentStatus,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      verificationId: verificationId ?? this.verificationId,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

enum AuthStatus {
  initial,
  registering,
  emailVerificationNeeded,
  phoneVerificationNeeded,
  authenticated,
  error,
}

/// Enhanced auth controller with verification
class EnhancedAuthController extends StateNotifier<AuthFlowStateV2> {
  EnhancedAuthController(this._ref) : super(const AuthFlowStateV2());

  final Ref _ref;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      currentStatus: AuthStatus.registering,
      isLoading: true,
      errorMessage: null,
    );

    try {
      // 1. Create user
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Send verification email
      await EmailVerificationService.sendVerificationEmail();

      // 3. Await email verification
      final isVerified = await EmailVerificationService.waitForEmailVerification();

      if (!isVerified) {
        state = state.copyWith(
          currentStatus: AuthStatus.error,
          isLoading: false,
          errorMessage: 'Email verification failed. Please try again.',
        );
        return;
      }

      // 4. Create user profile
      await UserService.ensureUserProfile(
        user: userCred.user!,
        fallbackName: email.split('@').first,
      );

      state = state.copyWith(
        currentStatus: AuthStatus.authenticated,
        isLoading: false,
      );

      appLogger.i('User registered and email verified: $email');
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        currentStatus: AuthStatus.error,
        isLoading: false,
        errorMessage: _mapFirebaseError(e),
      );
      appLogger.e('Registration error: ${e.code}', error: e);
    } catch (e) {
      state = state.copyWith(
        currentStatus: AuthStatus.error,
        isLoading: false,
        errorMessage: 'Registration failed. Please try again.',
      );
      appLogger.e('Unexpected registration error', error: e);
    }
  }

  Future<void> registerWithPhone({
    required String phoneNumber,
  }) async {
    state = state.copyWith(
      currentStatus: AuthStatus.registering,
      isLoading: true,
      errorMessage: null,
    );

    try {
      // 1. Send SMS code
      final verificationId = await PhoneVerificationService.sendSmsCode(
        phoneNumber: phoneNumber,
      );

      if (verificationId == null) {
        throw Exception('Failed to send SMS code');
      }

      // 2. Await verification code entry (user will enter code in UI)
      state = state.copyWith(
        currentStatus: AuthStatus.phoneVerificationNeeded,
        isLoading: false,
        verificationId: verificationId,
        phoneNumber: phoneNumber,
      );

      appLogger.i('SMS code sent to: $phoneNumber');
    } catch (e) {
      state = state.copyWith(
        currentStatus: AuthStatus.error,
        isLoading: false,
        errorMessage: 'Failed to send SMS code',
      );
      appLogger.e('Phone registration error', error: e);
    }
  }

  Future<void> verifyPhoneCode({
    required String smsCode,
  }) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        currentStatus: AuthStatus.error,
        errorMessage: 'Verification ID not found',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final success = await PhoneVerificationService.verifySmsCode(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );

      if (!success) {
        throw Exception('SMS verification failed');
      }

      // Create user profile
      final user = _auth.currentUser;
      if (user != null) {
        await UserService.ensureUserProfile(
          user: user,
          fallbackName: user.phoneNumber ?? 'User',
        );
      }

      state = state.copyWith(
        currentStatus: AuthStatus.authenticated,
        isLoading: false,
      );

      appLogger.i('Phone verified: ${state.phoneNumber}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Invalid verification code',
      );
      appLogger.e('Phone verification error', error: e);
    }
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'email-already-in-use' => 'Email is already in use',
      'weak-password' => 'Password is too weak',
      'invalid-email' => 'Invalid email format',
      'network-request-failed' => 'Network error. Check your connection.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}

/// Provider for enhanced auth
final enhancedAuthControllerProvider =
    StateNotifierProvider<EnhancedAuthController, AuthFlowStateV2>((ref) {
  return EnhancedAuthController(ref);
});
