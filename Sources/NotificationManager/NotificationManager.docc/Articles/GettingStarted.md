# Getting Started

Install the package, wire it into your app, and send your first notification.

## Overview

`NotificationManager` is designed to slot into a SwiftUI app with minimal setup. You create one
instance of ``NotificationManager``, inject it into the environment, request permission from the
user, and then schedule notifications from anywhere in your view hierarchy.

This article walks through each step in order.

## Installation

Add the package to your `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/NotificationManager", from: "1.0.0")
],
targets: [
  .target(
    name: "MyApp",
    dependencies: ["NotificationManager"]
  )
]
```

Or add it in Xcode via **File → Add Package Dependencies** and enter the repository URL.

## Wiring Into Your App

Create a single ``NotificationManager`` instance at the top of your app and pass it into the
SwiftUI environment using `.environment(_:)`. This makes it accessible throughout the entire
view hierarchy without passing it through initialisers.

```swift
import SwiftUI
import NotificationManager

@main
struct MyApp: App {
  @State private var notifier = NotificationManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(notifier)
    }
  }
}
```

## Accessing the Manager in Views

Use the `@Environment` property wrapper to read the manager in any view:

```swift
import SwiftUI
import NotificationManager

struct SettingsView: View {
  @Environment(NotificationManager.self) var notifier

  var body: some View {
    Text(notifier.permissionGranted ? "Notifications on" : "Notifications off")
  }
}
```

Because ``NotificationManager`` is `@Observable`, any property you read inside `body` — such as
``NotificationManager/permissionGranted`` or ``NotificationManager/authorizationStatus`` — will
automatically trigger a re-render when it changes.

## Requesting Permission

Call ``NotificationManager/requestAuthorization(for:)`` to prompt the user. It is safe to call
multiple times — if permission is already granted it returns `.authorized` immediately without
re-prompting.

```swift
struct OnboardingView: View {
  @Environment(NotificationManager.self) var notifier

  var body: some View {
    Button("Enable Notifications") {
      Task {
        let status = await notifier.requestAuthorization(for: [.alert, .sound, .badge])
        handleStatus(status)
      }
    }
  }

  private func handleStatus(_ status: PermissionStatus) {
    switch status {
    case .authorized:
      // Permission granted — schedule notifications as needed
      break
    case .denied(let settingsURL):
      // User previously denied — offer a link to Settings
      if let url = settingsURL {
        Task { await UIApplication.shared.open(url) }
      }
    case .notDetermined:
      // The system dismissed the prompt without a decision (unusual)
      break
    case .error(let error):
      print("Authorization error: \(error?.localizedDescription ?? "unknown")")
    }
  }
}
```

The ``PermissionStatus`` enum covers every outcome so you can handle each case explicitly,
including directing users to the Settings app when permission has been denied.

## Your First Notification

Once permission is granted, schedule a notification using ``NotificationManager/schedule(id:title:subtitle:body:category:type:sound:badge:attachments:interruptionLevel:userInfo:launchImageName:targetContentIdentifier:relevanceScore:filterCriteria:threadIdentifier:)``:

```swift
Button("Send Test Notification") {
  Task {
    await notifier.schedule(
      id: "first_notification",
      title: "Hello!",
      body: "Your first notification from NotificationManager.",
      type: .timeInterval(duration: .seconds(5), repeats: false)
    )
  }
}
```

This fires five seconds after the call. Move the app to the background to see it appear — iOS
does not display notifications while the app is in the foreground by default (unless you implement
`UNUserNotificationCenterDelegate`).

## Observing State

The manager automatically refreshes its state when the app returns to the foreground. You can
also check state at any time:

```swift
// Is permission currently granted?
print(notifier.permissionGranted)

// Are there any pending notifications at all?
print(notifier.hasPendingNotifications)

// Full authorisation status from the system
print(notifier.authorizationStatus)
```

## Next Steps

- Schedule different notification types: <doc:SchedulingNotifications>
- Query, inspect, and remove notifications: <doc:ManagingNotifications>
- Add interactive actions using categories: <doc:CustomCategoriesAndActions>
