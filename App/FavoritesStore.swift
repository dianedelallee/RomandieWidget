import SwiftUI

/// Gère les concerts favoris (persistés localement) et leurs rappels.
@MainActor
final class FavoritesStore: ObservableObject {
    @Published private(set) var ids: Set<String> = []
    private let key = "favoriteConcertIds"

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func isFavorite(_ concert: Concert) -> Bool {
        ids.contains(concert.id)
    }

    /// Bascule le favori et programme / annule le rappel associé.
    func toggle(_ concert: Concert) async {
        if ids.contains(concert.id) {
            ids.remove(concert.id)
            NotificationService.cancel(for: concert)
        } else {
            ids.insert(concert.id)
            if await NotificationService.requestAuthorization() {
                NotificationService.schedule(for: concert)
            }
        }
        UserDefaults.standard.set(Array(ids), forKey: key)
    }
}
