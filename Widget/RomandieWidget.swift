import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Timeline

struct ConcertEntry: TimelineEntry {
    let date: Date
    let concerts: [Concert]      // liste complète (paginée à l'affichage)
    let offset: Int              // index du premier concert affiché
    let images: [String: Data]   // concert.id -> données de l'affiche
    let errorMessage: String?

    func image(for concert: Concert) -> UIImage? {
        images[concert.id].flatMap(UIImage.init(data:))
    }
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> ConcertEntry {
        ConcertEntry(date: Date(), concerts: ConcertLoader.sample, offset: 0, images: [:], errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ConcertEntry) -> Void) {
        if context.isPreview {
            completion(ConcertEntry(date: Date(), concerts: ConcertLoader.sample, offset: 0, images: [:], errorMessage: nil))
            return
        }
        Task { completion(await loadEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConcertEntry>) -> Void) {
        Task {
            let entry = await loadEntry()
            // Rafraîchit ~toutes les 6 heures (les boutons rechargent à part).
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(6 * 3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func loadEntry() async -> ConcertEntry {
        // 1) Utilise le cache si récent (<2 h) — les taps sur ◀▶ sont alors instantanés.
        var concerts = ConcertCache.loadConcerts()
        let stale = ConcertCache.cacheDate.map { Date().timeIntervalSince($0) > 2 * 3600 } ?? true

        if concerts.isEmpty || stale {
            if let fresh = try? await ConcertLoader.fetch(), !fresh.isEmpty {
                concerts = fresh
                ConcertCache.saveConcerts(fresh)
                // Télécharge et met en cache toutes les affiches (en parallèle).
                await withTaskGroup(of: Void.self) { group in
                    for c in fresh {
                        guard let url = c.imageURL else { continue }
                        group.addTask {
                            if let data = await ConcertLoader.fetchImageData(url) {
                                ConcertCache.saveImage(data, for: c)
                            }
                        }
                    }
                }
                ConcertCache.pageOffset = 0   // nouvelle programmation -> on repart du début
            }
        }

        // 2) Charge les affiches en cache.
        var images: [String: Data] = [:]
        for c in concerts {
            if let d = ConcertCache.imageData(for: c) { images[c.id] = d }
        }

        let offset = min(max(0, ConcertCache.pageOffset), max(0, concerts.count - 1))
        let err = concerts.isEmpty ? "Impossible de charger la programmation." : nil
        return ConcertEntry(date: Date(), concerts: concerts, offset: offset, images: images, errorMessage: err)
    }
}

// MARK: - Vue principale (s'adapte à la taille)

struct RomandieWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: ConcertEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallView(entry: entry)
            case .systemLarge: ListView(entry: entry, pageSize: 6)
            default:           ListView(entry: entry, pageSize: 3) // medium
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

// MARK: - Boutons de pagination ◀ ▶

struct PagerButtons: View {
    let offset: Int
    let pageSize: Int
    let total: Int

    private var canPrev: Bool { offset > 0 }
    private var canNext: Bool { offset + pageSize < total }

    var body: some View {
        HStack(spacing: 6) {
            Button(intent: ShiftConcertsIntent(direction: -1, pageSize: pageSize)) {
                Image(systemName: "chevron.left").font(.caption2.bold())
            }
            .disabled(!canPrev)
            Button(intent: ShiftConcertsIntent(direction: 1, pageSize: pageSize)) {
                Image(systemName: "chevron.right").font(.caption2.bold())
            }
            .disabled(!canNext)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color.romandieRed)
    }
}

// MARK: - Petit widget : un concert + flèches

struct SmallView: View {
    let entry: ConcertEntry

    private var concert: Concert? {
        guard !entry.concerts.isEmpty else { return nil }
        return entry.concerts[min(entry.offset, entry.concerts.count - 1)]
    }

    var body: some View {
        if let c = concert {
            ZStack(alignment: .bottomLeading) {
                if let ui = entry.image(for: c) {
                    Image(uiImage: ui).resizable().scaledToFill()
                    LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.85)],
                                   startPoint: .top, endPoint: .bottom)
                } else {
                    Color.romandieRed
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(c.shortDateLabel.uppercased())
                            .font(.caption2).bold()
                            .foregroundStyle(.white.opacity(0.9))
                        Spacer()
                        Text("\(entry.offset + 1)/\(entry.concerts.count)")
                            .font(.caption2).bold()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text(c.title)
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    HStack {
                        Link(destination: DeepLink.url(for: c)) {
                            Text("Infos").font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        PagerButtons(offset: entry.offset, pageSize: 1, total: entry.concerts.count)
                            .foregroundStyle(.white)
                    }
                }
                .padding(10)
            }
        } else {
            EmptyStateView(message: entry.errorMessage)
        }
    }
}

// MARK: - Widget moyen / grand : liste paginée

struct ListView: View {
    let entry: ConcertEntry
    let pageSize: Int

    private var visible: [Concert] {
        guard !entry.concerts.isEmpty else { return [] }
        let start = min(entry.offset, max(0, entry.concerts.count - 1))
        let end = min(start + pageSize, entry.concerts.count)
        return Array(entry.concerts[start..<end])
    }

    var body: some View {
        if entry.concerts.isEmpty {
            EmptyStateView(message: entry.errorMessage)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(Color.romandieRed).frame(width: 8, height: 8)
                    Text("LE ROMANDIE")
                        .font(.caption2).bold()
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(entry.offset + 1)–\(min(entry.offset + pageSize, entry.concerts.count)) / \(entry.concerts.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    PagerButtons(offset: entry.offset, pageSize: pageSize, total: entry.concerts.count)
                }
                ForEach(visible) { c in
                    Link(destination: DeepLink.url(for: c)) {
                        ConcertRow(concert: c, poster: entry.image(for: c))
                    }
                    if c.id != visible.last?.id { Divider() }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
        }
    }
}

struct ConcertRow: View {
    let concert: Concert
    let poster: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Group {
                if let poster {
                    Image(uiImage: poster).resizable().scaledToFill()
                } else {
                    ZStack {
                        Color.romandieRed
                        VStack(spacing: 0) {
                            Text(dayNumber).font(.headline).bold()
                            Text(monthShort.uppercased()).font(.caption2)
                        }
                        .foregroundStyle(.white)
                    }
                }
            }
            .frame(width: 42, height: 42)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(concert.title)
                    .font(.caption).bold()
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
    }

    private var subtitle: String {
        var parts = [concert.shortDateLabel, concert.timeText]
        if !concert.priceText.isEmpty { parts.append(concert.priceText.capitalized) }
        return parts.joined(separator: " · ")
    }

    private var dayNumber: String {
        guard let d = concert.date else { return "•" }
        return String(Calendar.current.component(.day, from: d))
    }
    private var monthShort: String {
        guard let d = concert.date else { return "" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_CH")
        f.setLocalizedDateFormatFromTemplate("MMM")
        return f.string(from: d)
    }
}

struct EmptyStateView: View {
    let message: String?
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "music.note.list").font(.title2)
            Text(message ?? "Aucun concert à venir")
                .font(.caption).foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Déclaration du widget

struct RomandieWidget: Widget {
    let kind = "RomandieWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RomandieWidgetView(entry: entry)
        }
        .configurationDisplayName("Concerts au Romandie")
        .description("Les prochains concerts au Romandie (Lausanne).")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct RomandieWidgetBundle: WidgetBundle {
    var body: some Widget {
        RomandieWidget()
    }
}

// MARK: - Previews

#Preview("Medium", as: .systemMedium) {
    RomandieWidget()
} timeline: {
    ConcertEntry(date: .now, concerts: ConcertLoader.sample, offset: 0, images: [:], errorMessage: nil)
}
