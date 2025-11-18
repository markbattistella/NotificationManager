//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the sound to be played when a notification is delivered.
///
/// This type provides convenient access to system sounds, critical alert sounds, named bundled
/// audio files, and platform-specific sound options.
public enum NotificationSound {

    /// The system default notification sound.
    case `default`

    /// The system default critical alert sound.
    ///
    /// Critical alerts bypass certain system settings and may play even when the device is muted,
    /// depending on entitlement configuration.
    case defaultCritical

    /// A system default critical alert sound played at a specified audio volume.
    ///
    /// - Parameter level: The volume level used for playback.
    case defaultCriticalVolume(Float)

    /// A notification sound loaded from a bundled resource by name.
    ///
    /// - Parameter name: The name of the audio file resource.
    case named(String)

    /// A notification sound loaded from a file URL.
    ///
    /// - Parameter url: The location of the audio file.
    case fileURL(URL)

    #if os(iOS)
    /// The system default ringtone sound, available only on iOS.
    case defaultRingtone
    #endif
}

public extension NotificationSound {

    /// Resolves the notification sound into a `UNNotificationSound` instance.
    ///
    /// This value is computed at scheduling time and provides the concrete
    /// sound object to attach to a notification request.
    ///
    /// - Returns: A configured `UNNotificationSound`, or `nil` if no sound applies.
    @MainActor
    var value: UNNotificationSound? {
        switch self {

            case .default:
                return .default

            case .defaultCritical:
                return .defaultCritical

            case let .defaultCriticalVolume(level):
                return .defaultCriticalSound(withAudioVolume: level)

            case let .named(name):
                return UNNotificationSound(named: UNNotificationSoundName(name))

            case let .fileURL(url):
                return UNNotificationSound(named: UNNotificationSoundName(url.lastPathComponent))

            #if os(iOS)
            case .defaultRingtone:
                return .defaultRingtone
            #endif
        }
    }
}
