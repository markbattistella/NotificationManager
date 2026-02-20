# Custom Categories and Actions

Add interactive buttons to notifications and route user responses back into your app.

## Overview

iOS and macOS can display action buttons directly on a notification — "Snooze", "Mark Done",
"Reply", and so on. To use these, you register one or more *categories*, each containing a
set of *actions*, with the notification system. When you schedule a notification you associate
it with a category, and the system shows its actions automatically.

`NotificationManager` uses a protocol-based approach for this. You define your own types that
conform to ``NotificationActionDescriptor`` and ``NotificationCategoryDescriptor``, giving you
full type safety and making it easy to share category definitions across your codebase.

## Defining Actions

Conform to ``NotificationActionDescriptor`` for each action you want to appear on a notification:

```swift
import NotificationManager
import UserNotifications

struct SnoozeAction: NotificationActionDescriptor {
  var id: String { "action.snooze" }
  var title: LocalizedStringResource { "Snooze" }
  var icon: UNNotificationActionIcon? { UNNotificationActionIcon(systemImageName: "clock") }
  var options: UNNotificationActionOptions { [] }
}

struct DismissAction: NotificationActionDescriptor {
  var id: String { "action.dismiss" }
  var title: LocalizedStringResource { "Dismiss" }
  var icon: UNNotificationActionIcon? { nil }
  var options: UNNotificationActionOptions { [.destructive] }
}

struct OpenAction: NotificationActionDescriptor {
  var id: String { "action.open" }
  var title: LocalizedStringResource { "Open App" }
  var icon: UNNotificationActionIcon? { nil }
  var options: UNNotificationActionOptions { [.foreground] }  // brings app to foreground
}
```

The `options` property maps directly to `UNNotificationActionOptions`:
- `.foreground` — launches the app when the action is tapped
- `.destructive` — displays the action in a destructive style (red text on iOS)
- `.authenticationRequired` — requires device unlock before the action is performed

The `title` is a `LocalizedStringResource`, so it participates in Swift's string catalogue
localisation automatically.

## Defining Categories

Conform to ``NotificationCategoryDescriptor`` to group actions into a category:

```swift
struct ReminderCategory: NotificationCategoryDescriptor {
  var id: String { "category.reminder" }
  var actions: [NotificationActionDescriptor] {
    [SnoozeAction(), OpenAction(), DismissAction()]
  }
  var options: UNNotificationCategoryOptions { [] }
}
```

Common `UNNotificationCategoryOptions` values:
- `.customDismissAction` — fires the delegate when the user dismisses the notification
- `.allowInCarPlay` — surfaces the notification in CarPlay

## Registering Categories

Register your categories once, ideally at app launch before any notifications are scheduled:

```swift
@main
struct MyApp: App {
  @State private var notifier = NotificationManager()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(notifier)
        .onAppear {
          notifier.registerCategories([ReminderCategory()])
        }
    }
  }
}
```

Registration replaces the previous set of categories. If you have multiple categories, pass
them all in one call:

```swift
notifier.registerCategories([
  ReminderCategory(),
  AlertCategory(),
  UpdateCategory()
])
```

## Scheduling with a Category

Pass the category to ``NotificationManager/schedule(id:title:subtitle:body:category:type:sound:badge:attachments:interruptionLevel:userInfo:launchImageName:targetContentIdentifier:relevanceScore:filterCriteria:threadIdentifier:)``
using the `category` parameter:

```swift
await notifier.schedule(
  id: "reminder_monday",
  title: "Weekly reminder",
  body: "Don't forget your task.",
  category: ReminderCategory(),
  type: .calendar(weekday: 2, hour: 9, minute: 0, repeats: true)
)
```

The category's `id` is applied to the notification content, and the system looks it up from the
registered set to decide which actions to display.

## Handling Responses

Implement `UNUserNotificationCenterDelegate` to receive the user's action choice. You need to
set the delegate on `UNUserNotificationCenter` at launch:

```swift
@main
struct MyApp: App {
  @State private var notifier = NotificationManager()
  @State private var router = NavigationRouter()

  private let delegate = NotificationDelegate()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(notifier)
        .environment(router)
        .onAppear {
          notifier.registerCategories([ReminderCategory()])
          delegate.router = router

          // Assign the delegate to the notification centre
          UNUserNotificationCenter.current().delegate = delegate
        }
    }
  }
}
```

```swift
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {

  var router: NavigationRouter?

  // Called when the user taps the notification or one of its actions
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    let actionID = response.actionIdentifier
    let userInfo = response.notification.request.content.userInfo

    switch actionID {
    case SnoozeAction().id:
      // Re-schedule for 10 minutes later
      break

    case DismissAction().id:
      // Nothing to do
      break

    case UNNotificationDefaultActionIdentifier:
      // User tapped the notification body itself — navigate somewhere
      if let screen = userInfo["screen"] as? String {
        await MainActor.run { router?.navigate(to: screen) }
      }

    default:
      break
    }
  }

  // Called when a notification arrives while the app is in the foreground.
  // Return .banner to show it, or .list to add silently to Notification Centre.
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    return [.banner, .sound]
  }
}
```

## Passing Data Through Notifications

Include a `userInfo` dictionary when scheduling to carry arbitrary data to your delegate:

```swift
await notifier.schedule(
  id: "task_42",
  title: "Task due",
  body: "Your task is due soon.",
  category: ReminderCategory(),
  type: .timeInterval(duration: .seconds(30), repeats: false),
  userInfo: [
    "taskID": "42",
    "screen": "taskDetail"
  ]
)
```

Read it back in the delegate:

```swift
let taskID = response.notification.request.content.userInfo["taskID"] as? String
```

Keep `userInfo` values property-list compatible (String, Int, Bool, Date, Data, or nested
dictionaries and arrays of those types).

## Tips

- **Use reverse-domain style IDs** for action and category identifiers to avoid collisions with
  system identifiers (e.g., `"com.myapp.action.snooze"`)
- **Register categories before scheduling** — the system can only attach actions to a
  notification if the category is already registered when the notification fires
- **Reuse category instances** — since `NotificationCategoryDescriptor` is a protocol, a
  lightweight value type (struct) is ideal; create them on demand rather than storing them
