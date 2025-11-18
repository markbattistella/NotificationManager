//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import DefaultsKit

/// Keys used to store notification-related metadata in `UserDefaults`.
///
/// These keys provide structured access to values such as the last time the app was opened,
/// supporting features like inactivity reminders.
internal enum NotificationsUserDefaultsKey: String, UserDefaultsKeyRepresentable {

    /// Stores the timestamp for the app’s last launch or foreground activation.
    case appLastOpened

    /// The app group suite name used for storing notification data.
    ///
    /// This enables data sharing across extensions or other processes as needed.
    internal static var suiteName: String? {
        "com.markbattistella.packages.notificationManager"
    }
}
