# Cycles 🌸

App iOS native (SwiftUI) de suivi des **règles** et de l'**ovulation**, pensée pour la simplicité et le côté graphique. Dominante **rose pastel**.

## Fonctionnalités (v1)
- **Écran d'accueil héros** : le nombre de jours avant le **prochain événement le plus proche** (règles ou ovulation), dans un grand anneau de progression du cycle, avec la phase en cours.
- **Prédiction** de la prochaine date de règles, de l'ovulation et de la fenêtre fertile (moyenne des cycles saisis, repli sur la durée configurée).
- **Calendrier graphique** mensuel : règles passées/prévues, fenêtre fertile, ovulation. **Tap sur un jour** pour ajouter / modifier / supprimer une date de début de règles.
- **Saisie rapide** « J'ai mes règles aujourd'hui ».
- **Multi-profils** (suivre plusieurs personnes) avec prénom, couleur d'accent, durées personnalisées.
- **5 langues** (en/fr/es/de/pt), changeables dans l'app.
- **Notifications J-1** avant les règles et avant l'ovulation (par profil).
- **Widgets** écran d'accueil + écran de verrouillage (« X jours avant… »).
- **Verrouillage Face ID / Touch ID / code** + masquage dans le sélecteur d'apps.
- **Sync iCloud** (CloudKit) entre les appareils Apple.

## Lancer
Ouvrir `Cycles.xcodeproj` dans Xcode, scheme **Cycles**, ⌘R.
Pour la sync iCloud réelle : sélectionner ton **Team** + un compte iCloud sur l'appareil (sinon l'app tourne en local).

Voir [`AGENTS.md`](AGENTS.md) pour l'architecture, les conventions et les arguments de debug.

## Avertissement
Cycles fournit des **estimations** basées sur tes saisies. Ce n'est **pas** un dispositif médical ni une méthode de contraception.

## Push notifications (OneSignal)

The `OneSignal-XCFramework` Swift Package (pinned to **5.5.1**, only the
`OneSignalFramework` product) is linked into the app target, the app declares
`aps-environment`, and Push is enabled on the App ID `company.lno.cycles`.

Everything is gated on one constant — `OneSignalPush.appID` in
`Cycles/OneSignalPush.swift`. While it is empty the SDK is never
initialised: no registration, no network call, no permission prompt. Paste the App ID
from onesignal.com ▸ Settings ▸ Keys & IDs to switch push on.

OneSignal carries Crazy Bee Labs announcements and app-update notices only; anything
this app schedules for itself stays a local notification. A tap on a push can only open
an `apps.apple.com` or `crazybeelabs.com` link — the payload is untrusted input.

Still required server-side before any push is delivered: an APNs `.p8` key uploaded to
the OneSignal app (Settings ▸ Platforms ▸ Apple iOS).
