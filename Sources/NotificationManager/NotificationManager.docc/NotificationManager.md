# ``NotificationManager``

A modern, SwiftUI-native API for scheduling, managing, and handling local notifications.

## Overview

`NotificationManager` replaces boilerplate `UNUserNotificationCenter` code with a clean,
async/await API built for SwiftUI. It is an `@Observable` class you inject once into your
environment and then use from any view or service in your app.

Key capabilities:

- **Permission handling** — request, observe, and respond to authorisation status changes
- **Flexible scheduling** — time interval, calendar, weekday-repeating, and inactivity triggers
- **Rich content** — attachments from `UIImage`, SF Symbols, or any SwiftUI view
- **Protocol-driven categories** — define actionable notification categories with full type safety
- **Querying and removal** — inspect pending and delivered notifications, remove by ID or prefix
- **Automatic state refresh** — re-checks permission and pending state whenever the app foregrounds

## Topics

### Getting Started

- <doc:GettingStarted>

### Scheduling

- <doc:SchedulingNotifications>

### Managing Notifications

- <doc:ManagingNotifications>

### Categories and Actions

- <doc:CustomCategoriesAndActions>

### Core Manager

- ``NotificationManager``

### Scheduling Types

- ``NotificationType``
- ``NotificationWeekday``
- ``NotificationSound``

### Permission

- ``PermissionStatus``

### State and Capabilities

- ``NotificationState``
- ``NotificationCapabilities``
- ``NotificationError``

### Protocols

- ``NotificationActionDescriptor``
- ``NotificationCategoryDescriptor``
- ``NotificationAttachmentFactory``

### Attachments

- ``NotificationAttachmentBuilder``
