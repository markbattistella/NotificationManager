//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension ImageRenderer {

    /// Applies the appropriate screen scale for the current platform.
    ///
    /// On iOS, the scale is taken from `UIScreen.main.scale`.
    /// On macOS, the scale is taken from `NSScreen.main?.backingScaleFactor`,  with a fallback
    /// of `2` when no screen is available.
    ///
    /// This ensures images are rendered at the correct pixel density for the environment in
    /// which they are generated.
    @MainActor
    internal func applyPlatformScale() {

        #if os(iOS)

        self.scale = UIScreen.main.scale

        #elseif os(macOS)

        self.scale = NSScreen.main?.backingScaleFactor ?? 2

        #endif
    }
}
