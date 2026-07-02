import SwiftUI

/// Vue calendrier : grille mensuelle avec pastilles sur les jours de concert,
/// et liste des concerts du jour sélectionné.
struct CalendarView: View {
    let concerts: [Concert]

    @State private var monthAnchor = Date()
    @State private var selectedDay: Date?

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.locale = Locale(identifier: "fr_CH")
        c.firstWeekday = 2 // lundi
        return c
    }

    /// Concerts regroupés par jour (début de journée).
    private var byDay: [Date: [Concert]] {
        Dictionary(grouping: concerts.filter { $0.date != nil }) { c in
            cal.startOfDay(for: c.date!)
        }
    }

    private var firstOfMonth: Date {
        cal.date(from: cal.dateComponents([.year, .month], from: monthAnchor)) ?? monthAnchor
    }

    /// Cellules de la grille : nil pour les cases vides avant le 1er.
    private var cells: [Date?] {
        let weekday = cal.component(.weekday, from: firstOfMonth)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        let days = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        var out: [Date?] = Array(repeating: nil, count: leading)
        for d in 0..<days {
            out.append(cal.date(byAdding: .day, value: d, to: firstOfMonth))
        }
        return out
    }

    private let weekdaySymbols = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                LazyVGrid(columns: columns, spacing: 6) {
                    ForEach(weekdaySymbols, id: \.self) { s in
                        Text(s).font(.caption2).foregroundStyle(.secondary)
                    }
                    ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                        dayCell(day)
                    }
                }
                .padding(.horizontal)

                Divider()

                selectedDaySection
            }
            .padding(.vertical)
        }
    }

    private var header: some View {
        HStack {
            Button { changeMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthTitle).font(.headline)
            Spacer()
            Button { changeMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
        .tint(Color.romandieRed)
    }

    @ViewBuilder private func dayCell(_ day: Date?) -> some View {
        if let day {
            let has = !(byDay[cal.startOfDay(for: day)]?.isEmpty ?? true)
            let isSelected = selectedDay.map { cal.isDate($0, inSameDayAs: day) } ?? false
            Button {
                selectedDay = day
            } label: {
                VStack(spacing: 3) {
                    Text("\(cal.component(.day, from: day))")
                        .font(.callout)
                        .fontWeight(has ? .bold : .regular)
                        .foregroundStyle(isSelected ? .white : (has ? Color.primary : Color.secondary))
                    Circle()
                        .fill(has ? Color.romandieRed : .clear)
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.romandieRed : .clear)
                )
            }
            .buttonStyle(.plain)
            .disabled(!has)
        } else {
            Color.clear.frame(height: 40)
        }
    }

    @ViewBuilder private var selectedDaySection: some View {
        if let day = selectedDay, let list = byDay[cal.startOfDay(for: day)], !list.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(dayTitle(day)).font(.headline).padding(.horizontal)
                ForEach(list) { c in
                    NavigationLink(value: c) {
                        ConcertCalendarRow(concert: c)
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            ContentUnavailableView("Sélectionne un jour",
                                   systemImage: "hand.tap",
                                   description: Text("Les jours avec un point rouge ont un concert."))
                .padding(.top, 20)
        }
    }

    // MARK: - Helpers

    private func changeMonth(_ delta: Int) {
        if let d = cal.date(byAdding: .month, value: delta, to: firstOfMonth) {
            monthAnchor = d
        }
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_CH")
        f.setLocalizedDateFormatFromTemplate("MMMM yyyy")
        return f.string(from: firstOfMonth).capitalized
    }

    private func dayTitle(_ d: Date) -> String {
        let f = DateFormatter(); f.locale = Locale(identifier: "fr_CH")
        f.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
        return f.string(from: d).capitalized
    }
}

private struct ConcertCalendarRow: View {
    let concert: Concert
    @EnvironmentObject private var tickets: TicketStore
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.romandieRed)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 2) {
                Text(concert.title).font(.subheadline).bold().foregroundStyle(.primary)
                Text("\(concert.timeText)\(concert.priceText.isEmpty ? "" : " · \(concert.priceText)")")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if tickets.hasTicket(concert) {
                Image(systemName: "qrcode").font(.caption).foregroundStyle(Color.romandieRed)
            }
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
