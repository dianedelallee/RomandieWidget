import SwiftUI

struct ConcertDetailView: View {
    let concert: Concert

    @Environment(\.openURL) private var openURL
    @State private var calendarMessage: String?
    @State private var calendarOK = false
    @State private var addingToCalendar = false

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

                VStack(spacing: 10) {
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

                if let calendarMessage {
                    Text(calendarMessage)
                        .font(.caption)
                        .foregroundStyle(calendarOK ? .green : .red)
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Concert")
        .navigationBarTitleDisplayMode(.inline)
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
