import SwiftUI

/// Stocke localement les billets PDF importés, associés à chaque concert.
/// Tout est sur l'appareil (dossier Documents/tickets), aucune infra.
@MainActor
final class TicketStore: ObservableObject {
    @Published private(set) var ids: Set<String> = []
    private let key = "ticketConcertIds"

    init() {
        ids = Set(UserDefaults.standard.stringArray(forKey: key) ?? [])
    }

    func hasTicket(_ concert: Concert) -> Bool { ids.contains(concert.id) }

    /// URL du PDF stocké pour ce concert (nil si absent).
    func url(for concert: Concert) -> URL? {
        let u = fileURL(for: concert)
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    /// Copie le PDF choisi dans le stockage de l'app.
    func importTicket(from source: URL, for concert: Concert) throws {
        let scoped = source.startAccessingSecurityScopedResource()
        defer { if scoped { source.stopAccessingSecurityScopedResource() } }

        let dest = fileURL(for: concert)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.copyItem(at: source, to: dest)

        ids.insert(concert.id)
        persist()
    }

    func delete(for concert: Concert) {
        try? FileManager.default.removeItem(at: fileURL(for: concert))
        ids.remove(concert.id)
        persist()
    }

    // MARK: - Privé

    private func persist() {
        UserDefaults.standard.set(Array(ids), forKey: key)
    }

    private var directory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("tickets", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func fileURL(for concert: Concert) -> URL {
        let slug = concert.url.lastPathComponent.isEmpty ? "ticket" : concert.url.lastPathComponent
        return directory.appendingPathComponent(slug + ".pdf")
    }
}
