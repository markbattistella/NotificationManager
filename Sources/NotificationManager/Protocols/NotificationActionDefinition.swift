//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import UserNotifications

/// Defines the properties required to describe a notification action.
///
/// Conforming types supply identifiers, display titles, and behavioural options used when
/// constructing a ``UNNotificationAction``.
public protocol NotificationActionDefinition {

    /// The unique identifier for the action.
    var id: String { get }

    /// The user-visible title displayed for the action.
    var title: LocalizedStringResource { get }

    /// The behavioural options that configure how the action operates.
    var options: UNNotificationActionOptions { get }
}
