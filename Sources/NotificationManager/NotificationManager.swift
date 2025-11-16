//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import SimpleLogger
import DefaultsKit
@_exported import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

/// Manages local notification permissions, categories, and scheduling.
///
/// This class provides a unified interface for interacting with ``UNUserNotificationCenter``. It
/// handles permission requests, category registration, scheduling one-off or repeating
/// notifications, and querying or removing pending requests.
///
/// Instances of this manager are observable and update the UI automatically when permission-related
/// values change.
@MainActor
@Observable
public final class NotificationManager {

    /// The underlying system notification centre used to register categories, request permissions,
    /// schedule notifications, and inspect pending requests.
    @ObservationIgnored
    private let center = UNUserNotificationCenter.current()

    /// A logging helper used to record notification-related events such as permission requests,
    /// scheduling operations, and errors.
    @ObservationIgnored
    private let logger = SimpleLogger(category: .pushNotifications)

    /// The identifier used for the inactivity reminder notification.
    private static let inactivityReminderId = "com.markbattistella.package.notificationManager.inactivityReminder"

    /// The system’s current authorization state for local notifications.
    ///
    /// This value reflects the user’s most recently retrieved settings and is updated when permissions
    /// are requested or refreshed.
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// A Boolean value indicating whether the app has permission to deliver notifications.
    ///
    /// Returns `true` when the authorization state is `.authorized` or `.provisional`, and
    /// `false` in all other cases.
    public var permissionGranted: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }

    /// Creates a notification manager instance.
    public init() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        #endif

        Task {
            await refreshPermissionStatus()
        }
    }

    @objc
    private func handleAppDidBecomeActive() {
        Task { @MainActor [weak self] in
            await self?.refreshPermissionStatus()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
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
                        title: String(localized: $0.title),
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

    /// Requests permission to deliver local notifications and reports the outcome.
    ///
    /// This method evaluates the current authorization state and performs the appropriate action:
    ///
    /// - If the user has previously denied notifications, no permission prompt is shown and the
    /// result indicates that the app must redirect the user to Settings.
    /// - If permission has already been granted, the method returns immediately without
    /// displaying a prompt.
    /// - If the authorization status is undetermined, the system permission dialog is presented
    /// and the result reflects the user’s choice.
    ///
    /// The returned value describes the action taken and the resulting authorization state,
    /// allowing the caller to update the UI or navigate to system settings as needed.
    ///
    /// - Returns: A ``PermissionRequestResult`` value describing the outcome of the permission
    /// request flow.
    @MainActor
    @discardableResult
    public func requestPermission() async -> PermissionRequestResult {
        await refreshPermissionStatus()

        switch authorizationStatus {
            case .denied:
                #if canImport(UIKit) && !os(macOS)
                let url = URL(string: UIApplication.openNotificationSettingsURLString)!
                return .needsSettings(url)
                #else
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!
                return .needsSettings(url)
                #endif

            case .authorized, .provisional:
                return .alreadyAuthorized

            case .notDetermined, .ephemeral:
                do {
                    let granted = try await center
                        .requestAuthorization(options: [.alert, .sound, .badge])
                    await refreshPermissionStatus()
                    return granted ? .granted : .denied
                } catch {
                    self.authorizationStatus = .denied
                    return .error(error)
                }

            @unknown default:
                return .error(nil)
        }
    }

    /// Reloads the system’s current notification authorization status.
    ///
    /// This method queries ``UNUserNotificationCenter`` for the latest permission state and
    /// updates ``authorizationStatus`` accordingly.
    ///
    /// Use this method when the app becomes active or after returning from Settings to ensure the
    /// UI reflects any changes made by the user.
    @MainActor
    public func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }
}

// MARK: - Badge setting

extension NotificationManager {

    /// Sets the app's badge count to the specified number.
    ///
    /// - Parameter count: The badge number to display. Pass 0 to hide the badge.
    /// - Throws: An error if the badge count cannot be set.
    public func setBadgeCount(_ count: Int) async throws {
        try await center.setBadgeCount(count)
    }

    /// Clears the app's badge by setting it to zero.
    ///
    /// - Throws: An error if the badge count cannot be cleared.
    public func clearBadge() async throws {
        try await center.setBadgeCount(0)
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

    /// Convenience overload that accepts `LocalizedStringResource` and converts them to localized
    /// `String` before scheduling.
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
        title: LocalizedStringResource,
        body: LocalizedStringResource,
        category: NotificationCategoryDefinition? = nil,
        type: LocalNotificationType,
        sound: NotificationSound = .default,
        attachments: [NotificationAttachmentProviding] = [],
        userInfo: [AnyHashable : Any] = [:]
    ) async {
        await schedule(
            id: id,
            title: String(localized: title),
            body: String(localized: body),
            category: category,
            type: type,
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

    /// Convenience overload for repeating weekday notifications accepting `LocalizedStringResource`
    /// titles and bodies.
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
        title: LocalizedStringResource,
        body: LocalizedStringResource,
        category: NotificationCategoryDefinition? = nil,
        hour: Int,
        minute: Int,
        days: [NotificationWeekday],
        sound: NotificationSound = .default,
        attachments: [NotificationAttachmentProviding] = [],
        userInfo: [AnyHashable : Any] = [:]
    ) async {
        await scheduleRepeatingWeekdays(
            id: baseId,
            title: String(localized: title),
            body: String(localized: body),
            category: category,
            hour: hour,
            minute: minute,
            days: days,
            sound: sound,
            attachments: attachments,
            userInfo: userInfo
        )
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
        content.userInfo = userInfo
        content.sound = sound.value

        if let category {
            content.categoryIdentifier = category.id
        }

        let built: [UNNotificationAttachment] = await withTaskGroup(
            of: UNNotificationAttachment?.self
        ) { group in
            for item in attachments {
                group.addTask { await item.makeAttachment() }
            }

            var results: [UNNotificationAttachment] = []
            for await attachment in group {
                if let attachment {
                    results.append(attachment)
                }
            }
            return results
        }
        if !built.isEmpty { content.attachments = built }

        let trigger: UNNotificationTrigger

        switch type {
            case let .timeInterval(duration, repeats):
                let rawSeconds = duration.timeInterval
                let seconds = max(rawSeconds, repeats ? 60 : 0.1)
                if repeats && rawSeconds < 60 {
                    logger.warning("Repeating notification duration adjusted from \(rawSeconds)s to 60s (minimum)")
                }

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

// MARK: - Inactivity Scheduler

extension NotificationManager {

    /// Schedules a repeating inactivity reminder notification.
    ///
    /// This method stores the provided `duration` and the current timestamp in the
    /// notification-specific defaults container, removes any previously scheduled inactivity reminder,
    /// and registers a new repeating time-interval notification.
    ///
    /// Use this when your app wants to notify the user after a period of inactivity.
    ///
    /// - Parameters:
    ///   - duration: The interval before the reminder is delivered. Defaults to one week.
    ///   - title: The notification’s title text.
    ///   - body: The main message displayed in the notification.
    ///
    /// The reminder repeats automatically at the specified interval.
    public func scheduleInactivityReminder(
        duration: Duration = .seconds(7 * 24 * 60 * 60),
        title: String,
        body: String
    ) async {
        let id = Self.inactivityReminderId
        let defaults = UserDefaults.notification

        defaults.set(
            duration.timeInterval,
            for: NotificationsUserDefaultsKey.inactivityIntervalSeconds
        )
        defaults.set(
            Date.now,
            for: NotificationsUserDefaultsKey.appLastOpened
        )

        removePendingNotification(id: id)

        await schedule(
            id: id,
            title: title,
            body: body,
            type: .timeInterval(duration: duration, repeats: true),
            sound: .default
        )
    }

    /// Records the current time as the app’s last-open timestamp.
    ///
    /// This value is used by the inactivity reminder system to track user activity. Host
    /// applications should call this when the app becomes active or when the relevant feature is
    /// used.
    public func markAppOpened() {
        UserDefaults.notification.set(
            Date.now,
            for: NotificationsUserDefaultsKey.appLastOpened
        )
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

    /// Removes a single delivered notification from Notification Center.
    ///
    /// Use this method to remove a notification that has already been delivered and is visible in
    /// the notification center. This does not affect pending notifications.
    ///
    /// - Parameter id: The identifier of the delivered notification to remove.
    public func removeDeliveredNotification(id: String) {
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }

    /// Removes all delivered notifications from Notification Center.
    ///
    /// Use this method to clear all notifications that have been delivered to the user. This does
    /// not affect pending notifications that have not yet been delivered.
    public func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }

    /// Fetches all delivered notifications currently visible in Notification Center.
    ///
    /// - Returns: An array of all `UNNotification` objects that have been delivered and are still
    /// visible to the user.
    public func deliveredNotifications() async -> [UNNotification] {
        await center.deliveredNotifications()
    }

    /// Checks whether a notification with the given identifier is currently scheduled.
    ///
    /// - Parameter id: The notification identifier to check.
    /// - Returns: `true` if a pending notification with this ID exists, `false` otherwise.
    public func isNotificationScheduled(id: String) async -> Bool {
        let pending = await center.pendingNotificationRequests()
        return pending.contains { $0.identifier == id }
    }
}
