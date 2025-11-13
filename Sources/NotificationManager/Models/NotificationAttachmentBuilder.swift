//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import UIKit
import SwiftUI
import UserNotifications

/// A factory namespace for building `UNNotificationAttachment` instances from images, SF Symbols,
/// or rendered SwiftUI views.
///
/// Each nested builder conforms to ``NotificationAttachmentProviding`` and produces a fully-formed
/// attachment stored in a temporary location suitable for use with `UNMutableNotificationContent`.
public enum NotificationAttachmentBuilder {

    // MARK: - 1. UIImage Builder

    /// A builder that creates a notification attachment from a `UIImage`.
    ///
    /// Use this when you already have raster image data and want it displayed inside a local
    /// notification.
    public struct Image: NotificationAttachmentProviding {

        private let image: UIImage
        private let id: String

        /// Creates an image-based attachment builder.
        ///
        /// - Parameters:
        ///   - image: The image to encode and attach.
        ///   - id: A unique identifier for the attachment file. Defaults to a generated UUID.
        public init(_ image: UIImage, id: String = UUID().uuidString) {
            self.image = image
            self.id = id
        }

        /// Produces a `UNNotificationAttachment` using the stored image.
        ///
        /// The image is written to a temporary file and then wrapped inside a
        /// `UNNotificationAttachment`. The temporary file is removed after the attachment is
        /// created.
        ///
        /// - Returns: A notification attachment, or `nil` if creation fails.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {
            return await NotificationAttachmentBuilder.createAttachment(from: image, id: id)
        }
    }

    // MARK: - 2. SF Symbol Builder

    /// A builder that renders an SF Symbol into an image and converts it into a
    /// `UNNotificationAttachment`.
    ///
    /// Use this when you need dynamic or stylised SF Symbol artwork in a notification.
    public struct Symbol: NotificationAttachmentProviding {

        private let name: String
        private let pointSize: CGFloat
        private let weight: UIImage.SymbolWeight
        private let scale: UIImage.SymbolScale
        private let foreground: UIColor
        private let background: UIColor
        private let id: String

        /// Creates an SF Symbol-based attachment builder.
        ///
        /// - Parameters:
        ///   - name: The SF Symbol name.
        ///   - pointSize: The symbol rendering point size.
        ///   - weight: The symbol stroke weight.
        ///   - scale: The symbol scale.
        ///   - foreground: The foreground colour applied when drawing.
        ///   - background: The background fill colour behind the symbol.
        ///   - id: A unique identifier for the attachment file.
        public init(
            _ name: String,
            pointSize: CGFloat = 80,
            weight: UIImage.SymbolWeight = .regular,
            scale: UIImage.SymbolScale = .medium,
            foreground: UIColor = .white,
            background: UIColor = .clear,
            id: String = UUID().uuidString
        ) {
            self.name = name
            self.pointSize = pointSize
            self.weight = weight
            self.scale = scale
            self.foreground = foreground
            self.background = background
            self.id = id
        }

        /// Renders the configured SF Symbol into a raster image and produces a notification
        /// attachment.
        ///
        /// - Returns: A notification attachment, or `nil` if the symbol cannot be rendered or the
        /// attachment cannot be created.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {

            let config = UIImage.SymbolConfiguration(
                pointSize: pointSize,
                weight: weight,
                scale: scale
            )

            guard let symbol = UIImage(systemName: name, withConfiguration: config) else {
                return nil
            }

            let renderer = UIGraphicsImageRenderer(size: symbol.size)
            let rendered = renderer.image { ctx in
                background.setFill()
                ctx.fill(CGRect(origin: .zero, size: symbol.size))

                foreground.setFill()
                symbol.draw(at: .zero)
            }

            return await NotificationAttachmentBuilder.createAttachment(from: rendered, id: id)
        }
    }

    // MARK: - 3. SwiftUI View Builder

    /// A builder that renders a SwiftUI view into an image and converts it into a
    /// `UNNotificationAttachment`.
    ///
    /// Use this to embed custom layouts, shapes, colours, or dynamic SwiftUI content inside a
    /// notification.
    public struct View<V: SwiftUI.View & Sendable>: NotificationAttachmentProviding {

        private let view: V
        private let size: CGSize
        private let scale: CGFloat
        private let id: String

        /// Creates a view-based attachment builder.
        ///
        /// - Parameters:
        ///   - view: The SwiftUI view to render.
        ///   - size: The rendering size of the view.
        ///   - scale: The output scale factor.
        ///   - id: A unique identifier for the attachment file.
        public init(
            _ view: V,
            size: CGSize = .init(width: 120, height: 120),
            scale: CGFloat = UIScreen.main.scale,
            id: String = UUID().uuidString
        ) {
            self.view = view
            self.size = size
            self.scale = scale
            self.id = id
        }

        /// Renders the SwiftUI view into an image and produces a notification attachment.
        ///
        /// - Returns: The created attachment, or `nil` if rendering fails.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {
            let renderer = ImageRenderer(
                content: view.frame(width: size.width, height: size.height)
            )
            renderer.scale = scale

            guard let uiImage = renderer.uiImage else { return nil }
            return await NotificationAttachmentBuilder.createAttachment(from: uiImage, id: id)
        }
    }
}

// MARK: - Shared Helper

extension NotificationAttachmentBuilder {

    /// Writes an image to a temporary file and wraps it in a `UNNotificationAttachment`.
    ///
    /// The temporary file is removed immediately after attachment creation. This method must run
    /// on the main actor due to UIKit and notifications-related APIs.
    ///
    /// - Parameters:
    ///   - image: The image to encode.
    ///   - id: A unique filename and attachment identifier.
    ///
    /// - Returns: A notification attachment, or `nil` if encoding fails.
    @MainActor
    static func createAttachment(
        from image: UIImage,
        id: String
    ) async -> UNNotificationAttachment? {

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(id).png")

        guard let data = image.pngData() else { return nil }

        do {
            try data.write(to: url)
            let attachment = try UNNotificationAttachment(identifier: id, url: url)

            try? FileManager.default.removeItem(at: url)

            return attachment

        } catch {
            print("Failed to create attachment: \(error)")
            return nil
        }
    }
}
