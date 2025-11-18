//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import CoreLocation.CLCircularRegion

/// Represents the trigger mechanism used to schedule a local notification.
///
/// Each case describes a different type of notification trigger, such as time-interval,
/// calendar-based, or (where supported) location-based triggers.
public enum NotificationType {

    /// A trigger that fires after the specified time interval elapses.
    ///
    /// - Parameters:
    ///   - duration: The delay before the notification is delivered.
    ///   - repeats: Indicates whether the trigger repeats after firing.
    case timeInterval(duration: Duration, repeats: Bool)

    /// A trigger that fires at a specific time of day, optionally restricted to a particular
    /// weekday.
    ///
    /// - Parameters:
    ///   - weekday: The weekday (1–7) on which the notification fires, or `nil` to match any day.
    ///   - hour: The hour of the notification trigger.
    ///   - minute: The minute of the notification trigger.
    ///   - repeats: Indicates whether the trigger repeats on the defined schedule.
    case calendar(weekday: Int?, hour: Int, minute: Int, repeats: Bool)

    #if os(iOS) || os(watchOS)
    /// A trigger that fires when the user enters or exits a geographic region.
    ///
    /// - Parameters:
    ///   - region: The circular geographic region monitored for entry/exit.
    ///   - repeats: Indicates whether the trigger repeats after firing.
    case location(region: CLCircularRegion, repeats: Bool)
    #endif
}

public extension NotificationType {

    /// Returns the hour component of a calendar-based trigger.
    ///
    /// - Returns: The hour value if the trigger is `.calendar`, otherwise `nil`.
    var hour: Int? {
        if case let .calendar(_, hour, _, _) = self { return hour }
        return nil
    }

    /// Returns the minute component of a calendar-based trigger.
    ///
    /// - Returns: The minute value if the trigger is `.calendar`, otherwise `nil`.
    var minute: Int? {
        if case let .calendar(_, _, minute, _) = self { return minute }
        return nil
    }
}
