//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import UserNotifications

/// A representation of all supported notification sound types.
///
/// This enum provides access to system-provided alert sounds, critical sounds, bundled audio files
/// included with the app, user-supplied sound files placed inside the app’s `/Library/Sounds`
/// directory, and fully custom file URLs.
///
/// Use this type when assigning values to the `sound` property of `UNMutableNotificationContent`.
public enum NotificationSound: Sendable {

    /// The system default notification sound.
    case `default`

    /// The system default critical alert sound.
    ///
    /// Critical alerts play even when the device is muted (requires entitlement).
    case defaultCritical

    /// A system critical alert sound played at a specific volume.
    ///
    /// - Parameter Float: Volume from `0.0` (quietest) to `1.0` (loudest).
    case defaultCriticalVolume(Float)

    /// A custom sound file located in one of the Apple-supported search locations:
    ///
    /// 1. `<app_container>/Library/Sounds`
    /// 2. `<group_container>/Library/Sounds`
    /// 3. The app’s main bundle
    ///
    /// Provide the full filename including extension.
    ///
    /// Example:
    /// ```swift
    /// sound: .named("waterdrops.caf")
    /// ```
    case named(String)

    /// A fully custom sound file referenced by URL.
    ///
    /// Use this when you need to reference a file located outside the standard sound search
    /// locations. The URL's filename will be used as the name passed to `UNNotificationSound`,
    /// so ensure the file exists before scheduling.
    case fileURL(URL)

    /// The system default ringtone sound.
    #if os(iOS)
    case defaultRingtone
    #endif
}

// MARK: - Conversion to UNNotificationSound

public extension NotificationSound {

    /// Converts the sound representation into a `UNNotificationSound` instance.
    ///
    /// This value should be assigned to the `sound` property of
    /// `UNMutableNotificationContent`. Some variants are unavailable on certain
    /// platforms; for example, `defaultRingtone` is iOS-only.
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
