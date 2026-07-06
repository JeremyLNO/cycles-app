# AGENTS.md — Cycles (app iOS de suivi des règles & de l'ovulation)

Règles de collaboration Claude Code ⇄ Xcode local. À lire avant toute modification.

## Le projet
- App iOS **SwiftUI + SwiftData (+ CloudKit) + WidgetKit**, UI multilingue (en/fr/es/de/pt).
- Dossier local : `~/cycles-app/` — c'est **le** projet ouvert dans Xcode (pas de copie).
- Affiche en priorité **le nombre de jours avant le prochain événement** (règles ou ovulation, le plus proche). Dominante **rose pastel**.

## Architecture
- **Targets** : `Cycles` (app, bundle `company.lno.cycles`) + `CyclesWidget`
  (extension, `company.lno.cycles.CyclesWidget`). App Group `group.company.lno.cycles`.
- **`Shared/`** compilé dans **les deux** targets : `CycleEngine` (prédiction, fonctions pures),
  `Palette`, `Components`, `Localization`, `SharedStore` (snapshot App Group), `WidgetContent`.
- **`Cycles/`** = app : `CyclesApp` (@main, container, racine, onglets), `HomeView`,
  `CalendarView`, `ProfilesView` (+ onboarding + éditeur), `SettingsView`, `LogPeriodSheet`,
  `AppLock`, `NotificationManager`, `Models` (@Model SwiftData).
- **`CyclesWidget/`** = widget : `CyclesWidget.swift`, `Info.plist`, entitlements.
- Déploiement **iOS 17+**, Swift 5 mode.

## Données & sync
- **SwiftData** `Profile` + `PeriodEntry`. Sync **iCloud (CloudKit)** via `ModelConfiguration(cloudKitDatabase: .automatic)`, avec **repli local-only** si CloudKit indisponible (`PersistenceController.make()`).
- Modèle **compatible CloudKit** : attributs avec valeurs par défaut/optionnels, relations optionnelles, **pas de `.unique`**. Le respecter pour toute évolution.
- Le **widget ne lit pas SwiftData** : l'app écrit un `CycleSnapshot` dans l'App Group (`SharedStore`) + `WidgetCenter.reloadAllTimelines()` à chaque changement.

## Compiler & lancer
- Ouvrir `Cycles.xcodeproj`, scheme **Cycles**, **⌘R** (simulateur iOS 26.x présent).
- ⚠️ **CloudKit** nécessite ton **Team** (`DEVELOPMENT_TEAM = 2E6D4Q69QB`) sélectionné + un compte iCloud sur le simulateur/appareil. Sans cela, l'app tourne en **local-only** (compile & fonctionne).
- Vérif. en ligne de commande (sans signature) :
  ```
  xcodebuild -project Cycles.xcodeproj -scheme Cycles -sdk iphonesimulator \
    -destination 'id=<UDID booté>' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build
  xcrun simctl install <UDID> build/Build/Products/Debug-iphonesimulator/Cycles.app
  xcrun simctl launch <UDID> company.lno.cycles -demoSeed -skipNotifPrompt -unlock -demoLang fr
  ```

## Arguments de lancement (Debug, captures)
- `-demoSeed` : crée des profils déterministes (Léa, Sofia) si la base est vide.
- `-demoLang <en|fr|es|de|pt>` : force la langue.
- `-skipNotifPrompt` : pas de demande d'autorisation notifications.
- `-unlock` : ignore le verrouillage Face ID (pour les captures).
- `-startTab <home|calendar|settings>` : onglet initial.
- `-widgetGallery` : aperçu in-app des widgets (small + medium).

## Conventions
- `project.pbxproj` **écrit à la main**, schéma d'UUID lisible (comme fasting-app) :
  `AA…` projet/groupes · `BB…` targets · `CC…` produits · `DD…` config lists · `EE…` build configs ·
  `FF…` phases · `AB…` refs `Shared/` · `AC…` refs app · `AD…` refs widget · `BA…` build files app · `BD…` build files widget.
- **Ajouter un fichier `Shared/`** = 1 `PBXFileReference` + entrée groupe Shared + `PBXBuildFile` **dans les deux** targets qui en ont besoin + entrées dans les `PBXSourcesBuildPhase` concernées. (Tout fichier `Shared/` utilisé par le widget doit être ajouté à la phase Sources du widget — cf. `CycleEngine.swift`.)
- **Localisation** : tout le texte via `L.t("clé", lang)` (table dans `Localization.swift`). Pas d'emoji décoratif dans l'UI (certains runtimes les rendent en « tofu ») → utiliser des **SF Symbols** (`CyclePhase.symbol`).
- **Design** : `Palette` (rose pastel + teinte par phase) + `Components` (`ProgressRing`, `GlassCard`, `PhaseChip`, `ProfileAvatar`, `StatTile`).

## Avertissement
- L'app fournit des **estimations** (méthode calendaire). Ce n'est **pas** un dispositif médical ni une méthode de contraception (mention dans Réglages).
