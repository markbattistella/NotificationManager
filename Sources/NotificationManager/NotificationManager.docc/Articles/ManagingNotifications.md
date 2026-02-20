# Managing Notifications

Query pending and delivered notifications, inspect their state, and remove them individually or in bulk.

## Overview

After scheduling notifications you often need to check what is pending, verify a specific
notification is still scheduled, or remove some or all of them. ``NotificationManager`` wraps
the relevant `UNUserNotificationCenter` APIs behind a cleaner interface and adds prefix-based
bulk operations that are particularly useful when you schedule families of related notifications
(such as weekday-repeating reminders sharing a common base ID).

## Querying Pending Notifications

### All pending

```swift
let pending = await notifier.pendingNotifications()
print("Pending count: \(pending.count)")
```

### Matching a prefix

When you schedule a family of notifications with a shared prefix (e.g., weekday reminders using
`scheduleRepeatingNotification`), you can query them as a group:

```swift
let hydrationReminders = await notifier.pendingNotifications(matchingPrefix: "hydration")
```

### Check if a specific notification is scheduled

```swift
let isScheduled = await notifier.isNotificationScheduled(id: "daily_8am")
if isScheduled {
  // Already in the queue
}
```

### Next trigger date

Inspect when a pending notification will next fire:

```swift
if let date = await notifier.nextTriggerDate(for: "daily_8am") {
  print("Next fires: \(date.formatted())")
}
```

This works for both calendar and time-interval triggers. It returns `nil` if the notification is
not in the pending queue or its trigger cannot be resolved.

## Querying Delivered Notifications

Notifications that have already been shown remain accessible until the user dismisses them:

```swift
let delivered = await notifier.deliveredNotifications()
```

## Full Notification State

For a combined view of whether a notification is pending, delivered, or both, use
``NotificationManager/notificationState(id:)``:

```swift
let state = await notifier.notificationState(id: "reminder_1")

print(state.isPending)    // true if waiting in the queue
print(state.isDelivered)  // true if shown and still in Notification Centre

if let request = state.request {
  // Access the pending UNNotificationRequest
}

if let delivered = state.delivered {
  // Access the delivered UNNotification
}
```

## Observing State Changes

``NotificationManager/hasPendingNotifications`` is an `@Observable` property that updates
automatically on app foreground. You can drive UI from it directly:

```swift
struct NotificationStatusView: View {
  @Environment(NotificationManager.self) var notifier

  var body: some View {
    Label(
      notifier.hasPendingNotifications ? "Reminders active" : "No reminders set",
      systemImage: notifier.hasPendingNotifications ? "bell.fill" : "bell.slash"
    )
  }
}
```

Call ``NotificationManager/refreshAll()`` to manually trigger a refresh at any time:

```swift
await notifier.refreshAll()
```

## Removing Pending Notifications

### Single notification

```swift
notifier.removePendingNotification(id: "daily_8am")
```

### All notifications matching a prefix

```swift
await notifier.removePendingNotifications(matchingPrefix: "hydration")
```

This is the most convenient way to remove a family of related notifications without tracking
each individual ID.

### Specific weekdays from a repeating set

When you have used ``NotificationManager/scheduleRepeatingNotification(id:title:subtitle:body:category:hour:minute:days:sound:badge:attachments:interruptionLevel:userInfo:launchImageName:targetContentIdentifier:relevanceScore:filterCriteria:threadIdentifier:)``
and only want to remove certain days:

```swift
// Remove only the Monday and Friday reminders from the "hydration" set
notifier.removePendingWeekdayNotifications(
  id: "hydration",
  days: [.monday, .friday]
)
```

The method reconstructs the derived identifiers (`hydration_2`, `hydration_6`) and removes them
in one batch.

### Everything

```swift
notifier.removeAllPendingNotifications()
```

## Removing Delivered Notifications

Remove notifications that have already been delivered and are visible in Notification Centre:

```swift
// One specific notification
notifier.removeDeliveredNotification(id: "reminder_1")

// All delivered notifications
notifier.removeAllDeliveredNotifications()
```

## Clearing the Badge

Reset the app icon badge count to zero:

```swift
notifier.removeNotificationBadges()
```

Call this when the user opens the app after receiving a badged notification.

## Checking Capabilities

``NotificationManager/capabilities()`` reports which notification features the user has enabled
in their system settings:

```swift
let caps = await notifier.capabilities()

print(caps.allowsAlert)             // banner-style notifications
print(caps.allowsSound)             // sounds
print(caps.allowsBadge)             // badge counts
print(caps.allowsAnnouncements)     // Siri Announce (iOS only)
print(caps.criticalAlertSupported)  // critical alert entitlement active
```

Use this to adapt your scheduling — for example, only setting a badge count when `allowsBadge`
is true.
