//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI

/// A simple detail view displayed when navigating from a notification route.
struct DetailView: View {

    /// The identifier of the notification that triggered navigation.
    let id: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Detail Screen")
                .font(.largeTitle)
            Text("Opened from notification id: \(id)")
        }
        .padding()
    }
}
