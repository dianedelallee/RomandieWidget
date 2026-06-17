import AppIntents
import WidgetKit

/// Fait défiler la liste des concerts dans le widget (boutons ◀ ▶).
/// S'exécute dans le process de l'extension widget, donc partage le cache
/// (UserDefaults) avec le timeline provider — pas besoin d'App Group.
struct ShiftConcertsIntent: AppIntent {
    static var title: LocalizedStringResource = "Naviguer dans les concerts"

    @Parameter(title: "Direction") var direction: Int
    @Parameter(title: "Taille de page") var pageSize: Int

    init() {}
    init(direction: Int, pageSize: Int) {
        self.direction = direction
        self.pageSize = pageSize
    }

    func perform() async throws -> some IntentResult {
        let ps = max(1, pageSize)
        ConcertCache.pageOffset += direction * ps
        ConcertCache.clampPage(pageSize: ps)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
