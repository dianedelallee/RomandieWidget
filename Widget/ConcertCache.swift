import Foundation
import UIKit

/// Cache local du widget : concerts + affiches + position de pagination.
/// Stocké dans le UserDefaults / dossier caches de l'extension widget
/// (partagé entre l'intent de pagination et le timeline provider, sans App Group).
enum ConcertCache {
    private static let defaults = UserDefaults.standard
    private static let concertsKey = "cachedConcerts"
    private static let dateKey = "cachedConcertsDate"
    private static let offsetKey = "pageOffset"

    /// Index (dans la liste) du premier concert affiché.
    static var pageOffset: Int {
        get { defaults.integer(forKey: offsetKey) }
        set { defaults.set(newValue, forKey: offsetKey) }
    }

    // MARK: - Concerts

    static func saveConcerts(_ concerts: [Concert]) {
        if let data = try? JSONEncoder().encode(concerts) {
            defaults.set(data, forKey: concertsKey)
            defaults.set(Date(), forKey: dateKey)
        }
    }

    static func loadConcerts() -> [Concert] {
        guard let data = defaults.data(forKey: concertsKey),
              let c = try? JSONDecoder().decode([Concert].self, from: data) else { return [] }
        return c
    }

    static var cacheDate: Date? { defaults.object(forKey: dateKey) as? Date }

    // MARK: - Pagination

    /// Dernier offset de page valide pour une taille de page donnée.
    static func lastPageStart(total: Int, pageSize: Int) -> Int {
        let ps = max(1, pageSize)
        return total <= 0 ? 0 : ((total - 1) / ps) * ps
    }

    /// Borne l'offset courant dans les limites.
    static func clampPage(pageSize: Int) {
        let last = lastPageStart(total: loadConcerts().count, pageSize: pageSize)
        pageOffset = min(max(0, pageOffset), last)
    }

    // MARK: - Affiches (fichiers dans le dossier caches)

    private static var imagesDir: URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("posters", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func fileURL(for concert: Concert) -> URL {
        let name = concert.url.lastPathComponent.isEmpty ? "img" : concert.url.lastPathComponent
        return imagesDir.appendingPathComponent(name + ".jpg")
    }

    static func imageData(for concert: Concert) -> Data? {
        try? Data(contentsOf: fileURL(for: concert))
    }

    /// Redimensionne et enregistre l'affiche (petite taille pour garder le cache léger).
    static func saveImage(_ data: Data, for concert: Concert) {
        guard let img = UIImage(data: data) else { return }
        let scaled = img.downscaled(maxDimension: 220)
        if let jpeg = scaled.jpegData(compressionQuality: 0.7) {
            try? jpeg.write(to: fileURL(for: concert))
        }
    }
}

private extension UIImage {
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let m = max(size.width, size.height)
        guard m > maxDimension else { return self }
        let scale = maxDimension / m
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
