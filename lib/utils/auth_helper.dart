// ignore: depend_on_referenced_packages
import '../database/guardian_db.dart';

class AuthHelper {
  /// Returns the phone number of the currently logged-in guardian, or null if not logged in.
  static Future<String?> getCurrentGuardianPhone() async {
    final guardian = await GuardianDB.getLoggedInGuardian();
    return guardian?.userPhone;
  }
}
