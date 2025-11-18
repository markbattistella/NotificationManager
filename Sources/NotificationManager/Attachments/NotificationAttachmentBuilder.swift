//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI

/// A namespace containing helper types for generating notification attachments from images,
/// views, and system symbols.
///
/// Each builder conforms to ``NotificationAttachmentFactory`` and produces a
/// ``UNNotificationAttachment`` suitable for inclusion in a notification request.
public enum NotificationAttachmentBuilder {

    #if canImport(UIKit)
    /// Creates a notification attachment from a `UIImage`.
    ///
    /// This builder writes the image to a temporary file and returns an attachment referencing
    /// that file. Use this when you already have a prepared image.
    public struct AttachmentImage: NotificationAttachmentFactory {

        private let image: UIImage
        private let id: String

        /// Creates a new image-based attachment builder.
        ///
        /// - Parameters:
        ///   - image: The source image used to generate the attachment.
        ///   - id: A unique identifier for the attachment file. Defaults to a UUID.
        public init(_ image: UIImage, id: String = UUID().uuidString) {
            self.image = image
            self.id = id
        }

        /// Generates the attachment by encoding the image as PNG and writing it to disk.
        ///
        /// - Returns: A `UNNotificationAttachment` containing the rendered image, or `nil` if
        /// creation fails.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {
            await NotificationAttachmentBuilder.createAttachment(
                from: image,
                id: id
            )
        }
    }
    #endif

    /// Creates a notification attachment from a rendered SF Symbol.
    ///
    /// This builder renders a symbol inside a coloured background using SwiftUI, converts it
    /// into an image, and produces a PNG-based attachment.
    public struct AttachmentSymbol: NotificationAttachmentFactory {
        private let name: String
        private let size: CGSize
        private let foreground: Color
        private let background: Color
        private let id: String

        /// Creates a new symbol-based attachment builder.
        ///
        /// - Parameters:
        ///   - name: The SF Symbol name to render.
        ///   - size: The rendering size. Defaults to `80×80`.
        ///   - foreground: The symbol foreground colour.
        ///   - background: The background colour.
        ///   - id: A unique identifier for the attachment file.
        public init(
            _ name: String,
            size: CGSize = .init(width: 300, height: 300),
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

        /// Renders the symbol using SwiftUI and converts it into a notification attachment.
        ///
        /// - Returns: A `UNNotificationAttachment` containing the rendered symbol, or `nil`
        ///   if rendering fails.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {

            let view = ZStack {
                background
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(foreground)
                    .padding(10)
            }.frame(width: size.width, height: size.height)

            let renderer = ImageRenderer(content: view)
            renderer.applyPlatformScale()

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

    /// Creates a notification attachment from an arbitrary SwiftUI view.
    ///
    /// The view is rendered at the specified size and converted into a PNG image for use as an
    /// attachment.
    public struct AttachmentView<V: View>: NotificationAttachmentFactory {
        private let view: V
        private let size: CGSize
        private let id: String

        /// Creates a new view-based attachment builder.
        ///
        /// - Parameters:
        ///   - view: The SwiftUI view to render.
        ///   - size: The size of the rendered view. Defaults to `120×120`.
        ///   - id: A unique identifier for the attachment file.
        public init(
            _ view: V,
            size: CGSize = .init(width: 300, height: 300),
            id: String = UUID().uuidString
        ) {
            self.view = view
            self.size = size
            self.id = id
        }

        /// Renders the view to an image and produces a notification attachment.
        ///
        /// - Returns: A `UNNotificationAttachment` containing the rendered view, or `nil` if
        /// rendering fails.
        @MainActor
        public func makeAttachment() async -> UNNotificationAttachment? {

            let renderer = ImageRenderer(
                content: view
                    .frame(width: size.width, height: size.height)
            )
            renderer.applyPlatformScale()

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

extension NotificationAttachmentBuilder {

    /// Creates a `UNNotificationAttachment` by writing an image to a temporary PNG file.
    ///
    /// This method accepts either a `UIImage` or `NSImage`, based on platform availability. If
    /// the image cannot be converted to PNG data or written to disk, the method returns `nil`.
    ///
    /// - Parameters:
    ///   - image: The platform image object.
    ///   - id: The identifier used for the attachment and temp file.
    /// - Returns: A `UNNotificationAttachment`, or `nil` if creation fails.
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
