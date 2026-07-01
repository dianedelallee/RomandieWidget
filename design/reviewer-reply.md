# Réponse au reviewer (Resolution Center)

À coller dans App Store Connect → Resolution Center, en réponse au refus.
(En anglais — c'est la langue habituelle de l'App Review.)

---

Hello, and thank you for the review.

**Guideline 2.3.6 — Age Rating**
We have updated the Age Rating on the App Information page: "Age Assurance" and all
In-App / Parental Controls are now set to "None". The app does not include any such
controls.

**Guideline 4.2.2 — Minimum Functionality**
Thank you for the feedback. The new build (version 1.0, build N) adds substantial native
functionality that goes well beyond a web browsing experience:

• Home Screen Widgets (WidgetKit) in three sizes, with interactive pagination buttons
  (App Intents) to browse upcoming concerts directly from the Home Screen, and deep links
  that open the corresponding concert inside the app.
• Favorites: users can save concerts locally and receive a local push notification
  reminder before each saved concert (UserNotifications).
• Native search and filtering (All / Favorites / Free).
• Calendar integration (EventKit): add a concert to the system Calendar with a reminder.
• A native MapKit map of the venue with turn-by-turn directions (Apple Maps).
• Native sharing (share sheet) and offline access to previously loaded data.

These features rely on native iOS frameworks (WidgetKit, App Intents, UserNotifications,
EventKit, MapKit) and are not available through a website. We believe the app now offers a
lasting, engaging native experience.

Thank you for your time.

---

## Rappel : ce qu'il faut faire
1. **Age Rating** : App Store Connect → App Information → Age Rating → Edit →
   "Age Assurance" = None (et tout In-App Controls = None). Enregistrer.
2. **Nouveau build** : incrémenter le build (2), Archive → Distribute → Upload.
3. Associer le nouveau build à la version, coller cette réponse, **Submit for Review**.
   (Remplace « build N » par le vrai numéro.)
