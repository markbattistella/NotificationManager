//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the current status of a notification identified by a specific identifier.
///
/// This structure describes whether a notification is scheduled (pending), whether it has
/// already been delivered, and provides the associated request or delivered notification objects
/// when available.
public struct NotificationState {

    /// Indicates whether the notification currently exists in the pending queue.
    public let isPending: Bool

    /// Indicates whether the notification has been delivered and is still retained by the system.
    public let isDelivered: Bool

    /// The pending notification request, if one exists for the identifier.
    public let request: UNNotificationRequest?

    /// The delivered notification instance, if one exists for the identifier.
    public let delivered: UNNotification?
}
