//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Describes the effective notification capabilities available to the app.
///
/// These values reflect the user’s current system notification settings and indicate which
/// features can be used when scheduling or delivering notifications.
public struct NotificationCapabilities: Sendable {
    
    /// Indicates whether alert-style notifications are allowed.
    public let allowsAlert: Bool
    
    /// Indicates whether sound playback is permitted for notifications.
    public let allowsSound: Bool
    
    /// Indicates whether the app is allowed to update its badge count.
    public let allowsBadge: Bool
    
    /// Indicates whether announcement-style notifications are enabled.
    public let allowsAnnouncements: Bool
    
    /// Indicates whether the device and system support critical alerts.
    public let criticalAlertSupported: Bool
}
