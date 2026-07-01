import SwiftUI
import MapKit

struct ConcertDetailView: View {
    let concert: Concert

    @EnvironmentObject private var favorites: FavoritesStore
    @Environment(\.openURL) private var openURL
    @State private var calendarMessage: String?
    @State private var calendarOK = false
    @State private var addingToCalendar = false
    @State private var showMapChoice = false

    // Coordonnées du Romandie (Place de l'Europe, Lausanne).
    private let venue = CLLocationCoordinate2D(latitude: 46.52033, longitude: 6.63028)
    private let venueAddress = "Le Romandie, Place de l'Europe 1, 1003 Lausanne"

    private var isFavorite: Bool { favorites.isFavorite(concert) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                if let img = concert.imageURL {
                    AsyncImage(url: img) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFit()
                        default:
                            Rectangle().fill(Color.romandieRed.opacity(0.15))
                                .frame(height: 200)
                                .overlay(ProgressView())
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Text(concert.title)
                    .font(.title2).bold()

                HStack(spacing: 14) {
                    Label(concert.shortDateLabel, systemImage: "calendar")
                    Label(concert.timeText, systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if !concert.priceText.isEmpty {
                    Label(concert.priceText, systemImage: "ticket")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.romandieRed)
                }

                actions

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(calendarOK ? .green : .red)
                }

                mapSection

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Concert")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: concert.url,
                          subject: Text(concert.title),
                          message: Text("\(concert.title) — \(concert.shortDateLabel) au Romandie"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await favorites.toggle(concert) }
                } label: {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(.pink)
                }
                .accessibilityLabel(isFavorite ? "Retirer des favoris" : "Ajouter aux favoris")
            }
        }
    }

    // MARK: - Actions

    @ViewBuilder private var actions: some View {
        VStack(spacing: 10) {
            Button {
                Task { await favorites.toggle(concert) }
            } label: {
                Label(isFavorite ? "Dans tes favoris — rappel activé" : "Suivre ce concert (rappel)",
                      systemImage: isFavorite ? "heart.fill" : "heart")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)

            if let ticket = concert.ticketURL {
                Button {
                    openURL(ticket)
                } label: {
                    Label("Billetterie", systemImage: "ticket.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.romandieRed)
            }

            Button {
                Task { await addToCalendar() }
            } label: {
                Label(calendarOK ? "Ajouté au calendrier" : "Ajouter au calendrier",
                      systemImage: calendarOK ? "checkmark.circle.fill" : "calendar.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(addingToCalendar || calendarOK)

            Button {
                openURL(concert.url)
            } label: {
                Label("Page de l'événement", systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(.top, 4)
    }

    // MARK: - Carte

    @ViewBuilder private var mapSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accès")
                .font(.headline)

            Map(initialPosition: .region(MKCoordinateRegion(
                center: venue, latitudinalMeters: 500, longitudinalMeters: 500))) {
                Marker("Le Romandie", coordinate: venue)
                    .tint(Color.romandieRed)
            }
            .frame(height: 170)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)

            Button {
                showMapChoice = true
            } label: {
                Label("Itinéraire", systemImage: "location.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .confirmationDialog("Ouvrir l'itinéraire dans…",
                                isPresented: $showMapChoice, titleVisibility: .visible) {
                Button("Plans (Apple)") { openAppleMaps() }
                Button("Google Maps") { openGoogleMaps() }
                Button("Annuler", role: .cancel) {}
            }

            Text(venueAddress)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openAppleMaps() {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: venue))
        item.name = "Le Romandie"
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    private func openGoogleMaps() {
        // Lien universel : ouvre l'app Google Maps si installée, sinon le navigateur.
        if let url = URL(string: "https://www.google.com/maps/dir/?api=1&destination=\(venue.latitude),\(venue.longitude)") {
            openURL(url)
        }
    }

    private func addToCalendar() async {
        addingToCalendar = true
        calendarMessage = nil
        do {
            try await CalendarService.addEvent(for: concert)
            calendarOK = true
            calendarMessage = "Événement ajouté à ton calendrier (rappel 2 h avant)."
        } catch {
            calendarMessage = error.localizedDescription
        }
        addingToCalendar = false
    }
}
