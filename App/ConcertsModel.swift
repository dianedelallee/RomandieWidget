import SwiftUI
import WidgetKit

/// Charge et partage la liste des concerts entre les onglets de l'app.
@MainActor
final class ConcertsModel: ObservableObject {
    @Published var concerts: [Concert] = []
    @Published var loading = true
    @Published var error: String?

    func load() async {
        loading = true
        error = nil
        do {
            concerts = try await ConcertLoader.fetch()
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            self.error = "Impossible de charger la programmation du Romandie."
        }
        loading = false
    }
}
