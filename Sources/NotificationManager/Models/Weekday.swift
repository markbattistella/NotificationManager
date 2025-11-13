//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A calendar-aware representation of a weekday.
///
/// `Weekday` wraps the integer-based weekday value used by `DateComponents` and
/// `UNCalendarNotificationTrigger`, where valid values range from **1 through 7**.
///
/// The mapping always corresponds to the order of ``Calendar/weekdaySymbols``—that is:
/// - **1** represents the first symbol (usually Sunday),
/// - **7** represents the last symbol (usually Saturday).
///
/// This ordering is consistent across all calendar systems supported by iOS. Although different
/// calendars may begin their week on different days, Apple guarantees that weekday indices always
/// map to the fixed `weekdaySymbols` order.
///
/// `Weekday` provides convenience constants such as ``sunday`` and ``monday`` for ease of use,
/// along with support for iteration via ``CaseIterable``.
///
/// Example:
/// ```swift
/// let day = Weekday(2)
/// print(day.name) // "Monday" in the current locale
/// ```
public struct Weekday: Hashable, CaseIterable {

    /// The 1-based weekday value (1–7), matching `Calendar.weekdaySymbols`.
    ///
    /// - Important: Apple guarantees that:
    ///     - `1` corresponds to `weekdaySymbols[0]` (commonly Sunday)
    ///     - `7` corresponds to `weekdaySymbols[6]` (commonly Saturday)
    ///
    /// This mapping does **not** shift based on locale preferences such as the user's "first
    /// weekday" setting.
    public let value: Int

    /// Creates a new weekday instance using a 1-based weekday index.
    ///
    /// - Parameter value: An integer from **1 through 7**.
    /// - Precondition: The value must be within the allowed range.
    ///
    /// Example:
    /// ```swift
    /// let weekday = Weekday(3) // Tuesday
    /// ```
    public init(_ value: Int) {
        precondition((1...7).contains(value), "Weekday must be between 1 and 7")
        self.value = value
    }

    /// A collection of all weekday values from **1 to 7**, in order.
    ///
    /// The sequence corresponds directly to `Calendar.weekdaySymbols`.
    public static var allCases: [Weekday] {
        (1...7).map { Weekday($0) }
    }

    /// The localized full name of the weekday.
    ///
    /// This value is derived from ``Calendar/weekdaySymbols`` using the current system calendar
    /// and locale.
    ///
    /// Example outputs:
    /// - `"Sunday"`
    /// - `"Montag"` (German locale)
    /// - `"יום ראשון"` (Hebrew locale)
    public var name: String {
        Calendar.current.weekdaySymbols[value - 1]
    }
}

// MARK: - Convenience static constants

public extension Weekday {

    /// The weekday representing Sunday (`1` in the system calendar).
    static var sunday: Weekday { Weekday(1) }

    /// The weekday representing Monday (`2` in the system calendar).
    static var monday: Weekday { Weekday(2) }

    /// The weekday representing Tuesday (`3` in the system calendar).
    static var tuesday: Weekday { Weekday(3) }

    /// The weekday representing Wednesday (`4` in the system calendar).
    static var wednesday: Weekday { Weekday(4) }

    /// The weekday representing Thursday (`5` in the system calendar).
    static var thursday: Weekday { Weekday(5) }

    /// The weekday representing Friday (`6` in the system calendar).
    static var friday: Weekday { Weekday(6) }

    /// The weekday representing Saturday (`7` in the system calendar).
    static var saturday: Weekday { Weekday(7) }
}
