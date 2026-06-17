import SwiftUI
import WidgetKit

@main
struct RomandieApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var concerts: [Concert] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Chargement…")
                } else if let error {
                    ContentUnavailableView("Oups", systemImage: "wifi.slash", description: Text(error))
                } else {
                    List {
                        ForEach(concerts) { c in
                            NavigationLink(value: c) {
                                HStack(spacing: 12) {
                                    VStack {
                                        Text(dayNumber(c)).font(.title3).bold()
                                        Text(monthShort(c).uppercased()).font(.caption2)
                                    }
                                    .frame(width: 42)
                                    .foregroundStyle(Color.romandieRed)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(c.title).font(.subheadline).bold()
                                        Text("\(c.timeText)\(c.priceText.isEmpty ? "" : " · \(c.priceText)")")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        Section {
                            Text("App non-officielle. Données et affiches : leromandie.ch")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: Concert.self) { c in
                        ConcertDetailView(concert: c)
                    }
                }
            }
            .navigationTitle("Le Romandie")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; error = nil
        do {
            concerts = try await ConcertLoader.fetch()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            self.error = "Impossible de charger la programmation du Romandie."
        }
        loading = false
    }

    private func dayNumber(_ c: Concert) -> String {
        guard let d = c.date else { return "•" }
        return String(Calendar.current.component(.day, from: d))
    }
    private func monthShort(_ c: Concert) -> String {
        guard let d = c.date else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_CH")
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f.string(from: d)
    }
}
