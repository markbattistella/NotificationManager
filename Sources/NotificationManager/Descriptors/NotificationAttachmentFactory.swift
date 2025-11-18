//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A factory protocol for producing notification attachments asynchronously.
///
/// Conforming types encapsulate the logic required to generate a ``UNNotificationAttachment``.
/// Attachments are created at scheduling time and applied to the notification content if
/// successfully produced.
///
/// Implement this protocol when you need to attach images, files, or other media to a notification
/// request.
public protocol NotificationAttachmentFactory {

    /// Creates and returns a notification attachment.
    ///
    /// - Returns: A ``UNNotificationAttachment`` if creation succeeds, or `nil` if the attachment
    /// cannot be generated.
    func makeAttachment() async -> UNNotificationAttachment?
}
