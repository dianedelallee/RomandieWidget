# Widget Romandie 🎸

Un widget iOS (WidgetKit) qui affiche les prochains concerts au **Romandie** (Lausanne),
récupérés en direct depuis [leromandie.ch/programmation](https://www.leromandie.ch/programmation).

> ⚠️ **Application non-officielle.** Les données et les affiches proviennent de
> leromandie.ch ; ce projet n'est pas affilié au Romandie.

**Widget** (avec affiche + prix) :
- **Petit** : le prochain concert avec son affiche.
- **Moyen** : les 3 prochains concerts.
- **Grand** : les 7 prochains concerts.

**App hôte** : liste complète + page détail par concert avec
**billetterie** (Petzi), **ajout au calendrier** (rappel 2 h avant) et lien vers
la page de l'événement. Un tap sur le widget ouvre l'événement / la programmation.

## Prérequis

- **Xcode** (App Store, ~7 Go) — pas seulement les Command Line Tools.
- Pour l'installer sur ton iPhone : un **Apple ID** suffit (signature gratuite, à
  renouveler tous les 7 jours). Un compte développeur payant n'est pas obligatoire.

## Ouvrir le projet

Le projet est déjà généré : ouvre **`RomandieWidget.xcodeproj`** dans Xcode.

> Le projet est produit par [XcodeGen](https://github.com/yonossi/XcodeGen) à partir de
> `project.yml`. Si tu modifies la structure des fichiers, régénère-le avec :
> ```
> xcodegen generate
> ```

## Compiler & installer

1. Ouvre `RomandieWidget.xcodeproj`.
2. Sélectionne le target **RomandieApp**, onglet **Signing & Capabilities**.
3. Dans **Team**, choisis ton Apple ID (ajoute-le via *Add an Account…* si besoin).
   Fais de même pour le target **RomandieWidgetExtension**.
   - Si Xcode râle sur le bundle id, change `ch.leromandie.widget` pour quelque chose
     d'unique (ex. `ch.tonprenom.romandie`) dans les deux targets.
4. Branche ton iPhone, sélectionne-le comme destination, et lance (▶︎).
5. Sur l'iPhone : *Réglages > Confidentialité > Gérer les apps* → fais confiance à ton
   profil de développeur la première fois.
6. Ajoute le widget : appui long sur l'écran d'accueil → **+** → cherche *Romandie* →
   choisis la taille → **Ajouter**.

## Structure

```
Shared/          code partagé app + widget
  Concert.swift          modèle + parseur HTML (regex, zéro dépendance)
  ConcertLoader.swift    téléchargement réseau + données d'exemple
  Theme.swift            couleur Romandie
Widget/          extension WidgetKit
  RomandieWidget.swift   timeline provider + vues (small/medium/large)
  Info.plist
App/             app hôte minimale
  RomandieApp.swift
project.yml      définition XcodeGen
```

## Comment ça marche

Le widget télécharge la page `programmation`, repère chaque bloc `<article>` (date, heure,
titre, lien, image), garde les événements à venir, les trie par date, et rafraîchit
~toutes les 6 heures. Aucune API tierce, aucune clé.

## Si le site change

Si le HTML du Romandie évolue, seuls les motifs (regex) dans `Shared/Concert.swift`
(`RomandieParser.parse`) sont à ajuster. Le parseur a été testé contre la vraie page :
il extrait correctement les 13 concerts à venir avec leurs dates.
