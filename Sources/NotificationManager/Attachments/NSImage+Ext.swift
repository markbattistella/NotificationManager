//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

extension NSImage {

    /// Returns PNG-encoded data for the image, or `nil` if encoding fails.
    internal func pngData() -> Data? {
        guard
            let tiff = self.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff)
        else { return nil }

        return rep.representation(using: .png, properties: [:])
    }
}
#endif
