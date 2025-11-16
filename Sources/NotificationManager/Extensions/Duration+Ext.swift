//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension Duration {

    /// Converts the duration into a `TimeInterval` value.
    ///
    /// This computes the total number of seconds represented by the duration by combining its
    /// whole-second and attosecond components. The returned value is suitable for APIs that
    /// require a `TimeInterval`, including `UNTimeIntervalNotificationTrigger`.
    ///
    /// - Returns: The duration expressed as a floating-point number of seconds.
    internal var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return TimeInterval(seconds)
        + TimeInterval(attoseconds) / 1_000_000_000_000_000_000
    }
}
