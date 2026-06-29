import Foundation
import EventKit

enum CalendarError: LocalizedError {
    case accessDenied
    case noCalendar

    var errorDescription: String? {
        switch self {
        case .accessDenied: return "Accès au calendrier refusé. Autorise-le dans Réglages."
        case .noCalendar:   return "Aucun calendrier disponible pour enregistrer l'événement."
        }
    }
}

enum CalendarService {

    /// Ajoute un concert au calendrier (accès en écriture seule, iOS 17+).
    static func addEvent(for concert: Concert) async throws {
        let store = EKEventStore()

        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else { throw CalendarError.accessDenied }

        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarError.noCalendar
        }

        let start = concert.startDate ?? concert.date ?? Date()

        let event = EKEvent(eventStore: store)
        event.title = concert.title
        event.startDate = start
        event.endDate = start.addingTimeInterval(3 * 3600) // ~3 h
        event.location = "Le Romandie, Place de l'Europe 1 A, 1003 Lausanne"
        event.url = concert.url
        event.notes = "Concert au Romandie\(concert.priceText.isEmpty ? "" : " · \(concert.priceText)")"
        event.calendar = calendar
        // Rappel 2 h avant.
        event.addAlarm(EKAlarm(relativeOffset: -2 * 3600))

        try store.save(event, span: .thisEvent)
    }
}
