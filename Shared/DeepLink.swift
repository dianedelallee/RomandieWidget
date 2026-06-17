import Foundation

/// Lien interne "romandie://event?id=..." pour ouvrir un concert dans l'app
/// depuis le widget.
enum DeepLink {
    static let scheme = "romandie"

    /// URL d'ouverture d'un concert dans l'app.
    static func url(for concert: Concert) -> URL {
        var c = URLComponents()
        c.scheme = scheme
        c.host = "event"
        c.queryItems = [URLQueryItem(name: "id", value: concert.id)]
        return c.url!
    }

    /// Extrait l'identifiant de concert d'une URL entrante (nil si ce n'est pas un deep link valide).
    static func eventId(from url: URL) -> String? {
        guard url.scheme == scheme, url.host == "event" else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "id" })?.value
    }
}
