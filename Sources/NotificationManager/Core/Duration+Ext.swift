//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension Duration {

    /// Converts the duration to a `TimeInterval` value.
    ///
    /// This computed property decomposes the duration into its seconds and
    /// attoseconds components, then produces a `TimeInterval` by combining them.
    /// The attosecond component is converted to seconds using a fixed division
    /// factor of 1e18.
    ///
    /// - Returns: The duration expressed as a `TimeInterval`.
    internal var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds)
        + TimeInterval(attoseconds) / 1_000_000_000_000_000_000
    }

    /// Creates a duration representing the specified number of days.
    ///
    /// - Parameter value: The number of days.
    /// - Returns: A `Duration` equal to `value` days.
    internal static func days(_ value: Double) -> Duration {
        .seconds(value * 86_400)
    }
}
