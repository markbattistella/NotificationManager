//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Describes an action that can be included in a custom notification category.
///
/// Conforming types define the identifier, display title, and behaviour options for an action
/// shown within a delivered notification. These actions appear in the system notification
/// interface and allow the user to respond directly.
///
/// Each descriptor is transformed into a ``UNNotificationAction`` when registering notification
/// categories.
///
/// Conform to this protocol when creating custom notification actions.
public protocol NotificationActionDescriptor {

    /// The unique identifier for the action.
    ///
    /// This value is used to differentiate actions when handling user responses.
    var id: String { get }

    /// The user-visible title displayed for the action.
    ///
    /// This value supports localisation.
    var title: LocalizedStringResource { get }

    /// Option flags that define the behaviour of the action, such as whether it requires
    /// authentication or performs a destructive operation.
    var options: UNNotificationActionOptions { get }
}

