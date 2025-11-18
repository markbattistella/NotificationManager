//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// An error type representing failures that may occur when interacting with the notification
/// system.
///
/// Use this type to distinguish between different notification-related failure conditions and
/// present appropriate messaging to the user when needed.
public enum NotificationError: Error {

    /// Indicates that a notification operation failed because the user has not granted the
    /// required notification permissions.
    case permissionDenied
}

extension NotificationError: LocalizedError {

    /// A human-readable description of the error.
    ///
    /// This value is suitable for displaying to the user in error alerts or logs.
    public var errorDescription: String? {
        switch self {
            case .permissionDenied:
                return String(localized: "Notification permission has not been granted.")
        }
    }
}
