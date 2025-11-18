//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Describes a custom notification category, including its identifier, available actions, and
/// behavioural options.
///
/// Conforming types provide the information required to construct a ``UNNotificationCategory``
/// during category registration. Categories allow notifications to present user-interactive
/// actions and define system-level behaviours such as whether notifications of this type appear
/// in CarPlay or require device authentication.
///
/// Implement this protocol when defining custom categories for your notification workflow.
public protocol NotificationCategoryDescriptor {

    /// The unique identifier for the category.
    ///
    /// This identifier is applied to notification content to associate it with the corresponding
    /// registered category.
    var id: String { get }

    /// The actions made available in notifications that use this category.
    ///
    /// Each action is transformed into a ``UNNotificationAction`` during category registration.
    var actions: [NotificationActionDescriptor] { get }

    /// The option flags defining the behaviour of the category.
    ///
    /// These options control how the category behaves within the notification system, including
    /// visibility and interaction rules.
    var options: UNNotificationCategoryOptions { get }
}
