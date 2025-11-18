//
// Project: NotificationManagerExample
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SwiftUI
import NotificationManager

/// A weekday selection component allowing multi-select via circular buttons.
struct WeekdayPicker: View {

    /// The currently selected weekdays.
    @Binding var selectedDays: Set<NotificationWeekday>

    var body: some View {
        HStack {
            ForEach(NotificationWeekday.allCases) { day in
                /// Toggles a weekday between selected and unselected states.
                Button {
                    toggle(day)
                } label: {
                    ZStack {
                        Circle()
                            .fill(selectedDays.contains(day)
                                  ? Color.accentColor
                                  : Color.gray.opacity(0.5))

                        Text(day.localizedVeryShortSymbol)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// Adds or removes a weekday from the selection set.
    private func toggle(_ day: NotificationWeekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}
