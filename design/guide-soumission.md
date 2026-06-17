# Guide de soumission App Store — Agenda Le Romandie

De l'archive à la review. À faire **une fois ton compte Apple Developer validé**.

---

## 0. Prérequis
- Compte **Apple Developer** actif (99 $/an).
- Dans Xcode : projet ouvert, **Team payante** sélectionnée dans *Signing & Capabilities*
  sur les **2 targets** (RomandieApp + RomandieWidgetExtension).
- Bundle ids : `ch.diane.romandie` et `ch.diane.romandie.widget`.
- Tes **5 captures** prêtes (format 6,9").

---

## 1. Régler version et numéro de build
Dans Xcode → target **RomandieApp** → onglet **General** :
- **Version** : `1.0`
- **Build** : `1`
> À chaque nouvel envoi du même 1.0, il faudra **incrémenter le build** (2, 3, …).
> C'est déjà géré via `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION` dans `project.yml`.

---

## 2. Créer la fiche dans App Store Connect
Sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com) :
1. **Apps → + → New App**.
2. Plateforme **iOS**, langue principale **Français (France)**.
3. **Nom** : `Agenda Le Romandie` · **Bundle ID** : `ch.diane.romandie`
   (s'il n'apparaît pas, va d'abord le créer dans *Certificates, Identifiers & Profiles → Identifiers*).
4. **SKU** : un code libre, ex. `romandie-widget-001`.
5. Remplis la fiche avec le contenu de `app-store-listing.md`
   (sous-titre, description, mots-clés, catégories, URLs, droits).
6. **Captures d'écran** : glisse tes 5 images dans la section iPhone 6,9".
7. **App Privacy** : clique *Get Started* → réponds **« No / Data Not Collected »** partout.
8. **URL de politique de confidentialité** :
   `https://www.fatalement.com/romandie-confidentialite.html`

---

## 3. Archiver l'app (Xcode)
1. En haut, choisis la destination **Any iOS Device (arm64)**
   (pas un simulateur — sinon « Archive » est grisé).
2. Menu **Product → Archive**.
3. La fenêtre **Organizer** s'ouvre avec ton archive.

---

## 4. Envoyer le build
Dans l'Organizer :
1. Sélectionne l'archive → **Distribute App**.
2. **App Store Connect** → **Upload** → suis les étapes (laisse les options par défaut :
   signature automatique, symboles inclus).
3. Attends la fin de l'upload, puis le **traitement** côté Apple (~15–30 min).
   Tu reçois un mail quand le build est prêt.

---

## 5. Associer le build et soumettre
De retour dans App Store Connect, sur la fiche de l'app :
1. Section **Build** → **+** → choisis le build que tu viens d'envoyer.
2. Vérifie une dernière fois description / captures / URLs.
3. **Add for Review** → **Submit for Review**.

---

## 6. Review
- Délai habituel : **24–48 h**.
- En cas de refus, Apple explique le motif → tu corriges, incrémentes le build, ré-envoies.
- Point de vigilance pour cette app : **propriété intellectuelle** (nom « Le Romandie » +
  affiches). La mention « non-officiel » aide ; garde l'accord du Romandie sous la main.

---

## 7. Publication
Une fois **Approved** :
- Mise en ligne **automatique** ou **manuelle** (à ton choix lors de la soumission).
- 🎉 L'app est sur l'App Store.

---

### Rappels utiles
- L'app déclare déjà **ITSAppUsesNonExemptEncryption = false** → pas de question sur le
  chiffrement à chaque envoi.
- Si tu modifies la structure et relances `xcodegen generate`, **re-sélectionne ta Team**.
