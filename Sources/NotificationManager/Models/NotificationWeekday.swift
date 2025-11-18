//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents a weekday value used for scheduling calendar-based notifications.
///
/// The stored value follows the system convention where Sunday is `1` and Saturday is `7`.
/// Initialisation enforces that the value is within the valid range.
///
/// This type provides convenient access to the system’s localised weekday names and symbols,
/// making it suitable for UI display and user-facing scheduling features.
public struct NotificationWeekday: Hashable {

    /// The integer value of the weekday (1 = Sunday … 7 = Saturday).
    public let value: Int

    /// The user’s current autoupdating calendar, used for resolving names.
    private let calendar = Calendar.autoupdatingCurrent

    /// Creates a weekday from an integer value.
    ///
    /// - Parameter value: The weekday number, where `1...7` are valid.
    /// - Precondition: The value must be between `1` and `7`.
    public init(_ value: Int) {
        precondition((1...7).contains(value), "Weekday must be between 1 and 7")
        self.value = value
    }
}

extension NotificationWeekday: CaseIterable {

    /// Returns an array containing all weekdays in order, from Sunday (`1`) through
    /// Saturday (`7`).
    public static var allCases: [NotificationWeekday] {
        (1...7).map { NotificationWeekday($0) }
    }
}

extension NotificationWeekday: Identifiable {

    /// A stable identifier for the weekday, matching its integer value (`1` for Sunday … `7`
    /// for Saturday).
    public var id: Int { value }
}

extension NotificationWeekday {

    /// The fully localised name of the weekday (e.g. “Monday”).
    public var localizedName: String {
        calendar.weekdaySymbols[value - 1]
    }

    /// The short-form localised symbol for the weekday (e.g. “Mon”).
    public var localizedShortSymbol: String {
        calendar.shortWeekdaySymbols[value - 1]
    }

    /// The very short-form localised symbol for the weekday (e.g. “M”).
    public var localizedVeryShortSymbol: String {
        calendar.veryShortWeekdaySymbols[value - 1]
    }
}

extension NotificationWeekday {

    /// The Sunday weekday value (`1`).
    public static var sunday: NotificationWeekday { NotificationWeekday(1) }

    /// The Monday weekday value (`2`).
    public static var monday: NotificationWeekday { NotificationWeekday(2) }

    /// The Tuesday weekday value (`3`).
    public static var tuesday: NotificationWeekday { NotificationWeekday(3) }

    /// The Wednesday weekday value (`4`).
    public static var wednesday: NotificationWeekday { NotificationWeekday(4) }

    /// The Thursday weekday value (`5`).
    public static var thursday: NotificationWeekday { NotificationWeekday(5) }

    /// The Friday weekday value (`6`).
    public static var friday: NotificationWeekday { NotificationWeekday(6) }

    /// The Saturday weekday value (`7`).
    public static var saturday: NotificationWeekday { NotificationWeekday(7) }
}
