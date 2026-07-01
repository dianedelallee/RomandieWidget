import SwiftUI
import WidgetKit

@main
struct RomandieApp: App {
    @StateObject private var favorites = FavoritesStore()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(favorites)
        }
    }
}

enum ConcertFilter: String, CaseIterable, Identifiable {
    case all = "Tous"
    case favorites = "Favoris"
    case free = "Gratuit"
    var id: String { rawValue }
}

struct ContentView: View {
    @EnvironmentObject private var favorites: FavoritesStore
    @State private var concerts: [Concert] = []
    @State private var loading = true
    @State private var error: String?
    @State private var path: [Concert] = []
    @State private var pendingEventId: String?
    @State private var query = ""
    @State private var filter: ConcertFilter = .all

    private var visibleConcerts: [Concert] {
        concerts.filter { c in
            switch filter {
            case .all: return true
            case .favorites: return favorites.isFavorite(c)
            case .free: return c.priceText.uppercased().contains("GRATUIT")
            }
        }
        .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if loading {
                    ProgressView("Chargement…")
                } else if let error {
                    ContentUnavailableView("Oups", systemImage: "wifi.slash", description: Text(error))
                } else {
                    VStack(spacing: 0) {
                        Picker("Filtre", selection: $filter) {
                            ForEach(ConcertFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 6)

                        list
                    }
                }
            }
            .navigationTitle("Le Romandie")
            .navigationDestination(for: Concert.self) { c in
                ConcertDetailView(concert: c)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .searchable(text: $query, prompt: "Rechercher un concert")
        .task { await load() }
        .onOpenURL { url in
            guard let id = DeepLink.eventId(from: url) else { return }
            navigate(toEventId: id)
        }
    }

    @ViewBuilder private var list: some View {
        if visibleConcerts.isEmpty {
            ContentUnavailableView(
                filter == .favorites ? "Aucun favori" : "Aucun concert",
                systemImage: filter == .favorites ? "heart" : "magnifyingglass",
                description: Text(filter == .favorites
                                  ? "Touche le cœur d'un concert pour le suivre."
                                  : "Essaie un autre filtre ou une autre recherche.")
            )
        } else {
            List {
                ForEach(visibleConcerts) { c in
                    NavigationLink(value: c) { row(c) }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                Task { await favorites.toggle(c) }
                            } label: {
                                Label(favorites.isFavorite(c) ? "Retirer" : "Favori",
                                      systemImage: favorites.isFavorite(c) ? "heart.slash.fill" : "heart.fill")
                            }
                            .tint(.pink)
                        }
                }
                Section {
                    Text("App non-officielle. Données et affiches : leromandie.ch")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
        }
    }

    private func row(_ c: Concert) -> some View {
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
            Spacer(minLength: 0)
            if favorites.isFavorite(c) {
                Image(systemName: "heart.fill").font(.caption).foregroundStyle(.pink)
            }
        }
        .padding(.vertical, 2)
    }

    private func load() async {
        loading = true; error = nil
        do {
            concerts = try await ConcertLoader.fetch()
            WidgetCenter.shared.reloadAllTimelines()
            if let id = pendingEventId {
                pendingEventId = nil
                navigate(toEventId: id)
            }
        } catch {
            self.error = "Impossible de charger la programmation du Romandie."
        }
        loading = false
    }

    private func navigate(toEventId id: String) {
        if let concert = concerts.first(where: { $0.id == id }) {
            path = [concert]
        } else {
            pendingEventId = id
        }
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
