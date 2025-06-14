import 'user_logs_service.dart';
import 'user_service.dart';

class HighwayLogger {
  static Future<void> logHighwayEntry({
    required String location,
    required int pointsEarned,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId != null && userId > 0) {
        await UserLogsService.logHighwayActivity(
          userId: userId,
          activity: 'Entry',
          location: location,
          pointsEarned: pointsEarned,
        );
        
        // Also log the points change
        await UserLogsService.logPointsChange(
          userId: userId,
          pointsChange: pointsEarned,
          activityType: 'Highway Entry',
          details: location,
        );
      }
    } catch (e) {
      print('Error logging highway entry: $e');
    }
  }

  static Future<void> logHighwayExit({
    required String location,
    required int pointsEarned,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId != null && userId > 0) {
        await UserLogsService.logHighwayActivity(
          userId: userId,
          activity: 'Exit',
          location: location,
          pointsEarned: pointsEarned,
        );
        
        // Also log the points change
        await UserLogsService.logPointsChange(
          userId: userId,
          pointsChange: pointsEarned,
          activityType: 'Highway Exit',
          details: location,
        );
      }
    } catch (e) {
      print('Error logging highway exit: $e');
    }
  }

  static Future<void> logPointsRecharge({
    required int pointsAdded,
    required String paymentMethod,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId != null && userId > 0) {
        await UserLogsService.logPointsChange(
          userId: userId,
          pointsChange: pointsAdded,
          activityType: 'Points Recharge',
          details: 'Payment via $paymentMethod',
        );
      }
    } catch (e) {
      print('Error logging points recharge: $e');
    }
  }

  static Future<void> logPointsUsage({
    required int pointsUsed,
    required String purpose,
  }) async {
    try {
      final userId = await UserService.getUserId();
      if (userId != null && userId > 0) {
        await UserLogsService.logPointsChange(
          userId: userId,
          pointsChange: -pointsUsed,
          activityType: 'Points Usage',
          details: purpose,
        );
      }
    } catch (e) {
      print('Error logging points usage: $e');
    }
  }
} 