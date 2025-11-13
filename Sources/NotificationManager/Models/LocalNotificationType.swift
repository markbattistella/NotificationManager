//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import CoreLocation.CLCircularRegion

/// Represents the trigger mechanism for a local notification.
///
/// This type defines when and how a notification should fire, supporting time-based,
/// calendar-based, and location-based triggers.
public enum LocalNotificationType {

    /// A trigger that fires after a specified time interval.
    ///
    /// - Parameters:
    ///   - seconds: The delay before the notification is delivered.
    ///   - repeats: Indicates whether the trigger repeats at the given interval.
    case timeInterval(seconds: TimeInterval, repeats: Bool)

    /// A calendar-based trigger for scheduled delivery.
    ///
    /// - Parameters:
    ///   - weekday: The weekday number (1–7) to match, or `nil` to omit the field.
    ///   - hour: The hour at which the notification should fire.
    ///   - minute: The minute at which the notification should fire.
    ///   - repeats: Indicates whether the trigger repeats on the matched date components.
    case calendar(weekday: Int?, hour: Int, minute: Int, repeats: Bool)

    /// A location-based trigger that fires when entering or exiting a region.
    ///
    /// - Parameters:
    ///   - region: The circular region monitored for notification delivery.
    ///   - repeats: Indicates whether the trigger repeats each time the region boundary is crossed.
    #if os(iOS) || os(watchOS)
    case location(region: CLCircularRegion, repeats: Bool)
    #endif
}

public extension LocalNotificationType {

    /// Returns the hour component if this is a calendar-based trigger.
    ///
    /// - Returns: The hour value, or `nil` for non-calendar triggers.
    var hour: Int? {
        if case let .calendar(_, hour, _, _) = self { return hour }
        return nil
    }

    /// Returns the minute component if this is a calendar-based trigger.
    ///
    /// - Returns: The minute value, or `nil` for non-calendar triggers.
    var minute: Int? {
        if case let .calendar(_, _, minute, _) = self { return minute }
        return nil
    }
}
