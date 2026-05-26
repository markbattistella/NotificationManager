//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import DefaultsKit
import Foundation

extension UserDefaults {

  /// The `UserDefaults` instance used for notification-related persistence.
  ///
  /// This value attempts to load a custom app group suite specified by
  /// ``NotificationsUserDefaultsKey/suiteName``. If the suite cannot be created, the standard
  /// `UserDefaults` instance is used as a fallback.
  @MainActor
  internal static var notification: UserDefaults {
    guard let userDefaults = UserDefaults(suiteName: NotificationsUserDefaultsKey.suiteName) else {
      return .standard
    }
    return userDefaults
  }
}
