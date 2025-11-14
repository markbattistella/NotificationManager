//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

#if canImport(UIKit)
import UIKit
#endif

import SwiftUI
import UserNotifications

/// A factory namespace for constructing `UNNotificationAttachment` instances
/// from bitmaps, SF Symbols, or rendered SwiftUI views.
public enum NotificationAttachmentBuilder {

    // MARK: - 1. UIImage Builder (iOS / tvOS / watchOS only)

    #if canImport(UIKit)

    /// Builds a notification attachment from a `UIImage`.
    public struct AttachmentImage: NotificationAttachmentProviding {

        private let image: UIImage
        private let id: String

        public init(_ image: UIImage, id: String = UUID().uuidString) {
            self.image = image
            self.id = id
        }

        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {
            await NotificationAttachmentBuilder.createAttachment(
                from: image,
                id: id
            )
        }
    }
    #endif

    // MARK: - 2. SF Symbol Builder (all platforms via SwiftUI renderer)

    /// Renders an SF Symbol using SwiftUI and produces an attachment.
    public struct Symbol: NotificationAttachmentProviding {

        private let name: String
        private let size: CGSize
        private let foreground: Color
        private let background: Color
        private let id: String

        public init(
            _ name: String,
            size: CGSize = .init(width: 80, height: 80),
            foreground: Color = .white,
            background: Color = .clear,
            id: String = UUID().uuidString
        ) {
            self.name = name
            self.size = size
            self.foreground = foreground
            self.background = background
            self.id = id
        }

        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {

            let view = ZStack {
                background
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(foreground)
                    .padding(10)
            }
                .frame(width: size.width, height: size.height)

            let renderer = ImageRenderer(content: view)

            guard let cgImage = renderer.cgImage else { return nil }

#if canImport(UIKit)
            let img = UIImage(cgImage: cgImage)
#elseif canImport(AppKit)
            let img = NSImage(cgImage: cgImage, size: size)
#endif

            return await NotificationAttachmentBuilder.createAttachment(
                from: img,
                id: id
            )
        }
    }


    // MARK: - 3. SwiftUI View Builder (cross-platform)

    /// Renders a SwiftUI view into an attachment-ready bitmap.
    public struct View<V: SwiftUI.View & Sendable>: NotificationAttachmentProviding {

        private let view: V
        private let size: CGSize
        private let id: String

        public init(
            _ view: V,
            size: CGSize = .init(width: 120, height: 120),
            id: String = UUID().uuidString
        ) {
            self.view = view
            self.size = size
            self.id = id
        }

        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {

            let renderer = ImageRenderer(
                content: view
                    .frame(width: size.width, height: size.height)
            )

            guard let cgImage = renderer.cgImage else { return nil }

#if canImport(UIKit)
            let img = UIImage(cgImage: cgImage)
#else
            let img = NSImage(cgImage: cgImage, size: size)
#endif

            return await NotificationAttachmentBuilder.createAttachment(
                from: img,
                id: id
            )
        }
    }
}

// MARK: - Shared Helper (cross-platform)

extension NotificationAttachmentBuilder {

    /// Writes an image to temporary storage and turns it into a `UNNotificationAttachment`.
    @MainActor
    static func createAttachment(
        from image: AnyObject,
        id: String
    ) async -> UNNotificationAttachment? {

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(id).png")

        let data: Data?

#if canImport(UIKit)
        data = (image as? UIImage)?.pngData()
#elseif canImport(AppKit)
        data = (image as? NSImage)?.pngData()
#else
        data = nil
#endif

        guard let png = data else { return nil }
        do {
            try png.write(to: tempURL)
            let attachment = try UNNotificationAttachment(
                identifier: id,
                url: tempURL,
                options: [:]
            )
            return attachment
        } catch {
            print("Attachment creation failed: \(error)")
            return nil
        }
    }
}

// MARK: - NSImage PNG Extension (macOS)

#if canImport(AppKit)
import AppKit

private extension NSImage {
    func pngData() -> Data? {
        guard
            let tiff = self.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff)
        else { return nil }

        return rep.representation(using: .png, properties: [:])
    }
}
#endif
