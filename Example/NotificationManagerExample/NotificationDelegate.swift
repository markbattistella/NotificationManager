//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import NotificationManager
import SwiftUI

/// Delegate responsible for handling notification presentation and user actions.
///
/// This class serves as the ``UNUserNotificationCenterDelegate`` for the app, enabling foreground
/// presentation and routing or scheduling behaviour when users interact with delivered
/// notifications.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

    /// Shared singleton instance used across the application.
    static let shared = NotificationDelegate()

    /// Reference to the notification manager for scheduling follow-up actions.
    weak var notificationManager: NotificationManager?

    /// Reference to the notification router for navigating based on actions.
    weak var router: NotificationRouter?

    /// Determines how notifications are presented when the app is in the foreground.
    ///
    /// - Parameters:
    ///   - center: The notification centre handling the request.
    ///   - notification: The notification being delivered.
    ///   - completionHandler: A closure specifying allowed presentation options.
    ///
    /// This implementation ensures banners, list entries, and sounds are shown even while the app
    /// is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
        @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    /// Handles user interactions with delivered notifications.
    ///
    /// - Parameters:
    ///   - center: The notification centre handling the request.
    ///   - response: The user’s chosen action or notification tap.
    ///   - completionHandler: A closure executed once handling is complete.
    ///
    /// This method routes to detail views, schedules snoozed alerts, or performs no action
    /// depending on the tapped button.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {

        let info = response.notification.request.content.userInfo

        switch response.actionIdentifier {

            case DemoAction.open.id:
                if let id = info["noteID"] as? String {
                    router?.route = .detail(id: id)
                }

            case DemoAction.snooze.id:
                Task {
                    let attachment = NotificationAttachmentBuilder.Symbol(
                        "clock.fill",
                        foreground: .red,
                        background: .yellow,
                    )

                    await notificationManager?.schedule(
                        id: "snooze-\(UUID().uuidString)",
                        title: "Snoozed Notification",
                        body: "This is a snoozed alert.",
                        category: SnoozeCategory.oneOff,
                        type: .timeInterval(seconds: 10, repeats: false),
                        attachments: [attachment],
                        userInfo: info
                    )
                }

            case DemoAction.cancel.id:
                break

            default:
                break
        }

        completionHandler()
    }
}
