import '../session/mock_session.dart';

/// Stand-in for real sign-in. Every mock registration goes through here.
abstract final class AccountAuth {
  static Future<void> registerWithMock() => MockSession.signIn();

  static Future<void> continueAsGuest() => MockSession.signInAsGuest();

  static Future<bool> redeemInvite(String code) =>
      MockSession.redeemPremiumCode(code);
}
