import SwiftUI

@main
struct RomandieWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchContentView()
        }
    }
}

struct WatchContentView: View {
    @State private var concerts: [Concert] = []
    @State private var loading = true
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView()
                } else if let error {
                    Text(error).font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    List(concerts) { c in
                        NavigationLink {
                            WatchDetailView(concert: c)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(c.shortDateLabel.uppercased())
                                    .font(.caption2).foregroundStyle(Color.romandieRed)
                                Text(c.title).font(.headline).lineLimit(2)
                                Text("\(c.timeText)\(c.priceText.isEmpty ? "" : " · \(c.priceText)")")
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Romandie")
        }
        .task { await load() }
    }

    private func load() async {
        loading = true; error = nil
        do {
            concerts = try await ConcertLoader.fetch()
        } catch {
            self.error = "Impossible de charger la programmation."
        }
        loading = false
    }
}

struct WatchDetailView: View {
    let concert: Concert

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(concert.title).font(.headline)
                Label(concert.shortDateLabel, systemImage: "calendar").font(.caption)
                Label(concert.timeText, systemImage: "clock").font(.caption)
                if !concert.priceText.isEmpty {
                    Label(concert.priceText, systemImage: "ticket")
                        .font(.caption).foregroundStyle(Color.romandieRed)
                }
                if let ticket = concert.ticketURL {
                    Link(destination: ticket) {
                        Label("Billetterie", systemImage: "ticket.fill")
                    }
                    .font(.caption)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
        .navigationTitle("Concert")
    }
}
