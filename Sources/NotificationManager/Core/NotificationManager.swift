//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

import Foundation
import Observation
import SimpleLogger
import DefaultsKit
@_exported import UserNotifications

/// A manager responsible for tracking and refreshing the app’s notification-related state,
/// including authorisation status and pending notification counts.
///
/// This type observes changes to its published properties and refreshes state when the app
/// becomes active. It also performs an initial refresh on creation.
@MainActor
@Observable
public final class NotificationManager {
    
    // MARK: Non-observed
    
    /// The system notification centre used to query and manage notification settings.
    @ObservationIgnored
    private let center = UNUserNotificationCenter.current()
    
    /// Logger used for recording push-notification–related events.
    @ObservationIgnored
    private let logger = SimpleLogger(category: .pushNotifications)
    
    /// User defaults storage for persisting notification-related values.
    @ObservationIgnored
    private let defaults = UserDefaults.notification
    
    /// A task used to perform the initial state refresh when the manager is created.
    @ObservationIgnored
    private var initialRefreshTask: Task<Void, Never>?
    
    /// A task used to perform state refreshes whenever the app enters the foreground.
    @ObservationIgnored
    private var foregroundRefreshTask: Task<Void, Never>?
    
    // MARK: Observed
    
    /// The current notification authorisation status for the application.
    ///
    /// This value is updated during refresh operations.
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Indicates whether the user has granted notification permissions.
    ///
    /// This returns `true` when the authorisation status is either `.authorized` or
    /// `.provisional`.
    public var permissionGranted: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    /// Indicates whether any pending notifications exist for the application.
    ///
    /// This value is updated during refresh operations.
    public var hasPendingNotifications: Bool = false
    
    // MARK: Initialiser
    
    /// Creates a new notification manager, registers for foreground-activation notifications,
    /// and triggers an initial refresh of notification state.
    public init() {
        #if canImport(UIKit)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        #elseif canImport(AppKit)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        #endif
        
        initialRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshAll()
        }
    }
    
    /// Cancels any active refresh tasks and removes the activity observer.
    deinit {
        initialRefreshTask?.cancel()
        foregroundRefreshTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
    
    /// Called when the application becomes active.
    ///
    /// Cancels any in-progress foreground refresh and starts a new refresh task.
    @objc
    private func appDidBecomeActive() {
        foregroundRefreshTask?.cancel()
        foregroundRefreshTask = Task { [weak self] in
            guard let self else { return }
            await self.refreshAll()
        }
    }
}

// MARK: - Internals

extension NotificationManager {
    
    /// Refreshes the state indicating whether any pending notification requests exist.
    ///
    /// This method queries the system for all pending notification requests and updates
    /// ``hasPendingNotifications`` based on whether the returned list is empty.
    internal func refreshPendingState() async {
        let pending = await pendingNotifications()
        hasPendingNotifications = !pending.isEmpty
    }
    
    /// Performs a full refresh of all notification-related state managed by
    /// ``NotificationManager``.
    ///
    /// This method updates both the current authorisation status and the presence of pending
    /// notification requests.
    public func refreshAll() async {
        await refreshAuthorizationStatus()
        await refreshPendingState()
    }
}

// MARK: - Permission

extension NotificationManager {

    /// Requests notification authorisation from the user using the specified options.
    ///
    /// This method first refreshes the current authorisation status, then behaves according to
    /// that status:
    /// - If already authorised or provisionally authorised, returns
    /// ``PermissionRequestResult.authorized``.
    /// - If denied, returns ``PermissionRequestResult.denied`` with a URL pointing to the
    /// system’s notification settings.
    /// - If not determined or ephemeral, attempts a new authorisation request and returns either
    /// ``PermissionRequestResult.authorized`` or ``PermissionRequestResult.denied``.
    /// - If an error occurs during the request, sets the status to `.denied`, logs the error, and
    /// returns ``PermissionRequestResult.error``.
    ///
    /// - Parameter options: The notification features being requested. Defaults to alert
    /// permissions.
    /// - Returns: A result value describing the outcome of the authorisation request.
    public func requestAuthorization(
        for options: UNAuthorizationOptions = [.alert]
    ) async -> PermissionRequestResult {
        await refreshAuthorizationStatus()

        switch authorizationStatus {
            case .authorized, .provisional:
                return .authorized

            case .denied:
                let url = appNotificationSettingsURL()
                return .denied(url)

            case .notDetermined, .ephemeral:
                do {
                    let granted = try await center.requestAuthorization(options: options)
                    await refreshAuthorizationStatus()
                    return granted ? .authorized : .denied(nil)
                } catch {
                    self.authorizationStatus = .denied
                    logger.error("Authorization request failed: \(error.localizedDescription)")
                    return .error(error)
                }

            @unknown default:
                logger.error("Unknown authorization status: \(self.authorizationStatus.rawValue)")
                return .error(nil)
        }
    }

    /// Updates the app’s notification authorisation options.
    ///
    /// Call this method to request additional notification capabilities after the user has
    /// already granted either full or provisional authorisation. If the current authorisation
    /// status is neither authorised nor provisional, the method exits without making a new
    /// request.
    ///
    /// - Parameter options: The notification options to request from the system.
    /// - Note: Logs a warning if the request for additional options fails.
    public func updateOptions(to options: UNAuthorizationOptions) async {
        guard [.authorized, .provisional].contains(authorizationStatus) else { return }
        do {
            try await center.requestAuthorization(options: options)
        } catch {
            logger.warning("Failed to request additional notification options: \(error.localizedDescription)")
        }
    }

    /// Refreshes the cached notification authorisation status.
    ///
    /// This method queries the system for the current notification settings and updates
    /// ``authorizationStatus`` accordingly.
    internal func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        self.authorizationStatus = settings.authorizationStatus
    }
    
    /// Returns the system URL for the application's notification settings page.
    ///
    /// The exact URL depends on the platform:
    /// - On iOS, returns the system-defined URL pointing to the app’s notification settings.
    /// - On macOS, constructs a System Settings deep link using the app’s bundle identifier.
    ///
    /// - Returns: A URL that can be opened to show the user their notification settings.
    /// - Precondition: The URL must be valid for the platform; otherwise the process terminates.
    internal func appNotificationSettingsURL() -> URL {

        #if canImport(UIKit) && !os(macOS)

        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            preconditionFailure("Invalid iOS notification settings URL")
        }
        return url

        #else

        guard let bundleID = Bundle.main.bundleIdentifier?
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            preconditionFailure("Missing bundle identifier")
        }
        
        let urlString = "x-apple.systempreferences:com.apple.preference.notifications?\(bundleID)"
        
        guard let url = URL(string: urlString) else {
            preconditionFailure("Invalid macOS notification settings URL")
        }
        
        return url

        #endif
    }
}

// MARK: - Notification Capabilities

extension NotificationManager {
    
    /// Returns the app’s effective notification capabilities based on the current system
    /// notification settings.
    ///
    /// This method queries the system for notification settings and reports which capabilities
    /// are enabled, including alerts, sounds, badges, announcements, and critical alerts.
    ///
    /// - Returns: A ``NotificationCapabilities`` value describing the enabled features.
    public func capabilities() async -> NotificationCapabilities {
        let settings = await center.notificationSettings()

        #if os(macOS)
        let allowsAnnouncements = false
        #else
        let allowsAnnouncements = (settings.announcementSetting == .enabled)
        #endif

        return NotificationCapabilities(
            allowsAlert: settings.alertSetting == .enabled,
            allowsSound: settings.soundSetting == .enabled,
            allowsBadge: settings.badgeSetting == .enabled,
            allowsAnnouncements: allowsAnnouncements,
            criticalAlertSupported: settings.criticalAlertSetting == .enabled
        )
    }
}


// MARK: - Category Registration

extension NotificationManager {
    
    /// Registers the specified notification categories with the system.
    ///
    /// Each ``NotificationCategoryDescriptor`` is converted into a ``UNNotificationCategory``
    /// with its associated actions. The resulting set replaces all previously registered
    /// categories for the application.
    ///
    /// - Parameter categories: The custom notification categories to register.
    ///
    /// After registration completes, a log entry is recorded indicating the number of categories
    /// registered.
    public func registerCategories(_ categories: [NotificationCategoryDescriptor]) {
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
        logger.info("Registered \(categories.count) notification categories")
    }
}

// MARK: - Standard Notifications

extension NotificationManager {
    
    /// Schedules a local notification with the specified content and delivery configuration.
    ///
    /// Before scheduling, this method refreshes the current authorisation status and verifies
    /// that notification permission has been granted. If permission is denied, the method logs a
    /// warning and returns a failure result.
    ///
    /// On success, the request is forwarded to the internal scheduling routine, which handles
    /// creation of the notification content, trigger configuration, attachment processing, and
    /// final submission to the notification centre.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the notification request.
    ///   - title: The primary text displayed in the notification.
    ///   - subtitle: Optional secondary text displayed beneath the title.
    ///   - body: The main content text of the notification.
    ///   - category: An optional category descriptor used to configure actions.
    ///   - type: The notification delivery type, such as immediate or scheduled.
    ///   - sound: The notification sound to play. Defaults to ``NotificationSound.default``.
    ///   - badge: An optional badge number to apply to the app icon.
    ///   - attachments: Optional attachments created using ``NotificationAttachmentFactory``.
    ///   - interruptionLevel: The interruption level controlling the prominence of the
    ///   notification.
    ///   - userInfo: Additional metadata to include in the notification payload.
    ///   - launchImageName: Optional image name to display when the app launches from the
    ///   notification.
    ///   - targetContentIdentifier: An optional identifier for targeted content updates.
    ///   - relevanceScore: A floating-point score used by the system for relevance-based
    ///   delivery.
    ///   - filterCriteria: Optional filter criteria used in notification summaries and
    ///   relevance.
    ///   - threadIdentifier: Optional thread identifier for grouping notifications.
    ///
    /// - Returns: A result indicating success or failure of scheduling the notification.
    @discardableResult
    public func schedule(
        id: String,
        title: String,
        subtitle: String = "",
        body: String,
        category: NotificationCategoryDescriptor? = nil,
        type: NotificationType,
        sound: NotificationSound = .default,
        badge: Int? = nil,
        attachments: [NotificationAttachmentFactory] = [],
        interruptionLevel: UNNotificationInterruptionLevel = .active,
        userInfo: [AnyHashable : Any] = [:],
        launchImageName: String? = nil,
        targetContentIdentifier: String? = nil,
        relevanceScore: Double = 1,
        filterCriteria: String? = nil,
        threadIdentifier: String? = nil
    ) async -> Result<Void, Error> {
        
        await refreshAuthorizationStatus()
        
        guard permissionGranted else {
            logger.warning("Notification not scheduled: permission not granted.")
            return .failure(NotificationError.permissionDenied)
        }
        
        return await _schedule(
            id: id,
            title: title,
            subtitle: subtitle,
            body: body,
            category: category,
            type: type,
            sound: sound,
            badge: badge,
            attachments: attachments,
            interruptionLevel: interruptionLevel,
            userInfo: userInfo,
            launchImageName: launchImageName,
            targetContentIdentifier: targetContentIdentifier,
            relevanceScore: relevanceScore,
            filterCriteria: filterCriteria,
            threadIdentifier: threadIdentifier
        )
    }
}

// MARK: - Repeating Notifications

extension NotificationManager {
    
    /// Schedules a repeating notification for the specified days and time.
    ///
    /// This method refreshes the current authorisation status and verifies that the app has
    /// permission to schedule notifications. If permission is not granted, the method logs a
    /// warning and exits without scheduling any reminders.
    ///
    /// For each weekday provided, a separate repeating calendar notification is scheduled using
    /// a unique identifier derived from the base `id` and the day’s raw value. Attachments,
    /// sound, badge values, category, metadata, and all other content configuration values are
    /// applied to each scheduled request.
    ///
    /// - Parameters:
    ///   - id: The base identifier for the repeating notification.
    ///   - title: The primary text shown in the notification.
    ///   - subtitle: Optional secondary text displayed beneath the title.
    ///   - body: The main message body of the notification.
    ///   - category: Optional category descriptor used to configure notification actions.
    ///   - hour: The hour component of the scheduled time.
    ///   - minute: The minute component of the scheduled time.
    ///   - days: The weekdays on which the notification repeats.
    ///   - sound: The sound to play when the notification is delivered.
    ///   - badge: An optional badge value to display on the app icon.
    ///   - attachments: Optional attachments added to the notification.
    ///   - interruptionLevel: The notification interruption level.
    ///   - userInfo: Additional metadata included with the notification.
    ///   - launchImageName: Optional launch image to display on app launch.
    ///   - targetContentIdentifier: Optional identifier for targeted content updates.
    ///   - relevanceScore: Relevance score for system ranking.
    ///   - filterCriteria: Optional filter criteria.
    ///   - threadIdentifier: Optional grouping identifier for related notifications.
    ///
    /// Each scheduled reminder repeats weekly at the specified time.
    public func scheduleRepeatingNotification(
        id: String,
        title: String,
        subtitle: String = "",
        body: String,
        category: NotificationCategoryDescriptor? = nil,
        hour: Int,
        minute: Int,
        days: [NotificationWeekday],
        sound: NotificationSound = .default,
        badge: Int? = nil,
        attachments: [NotificationAttachmentFactory] = [],
        interruptionLevel: UNNotificationInterruptionLevel = .active,
        userInfo: [AnyHashable : Any] = [:],
        launchImageName: String? = nil,
        targetContentIdentifier: String? = nil,
        relevanceScore: Double = 1,
        filterCriteria: String? = nil,
        threadIdentifier: String? = nil
    ) async {
        
        await refreshAuthorizationStatus()
        guard permissionGranted else {
            logger.warning("Repeating reminder not scheduled: permission not granted.")
            return
        }
        
        for day in days {
            let notificationID = "\(id)_\(day.value)"
            await _schedule(
                id: notificationID,
                title: title,
                subtitle: subtitle,
                body: body,
                category: category,
                type: .calendar(weekday: nil, hour: hour, minute: minute, repeats: true),
                weekday: day.value,
                sound: sound,
                badge: badge,
                attachments: attachments,
                interruptionLevel: interruptionLevel,
                userInfo: userInfo,
                launchImageName: launchImageName,
                targetContentIdentifier: targetContentIdentifier,
                relevanceScore: relevanceScore,
                filterCriteria: filterCriteria,
                threadIdentifier: threadIdentifier
            )
        }
    }
}

// MARK: - Inactive Notifications

extension NotificationManager {
    
    /// Schedules an inactivity reminder after a specified period of time has elapsed since the
    /// app was last opened.
    ///
    /// This method refreshes the current authorisation status and ensures permission has been
    /// granted. If permission is denied, the reminder is not scheduled and a warning is logged.
    ///
    /// When permission is granted, the method updates the stored “last opened” date, removes
    /// any previously pending inactivity reminder, and schedules a new time-interval–based
    /// notification using the provided content and metadata.
    ///
    /// - Parameters:
    ///   - duration: The delay before the reminder is triggered. Defaults to seven days.
    ///   - repeats: Indicates whether the reminder repeats. Defaults to `false`.
    ///   - title: The primary text displayed in the notification.
    ///   - subtitle: Optional secondary text displayed below the title.
    ///   - body: The main message body of the notification.
    ///   - category: Optional category descriptor used to configure actions.
    ///   - sound: The notification sound to play.
    ///   - badge: An optional badge value.
    ///   - attachments: Optional attachments to include with the notification.
    ///   - userInfo: Additional metadata included in the notification payload.
    ///
    /// A log entry is recorded after scheduling, including the time interval and identifier.
    public func scheduleInactivityReminder(
        duration: Duration = .seconds(7 * 24 * 60 * 60),
        repeats: Bool = false,
        title: String,
        subtitle: String = "",
        body: String,
        category: NotificationCategoryDescriptor? = nil,
        sound: NotificationSound = .default,
        badge: Int? = nil,
        attachments: [NotificationAttachmentFactory] = [],
        userInfo: [AnyHashable : Any] = [:]
    ) async {
        
        await refreshAuthorizationStatus()
        guard permissionGranted else {
            logger.warning("Inactivity reminder not scheduled: permission not granted.")
            return
        }
        
        defaults.set(
            Date.now,
            for: NotificationsUserDefaultsKey.appLastOpened
        )
        
        let inactivityReminderId = "com.markbattistella.package.notificationManager.inactivityReminder"
        
        removePendingNotification(id: inactivityReminderId)
        
        await _schedule(
            id: inactivityReminderId,
            title: title,
            subtitle: subtitle,
            body: body,
            category: category,
            type: .timeInterval(duration: duration, repeats: repeats),
            sound: sound,
            badge: badge,
            attachments: attachments,
            userInfo: userInfo
        )
        logger.info("Scheduled inactivity reminder with interval=\(duration.timeInterval), id=\(inactivityReminderId)")
    }
    
    /// Records that the app has been opened by updating the “last opened” timestamp stored in
    /// user defaults.
    ///
    /// This value is used when scheduling inactivity reminders.
    public func markAppOpened() {
        defaults.set(Date.now, for: NotificationsUserDefaultsKey.appLastOpened)
    }
}

// MARK: - Internal Scheduling

extension NotificationManager {
    
    /// Builds and schedules a local notification request using the specified content and
    /// trigger configuration.
    ///
    /// This method assembles the notification payload, resolves and applies optional attributes
    /// such as attachments, category identifiers, thread identifiers, and launch images, and
    /// creates an appropriate trigger based on the provided ``NotificationType``.
    ///
    /// Notification construction is performed on a detached task to offload the work from the
    /// main actor. Attachments are generated concurrently using a task group.
    ///
    /// After the request is built, this method attempts to add it to the system notification
    /// centre. A failure to construct or schedule the request is logged and returned to the
    /// caller.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for the notification request.
    ///   - title: The main title displayed in the notification.
    ///   - subtitle: Optional text displayed beneath the title.
    ///   - body: The body text of the notification.
    ///   - category: Optional category descriptor used to configure actions and the category
    ///   identifier.
    ///   - type: The notification trigger type, such as time interval, calendar, or location.
    ///   - weekday: Optional weekday override for calendar-based triggers.
    ///   - sound: The notification sound to play.
    ///   - badge: Optional badge value.
    ///   - attachments: A list of factories used to produce notification attachments.
    ///   - interruptionLevel: The system interruption level for the notification.
    ///   - userInfo: Additional metadata included in the notification payload.
    ///   - launchImageName: Optional image name used when launching the app from the
    ///   notification.
    ///   - targetContentIdentifier: Optional identifier used for content updates.
    ///   - relevanceScore: A relevance score used for ranking in summaries and stacks.
    ///   - filterCriteria: Optional criteria for system-level relevance filtering.
    ///   - threadIdentifier: Optional identifier used to group notifications.
    ///
    /// - Returns: A result indicating either successful scheduling or the error encountered.
    @discardableResult
    private func _schedule(
        id: String,
        title: String,
        subtitle: String = "",
        body: String,
        category: NotificationCategoryDescriptor? = nil,
        type: NotificationType,
        weekday: Int? = nil,
        sound: NotificationSound = .default,
        badge: Int? = nil,
        attachments: [NotificationAttachmentFactory] = [],
        interruptionLevel: UNNotificationInterruptionLevel = .active,
        userInfo: [AnyHashable : Any] = [:],
        launchImageName: String? = nil,
        targetContentIdentifier: String? = nil,
        relevanceScore: Double = 1,
        filterCriteria: String? = nil,
        threadIdentifier: String? = nil
    ) async -> Result<Void, Error> {
        
        let resolvedSound = sound.value
        let resolvedLaunchImageName = launchImageName
        let resolvedThreadIdentifier = threadIdentifier
        let resolvedCategoryIdentifier = category?.id
        
        let requestResult = await Task { () -> Result<UNNotificationRequest, Error> in
            let content = UNMutableNotificationContent()
            content.title = title
            content.subtitle = subtitle
            content.body = body
            content.userInfo = userInfo
            content.sound = resolvedSound
            content.badge = NSNumber(integerLiteral: badge ?? 0)
            content.interruptionLevel = interruptionLevel
            content.targetContentIdentifier = targetContentIdentifier
            content.relevanceScore = relevanceScore
            content.filterCriteria = filterCriteria
            
            #if os(iOS)
            if let resolvedLaunchImageName {
                content.launchImageName = resolvedLaunchImageName
            }
            #endif

            if let resolvedThreadIdentifier {
                content.threadIdentifier = resolvedThreadIdentifier
            }

            if let resolvedCategoryIdentifier {
                content.categoryIdentifier = resolvedCategoryIdentifier
            }
            
            let compiledAttachments: [UNNotificationAttachment] = await withTaskGroup(
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
            
            if !compiledAttachments.isEmpty {
                content.attachments = compiledAttachments
            }
            
            let trigger: UNNotificationTrigger
            
            switch type {
                case let .timeInterval(duration, repeats):
                    let rawSeconds = duration.timeInterval
                    let seconds = max(rawSeconds, repeats ? 60 : 0.1)
                    
                    let finalTrigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: seconds,
                        repeats: repeats
                    )
                    trigger = finalTrigger
                    
                case let .calendar(weekday, hour, minute, repeats):
                    var comps = DateComponents()
                    comps.hour = hour
                    comps.minute = minute
                    comps.weekday = weekday
                    
                    trigger = UNCalendarNotificationTrigger(
                        dateMatching: comps,
                        repeats: repeats
                    )
                    
                #if (os(iOS) && !targetEnvironment(macCatalyst)) || os(watchOS)
                case let .location(region, repeats):
                    trigger = UNLocationNotificationTrigger(region: region, repeats: repeats)
                #endif
            }
            
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            return .success(request)
        }.value
        
        switch requestResult {
            case .failure(let error):
                logger.error("Failed to build notification: \(error.localizedDescription)")
                return .failure(error)
                
            case .success(let request):
                do {
                    try await center.add(request)
                    await refreshPendingState()
                    return .success(())
                } catch {
                    logger.error("Failed to schedule notification - ID: \(id) - Error: \(error)")
                    return .failure(error)
                }
        }
    }
}

// MARK: - Querying Notifications

extension NotificationManager {
    
    /// Returns all pending notification requests scheduled for the application.
    ///
    /// - Returns: An array of ``UNNotificationRequest`` values representing all unsatisfied
    /// scheduled notifications.
    public func pendingNotifications() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }
    
    /// Returns all pending notifications whose identifiers begin with the specified prefix.
    ///
    /// This is useful when scheduling families of related notifications, such as repeating
    /// reminders using a common base identifier.
    ///
    /// - Parameter prefix: The identifier prefix to match.
    /// - Returns: All pending notification requests whose identifiers share the prefix.
    public func pendingNotifications(matchingPrefix prefix: String) async -> [UNNotificationRequest] {
        let all = await pendingNotifications()
        return all.filter { $0.identifier.hasPrefix(prefix) }
    }
    
    /// Returns all delivered notifications retained by the system.
    ///
    /// Delivered notifications remain available until cleared by the user or removed through
    /// notification centre APIs.
    ///
    /// - Returns: An array of delivered ``UNNotification`` instances.
    public func deliveredNotifications() async -> [UNNotification] {
        await center.deliveredNotifications()
    }
    
    /// Indicates whether a notification with the specified identifier is currently scheduled.
    ///
    /// - Parameter id: The identifier of the notification to check.
    /// - Returns: `true` if a matching request exists in the pending queue.
    public func isNotificationScheduled(id: String) async -> Bool {
        let pending = await pendingNotifications()
        return pending.contains { $0.identifier == id }
    }
    
    /// Returns the current state of a notification with the given identifier.
    ///
    /// The result describes whether the notification is pending, has been delivered, and includes
    /// the corresponding request and delivered notification if available.
    ///
    /// - Parameter id: The identifier of the notification.
    /// - Returns: A ``NotificationState`` describing the notification’s status.
    public func notificationState(id: String) async -> NotificationState {
        let allPending = await pendingNotifications()
        let allDelivered = await deliveredNotifications()
        
        let pendingRequest = allPending.first { $0.identifier == id }
        let deliveredNotification = allDelivered.first { $0.request.identifier == id }
        
        return NotificationState(
            isPending: pendingRequest != nil,
            isDelivered: deliveredNotification != nil,
            request: pendingRequest,
            delivered: deliveredNotification
        )
    }
    
    /// Returns the next scheduled trigger date for the notification with the given identifier.
    ///
    /// This inspects the underlying trigger and returns its computed next trigger date for both
    /// calendar and time-interval–based notifications. If the request does not exist or the
    /// trigger cannot be resolved, the method returns `nil`.
    ///
    /// - Parameter id: The identifier of the notification.
    /// - Returns: The next trigger date, or `nil` if unavailable.
    public func nextTriggerDate(for id: String) async -> Date? {
        let pending = await pendingNotifications()
        guard let request = pending.first(where: { $0.identifier == id }),
              let trigger = request.trigger else {
            return nil
        }
        
        if let calendarTrigger = trigger as? UNCalendarNotificationTrigger {
            return calendarTrigger.nextTriggerDate()
        } else if let timeIntervalTrigger = trigger as? UNTimeIntervalNotificationTrigger {
            return timeIntervalTrigger.nextTriggerDate()
        }
        
        return nil
    }
}

// MARK: - Removing Notifications

extension NotificationManager {
    
    /// Removes a single pending notification with the specified identifier.
    ///
    /// After removal, a log entry is recorded indicating the identifier that was cleared.
    ///
    /// - Parameter id: The identifier of the pending notification to remove.
    public func removePendingNotification(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
        logger.info("Removed pending notification: \(id)")
    }
    
    /// Removes all pending notifications whose identifiers begin with the specified prefix.
    ///
    /// This is commonly used for grouped or repeating notifications that share a naming pattern.
    ///
    /// - Parameter prefix: The prefix used to match identifiers.
    public func removePendingNotifications(matchingPrefix prefix: String) async {
        let requests = await center.pendingNotificationRequests()
        let ids = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        logger.info("Removed \(ids.count) notifications matching prefix: \(prefix)")
    }
    
    /// Removes pending weekday-based notifications generated from a common base identifier.
    ///
    /// This method constructs the derived identifiers used when scheduling repeating weekday
    /// notifications and removes them in a single batch.
    ///
    /// - Parameters:
    ///   - id: The base identifier for the weekday reminders.
    ///   - days: The weekdays whose corresponding notifications should be removed.
    public func removePendingWeekdayNotifications(id: String, days: [NotificationWeekday]) {
        let ids = days.map { "\(id)_\($0.value)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
        logger.info("Removed \(ids.count) weekday notifications for id: \(id)")
    }
    
    /// Removes all pending notifications scheduled for the application.
    ///
    /// A log entry is recorded after removal.
    public func removeAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
        logger.info("Removed all pending notifications")
    }
    
    /// Removes a delivered notification with the specified identifier.
    ///
    /// - Parameter id: The identifier of the delivered notification to remove.
    public func removeDeliveredNotification(id: String) {
        center.removeDeliveredNotifications(withIdentifiers: [id])
        logger.info("Removed delivered notification: \(id)")
    }
    
    /// Removes all delivered notifications retained by the system.
    ///
    /// A log entry is recorded after completion.
    public func removeAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
        logger.info("Removed all delivered notifications")
    }

    /// Resets the app's notification badge count to zero.
    ///
    /// Use this to clear any badge number displayed on the app icon. This method sets the badge
    /// count on the provided `UNUserNotificationCenter` to `0`.
    public func removeNotificationBadges() {
        center.setBadgeCount(0)
    }
}
