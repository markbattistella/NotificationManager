//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI
import NotificationManager

/// The main application entry point for the Notification Manager example.
///
/// This app configures the notification centre delegate, injects shared notification and routing
/// state into the environment, registers categories, and refreshes permission status on launch.
@main
struct NotificationManagerExampleApp: App {
    
    /// The shared notification manager instance for the app lifecycle.
    @State private var notifications = NotificationManager()
    
    /// The shared router responsible for navigation triggered by notifications.
    @State private var router = NotificationRouter()
    
    /// Configures the notification centre delegate and injects required references.
    init() {
        let center = UNUserNotificationCenter.current()
        let delegate = NotificationDelegate.shared
        center.delegate = delegate
        delegate.notificationManager = notifications
        delegate.router = router
    }
    
    /// Defines the main UI scene and environment.
    ///
    /// Registers categories and refreshes permissions when the view hierarchy loads.
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(notifications)
                .environment(router)
                .task {
                    notifications.registerCategories([
                        DemoCategory.reminder,
                        SnoozeCategory.oneOff
                    ])
                }
        }
    }
}

/// A router used for navigation decisions driven by notification interactions.
///
/// Assigning a ``route`` value allows the UI layer to respond accordingly.
@Observable
final class NotificationRouter {
    
    /// The current route requested by a notification action.
    var route: AppRoute?
    
    /// Destinations the router may direct the app to.
    enum AppRoute: Hashable {
        
        /// Navigate to a detailed view for a specific item.
        case detail(id: String)
    }
}
