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
public enum PermissionRequestResult {

    /// The user granted notification permission, either fully or provisionally.
    case authorized

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
