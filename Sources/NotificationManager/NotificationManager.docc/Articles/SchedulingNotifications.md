# Scheduling Notifications

Schedule one-off, recurring, weekday-based, and inactivity-triggered notifications.

## Overview

``NotificationManager`` provides several scheduling methods to cover the most common notification
patterns. All scheduling methods check permission before acting — if permission has not been
granted they log a warning and return without scheduling.

The trigger type is always expressed as a ``NotificationType`` value, which lets you switch
between time-interval, calendar, and location triggers from a single parameter.

## Time Interval Notifications

Use `.timeInterval` to fire a notification after a delay:

```swift
// Fire once after 10 seconds
await notifier.schedule(
  id: "one_off",
  title: "Heads up",
  body: "Ten seconds have passed.",
  type: .timeInterval(duration: .seconds(10), repeats: false)
)

// Repeat every 2 minutes (minimum repeat interval is 60 seconds)
await notifier.schedule(
  id: "repeating",
  title: "Reminder",
  body: "Still here!",
  type: .timeInterval(duration: .seconds(120), repeats: true)
)
```

> Note: iOS enforces a minimum repeat interval of 60 seconds. The package automatically clamps
> the interval to avoid a system error.

## Calendar Notifications

Use `.calendar` to fire at a specific time of day, optionally restricted to a weekday:

```swift
// Every day at 8:00 AM
await notifier.schedule(
  id: "daily_8am",
  title: "Morning check-in",
  body: "Good morning!",
  type: .calendar(weekday: nil, hour: 8, minute: 0, repeats: true)
)

// Every Monday at 9:30 AM (weekday 2 = Monday in Gregorian calendars)
await notifier.schedule(
  id: "monday_standup",
  title: "Standup",
  body: "Time for your weekly standup.",
  type: .calendar(weekday: 2, hour: 9, minute: 30, repeats: true)
)
```

The `weekday` parameter follows Foundation's `DateComponents.weekday` convention:
`1` = Sunday, `2` = Monday … `7` = Saturday.

## Weekday-Repeating Notifications

When you need the same notification on multiple days of the week, use
``NotificationManager/scheduleRepeatingNotification(id:title:subtitle:body:category:hour:minute:days:sound:badge:attachments:interruptionLevel:userInfo:launchImageName:targetContentIdentifier:relevanceScore:filterCriteria:threadIdentifier:)``
with an array of ``NotificationWeekday`` values:

```swift
let workdays: [NotificationWeekday] = [.monday, .tuesday, .wednesday, .thursday, .friday]

await notifier.scheduleRepeatingNotification(
  id: "water",
  title: "Stay hydrated",
  body: "Time to drink some water.",
  hour: 10,
  minute: 0,
  days: workdays
)
```

Each day gets its own notification request with a derived identifier — `water_2`, `water_3`,
`water_4`, `water_5`, `water_6` in the example above. This naming convention makes it easy to
remove individual days later using ``NotificationManager/removePendingWeekdayNotifications(id:days:)``.

### The NotificationWeekday type

``NotificationWeekday`` provides static members for each day and locale-aware display strings:

```swift
let day = NotificationWeekday.wednesday

print(day.value)                  // 4
print(day.localizedName)          // "Wednesday" (localised)
print(day.localizedShortSymbol)   // "Wed"
print(day.localizedVeryShortSymbol) // "W"

// All days in order (Sunday through Saturday)
let all = NotificationWeekday.allCases
```

You can also create one from a raw Foundation weekday integer:

```swift
let friday = NotificationWeekday(6)
```

## Inactivity Reminders

Use ``NotificationManager/scheduleInactivityReminder(duration:repeats:title:subtitle:body:category:sound:badge:attachments:userInfo:)``
to re-engage users who haven't opened the app for a while:

```swift
// Call once per app launch — this resets the timer and schedules the reminder
await notifier.scheduleInactivityReminder(
  duration: .seconds(7 * 24 * 60 * 60), // 7 days
  title: "We miss you!",
  body: "Open the app to pick up where you left off."
)
```

Each call to this method:
1. Records the current time as the "last opened" date
2. Cancels any previously pending inactivity reminder
3. Schedules a new one at the specified interval

Call ``NotificationManager/markAppOpened()`` at launch to reset the timer without scheduling a
new reminder, for example when the app is opened from a different notification:

```swift
func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
  notifier.markAppOpened()
}
```

## Additional Content Options

All scheduling methods accept the same optional parameters for enriching notification content:

```swift
await notifier.schedule(
  id: "rich_example",
  title: "Rich Notification",
  subtitle: "With extra content",
  body: "This notification has everything.",
  type: .timeInterval(duration: .seconds(5), repeats: false),
  sound: .named("chime"),          // custom bundled sound
  badge: 1,                        // badge count to show on icon
  interruptionLevel: .timeSensitive,
  userInfo: ["screen": "dashboard"],
  threadIdentifier: "updates"      // groups related notifications
)
```

### Sound options

``NotificationSound`` provides several options:

```swift
.default                            // system default
.defaultCritical                    // bypasses silent mode (requires entitlement)
.defaultCriticalVolume(0.8)         // critical at specific volume
.named("chime")                     // bundled audio file by name
.fileURL(url)                       // bundled audio file by URL
```

### Attachments

Attach an image using one of the builders in ``NotificationAttachmentBuilder``:

```swift
// SF Symbol rendered as an image
let icon = NotificationAttachmentBuilder.AttachmentSymbol(
  "star.fill",
  foreground: .yellow,
  background: .black
)

// UIImage
let photo = NotificationAttachmentBuilder.AttachmentImage(someUIImage)

// Any SwiftUI view
let card = NotificationAttachmentBuilder.AttachmentView(
  MyNotificationCard(),
  size: CGSize(width: 300, height: 300)
)

await notifier.schedule(
  id: "with_image",
  title: "Photo attached",
  body: "Tap to view.",
  type: .timeInterval(duration: .seconds(5), repeats: false),
  attachments: [icon]
)
```

## Checking the Result

``NotificationManager/schedule(id:title:subtitle:body:category:type:sound:badge:attachments:interruptionLevel:userInfo:launchImageName:targetContentIdentifier:relevanceScore:filterCriteria:threadIdentifier:)``
returns a `Result<Void, Error>` so you can act on failures:

```swift
let result = await notifier.schedule(
  id: "checked",
  title: "Test",
  body: "Checking the result",
  type: .timeInterval(duration: .seconds(5), repeats: false)
)

switch result {
case .success:
  print("Scheduled successfully")
case .failure(let error):
  print("Failed: \(error.localizedDescription)")
}
```

The return value is `@discardableResult`, so you can ignore it when you don't need error handling.
