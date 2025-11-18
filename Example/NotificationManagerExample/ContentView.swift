//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI
import NotificationManager

/// A view demonstrating notification permissions, scheduling, repeating reminders, pending
/// notifications, and navigation to detail screens.
struct ContentView: View {

    /// Manages notification authorisation, scheduling, and retrieval.
    @Environment(NotificationManager.self) private var notifications

    /// Handles routing based on notification-triggered navigation.
    @Environment(NotificationRouter.self) private var router

    /// The list of currently pending notification requests.
    @State private var pending: [UNNotificationRequest] = []

    /// The selected time for repeating weekday reminders.
    @State private var reminderTime = Date()

    /// The selected weekdays for repeating reminders.
    @State private var selectedDays: Set<NotificationWeekday> = [.monday, .wednesday, .friday]

    /// A URL to open system settings when permission is denied.
    ///
    /// - Important: This will not work on simulator. Only physical devices open to the
    /// notification url.
    @State private var settingsURL: URL?

    var body: some View {
        NavigationStack(
            path: Binding(
                get: { router.route.map { [$0] } ?? [] },
                set: { newValue in router.route = newValue.last }
            )
        ) {
            List {

                // MARK: Permissions Section

                Section("Permissions") {
                    Button("Request Permission - Badges only") {
                        Task {
                            let result = await notifications.requestAuthorization()
                            switch result {
                                case .denied(let url): settingsURL = url
                                default: settingsURL = nil
                            }
                        }
                    }

                    Button("Update Permission - Alert, Badge, and Sound") {
                        Task { await notifications.updateOptions(to: [.alert, .badge, .sound]) }
                    }

                    LabeledContent(
                        "authorizationStatus",
                        value: String(describing: notifications.authorizationStatus)
                    )

                    LabeledContent(
                        "permissionGranted",
                        value: notifications.permissionGranted.description
                    )

                    if let settingsURL {
                        Button("Open Settings") { UIApplication.shared.open(settingsURL) }
                    }
                }

                // MARK: Quick Notifications

                Section("Quick notifications") {
                    Button("In 10 seconds - Default Sound") {
                        Task {
                            let attachment = NotificationAttachmentBuilder
                                .AttachmentSymbol("bell.fill", foreground: .white, background: .blue)

                            await notifications.schedule(
                                id: "quick-notification",
                                title: "10 second alert",
                                subtitle: "This is the subtitle line",
                                body: "This is the main body. The notification fired after 10 seconds!",
                                category: DemoCategory.reminder,
                                type: .timeInterval(duration: .seconds(10), repeats: false),
                                sound: .default,
                                badge: 1,
                                attachments: [attachment],
                                userInfo: ["noteID" : "123"]
                            )
                        }
                    }

                    Button("In 10 seconds - Custom Sound") {
                        Task {
                            let view = VStack {
                                Text("Hello World!")
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                Text("This is a SwiftUI view as a notification image.")
                            }

                            let attachment = NotificationAttachmentBuilder
                                .AttachmentView(view, size: .init(width: 300, height: 300))

                            await notifications.schedule(
                                id: "quick-notification",
                                title: "10 second alert",
                                body: "This is the main body. The notification fired after 10 seconds! It has a custom sound.",
                                category: DemoCategory.reminder,
                                type: .timeInterval(duration: .seconds(10), repeats: false),
                                sound: .named("water-drop.caf"),
                                badge: 2,
                                attachments: [attachment],
                                userInfo: ["noteID" : "123"]
                            )
                        }
                    }
                }

                // MARK: Repeating Reminders

                Section("Repeating weekday notifications") {
                    DatePicker(
                        "Alert time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labeledContentStyle(.automatic)

                    WeekdayPicker(selectedDays: $selectedDays)

                    Button("Schedule Repeating Reminder") {
                        Task {
                            let attachment = NotificationAttachmentBuilder.AttachmentSymbol("calendar")
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)

                            await notifications.scheduleRepeatingNotification(
                                id: "weekday-reminder",
                                title: "Weekly Reminder",
                                body: "This is your repeating reminder!",
                                hour: comps.hour!,
                                minute: comps.minute!,
                                days: Array(selectedDays),
                                attachments: [attachment],
                                userInfo: ["noteID": "789"]
                            )
                        }
                    }
                }

                // MARK: Pending Notifications

                Section("Pending notifications") {
                    Button("Refresh pending") {
                        Task {
                            pending = await notifications.pendingNotifications()
                        }
                    }

                    ForEach(pending, id: \.identifier) { notification in
                        LabeledContent(
                            notification.identifier,
                            value: notification.content.body
                        )
                    }
                }

                // MARK: Remove Notifications

                Section("Remove") {
                    Button("Remove All Pending Notifications", role: .destructive) {
                        notifications.removeAllPendingNotifications()
                        pending = []
                    }
                }
            }
            .navigationDestination(for: NotificationRouter.AppRoute.self) { route in
                switch route {
                    case .detail(let id):
                        DetailView(id: id)
                }
            }
            .navigationTitle("Notification Demo")
            .labeledContentStyle(.vertical)
        }
    }
}
