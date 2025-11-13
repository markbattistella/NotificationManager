//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import NotificationManager

/// Demo category demonstrating conformance to ``NotificationCategoryDefinition``.
///
/// A category groups related notification actions and is referenced by scheduled notifications
/// that support user interaction.
enum DemoCategory: NotificationCategoryDefinition, Sendable {

    /// A reminder-style notification category.
    case reminder

    /// The unique identifier for the category.
    var id: String { "DEMO_CATEGORY" }

    /// The actions available within this category.
    ///
    /// Includes:
    /// - ``DemoAction/open``
    /// - ``DemoAction/snooze``
    /// - ``DemoAction/cancel``
    var actions: [NotificationActionDefinition] {
        [
            DemoAction.open,
            DemoAction.snooze,
            DemoAction.cancel
        ]
    }

    /// Options that customise the behaviour of the category.
    ///
    /// Includes support for a custom dismissal action.
    var options: UNNotificationCategoryOptions {
        [.customDismissAction]
    }
}
