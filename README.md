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
