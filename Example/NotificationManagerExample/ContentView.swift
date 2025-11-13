//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI
import NotificationManager

/// The main interface for managing and scheduling demo notifications.
///
/// Displays pending requests, allows users to schedule repeating weekday reminders, and responds
/// to navigation driven by the notification router.
struct ContentView: View {
    
    /// The shared notification manager from the environment.
    @Environment(NotificationManager.self) private var notifications
    
    /// The router used to handle navigation triggered by notifications.
    @Environment(NotificationRouter.self) private var router
    
    /// The list of pending notification requests currently scheduled.
    @State private var pending: [UNNotificationRequest] = []
    
    /// The selected time used when scheduling new reminders.
    @State private var reminderTime = Date()
    
    /// The set of weekdays chosen for repeating reminders.
    @State private var selectedDays: Set<NotificationWeekday> = [.monday, .wednesday, .friday]
    
    var body: some View {
        NavigationStack(
            path: Binding(
                get: { router.route.map { [$0] } ?? [] },
                set: { newValue in router.route = newValue.last }
            )
        ) {
            List {
                Section("Permissions") {
                    Button("Request Permission") {
                        Task { await notifications.requestPermission() }
                    }
                    Text("Granted: \(notifications.permissionGranted.description)")
                }
                
                Section("Repeating Weekday Reminder") {
                    DatePicker(
                        "Time",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    WeekdayPicker(selectedDays: $selectedDays)
                    
                    Button("Schedule Repeating Reminder") {
                        Task {
                            let comps = Calendar.current
                                .dateComponents([.hour, .minute], from: reminderTime)
                            
                            await notifications
                                .scheduleRepeatingWeekdays(
                                    id: "weekday-reminder",
                                    title: "Weekly Reminder",
                                    body: "This is your repeating reminder!",
                                    category: DemoCategory.reminder,
                                    hour: comps.hour!,
                                    minute: comps.minute!,
                                    days: Array(selectedDays),
                                    attachments: [],
                                    userInfo: ["noteID": "789"]
                                )
                        }
                    }
                }
                
                Section("Quick Tests") {
                    Button("Fire in 10 seconds") {
                        Task {
                            await notifications.schedule(
                                id: "test-timeinterval",
                                title: "10 second alert",
                                body: "This fired after 10 seconds",
                                category: DemoCategory.reminder,
                                type: .timeInterval(seconds: 10, repeats: false),
                                userInfo: ["noteID": "123"]
                            )
                        }
                    }
                }
                
                Section("Pending") {
                    Button("Refresh Pending") {
                        Task { await refreshPending() }
                    }
                    ForEach(pending, id: \.identifier) { req in
                        VStack(alignment: .leading) {
                            Text(req.identifier).font(.headline)
                            Text(req.content.body)
                        }
                    }
                }
                
                Section("Remove") {
                    Button("Remove All Pending") {
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
        }
    }
    
    /// Refreshes the list of pending notifications and updates the UI.
    ///
    /// Called when the user taps **Refresh Pending**.
    func refreshPending() async {
        pending = await notifications.pendingNotifications()
    }
}

// MARK: - Detail Sub-View

/// A simple detail screen showing the identifier passed from a notification.
///
/// Used when navigating from a delivered notification’s action.
struct DetailView: View {
    
    /// The identifier associated with the item to display.
    let id: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Detail Screen")
                .font(.largeTitle)
            Text("Opened from notification id: \(id)")
        }
        .padding()
    }
}

// MARK: - Sub-View Component

/// A horizontal picker allowing users to select multiple weekdays.
///
/// Displays days in fixed Sunday–Saturday order and toggles selection states
/// by updating the bound ``selectedDays`` set.
struct WeekdayPicker: View {
    
    /// The set of weekdays currently selected.
    @Binding var selectedDays: Set<NotificationWeekday>
    
    /// Days presented in a fixed Sunday–Saturday order.
    private let orderedDays: [(NotificationWeekday, String)] = [
        (.sunday,    "S"),
        (.monday,    "M"),
        (.tuesday,   "Tu"),
        (.wednesday, "W"),
        (.thursday,  "Th"),
        (.friday,    "F"),
        (.saturday,  "Sa")
    ]
    
    var body: some View {
        HStack {
            ForEach(orderedDays, id: \.0) { day, label in
                Button(label) {
                    toggle(day)
                }
                .padding(6)
                .frame(maxWidth: .infinity)
                .background(
                    selectedDays.contains(day)
                    ? Color.blue.opacity(0.9)
                    : Color.gray.opacity(0.25)
                )
                .foregroundStyle(
                    selectedDays.contains(day) ? .white : .primary
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
    
    /// Toggles the inclusion of a given weekday in ``selectedDays``.
    ///
    /// - Parameter day: The weekday to update.
    func toggle(_ day: NotificationWeekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
