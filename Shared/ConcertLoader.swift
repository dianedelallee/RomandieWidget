import Foundation

/// Récupère et analyse la programmation du Romandie depuis le site.
enum ConcertLoader {

    /// Télécharge la page programmation et renvoie les concerts à venir.
    static func fetch() async throws -> [Concert] {
        var request = URLRequest(url: RomandieParser.programmationURL)
        request.timeoutInterval = 15
        // Un User-Agent "navigateur" évite certains blocages.
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) RomandieWidget",
                         forHTTPHeaderField: "User-Agent")

        let (data, _) = try await URLSession.shared.data(for: request)
        let html = String(decoding: data, as: UTF8.self)
        return RomandieParser.parse(html: html)
    }

    /// Télécharge les données d'une image (visuel d'événement).
    static func fetchImageData(_ url: URL) async -> Data? {
        try? await URLSession.shared.data(from: url).0
    }

    /// Données de secours affichées en aperçu (placeholder / preview Xcode).
    static let sample: [Concert] = [
        Concert(id: "1",
                title: "THE LEMON TWIGS (US) + SUPPORT",
                dateText: "07 oct. 2026", timeText: "20H00",
                url: URL(string: "https://www.leromandie.ch/programmation")!,
                ticketURL: nil, priceText: "35 CHF",
                imageURL: nil,
                date: RomandieParser.parseDate("07 oct. 2026")),
        Concert(id: "2",
                title: "KALIKA (FR) + SUPPORT",
                dateText: "14 nov. 2026", timeText: "21H00",
                url: URL(string: "https://www.leromandie.ch/programmation")!,
                ticketURL: nil, priceText: "25 CHF",
                imageURL: nil,
                date: RomandieParser.parseDate("14 nov. 2026")),
        Concert(id: "3",
                title: "COILGUNS + SUPPORT",
                dateText: "12 déc. 2026", timeText: "21H00",
                url: URL(string: "https://www.leromandie.ch/programmation")!,
                ticketURL: nil, priceText: "25 CHF",
                imageURL: nil,
                date: RomandieParser.parseDate("12 déc. 2026"))
    ]
}

extension Concert {
    /// "lun. 21 juin" — libellé court et joli pour l'affichage.
    var shortDateLabel: String {
        guard let date else { return dateText }
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_CH")
        f.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return f.string(from: date).capitalized
    }
}
