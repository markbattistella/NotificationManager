//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import SimpleLogger
@_exported import UserNotifications

@MainActor
@Observable
public final class NotificationManager {

    /// Indicates whether the user has granted notification permissions.
    public var permissionGranted: Bool = false

    /// The system notification centre instance.
    @ObservationIgnored
    private let center = UNUserNotificationCenter.current()

    /// Logger used for internal debugging and push-notification–related events.
    @ObservationIgnored
    private let logger = SimpleLogger(category: .pushNotifications)

    /// Creates a new instance of the notification manager.
    public init() { }
}

// MARK: - Category Registration

extension NotificationManager {

    /// Registers custom notification categories with the system.
    ///
    /// - Parameter categories: A collection of category definitions describing
    ///   identifiers, actions, and options to register.
    ///
    /// Use this method before scheduling notifications that reference custom categories.
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

    /// Requests notification permission from the user.
    ///
    /// Updates ``permissionGranted`` based on the user's response.
    /// Call this method as part of your app’s onboarding or before scheduling notifications.
    @MainActor
    public func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permissionGranted = granted
        } catch {
            permissionGranted = false
        }
    }

    /// Refreshes the current notification permission status.
    ///
    /// Updates ``permissionGranted`` based on the device's current settings.
    @MainActor
    public func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionGranted = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
}

// MARK: - Scheduling

extension NotificationManager {

    /// Schedules a local notification with configurable content and trigger type.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the notification request.
    ///   - title: The notification title.
    ///   - body: The notification body.
    ///   - category: Optional category definition applied to the notification.
    ///   - type: The trigger type used to determine when the notification fires.
    ///   - userInfo: Additional metadata supplied with the notification payload.
    ///
    /// This method supports time interval, calendar-based, and location-based triggers.
    public func schedule(
        id: String,
        title: String,
        body: String,
        category: NotificationCategoryDefinition? = nil,
        type: LocalNotificationType,
        userInfo: [AnyHashable : Any] = [:]
    ) async {

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        content.userInfo = userInfo

        if let category { content.categoryIdentifier = category.id }

        let trigger: UNNotificationTrigger

        switch type {
            case let .timeInterval(seconds, repeats):
                trigger = UNTimeIntervalNotificationTrigger(
                    timeInterval: seconds,
                    repeats: repeats
                )

            case let .calendar(weekday, hour, minute, repeats):
                var comps = DateComponents()
                comps.hour = hour
                comps.minute = minute
                if let weekday { comps.weekday = weekday }
                trigger = UNCalendarNotificationTrigger(
                    dateMatching: comps,
                    repeats: repeats
                )

            case let .location(region, repeats):
                trigger = UNLocationNotificationTrigger(
                    region: region,
                    repeats: repeats
                )
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

    // MARK: - Weekday scheduling

    /// Schedules repeating notifications for multiple weekdays.
    ///
    /// - Parameters:
    ///   - id: The identifier applied to each scheduled request.
    ///   - title: The notification title.
    ///   - body: The notification body.
    ///   - category: Optional category definition applied to the notification.
    ///   - hour: The hour component of the schedule.
    ///   - minute: The minute component of the schedule.
    ///   - days: The weekdays on which the notification should repeat.
    ///   - userInfo: Additional metadata to include in each request.
    ///
    /// A separate notification request is created for each weekday supplied.
    public func scheduleRepeatingWeekdays(
        id baseId: String,
        title: String,
        body: String,
        category: NotificationCategoryDefinition? = nil,
        hour: Int,
        minute: Int,
        days: [Weekday],
        userInfo: [AnyHashable : Any] = [:]
    ) async {

        for day in days {
            let id = "\(baseId)_\(day.value)"
            await schedule(
                id: id,
                title: title,
                body: body,
                category: category,
                type: .calendar(
                    weekday: day.value,
                    hour: hour,
                    minute: minute,
                    repeats: true
                ),
                userInfo: userInfo.merging(["weekday": day.value]) { $1 }
            )
        }
    }
}

// MARK: - Removal & Queries

extension NotificationManager {

    // MARK: Single Removal

    /// Removes a pending notification with the specified identifier.
    public func removePendingNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: Prefix Removal

    /// Removes all pending notifications whose identifiers begin with the given prefix.
    public func removePendingNotifications(matchingPrefix prefix: String) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }

        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    /// Removes pending weekday-based repeating notifications.
    public func removePendingWeekdayNotifications(baseId: String, days: [Weekday]) {
        let ids = days.map { "\(baseId)_\($0.value)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: Remove All

    /// Removes all pending local notifications.
    public func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: Queries

    /// Returns all pending notification requests.
    public func pendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    /// Returns all pending notifications whose identifiers begin with the given prefix.
    public func pendingNotifications(matchingPrefix prefix: String) async -> [UNNotificationRequest] {
        let all = await center.pendingNotificationRequests()
        return all.filter { $0.identifier.hasPrefix(prefix) }
    }
}
