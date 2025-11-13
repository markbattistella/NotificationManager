//
// Project: NotificationManager
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import UserNotifications

/// Defines the properties required to describe a notification category.
///
/// A category groups one or more actions and is referenced by notifications that support user
/// interaction.
public protocol NotificationCategoryDefinition {
    
    /// The unique identifier for the category.
    var id: String { get }
    
    /// The actions that belong to this category.
    var actions: [NotificationActionDefinition] { get }
    
    /// Options that configure the category’s behaviour.
    var options: UNNotificationCategoryOptions { get }
}
