import Foundation

/// Un concert / événement au Romandie.
struct Concert: Identifiable, Hashable {
    let id: String          // URL de l'événement (unique)
    let title: String       // Nom de l'événement
    let dateText: String    // Date brute affichée, ex. "21 juin 2026"
    let timeText: String    // Heure brute affichée, ex. "17H30"
    let url: URL            // Lien vers la page de l'événement
    let ticketURL: URL?     // Lien billetterie (Petzi le plus souvent)
    let priceText: String   // Prix affiché, ex. "25 CHF" ou "GRATUIT"
    let imageURL: URL?      // Visuel de l'événement
    let date: Date?         // Date analysée (jour, pour filtrer/trier)

    /// Date + heure analysées (pour l'ajout au calendrier). nil si la date est inconnue.
    var startDate: Date? {
        guard let date else { return nil }
        guard let m = timeText.range(of: "\\d{1,2}", options: .regularExpression) else { return date }
        let hour = Int(timeText[m]) ?? 20
        var minute = 0
        if let mm = timeText.range(of: "(?<=[Hh:])\\d{2}", options: .regularExpression) {
            minute = Int(timeText[mm]) ?? 0
        }
        return Calendar(identifier: .gregorian)
            .date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }
}

enum RomandieParser {

    static let programmationURL = URL(string: "https://www.leromandie.ch/programmation")!

    /// Parse le HTML de la page programmation et renvoie les concerts à venir, triés par date.
    static func parse(html: String, now: Date = Date()) -> [Concert] {
        var concerts: [Concert] = []

        // Chaque événement est un bloc <article ...> ... </article>
        for articleHTML in matches(in: html, pattern: "<article\\b[^>]*>([\\s\\S]*?)</article>", group: 1) {

            // <time ...> <span>21 juin 2026</span> <span>17H30</span> </time>
            let spans = matches(in: articleHTML,
                                pattern: "<span[^>]*>([\\s\\S]*?)</span>",
                                group: 1).map(clean)
            let dateText = spans.first ?? ""
            let timeText = spans.count > 1 ? spans[1] : ""

            // Titre dans le <h3 ...>...</h3>
            guard let rawTitle = firstMatch(in: articleHTML,
                                            pattern: "<h3[^>]*>([\\s\\S]*?)</h3>",
                                            group: 1) else { continue }
            let title = clean(rawTitle)
            if title.isEmpty { continue }

            // Liens de l'article : (image -> event), ("+ d'infos" -> event), (prix -> billetterie)
            let anchors = anchorPairs(in: articleHTML)

            // Lien vers la page de l'événement.
            let eventHref = anchors.first(where: { $0.href.contains("/event/") })?.href
                ?? anchors.first?.href
            guard let eventHref, let url = URL(string: clean(eventHref)) else { continue }

            // Le dernier lien est le bouton « prix » : son texte = le prix, sa cible = la billetterie.
            let priceAnchor = anchors.last(where: { !$0.text.isEmpty && $0.href != eventHref })
                ?? anchors.last(where: { !$0.text.isEmpty })
            let priceText = priceAnchor?.text ?? ""
            let ticketURL = priceAnchor.flatMap { URL(string: clean($0.href)) }

            // Image
            let imgSrc = firstMatch(in: articleHTML,
                                    pattern: "<img[^>]*src=\"([^\"]+)\"",
                                    group: 1)
            let imageURL = imgSrc.flatMap { URL(string: clean($0)) }

            let date = parseDate(dateText)

            concerts.append(Concert(id: url.absoluteString,
                                    title: title,
                                    dateText: dateText,
                                    timeText: timeText,
                                    url: url,
                                    ticketURL: ticketURL,
                                    priceText: priceText,
                                    imageURL: imageURL,
                                    date: date))
        }

        // Garde les événements à venir (ou sans date analysable), et trie.
        let startOfToday = Calendar.current.startOfDay(for: now)
        let upcoming = concerts.filter { c in
            guard let d = c.date else { return true }
            return d >= startOfToday
        }
        return upcoming.sorted { a, b in
            switch (a.date, b.date) {
            case let (x?, y?): return x < y
            case (nil, _):     return false
            case (_, nil):     return true
            }
        }
    }

    // MARK: - Date FR -> Date

    // Noms complets des mois (le site mélange formes pleines "juin" et abrégées "oct.", "déc."…)
    private static let frMonthNames = [
        "janvier", "février", "mars", "avril", "mai", "juin",
        "juillet", "août", "septembre", "octobre", "novembre", "décembre"
    ]

    /// Plie les accents et met en minuscules pour comparer "aout" ≈ "août".
    private static func fold(_ s: String) -> String {
        s.folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr"))
         .lowercased()
    }

    /// "oct" / "octobre" / "déc." -> numéro de mois, en tolérant les abréviations.
    private static func monthNumber(for token: String) -> Int? {
        let t = fold(token)
        guard t.count >= 3 else { return nil }
        for (i, name) in frMonthNames.enumerated() {
            let n = fold(name)
            if n == t || n.hasPrefix(t) || t.hasPrefix(n) { return i + 1 }
        }
        return nil
    }

    /// "21 juin 2026" ou "01 oct. 2026" -> Date
    static func parseDate(_ text: String) -> Date? {
        let parts = text.lowercased()
            .replacingOccurrences(of: "1er", with: "1")
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        guard parts.count >= 3,
              let day = Int(parts[0]),
              let month = monthNumber(for: parts[1]),
              let year = Int(parts[2]) else { return nil }
        var comps = DateComponents()
        comps.day = day; comps.month = month; comps.year = year
        comps.hour = 12
        return Calendar(identifier: .gregorian).date(from: comps)
    }

    // MARK: - Helpers regex / nettoyage HTML

    private static func matches(in text: String, pattern: String, group: Int) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return re.matches(in: text, range: range).compactMap { m in
            guard let r = Range(m.range(at: group), in: text) else { return nil }
            return String(text[r])
        }
    }

    private static func firstMatch(in text: String, pattern: String, group: Int) -> String? {
        matches(in: text, pattern: pattern, group: group).first
    }

    /// Extrait les liens <a href="...">texte</a> sous forme de paires (href, texte nettoyé).
    private static func anchorPairs(in html: String) -> [(href: String, text: String)] {
        guard let re = try? NSRegularExpression(
            pattern: "<a[^>]*href=\"([^\"]+)\"[^>]*>([\\s\\S]*?)</a>",
            options: [.caseInsensitive]) else { return [] }
        let range = NSRange(html.startIndex..., in: html)
        return re.matches(in: html, range: range).compactMap { m in
            guard let hr = Range(m.range(at: 1), in: html),
                  let tr = Range(m.range(at: 2), in: html) else { return nil }
            return (String(html[hr]), clean(String(html[tr])))
        }
    }

    /// Enlève les balises HTML, décode les entités courantes, normalise les espaces.
    private static func clean(_ s: String) -> String {
        var out = s.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        let entities = ["&amp;": "&", "&nbsp;": " ", "&#039;": "'", "&#39;": "'",
                        "&apos;": "'", "&quot;": "\"", "&eacute;": "é", "&egrave;": "è",
                        "&agrave;": "à", "&ecirc;": "ê", "&ocirc;": "ô", "&ndash;": "–"]
        for (k, v) in entities { out = out.replacingOccurrences(of: k, with: v) }
        out = out.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
