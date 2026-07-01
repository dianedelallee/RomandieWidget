import Foundation
import UserNotifications

/// Rappels locaux pour les concerts mis en favori.
enum NotificationService {

    /// Demande l'autorisation d'envoyer des notifications (une seule fois).
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        default:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
    }

    /// Programme un rappel : la veille à 18h, sinon 2 h avant le concert.
    static func schedule(for concert: Concert) {
        guard let start = concert.startDate else { return }
        let cal = Calendar.current

        var fire: Date?
        if let dayBefore = cal.date(byAdding: .day, value: -1, to: start) {
            fire = cal.date(bySettingHour: 18, minute: 0, second: 0, of: dayBefore)
        }
        if fire == nil || (fire ?? .distantPast) < Date() {
            fire = cal.date(byAdding: .hour, value: -2, to: start)
        }
        guard let fireDate = fire, fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Bientôt au Romandie 🎸"
        content.body = "\(concert.title) — \(concert.dateText) · \(concert.timeText)"
        content.sound = .default

        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: concert.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Annule le rappel d'un concert.
    static func cancel(for concert: Concert) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [concert.id])
    }
}
