//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import NotificationManager

/// Demo actions demonstrating conformance to ``NotificationActionDefinition``.
///
/// Each case represents a user-interactable action that can be attached to a notification category.
enum DemoAction: NotificationActionDefinition, Sendable {
    
    /// Opens the associated content.
    case open
    
    /// Snoozes the notification.
    case snooze
    
    /// Cancels or dismisses the notification.
    case cancel
    
    /// The unique identifier for the action.
    var id: String {
        switch self {
            case .open: return "OPEN_ACTION"
            case .snooze: return "SNOOZE_ACTION"
            case .cancel: return "CANCEL_ACTION"
        }
    }
    
    /// The user-visible title for the action.
    var title: LocalizedStringResource {
        switch self {
            case .open: return "Open"
            case .snooze: return "Snooze"
            case .cancel: return "Cancel"
        }
    }
    
    /// The behavioural options applied to the action.
    var options: UNNotificationActionOptions {
        switch self {
            case .open: return [.foreground]
            case .snooze: return []
            case .cancel: return [.destructive]
        }
    }
}
