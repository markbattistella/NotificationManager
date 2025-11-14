//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the outcome of a notification permission request.
///
/// Values of this type indicate whether permission was granted, denied, already available, or
/// requires a redirect to the system Settings app. It also includes an error case for unexpected
/// failures during the permission request process.
public enum PermissionRequestResult: Sendable {

    /// The user granted notification permission during this request.
    case granted

    /// The user explicitly denied permission during this request.
    case denied

    /// Notification permission had already been granted before the request was made.
    case alreadyAuthorized

    /// Permission had been denied previously and cannot be requested again.
    ///
    /// Includes a URL directing the user to the system Settings page for the app.
    case needsSettings(URL)

    /// An error occurred while attempting to request permission.
    ///
    /// Includes the underlying error when available.
    case error(Error?)
}
