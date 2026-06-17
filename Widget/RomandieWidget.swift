import WidgetKit
import SwiftUI

// MARK: - Timeline

struct ConcertEntry: TimelineEntry {
    let date: Date
    let concerts: [Concert]
    let images: [String: Data]   // concert.id -> données de l'affiche
    let errorMessage: String?

    func image(for concert: Concert) -> UIImage? {
        images[concert.id].flatMap(UIImage.init(data:))
    }
}

struct Provider: TimelineProvider {

    func placeholder(in context: Context) -> ConcertEntry {
        ConcertEntry(date: Date(), concerts: ConcertLoader.sample, images: [:], errorMessage: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (ConcertEntry) -> Void) {
        if context.isPreview {
            completion(ConcertEntry(date: Date(), concerts: ConcertLoader.sample, images: [:], errorMessage: nil))
            return
        }
        Task { completion(await loadEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ConcertEntry>) -> Void) {
        Task {
            let entry = await loadEntry()
            // Rafraîchit ~toutes les 6 heures.
            let next = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date().addingTimeInterval(6 * 3600)
            completion(Timeline(entries: [entry], policy: .after(next)))
        }
    }

    private func loadEntry() async -> ConcertEntry {
        do {
            let concerts = try await ConcertLoader.fetch()
            // Télécharge les affiches des concerts affichés (au max les 7 du grand widget).
            let toShow = Array(concerts.prefix(7))
            var images: [String: Data] = [:]
            await withTaskGroup(of: (String, Data?).self) { group in
                for c in toShow {
                    guard let url = c.imageURL else { continue }
                    group.addTask { (c.id, await ConcertLoader.fetchImageData(url)) }
                }
                for await (id, data) in group {
                    if let data { images[id] = data }
                }
            }
            return ConcertEntry(date: Date(), concerts: concerts, images: images, errorMessage: nil)
        } catch {
            return ConcertEntry(date: Date(), concerts: [], images: [:],
                                errorMessage: "Impossible de charger la programmation.")
        }
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
            case .systemLarge: ListView(entry: entry, maxRows: 7, title: true)
            default:           ListView(entry: entry, maxRows: 3, title: true) // medium
            }
        }
        .containerBackground(for: .widget) { Color(.systemBackground) }
    }
}

// MARK: - Petit widget : prochain concert

struct SmallView: View {
    let entry: ConcertEntry

    var body: some View {
        if let c = entry.concerts.first {
            ZStack(alignment: .bottomLeading) {
                if let ui = entry.image(for: c) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                    LinearGradient(colors: [.black.opacity(0.05), .black.opacity(0.85)],
                                   startPoint: .top, endPoint: .bottom)
                } else {
                    Color.romandieRed
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(c.shortDateLabel.uppercased())
                        .font(.caption2).bold()
                        .foregroundStyle(.white.opacity(0.9))
                    Text(c.title)
                        .font(.caption).bold()
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .minimumScaleFactor(0.8)
                }
                .padding(10)
            }
            .widgetURL(c.url)
        } else {
            EmptyStateView(message: entry.errorMessage)
        }
    }
}

// MARK: - Widget moyen / grand : liste

struct ListView: View {
    let entry: ConcertEntry
    let maxRows: Int
    let title: Bool

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
                }
                ForEach(entry.concerts.prefix(maxRows)) { c in
                    ConcertRow(concert: c, poster: entry.image(for: c))
                    if c.id != entry.concerts.prefix(maxRows).last?.id {
                        Divider()
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(12)
            .widgetURL(URL(string: "https://www.leromandie.ch/programmation"))
        }
    }
}

struct ConcertRow: View {
    let concert: Concert
    let poster: UIImage?

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Affiche (ou pastille date en repli)
            Group {
                if let poster {
                    Image(uiImage: poster)
                        .resizable()
                        .scaledToFill()
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
    ConcertEntry(date: .now, concerts: ConcertLoader.sample, images: [:], errorMessage: nil)
}
