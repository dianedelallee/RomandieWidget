import SwiftUI

@main
struct RomandieApp: App {
    @StateObject private var favorites = FavoritesStore()
    @StateObject private var tickets = TicketStore()
    @StateObject private var model = ConcertsModel()
    @State private var selectedTab = 0
    @State private var agendaSelection: Concert?
    @State private var pendingEventId: String?

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                AgendaTab(selection: $agendaSelection)
                    .tabItem { Label("Agenda", systemImage: "list.bullet") }
                    .tag(0)

                CalendarTab()
                    .tabItem { Label("Calendrier", systemImage: "calendar") }
                    .tag(1)
            }
            .tint(Color.romandieRed)
            .environmentObject(favorites)
            .environmentObject(tickets)
            .environmentObject(model)
            .task { if model.concerts.isEmpty { await model.load() } }
            .onOpenURL { url in
                guard let id = DeepLink.eventId(from: url) else { return }
                selectedTab = 0
                resolve(id)
            }
            .onChange(of: model.concerts) { _, _ in
                if let id = pendingEventId { pendingEventId = nil; resolve(id) }
            }
        }
    }

    private func resolve(_ id: String) {
        if let concert = model.concerts.first(where: { $0.id == id }) {
            agendaSelection = concert
        } else {
            pendingEventId = id
        }
    }
}

enum ConcertFilter: String, CaseIterable, Identifiable {
    case all = "Tous"
    case favorites = "Favoris"
    case free = "Gratuit"
    var id: String { rawValue }
}

// MARK: - Onglet Agenda (liste)

struct AgendaTab: View {
    @EnvironmentObject private var model: ConcertsModel
    @EnvironmentObject private var favorites: FavoritesStore
    @EnvironmentObject private var tickets: TicketStore
    @Binding var selection: Concert?
    @Environment(\.horizontalSizeClass) private var hSize
    @State private var query = ""
    @State private var filter: ConcertFilter = .all

    private var visibleConcerts: [Concert] {
        model.concerts.filter { c in
            switch filter {
            case .all: return true
            case .favorites: return favorites.isFavorite(c)
            case .free: return c.priceText.uppercased().contains("GRATUIT")
            }
        }
        .filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if model.loading {
                    ProgressView("Chargement…")
                } else if let error = model.error {
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { Task { await model.load() } } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        } detail: {
            if let selection {
                ConcertDetailView(concert: selection)
            } else {
                ContentUnavailableView("Choisis un concert",
                                       systemImage: "hand.tap",
                                       description: Text("Sélectionne un concert dans la liste."))
            }
        }
        .searchable(text: $query, prompt: "Rechercher un concert")
        .onAppear { autoSelectOnPad() }
        .onChange(of: model.concerts) { _, _ in autoSelectOnPad() }
    }

    /// Sur iPad (grand écran), pré-sélectionne un concert pour ne pas laisser
    /// le panneau détail vide. Sur iPhone, on ne pré-sélectionne pas.
    private func autoSelectOnPad() {
        if hSize == .regular, selection == nil {
            selection = visibleConcerts.first
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
            List(selection: $selection) {
                ForEach(visibleConcerts) { c in
                    row(c)
                        .tag(c)
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
            if tickets.hasTicket(c) {
                Image(systemName: "qrcode").font(.caption).foregroundStyle(Color.romandieRed)
            }
            if favorites.isFavorite(c) {
                Image(systemName: "heart.fill").font(.caption).foregroundStyle(.pink)
            }
        }
        .padding(.vertical, 2)
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

// MARK: - Onglet Calendrier

struct CalendarTab: View {
    @EnvironmentObject private var model: ConcertsModel
    @State private var path: [Concert] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if model.loading {
                    ProgressView("Chargement…")
                } else if let error = model.error {
                    ContentUnavailableView("Oups", systemImage: "wifi.slash", description: Text(error))
                } else {
                    CalendarView(concerts: model.concerts)
                }
            }
            .navigationTitle("Calendrier")
            .navigationDestination(for: Concert.self) { ConcertDetailView(concert: $0) }
        }
    }
}
