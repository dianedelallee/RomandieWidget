# Réponse au reviewer — 2e refus 4.2.2

## A) App Review Information → « Notes » (à coller dans App Store Connect, section App Review Information)

This app is designed for iPhone. Its core value is a set of native iOS features that are
not available through a website. Please test on an iPhone:

1) HOME SCREEN WIDGET (main feature): long-press the Home Screen → “+” → search
   “Romandie” → add the widget (Small, Medium, or Large). The widget shows upcoming
   concerts with posters, and includes interactive ◀ ▶ buttons (App Intents) to page
   through concerts without opening the app. Tapping a concert deep-links into its detail
   screen. (Widgets are not available on the iPad Home Screen, so this feature can only be
   evaluated on iPhone.)

2) FAVORITES + LOCAL NOTIFICATIONS: swipe a concert to the right (or tap the heart on the
   detail screen) to save it. Saving schedules a local notification reminder before the
   concert (UserNotifications). Filter the list by “Favoris”.

3) CALENDAR INTEGRATION (EventKit): on a concert’s detail, “Ajouter au calendrier” creates
   a system Calendar event with an alarm.

4) MAP + DIRECTIONS (MapKit): the detail screen shows a native map of the venue and an
   “Itinéraire” action that opens Apple Maps or Google Maps with directions.

5) CALENDAR VIEW (bottom tab "Calendrier"): a native interactive month calendar that marks
   the days with concerts, lets you tap a day to see that day's concerts, and browse months.

6) SEARCH & FILTERS, native share sheet, and offline access to previously loaded data.

The app is organized in two tabs (Agenda list / Calendar), not a single web-like list.

Thank you.

---

## B) Resolution Center reply (réponse au message de refus)

Hello, and thank you for the follow-up.

We’d like to respectfully clarify the native functionality, as the review was performed on
an iPad Air (M3) where the app’s core feature — a Home Screen Widget — cannot be evaluated
(iPhone widgets are not available on the iPad Home Screen). The app is built for iPhone.

Beyond displaying concerts, the app provides substantial native functionality that a
website cannot offer:

• Home Screen Widgets (WidgetKit) in three sizes, with interactive pagination buttons
  (App Intents) and deep links into the app — testable only on iPhone.
• Favorites with scheduled local notification reminders (UserNotifications).
• Calendar integration (EventKit) with an alarm.
• A native venue map with directions (MapKit / Apple Maps / Google Maps).
• A native interactive Calendar view (month grid) — one of the app's two tabs.
• Native search, filtering, a share sheet, and offline access to cached data.

We’ve added detailed steps in the App Review Information notes to help evaluate each feature
on an iPhone. We’d be grateful if the app could be reviewed on an iPhone, where the widget —
its primary purpose — is available. We’re also happy to provide a short demo video.

Thank you very much for your time.

---

## C) Ce qu'il faut faire
1. **App Store Connect → ta version → App Review Information → Notes** : colle le bloc A.
   (Idéalement, joins une **vidéo de démo** : capture d'écran vidéo iPhone montrant le
   widget + favoris + notification. Menu simulateur/iPhone : enregistrement d'écran.)
2. **Resolution Center** : réponds au message avec le bloc B.
3. Pas besoin de nouveau build si le binaire 1.0 (5) est toujours associé — sinon ré-associe
   le build 5 et **Submit for Review**.
