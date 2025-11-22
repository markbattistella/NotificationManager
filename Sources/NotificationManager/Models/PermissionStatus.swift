//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the outcome of a request for notification authorisation.
///
/// This type indicates whether permission was granted, explicitly denied, or whether an error
/// occurred during the authorisation attempt.
public enum PermissionStatus {

    /// The user granted notification permission, either fully or provisionally.
    case authorized

    /// Permission is not determined yet.
    case notDetermined

    /// The user denied notification permission.
    ///
    /// - Parameter url: An optional URL to the system notification settings page, allowing the
    /// user to manually update permissions if desired.
    case denied(URL?)

    /// An error occurred while requesting notification permission.
    ///
    /// - Parameter error: The underlying error, if available.
    case error(Error?)
}

extension PermissionStatus: Equatable {

    /// Compares two ``PermissionStatus`` values for equality.
    ///
    /// Equality is determined by matching the associated cases and their associated values:
    /// - `.authorized` is equal only to `.authorized`.
    /// - `.notDetermined` is equal only to `.notDetermined`.
    /// - `.denied` compares equality based on the associated URL.
    /// - `.error` compares equality based on the underlying error, using the error domain and
    /// code when both sides contain non-`nil` errors.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side value to compare.
    ///   - rhs: The right-hand side value to compare.
    ///
    /// - Returns: `true` if both values represent the same permission state and their associated
    /// values match; otherwise, `false`.
    public static func == (lhs: PermissionStatus, rhs: PermissionStatus) -> Bool {
        switch (lhs, rhs) {

            case (.authorized, .authorized):
                return true

            case (.notDetermined, .notDetermined):
                return true

            case let (.denied(a), .denied(b)):
                return a == b

            case let (.error(a), .error(b)):
                switch (a, b) {
                    case (nil, nil):
                        return true
                    case let (x?, y?):
                        let nx = x as NSError
                        let ny = y as NSError
                        return nx.domain == ny.domain && nx.code == ny.code
                    default:
                        return false
                }

            default:
                return false
        }
    }
}
