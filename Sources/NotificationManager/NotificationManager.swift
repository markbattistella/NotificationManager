//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import SimpleLogger
@_exported import UserNotifications

/// Manages all local notification behaviour.
///
/// This manager provides a unified interface for requesting permissions, registering categories,
/// scheduling one-off or repeating notifications, creating attachments, and inspecting or removing
/// pending requests.
///
/// Use this class as the single point of interaction with `UNUserNotificationCenter`.
@MainActor
@Observable
public final class NotificationManager {

    /// Indicates whether the user has granted notification permissions.
    ///
    /// This value is updated after calling ``requestPermission()`` or ``refreshPermissionStatus()``.
    public var permissionGranted: Bool = false

    @ObservationIgnored
    private let center = UNUserNotificationCenter.current()

    @ObservationIgnored
    private let logger = SimpleLogger(category: .pushNotifications)

    /// Creates a notification manager instance.
    ///
    /// The manager is responsible for coordinating permission access, category registration,
    /// scheduling operations, and interacting with pending notifications.
    public init() { }
}

// MARK: - Category Registration

extension NotificationManager {

    /// Registers a set of custom notification categories.
    ///
    /// - Parameter categories: A list of category definitions describing identifiers, actions, and
    /// configuration options.
    ///
    /// Register categories before scheduling notifications that specify a custom category
    /// identifier.
    public func registerCategories(_ categories: [NotificationCategoryDefinition]) {
        let mapped = categories.map { category in
            UNNotificationCategory(
                identifier: category.id,
                actions: category.actions.map {
                    UNNotificationAction(
                        identifier: $0.id,
                        title: $0.title,
                        options: $0.options
                    )
                },
                intentIdentifiers: [],
                options: category.options
            )
        }

        center.setNotificationCategories(Set(mapped))
    }
}

// MARK: - Permissions

extension NotificationManager {

    /// Requests authorisation for alert, sound, and badge notifications.
    ///
    /// On completion, updates ``permissionGranted`` with the result.
    @MainActor
    public func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
        } catch {
            permissionGranted = false
        }
    }

    /// Updates ``permissionGranted`` using the system’s current authorisation state.
    ///
    /// Permissions are considered granted if the user’s status is `.authorized` or `.provisional`.
    @MainActor
    public func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized ||
        settings.authorizationStatus == .provisional
    }
}

// MARK: - Scheduling

extension NotificationManager {

    /// Schedules a one-off or repeating notification.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the request.
    ///   - title: The notification’s title.
    ///   - body: The main notification text.
    ///   - category: The category definition used for custom actions.
    ///   - type: Defines whether the notification is time-interval, calendar-based, or
    ///   location-triggered.
    ///   - sound: The notification sound to play when delivered.
    ///   - attachments: Optional attachment providers that generate `UNNotificationAttachment`
    ///   objects.
    ///   - userInfo: Arbitrary metadata attached to the request.
    ///
    /// Use this method for all single-notification scheduling needs.
    public func schedule(
        id: String,
        title: String,
        body: String,
        category: NotificationCategoryDefinition? = nil,
        type: LocalNotificationType,
        sound: NotificationSound = .default,
        attachments: [NotificationAttachmentProviding] = [],
        userInfo: [AnyHashable : Any] = [:]
    ) async {

        await scheduleInternal(
            id: id,
            title: title,
            body: body,
            category: category,
            type: type,
            weekday: nil,
            sound: sound,
            attachments: attachments,
            userInfo: userInfo
        )
    }

    /// Schedules repeating weekday-based notifications.
    ///
    /// Creates one request per supplied weekday by combining the `baseId` with the numeric
    /// weekday value.
    ///
    /// - Parameters:
    ///   - baseId: The root identifier for all weekday instances.
    ///   - title: Notification title text.
    ///   - body: Notification body text.
    ///   - category: Optional category association.
    ///   - hour: Hour component for the trigger (24-hour format).
    ///   - minute: Minute component for the trigger.
    ///   - days: The weekdays on which notifications repeat.
    ///   - sound: The notification sound to play when delivered.
    ///   - attachments: Optional attachment items.
    ///   - userInfo: Metadata added to each corresponding request.
    public func scheduleRepeatingWeekdays(
        id baseId: String,
        title: String,
        body: String,
        category: NotificationCategoryDefinition? = nil,
        hour: Int,
        minute: Int,
        days: [NotificationWeekday],
        sound: NotificationSound = .default,
        attachments: [NotificationAttachmentProviding] = [],
        userInfo: [AnyHashable : Any] = [:]
    ) async {

        for day in days {
            let id = "\(baseId)_\(day.value)"

            await scheduleInternal(
                id: id,
                title: title,
                body: body,
                category: category,
                type: .calendar(weekday: nil, hour: hour, minute: minute, repeats: true),
                weekday: day.value,
                sound: sound,
                attachments: attachments,
                userInfo: userInfo.merging(["weekday": day.value]) { $1 }
            )
        }
    }

    // MARK: - Private Scheduling

    /// Builds the content, attachments, and trigger for a notification request, then submits it
    /// to the notification centre.
    ///
    /// This method is used internally by public scheduling APIs.
    ///
    /// - Parameters:
    ///   - id: Unique request identifier.
    ///   - title: Displayed title.
    ///   - body: Displayed body text.
    ///   - category: Optional category identifier.
    ///   - type: Determines the trigger style.
    ///   - weekday: Optional weekday number for calendar triggers.
    ///   - sound: The notification sound to play when delivered.
    ///   - attachments: Providers for attachment generation.
    ///   - userInfo: Arbitrary metadata.
    private func scheduleInternal(
        id: String,
        title: String,
        body: String,
        category: NotificationCategoryDefinition?,
        type: LocalNotificationType,
        weekday: Int? = nil,
        sound: NotificationSound,
        attachments: [NotificationAttachmentProviding],
        userInfo: [AnyHashable : Any]
    ) async {

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        content.sound = sound.value

        if let category {
            content.categoryIdentifier = category.id
        }

        let built: [UNNotificationAttachment] = await {
            var result: [UNNotificationAttachment] = []
            for item in attachments {
                if let attachment = await item.makeAttachment() {
                    result.append(attachment)
                }
            }
            return result
        }()
        if !built.isEmpty { content.attachments = built }

        let trigger: UNNotificationTrigger

        switch type {
            case let .timeInterval(seconds, repeats):
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: seconds,
                    repeats: repeats
                )

            case let .calendar(_, hour, minute, repeats):
                var comps = DateComponents()
                comps.hour = hour
                comps.minute = minute
                comps.weekday = weekday

                trigger = UNCalendarNotificationTrigger(
                    dateMatching: comps,
                    repeats: repeats
                )

            #if os(iOS) || os(watchOS)
            case let .location(region, repeats):
                trigger = UNLocationNotificationTrigger(
                    region: region,
                    repeats: repeats
                )
            #endif
        }

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            logger.error("Failed to schedule notification \(id): \(error.localizedDescription)")
        }
    }
}

// MARK: - Removal & Queries

extension NotificationManager {

    /// Removes a single pending notification.
    ///
    /// - Parameter id: The identifier of the pending request to remove.
    public func removePendingNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Removes all pending notifications whose identifiers begin with the specified prefix.
    ///
    /// - Parameter prefix: A string prefix used to match request identifiers.
    public func removePendingNotifications(matchingPrefix prefix: String) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Removes weekday-specific repeating notifications created using
    /// ``scheduleRepeatingWeekdays(id:title:body:category:hour:minute:days:attachments:userInfo:)``.
    ///
    /// - Parameters:
    ///   - baseId: The base identifier from which weekday IDs were derived.
    ///   - days: A list of weekdays corresponding to the generated identifiers.
    public func removePendingWeekdayNotifications(baseId: String, days: [NotificationWeekday]) {
        let ids = days.map { "\(baseId)_\($0.value)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Removes every pending local notification request.
    public func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    /// Fetches all pending notification requests.
    ///
    /// - Returns: An array of all `UNNotificationRequest` values currently registered.
    public func pendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    /// Fetches pending notifications whose identifiers begin with a given prefix.
    ///
    /// - Parameter prefix: The prefix used for filtering.
    /// - Returns: All matching notification requests.
    public func pendingNotifications(matchingPrefix prefix: String) async -> [UNNotificationRequest] {
        let all = await center.pendingNotificationRequests()
        return all.filter { $0.identifier.hasPrefix(prefix) }
    }
}
