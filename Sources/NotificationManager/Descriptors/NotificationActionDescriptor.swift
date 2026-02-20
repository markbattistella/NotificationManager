//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A descriptor used to define an action that can appear in a custom notification category.
///
/// Types conforming to this protocol describe the properties needed to construct a
/// `UNNotificationAction` when registering notification categories. Each action specifies
/// an identifier, a user-facing title, optional iconography, and behaviour options that
/// determine how the system presents and handles the action within a delivered notification.
///
/// Conform to this protocol to create custom actions that allow users to respond directly
/// from the system notification interface.
public protocol NotificationActionDescriptor {

    /// A unique identifier for the action.
    ///
    /// Use this value to distinguish the action when handling a user's response in your app.
    var id: String { get }

    /// The title displayed for the action in the notification interface.
    ///
    /// Provide a value that supports localisation to ensure the action is presented correctly
    /// across different languages.
    var title: LocalizedStringResource { get }

    /// An optional icon displayed alongside the action.
    ///
    /// Use a `UNNotificationActionIcon` to supply an SF Symbol or image that provides
    /// additional visual context for the action. If `nil`, no icon is shown.
    var icon: UNNotificationActionIcon? { get }

    /// Behaviour options that define how the action operates.
    ///
    /// These flags determine characteristics such as whether the action launches the app,
    /// requires authentication, or represents a destructive operation.
    var options: UNNotificationActionOptions { get }
}
