//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import UserNotifications

/// A type that can asynchronously produce a `UNNotificationAttachment`.
///
/// Conforming types can generate attachments using any logic:
/// - Rendering images
/// - Downloading remote content
/// - Drawing with CoreGraphics
/// - Rendering SwiftUI views
///
/// Instances must be `Sendable` to ensure thread-safety under Swift concurrency.
@MainActor
public protocol NotificationAttachmentProviding: Sendable {
    func makeAttachment() async -> UNNotificationAttachment?
}
