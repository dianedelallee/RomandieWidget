import Foundation

/// Un concert / événement au Romandie.
struct Concert: Identifiable, Hashable {
    let id: String          // URL de l'événement (unique)
    let title: String       // Nom de l'événement
    let dateText: String    // Date brute affichée, ex. "21 juin 2026"
    let timeText: String    // Heure brute affichée, ex. "17H30"
    let url: URL            // Lien vers la page de l'événement
    let imageURL: URL?      // Visuel de l'événement
    let date: Date?         // Date analysée (pour filtrer/trier)
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

            // Premier lien <a href="...event..."> de l'article
            let href = firstMatch(in: articleHTML,
                                  pattern: "<a[^>]*href=\"([^\"]*event[^\"]*)\"",
                                  group: 1) ?? firstMatch(in: articleHTML,
                                                          pattern: "<a[^>]*href=\"([^\"]+)\"",
                                                          group: 1)
            guard let href, let url = URL(string: clean(href)) else { continue }

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
