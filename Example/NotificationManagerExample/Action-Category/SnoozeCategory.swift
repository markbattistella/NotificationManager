//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import NotificationManager

/// Category used for notifications that support a limited snooze-style interaction.
///
/// This category omits the snooze action and is intended for one-off notifications with simplified
/// user choices.
enum SnoozeCategory: NotificationCategoryDefinition, Sendable {

    /// A single-use snooze-related notification category.
    case oneOff

    /// The unique identifier for the category.
    var id: String { "SNOOZE_ONLY_CATEGORY" }

    /// The actions available within this category.
    ///
    /// Includes:
    /// - ``DemoAction/open``
    /// - ``DemoAction/cancel``
    var actions: [NotificationActionDefinition] {
        [
            DemoAction.open,
            DemoAction.cancel
        ]
    }

    /// Options that configure the behaviour of the category.
    ///
    /// This category uses no special options.
    var options: UNNotificationCategoryOptions {
        []
    }
}
