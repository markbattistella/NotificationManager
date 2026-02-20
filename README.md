<!-- markdownlint-disable MD033 MD041 -->
<div align="center">

# NotificationManager

![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FNotificationManager%2Fbadge%3Ftype%3Dswift-versions)

![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmarkbattistella%2FNotificationManager%2Fbadge%3Ftype%3Dplatforms)

![Licence](https://img.shields.io/badge/Licence-MIT-white?labelColor=blue&style=flat)

</div>

`NotificationManager` is a Swift package that provides a modern, Swift-first API for scheduling, managing, and handling local notifications — designed specifically for SwiftUI.

It solves the limitations of Apple's `UNUserNotificationCenter` API by offering:

- A clean async/await-based API
- An `@Observable` `NotificationManager` suitable for dependency injection
- A protocol-driven architecture for custom categories and actions
- Convenience helpers for weekday scheduling and inactivity reminders
- Clean removal, querying, and routing support

## Installation

Add `NotificationManager` to your Swift project using Swift Package Manager:

```swift
dependencies: [
  .package(url: "https://github.com/markbattistella/NotificationManager", from: "1.0.0")
]
```

Alternatively, add it using Xcode via `File > Add Packages` and entering the package repository URL.

## Setup

Create a `NotificationManager` instance and inject it into the SwiftUI environment from your app entry point:

```swift
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

Then access it anywhere in your view hierarchy:

```swift
@Environment(NotificationManager.self) var notifier
```

## Requesting Permission

Call `requestAuthorization(for:)` to prompt the user. It returns a `PermissionStatus` describing the outcome:

```swift
Button("Enable Notifications") {
  Task {
    let status = await notifier.requestAuthorization(for: [.alert, .sound, .badge])
    switch status {
    case .authorized:
      print("Notifications enabled")
    case .denied(let settingsURL):
      if let url = settingsURL {
        await UIApplication.shared.open(url)
      }
    case .notDetermined:
      break
    case .error(let error):
      print("Error: \(error?.localizedDescription ?? "unknown")")
    }
  }
}
```

You can observe the current state reactively via `permissionGranted` or `permissionStatus`:

```swift
if notifier.permissionGranted {
  // Show notification scheduling UI
}
```

## Scheduling Notifications

### One-off (time interval)

```swift
await notifier.schedule(
  id: "demo",
  title: "Hello",
  body: "This is a test",
  type: .timeInterval(duration: .seconds(5), repeats: false)
)
```

### Calendar-based (daily at a fixed time)

```swift
await notifier.schedule(
  id: "daily_8am",
  title: "Daily Reminder",
  body: "It's 8am!",
  type: .calendar(weekday: nil, hour: 8, minute: 0, repeats: true)
)
```

### Repeating on specific weekdays

```swift
let days: [NotificationWeekday] = [.monday, .wednesday, .friday]

await notifier.scheduleRepeatingNotification(
  id: "hydration",
  title: "Hydrate",
  body: "Drink some water",
  hour: 9,
  minute: 30,
  days: days
)
```

This schedules separate notifications with generated identifiers:

```text
hydration_2   // Monday
hydration_4   // Wednesday
hydration_6   // Friday
```

### Inactivity reminder

Schedule a notification that fires after a period of user inactivity:

```swift
await notifier.scheduleInactivityReminder(
  duration: .seconds(7 * 24 * 60 * 60), // 7 days
  title: "We miss you!",
  body: "Come back and check in."
)
```

Call `notifier.markAppOpened()` on each launch to reset the inactivity timer.

## Querying Notifications

```swift
// All pending
let all = await notifier.pendingNotifications()

// Matching a prefix
let hydration = await notifier.pendingNotifications(matchingPrefix: "hydration")

// Check if a specific one is scheduled
let isScheduled = await notifier.isNotificationScheduled(id: "demo")

// Full state (pending + delivered)
let state = await notifier.notificationState(id: "demo")
print(state.isPending, state.isDelivered)

// Next fire date
if let date = await notifier.nextTriggerDate(for: "daily_8am") {
  print(date)
}
```

## Removing Notifications

```swift
// Remove one pending
notifier.removePendingNotification(id: "hydration_2")

// Remove all matching a prefix
await notifier.removePendingNotifications(matchingPrefix: "hydration")

// Remove specific weekday-based notifications
notifier.removePendingWeekdayNotifications(
  id: "hydration",
  days: [.monday, .friday]
)

// Remove everything
notifier.removeAllPendingNotifications()

// Remove delivered
notifier.removeDeliveredNotification(id: "demo")
notifier.removeAllDeliveredNotifications()

// Clear badge count
notifier.removeNotificationBadges()
```

## Categories and Actions

`NotificationManager` uses a protocol-based approach. Define your own types conforming to `NotificationActionDescriptor` and `NotificationCategoryDescriptor`:

```swift
struct SnoozeAction: NotificationActionDescriptor {
  var id: String { "snooze" }
  var title: LocalizedStringResource { "Snooze" }
  var icon: UNNotificationActionIcon? { nil }
  var options: UNNotificationActionOptions { [] }
}

struct OpenAction: NotificationActionDescriptor {
  var id: String { "open" }
  var title: LocalizedStringResource { "Open" }
  var icon: UNNotificationActionIcon? { nil }
  var options: UNNotificationActionOptions { [.foreground] }
}

struct ReminderCategory: NotificationCategoryDescriptor {
  var id: String { "reminder" }
  var actions: [NotificationActionDescriptor] { [SnoozeAction(), OpenAction()] }
  var options: UNNotificationCategoryOptions { [] }
}
```

Register categories before scheduling notifications that use them:

```swift
notifier.registerCategories([ReminderCategory()])

await notifier.schedule(
  id: "reminder_1",
  title: "Reminder",
  body: "Don't forget!",
  category: ReminderCategory(),
  type: .timeInterval(duration: .seconds(60), repeats: false)
)
```

## Weekday Model

`NotificationWeekday` is a locale-aware weekday type. Values follow Foundation's convention: Sunday is `1`, Saturday is `7`:

```swift
print(NotificationWeekday.monday.value)                // 2
print(NotificationWeekday.monday.localizedName)        // "Monday"
print(NotificationWeekday.monday.localizedShortSymbol) // "Mon"
print(NotificationWeekday.allCases.map(\.localizedName))
```

Static members: `.sunday`, `.monday`, `.tuesday`, `.wednesday`, `.thursday`, `.friday`, `.saturday`

Or initialise directly from a Foundation weekday integer:

```swift
let wednesday = NotificationWeekday(4)
```

## Attachments

Attach images to notifications using one of the built-in builders:

```swift
// From a UIImage
let imageAttachment = NotificationAttachmentBuilder.AttachmentImage(myUIImage)

// From an SF Symbol
let symbolAttachment = NotificationAttachmentBuilder.AttachmentSymbol(
  "bell.fill",
  foreground: .white,
  background: .blue
)

// From any SwiftUI view
let viewAttachment = NotificationAttachmentBuilder.AttachmentView(
  MyCustomView(),
  size: CGSize(width: 300, height: 300)
)

await notifier.schedule(
  id: "with_attachment",
  title: "With Image",
  body: "Check this out",
  type: .timeInterval(duration: .seconds(5), repeats: false),
  attachments: [symbolAttachment]
)
```

## Routing from Notifications

Because `NotificationManager` is `@Observable`, you can inject it into the SwiftUI environment and route notification responses through your own router:

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

```swift
final class MyNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
  weak var router: RouteManager?

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let info = response.notification.request.content.userInfo
    if let id = info["noteId"] as? String {
      await MainActor.run { router?.push(.detail(id)) }
    }
  }
}
```

## Things to Note

- Local notifications depend on user permissions — always check `permissionGranted` before scheduling
- Calendar scheduling uses the user's device calendar and locale
- Notification identifiers must be unique; use prefix conventions for families of related notifications
- Categories must be registered before scheduling notifications that reference them
- Background app termination may delay delivery

## Contributing

Contributions are welcome. Please open an Issue or PR for fixes, feature proposals, or documentation improvements.

PR titles should follow the format: `YYYY-mm-dd - Title`

## Licence

`NotificationManager` is released under the MIT licence.
