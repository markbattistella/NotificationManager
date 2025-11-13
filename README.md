<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# NotificationManager

![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FNotificationManager%2Fbadge%3Ftype%3Dswift-versions)

![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FNotificationManager%2Fbadge%3Ftype%3Dplatforms)

![Licence](https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat)

</div>

`NotificationManager` is a Swift package that provides a modern, Swift-first API for scheduling, managing, and handling iOS local notifications — designed specifically for SwiftUI.

It solves the limitations of Apple's `UNUserNotificationCenter` API by offering:

- A clean async/await-based API
- An Observable `NotificationManager` suitable for dependency-injection
- A protocol-driven architecture for custom categories and actions
- Strong convenience helpers for weekday scheduling
- Clean removal, querying, and routing support

The goal is to provide a fully-featured, well-documented, SwiftUI-native notifications layer without boilerplate.

## Installation

Add `NotificationManager` to your Swift project using Swift Package Manager.

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/NotificationManager", from: "1.0.0")
]
```

Alternatively, you can add `NotificationManager` using Xcode by navigating to `File > Add Packages` and entering the package repository URL.

## Usage

### Request permission

```swift
@Environment(NotificationManager.self) var notifier
    
Button("Enable Notifications") {
  Task { await notifier.requestPermission() }
}
```

### Check current permission status

```swift
await notifier.refreshPermissionStatus()
print(notifier.permissionGranted)
```

### Registering Categories & Actions

Create categories using the built-in protocol types (included in package):

```swift
let snoozeAction = NotificationActionDefinition(
  id: "snooze",
  title: "Snooze",
  options: []
)

let openAction = NotificationActionDefinition(
  id: "open",
  title: "Open",
  options: [.foreground]
)

let reminderCategory = NotificationCategoryDefinition(
  id: "reminder",
  actions: [snoozeAction, openAction]
)

notifier.registerCategories([reminderCategory])
```

### Scheduling Notifications

#### Basic notification

```swift
await notifier.schedule(
  id: "demo",
  title: "Hello",
  body: "This is a simple test",
  type: .timeInterval(seconds: 5, repeats: false)
)
```

#### Calendar-based (daily)

```swift
await notifier.schedule(
  id: "daily_8am",
  title: "Daily Reminder",
  body: "It’s 8am!",
  type: .calendar(
    weekday: nil,
    hour: 8,
    minute: 0,
    repeats: true
  )
)
```

#### Weekday Scheduling

The package ships with a Foundation-backed weekday model (included in code).

```swift
let days: [Weekday] = [.monday, .wednesday, .friday]

await notifier.scheduleRepeatingWeekdays(
  id: "hydration",
  title: "Hydrate",
  body: "Drink some water",
  category: reminderCategory,
  hour: 9,
  minute: 30,
  days: days
)
```

This automatically schedules unique identifiers like:

```text
hydration_2   // Monday
hydration_4   // Wednesday
hydration_6   // Friday
```

### Removing Notifications

#### Remove one

```swift
notifier.removePendingNotification(id: "hydration_2")
```

#### Remove all matching prefix

```swift
await notifier.removePendingNotifications(matchingPrefix: "hydration")
```

#### Remove specific weekdays

```swift
notifier.removePendingWeekdayNotifications(
  baseId: "hydration",
  days: [.monday, .friday]
)
```

#### Remove everything

```swift
notifier.removeAllPendingNotifications()
```

#### Querying Pending Notifications

```swift
let all = await notifier.pendingNotifications()
let matching = await notifier.pendingNotifications(matchingPrefix: "hydration")
```

## Weekday Model

The package includes a robust, locale-aware Weekday type. This type:

- Always uses the system calendar's definition of weekday numbers
- Displays correct day names for any locale
- Allows day selection UIs
- Works with Foundation’s `DateComponents.weekday`

Example:

```swift
print(Weekday.monday.value)          // 2 in Gregorian calendars
print(Weekday.monday.name)           // "Monday" (or localised equivalent)
print(Weekday.allCases.map(\.name))  // Localised list
```

## Notification Categories & Actions

The package ships with the following definitions. They provide:

- Strong typing
- Clean identifiers
- Easy construction of actionable notifications
- A safe API surface that avoids Apple-string-literal pitfalls

### Routing from Notifications

Because the manager is an `@Observable`, you can inject it into the SwiftUI environment and cleanly route using your own router. Example flow:

#### App file

```swift
@main
struct MyApp: App {
  @State private var notifier = NotificationManager()
  @State private var router = RouteManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(notifier)
        .environment(router)
    }
  }
}
```

#### Delegate handling payload

```swift
final class DemoNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

  weak var router: RouteManager?
  weak var notifier: NotificationManager?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {

    let info = response.notification.request.content.userInfo

    if let id = info["noteId"] as? String {
      await MainActor.run {
        router?.push(.detail(id))
      }
    }
  }
}
```

## Things to Note

- Local notifications depend heavily on user permissions
- Calendar scheduling uses the user’s actual device calendar
- Identifiers must be unique, and prefix management is recommended
- Background app termination may delay delivery
- Categories must be registered before scheduling notifications

## Contributing

Contributions are welcome. Please open an Issue or PR for fixes, feature proposals, or documentation improvements.

PR titles should follow the format: `YYYY-mm-dd - Title`

## Licence

`NotificationManager` is released under the MIT licence.
