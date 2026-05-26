//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import UserNotifications

internal enum NotificationRequestBuilder {

  @MainActor
  internal static func makeRequest(
    id: String,
    title: String,
    subtitle: String = "",
    body: String,
    categoryIdentifier: String? = nil,
    type: NotificationType,
    sound: UNNotificationSound? = nil,
    badge: Int? = nil,
    attachments: [NotificationAttachmentFactory] = [],
    interruptionLevel: UNNotificationInterruptionLevel = .active,
    userInfo: [AnyHashable: Any] = [:],
    launchImageName: String? = nil,
    targetContentIdentifier: String? = nil,
    relevanceScore: Double = 1,
    filterCriteria: String? = nil,
    threadIdentifier: String? = nil
  ) async -> UNNotificationRequest {

    let content = UNMutableNotificationContent()
    content.title = title
    content.subtitle = subtitle
    content.body = body
    content.userInfo = userInfo
    content.sound = sound
    content.interruptionLevel = interruptionLevel
    content.targetContentIdentifier = targetContentIdentifier
    content.relevanceScore = relevanceScore
    content.filterCriteria = filterCriteria

    if let badge {
      content.badge = NSNumber(value: badge)
    }

    #if os(iOS)
      if let launchImageName {
        content.launchImageName = launchImageName
      }
    #endif

    if let threadIdentifier {
      content.threadIdentifier = threadIdentifier
    }

    if let categoryIdentifier {
      content.categoryIdentifier = categoryIdentifier
    }

    let compiledAttachments = await makeAttachments(from: attachments)
    if !compiledAttachments.isEmpty {
      content.attachments = compiledAttachments
    }

    return UNNotificationRequest(
      identifier: id,
      content: content,
      trigger: makeTrigger(for: type)
    )
  }

  @MainActor
  private static func makeAttachments(
    from factories: [NotificationAttachmentFactory]
  ) async -> [UNNotificationAttachment] {
    var attachments: [UNNotificationAttachment] = []
    attachments.reserveCapacity(factories.count)

    for factory in factories {
      if let attachment = await factory.makeAttachment() {
        attachments.append(attachment)
      }
    }

    return attachments
  }

  private static func makeTrigger(for type: NotificationType) -> UNNotificationTrigger {
    switch type {
    case .timeInterval(let duration, let repeats):
      let rawSeconds = duration.timeInterval
      let seconds = max(rawSeconds, repeats ? 60 : 0.1)

      return UNTimeIntervalNotificationTrigger(
        timeInterval: seconds,
        repeats: repeats
      )

    case .calendar(let weekday, let hour, let minute, let repeats):
      var components = DateComponents()
      components.hour = hour
      components.minute = minute
      components.weekday = weekday

      return UNCalendarNotificationTrigger(
        dateMatching: components,
        repeats: repeats
      )

    #if (os(iOS) && !targetEnvironment(macCatalyst)) || os(watchOS)
      case .location(let region, let repeats):
        return UNLocationNotificationTrigger(region: region, repeats: repeats)
    #endif
    }
  }
}
