//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Testing
import UserNotifications

@testable import NotificationManager

@MainActor
struct NotificationRequestBuilderTests {

  @Test("nil badge leaves notification badge unset")
  func nilBadgeLeavesNotificationBadgeUnset() async {
    let request = await makeRequest(badge: nil)

    #expect(request.content.badge == nil)
  }

  @Test("explicit badge is applied")
  func explicitBadgeIsApplied() async {
    let request = await makeRequest(badge: 7)

    #expect(request.content.badge?.intValue == 7)
  }

  @Test("repeating time interval is clamped to system minimum")
  func repeatingTimeIntervalIsClampedToSystemMinimum() async throws {
    let request = await makeRequest(
      type: .timeInterval(duration: .seconds(5), repeats: true)
    )
    let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)

    #expect(trigger.timeInterval == 60)
    #expect(trigger.repeats)
  }

  @Test("non-repeating time interval is clamped above zero")
  func nonRepeatingTimeIntervalIsClampedAboveZero() async throws {
    let request = await makeRequest(
      type: .timeInterval(duration: .zero, repeats: false)
    )
    let trigger = try #require(request.trigger as? UNTimeIntervalNotificationTrigger)

    #expect(trigger.timeInterval == 0.1)
    #expect(!trigger.repeats)
  }

  @Test("calendar trigger keeps weekday and time components")
  func calendarTriggerKeepsWeekdayAndTimeComponents() async throws {
    let request = await makeRequest(
      type: .calendar(
        weekday: NotificationWeekday.friday.value,
        hour: 16,
        minute: 45,
        repeats: true
      )
    )
    let trigger = try #require(request.trigger as? UNCalendarNotificationTrigger)

    #expect(trigger.dateComponents.weekday == NotificationWeekday.friday.value)
    #expect(trigger.dateComponents.hour == 16)
    #expect(trigger.dateComponents.minute == 45)
    #expect(trigger.repeats)
  }

  private func makeRequest(
    type: NotificationType = .timeInterval(duration: .seconds(5), repeats: false),
    badge: Int? = nil
  ) async -> UNNotificationRequest {
    await NotificationRequestBuilder.makeRequest(
      id: "test",
      title: "Title",
      body: "Body",
      type: type,
      badge: badge
    )
  }
}
