//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A calendar-aware representation of a weekday.
///
/// `NotificationWeekday` wraps the integer-based weekday value used by `DateComponents` and
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
/// `NotificationWeekday` provides convenience constants such as ``sunday`` and ``monday`` for
/// ease of use, along with support for iteration via ``CaseIterable``.
///
/// Example:
/// ```swift
/// let day = NotificationWeekday(2)
/// print(day.name) // "Monday" in the current locale
/// ```
public struct NotificationWeekday: Hashable, CaseIterable {

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
    public static var allCases: [NotificationWeekday] {
        (1...7).map { NotificationWeekday($0) }
    }
}

// MARK: - Localized Names & Symbols

extension NotificationWeekday {

    /// The localized full weekday name.
    ///
    /// Examples:
    /// - `"Sunday"`
    /// - `"Montag"`
    /// - `"יום ראשון"`
    public var localizedName: String {
        Calendar.autoupdatingCurrent.weekdaySymbols[value - 1]
    }

    /// The localized abbreviated symbol (3–letter, locale-specific).
    ///
    /// Examples:
    /// - `"Sun"`
    /// - `"Mon"`
    /// - `"So"`
    public var localizedShortSymbol: String {
        Calendar.autoupdatingCurrent.shortWeekdaySymbols[value - 1]
    }

    /// The localized minimal symbol (often 1–2 letters).
    ///
    /// Examples:
    /// - `"S"`
    /// - `"M"`
    /// - `"Su"`
    public var localizedVeryShortSymbol: String {
        Calendar.autoupdatingCurrent.veryShortWeekdaySymbols[value - 1]
    }
}

// MARK: - Convenience static constants

extension NotificationWeekday {

    /// The weekday representing Sunday (`1` in the system calendar).
    public static var sunday: NotificationWeekday { NotificationWeekday(1) }

    /// The weekday representing Monday (`2` in the system calendar).
    public static var monday: NotificationWeekday { NotificationWeekday(2) }

    /// The weekday representing Tuesday (`3` in the system calendar).
    public static var tuesday: NotificationWeekday { NotificationWeekday(3) }

    /// The weekday representing Wednesday (`4` in the system calendar).
    public static var wednesday: NotificationWeekday { NotificationWeekday(4) }

    /// The weekday representing Thursday (`5` in the system calendar).
    public static var thursday: NotificationWeekday { NotificationWeekday(5) }

    /// The weekday representing Friday (`6` in the system calendar).
    public static var friday: NotificationWeekday { NotificationWeekday(6) }

    /// The weekday representing Saturday (`7` in the system calendar).
    public static var saturday: NotificationWeekday { NotificationWeekday(7) }
}
