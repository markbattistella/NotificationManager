//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import DefaultsKit
import Foundation

extension UserDefaults {

    /// A dedicated `UserDefaults` container for the NotificationManager package.
    ///
    /// This uses the suite name defined in ``NotificationsUserDefaultsKey/suiteName`` to keep
    /// package data isolated from the host app’s defaults.
    ///
    /// If the suite cannot be loaded, this property gracefully falls back to `.standard`.
    internal static let notification: UserDefaults = {
        guard let userDefaults = UserDefaults(suiteName: NotificationsUserDefaultsKey.suiteName) else {
            return .standard
        }
        return userDefaults
    }()
}

/// Keys used by the NotificationManager for persistent storage.
///
/// These keys are stored inside the ``UserDefaults/notification`` container
/// to prevent collisions with application-level defaults.
internal enum NotificationsUserDefaultsKey: String, UserDefaultsKeyRepresentable {

    /// The most recent time the host app recorded an “app opened” event.
    ///
    /// This value is updated via ``NotificationManager/markAppOpened()`` and is typically used
    /// to determine user inactivity.
    case appLastOpened

    /// The interval, in seconds, used for scheduling inactivity reminder notifications.
    ///
    /// This value is written when calling
    /// ``NotificationManager/scheduleInactivityReminder(seconds:title:body:)``.
    case inactivityIntervalSeconds

    /// The suite name used for the notification-specific `UserDefaults` container.
    ///
    /// All keys defined in this enumeration are stored under this suite.
    internal static var suiteName: String? {
        "com.markbattistella.packages.notificationManager"
    }
}
