import Foundation

/// Supported in-app languages. The picker lets the user switch at runtime.
enum AppLanguage: String, CaseIterable, Identifiable {
    case en, fr, es, de, pt
    var id: String { rawValue }

    var flag: String {
        switch self {
        case .en: return "🇬🇧"
        case .fr: return "🇫🇷"
        case .es: return "🇪🇸"
        case .de: return "🇩🇪"
        case .pt: return "🇵🇹"
        }
    }

    /// Endonym (the language's name in that language).
    var name: String {
        switch self {
        case .en: return "English"
        case .fr: return "Français"
        case .es: return "Español"
        case .de: return "Deutsch"
        case .pt: return "Português"
        }
    }

    /// Locale used for date formatting (month/weekday names) in that language.
    var locale: Locale { Locale(identifier: rawValue) }

    static let storageKey = "app.language"

    /// First device-preferred language that we support, else English.
    static var systemDefault: AppLanguage {
        for id in Locale.preferredLanguages {
            let code = Locale(identifier: id).language.languageCode?.identifier ?? ""
            if let lang = AppLanguage(rawValue: code) { return lang }
        }
        return .en
    }

    /// Current language read from standard defaults (kept in sync with @AppStorage).
    static var current: AppLanguage {
        if let raw = UserDefaults.standard.string(forKey: storageKey),
           let lang = AppLanguage(rawValue: raw) { return lang }
        return systemDefault
    }
}

/// Tiny in-app localization table (key → per-language string).
enum L {
    static func t(_ key: String, _ lang: AppLanguage = .current) -> String {
        table[key]?[lang] ?? table[key]?[.en] ?? key
    }

    /// Convenience for "1 jour" / "3 jours" style counts.
    static func days(_ n: Int, _ lang: AppLanguage = .current) -> String {
        let unit = n == 1 ? t("unit_day", lang) : t("unit_days", lang)
        return "\(n) \(unit)"
    }

    static let table: [String: [AppLanguage: String]] = [
        // MARK: General
        "save":   [.en: "Save", .fr: "Enregistrer", .es: "Guardar", .de: "Speichern", .pt: "Guardar"],
        "cancel": [.en: "Cancel", .fr: "Annuler", .es: "Cancelar", .de: "Abbrechen", .pt: "Cancelar"],
        "delete": [.en: "Delete", .fr: "Supprimer", .es: "Eliminar", .de: "Löschen", .pt: "Eliminar"],
        "done":   [.en: "Done", .fr: "OK", .es: "Listo", .de: "Fertig", .pt: "Concluído"],
        "add":    [.en: "Add", .fr: "Ajouter", .es: "Añadir", .de: "Hinzufügen", .pt: "Adicionar"],
        "edit":   [.en: "Edit", .fr: "Modifier", .es: "Editar", .de: "Bearbeiten", .pt: "Editar"],
        "today":  [.en: "Today", .fr: "Aujourd'hui", .es: "Hoy", .de: "Heute", .pt: "Hoje"],
        "unit_day":  [.en: "day", .fr: "jour", .es: "día", .de: "Tag", .pt: "dia"],
        "unit_days": [.en: "days", .fr: "jours", .es: "días", .de: "Tage", .pt: "dias"],

        // MARK: Tabs
        "tab_home":     [.en: "Home", .fr: "Accueil", .es: "Inicio", .de: "Start", .pt: "Início"],
        "tab_calendar": [.en: "Calendar", .fr: "Calendrier", .es: "Calendario", .de: "Kalender", .pt: "Calendário"],
        "tab_settings": [.en: "Settings", .fr: "Réglages", .es: "Ajustes", .de: "Einstellungen", .pt: "Definições"],

        // MARK: Phases
        "phase_menstruation": [.en: "Period", .fr: "Règles", .es: "Regla", .de: "Periode", .pt: "Período"],
        "phase_follicular":   [.en: "Follicular phase", .fr: "Phase folliculaire", .es: "Fase folicular", .de: "Follikelphase", .pt: "Fase folicular"],
        "phase_fertile":      [.en: "Fertile window", .fr: "Fenêtre fertile", .es: "Ventana fértil", .de: "Fruchtbare Tage", .pt: "Janela fértil"],
        "phase_ovulation":    [.en: "Ovulation", .fr: "Ovulation", .es: "Ovulación", .de: "Eisprung", .pt: "Ovulação"],
        "phase_luteal":       [.en: "Luteal phase", .fr: "Phase lutéale", .es: "Fase lútea", .de: "Lutealphase", .pt: "Fase lútea"],

        // MARK: Home
        "before_period":    [.en: "until your period", .fr: "avant les règles", .es: "para la regla", .de: "bis zur Periode", .pt: "até o período"],
        "before_ovulation": [.en: "until ovulation", .fr: "avant l'ovulation", .es: "para la ovulación", .de: "bis zum Eisprung", .pt: "até a ovulação"],
        "today_period":     [.en: "Your period is expected today", .fr: "Tes règles sont prévues aujourd'hui", .es: "Tu regla se espera hoy", .de: "Deine Periode wird heute erwartet", .pt: "O teu período é esperado hoje"],
        "today_ovulation":  [.en: "Ovulation is expected today", .fr: "Ton ovulation est prévue aujourd'hui", .es: "Tu ovulación se espera hoy", .de: "Dein Eisprung wird heute erwartet", .pt: "A tua ovulação é esperada hoje"],
        "period_ongoing":   [.en: "Period in progress", .fr: "Règles en cours", .es: "Regla en curso", .de: "Periode läuft", .pt: "Período em curso"],

        // Hero ring — explicit, directional wording (started X days ago vs in X days)
        "hero_started_today":  [.en: "Your period started today", .fr: "Tes règles ont commencé aujourd'hui", .es: "Tu regla empezó hoy", .de: "Deine Periode hat heute begonnen", .pt: "O teu período começou hoje"],
        "hero_since_started":  [.en: "since your period started", .fr: "depuis le début de tes règles", .es: "desde que empezó tu regla", .de: "seit Beginn deiner Periode", .pt: "desde o início do teu período"],
        "hero_until_period":   [.en: "until your period starts", .fr: "avant le début de tes règles", .es: "hasta que empiece tu regla", .de: "bis deine Periode beginnt", .pt: "até o teu período começar"],
        "hero_until_ovulation":[.en: "until your ovulation", .fr: "avant ton ovulation", .es: "hasta tu ovulación", .de: "bis zu deinem Eisprung", .pt: "até à tua ovulação"],
        "hero_late_caption":   [.en: "your period hasn't started yet", .fr: "tes règles ne sont pas encore arrivées", .es: "tu regla aún no ha llegado", .de: "deine Periode ist noch nicht da", .pt: "o teu período ainda não chegou"],
        "hero_late_day":       [.en: "day late", .fr: "jour de retard", .es: "día de retraso", .de: "Tag überfällig", .pt: "dia de atraso"],
        "hero_late_days":      [.en: "days late", .fr: "jours de retard", .es: "días de retraso", .de: "Tage überfällig", .pt: "dias de atraso"],
        "cycle_day_fmt":    [.en: "Day %d of your cycle", .fr: "Jour %d du cycle", .es: "Día %d del ciclo", .de: "Tag %d des Zyklus", .pt: "Dia %d do ciclo"],
        "late_fmt":         [.en: "%d days late", .fr: "%d j de retard", .es: "%d días de retraso", .de: "%d Tage überfällig", .pt: "%d dias de atraso"],
        "log_period_today": [.en: "My period started today", .fr: "J'ai mes règles aujourd'hui", .es: "Hoy me vino la regla", .de: "Meine Periode hat heute begonnen", .pt: "O meu período começou hoje"],
        "next_period":      [.en: "Next period", .fr: "Prochaines règles", .es: "Próxima regla", .de: "Nächste Periode", .pt: "Próximo período"],
        "fertile_window":   [.en: "Fertile window", .fr: "Fenêtre fertile", .es: "Ventana fértil", .de: "Fruchtbare Tage", .pt: "Janela fértil"],
        "avg_cycle_fmt":    [.en: "Average cycle: %d days", .fr: "Cycle moyen : %d jours", .es: "Ciclo medio: %d días", .de: "Ø Zyklus: %d Tage", .pt: "Ciclo médio: %d dias"],
        "no_data_title":    [.en: "Let's get started", .fr: "Commençons", .es: "Empecemos", .de: "Los geht's", .pt: "Vamos começar"],
        "no_data_body":     [.en: "Log the first day of your last period to see your predictions.", .fr: "Indique le 1er jour de tes dernières règles pour voir tes prédictions.", .es: "Registra el primer día de tu última regla para ver tus predicciones.", .de: "Trage den 1. Tag deiner letzten Periode ein, um Vorhersagen zu sehen.", .pt: "Regista o 1.º dia do teu último período para ver as previsões."],
        "tips_label":       [.en: "Wellness tip", .fr: "Conseil bien-être", .es: "Consejo de bienestar", .de: "Wohlfühl-Tipp", .pt: "Dica de bem-estar"],

        // MARK: Calendar
        "calendar_title":   [.en: "Calendar", .fr: "Calendrier", .es: "Calendario", .de: "Kalender", .pt: "Calendário"],
        "legend_period":    [.en: "Period", .fr: "Règles", .es: "Regla", .de: "Periode", .pt: "Período"],
        "legend_predicted": [.en: "Predicted period", .fr: "Règles prévues", .es: "Regla prevista", .de: "Erwartete Periode", .pt: "Período previsto"],
        "legend_fertile":   [.en: "Fertile window", .fr: "Fenêtre fertile", .es: "Ventana fértil", .de: "Fruchtbare Tage", .pt: "Janela fértil"],
        "legend_ovulation": [.en: "Ovulation", .fr: "Ovulation", .es: "Ovulación", .de: "Eisprung", .pt: "Ovulação"],

        // MARK: Log sheet
        "log_title":    [.en: "Period start", .fr: "Début des règles", .es: "Inicio de la regla", .de: "Periodenbeginn", .pt: "Início do período"],
        "log_subtitle": [.en: "Pick the first day of your period", .fr: "Choisis le 1er jour de tes règles", .es: "Elige el primer día de tu regla", .de: "Wähle den ersten Tag deiner Periode", .pt: "Escolhe o 1.º dia do teu período"],
        "log_date":     [.en: "Date", .fr: "Date", .es: "Fecha", .de: "Datum", .pt: "Data"],
        "log_delete":   [.en: "Delete this entry", .fr: "Supprimer cette entrée", .es: "Eliminar esta entrada", .de: "Diesen Eintrag löschen", .pt: "Eliminar esta entrada"],

        // MARK: Profiles
        "profiles_title":  [.en: "People", .fr: "Personnes", .es: "Personas", .de: "Personen", .pt: "Pessoas"],
        "profile_add":     [.en: "Add a person", .fr: "Ajouter une personne", .es: "Añadir una persona", .de: "Person hinzufügen", .pt: "Adicionar pessoa"],
        "profile_name":    [.en: "First name", .fr: "Prénom", .es: "Nombre", .de: "Vorname", .pt: "Nome"],
        "profile_color":   [.en: "Colour", .fr: "Couleur", .es: "Color", .de: "Farbe", .pt: "Cor"],
        "profile_cycle_len":  [.en: "Cycle length", .fr: "Durée du cycle", .es: "Duración del ciclo", .de: "Zykluslänge", .pt: "Duração do ciclo"],
        "profile_period_len": [.en: "Period length", .fr: "Durée des règles", .es: "Duración de la regla", .de: "Periodenlänge", .pt: "Duração do período"],
        "profile_delete":  [.en: "Delete profile", .fr: "Supprimer le profil", .es: "Eliminar perfil", .de: "Profil löschen", .pt: "Eliminar perfil"],
        "profile_delete_q":[.en: "Delete this profile and all its data?", .fr: "Supprimer ce profil et toutes ses données ?", .es: "¿Eliminar este perfil y todos sus datos?", .de: "Dieses Profil und alle Daten löschen?", .pt: "Eliminar este perfil e todos os dados?"],
        "profile_edit":    [.en: "Edit profile", .fr: "Modifier le profil", .es: "Editar perfil", .de: "Profil bearbeiten", .pt: "Editar perfil"],
        "profile_new":     [.en: "New person", .fr: "Nouvelle personne", .es: "Nueva persona", .de: "Neue Person", .pt: "Nova pessoa"],
        "switch_profile":  [.en: "Switch person", .fr: "Changer de personne", .es: "Cambiar de persona", .de: "Person wechseln", .pt: "Mudar de pessoa"],
        "profile_about_you": [.en: "About you", .fr: "À propos de toi", .es: "Sobre ti", .de: "Über dich", .pt: "Sobre ti"],
        "profile_birthdate": [.en: "Date of birth", .fr: "Date de naissance", .es: "Fecha de nacimiento", .de: "Geburtsdatum", .pt: "Data de nascimento"],
        "profile_age":     [.en: "Age", .fr: "Âge", .es: "Edad", .de: "Alter", .pt: "Idade"],
        "profile_children":[.en: "Number of children", .fr: "Nombre d'enfants", .es: "Número de hijos", .de: "Anzahl der Kinder", .pt: "Número de filhos"],
        "years_old_fmt":   [.en: "%d years", .fr: "%d ans", .es: "%d años", .de: "%d Jahre", .pt: "%d anos"],

        // MARK: Onboarding
        "onb_language_title": [.en: "Choose your language", .fr: "Choisis ta langue", .es: "Elige tu idioma", .de: "Wähle deine Sprache", .pt: "Escolhe o teu idioma"],
        "onb_welcome_title": [.en: "Welcome to Period tracker made easy", .fr: "Bienvenue dans Period tracker made easy", .es: "Bienvenida a Period tracker made easy", .de: "Willkommen bei Period tracker made easy", .pt: "Bem-vinda ao Period tracker made easy"],
        "onb_welcome_body":  [.en: "Track your period and ovulation, simply.", .fr: "Suis tes règles et ton ovulation, en toute simplicité.", .es: "Sigue tu regla y tu ovulación, fácilmente.", .de: "Verfolge Periode und Eisprung – ganz einfach.", .pt: "Acompanha o teu período e ovulação, de forma simples."],
        "onb_name_title":    [.en: "What's your name?", .fr: "Comment t'appelles-tu ?", .es: "¿Cómo te llamas?", .de: "Wie heißt du?", .pt: "Como te chamas?"],
        "onb_name_body":     [.en: "We'll personalise the app with your name.", .fr: "On personnalise l'app avec ton prénom.", .es: "Personalizamos la app con tu nombre.", .de: "Wir personalisieren die App mit deinem Namen.", .pt: "Personalizamos a app com o teu nome."],
        "onb_last_title":    [.en: "Your last period", .fr: "Tes dernières règles", .es: "Tu última regla", .de: "Deine letzte Periode", .pt: "O teu último período"],
        "onb_last_body":     [.en: "When did your last period start?", .fr: "Quel a été le 1er jour de tes dernières règles ?", .es: "¿Cuándo empezó tu última regla?", .de: "Wann hat deine letzte Periode begonnen?", .pt: "Quando começou o teu último período?"],
        "onb_cycle_title":   [.en: "Your cycle length", .fr: "Durée de ton cycle", .es: "Duración de tu ciclo", .de: "Deine Zykluslänge", .pt: "Duração do teu ciclo"],
        "onb_cycle_body":    [.en: "The average is 28 days. You can change it later.", .fr: "La moyenne est de 28 jours. Tu pourras l'ajuster plus tard.", .es: "La media es 28 días. Podrás cambiarlo después.", .de: "Der Durchschnitt liegt bei 28 Tagen. Später änderbar.", .pt: "A média é de 28 dias. Podes ajustar mais tarde."],
        "onb_start":         [.en: "Get started", .fr: "C'est parti", .es: "Empezar", .de: "Loslegen", .pt: "Começar"],

        // MARK: Settings
        "settings_general":   [.en: "General", .fr: "Général", .es: "General", .de: "Allgemein", .pt: "Geral"],
        "settings_language":  [.en: "Language", .fr: "Langue", .es: "Idioma", .de: "Sprache", .pt: "Idioma"],
        "settings_people":    [.en: "People", .fr: "Personnes", .es: "Personas", .de: "Personen", .pt: "Pessoas"],
        "settings_notifications": [.en: "Notifications", .fr: "Notifications", .es: "Notificaciones", .de: "Mitteilungen", .pt: "Notificações"],
        "notif_period":       [.en: "Period reminder (1 day before)", .fr: "Rappel des règles (J-1)", .es: "Aviso de regla (1 día antes)", .de: "Perioden-Erinnerung (1 Tag vorher)", .pt: "Lembrete de período (1 dia antes)"],
        "notif_ovulation":    [.en: "Ovulation reminder (1 day before)", .fr: "Rappel d'ovulation (J-1)", .es: "Aviso de ovulación (1 día antes)", .de: "Eisprung-Erinnerung (1 Tag vorher)", .pt: "Lembrete de ovulação (1 dia antes)"],
        "notif_time":         [.en: "Reminder time", .fr: "Heure des rappels", .es: "Hora del aviso", .de: "Uhrzeit der Erinnerung", .pt: "Hora do lembrete"],
        "settings_privacy":   [.en: "Privacy", .fr: "Confidentialité", .es: "Privacidad", .de: "Datenschutz", .pt: "Privacidade"],
        "settings_lock":      [.en: "Lock with Face ID / passcode", .fr: "Verrouiller avec Face ID / code", .es: "Bloquear con Face ID / código", .de: "Mit Face ID / Code sperren", .pt: "Bloquear com Face ID / código"],
        "settings_sync":      [.en: "Sync", .fr: "Synchronisation", .es: "Sincronización", .de: "Synchronisierung", .pt: "Sincronização"],
        "settings_sync_icloud": [.en: "iCloud sync", .fr: "Sync iCloud", .es: "Sincronización con iCloud", .de: "iCloud-Sync", .pt: "Sincronização iCloud"],
        "sync_status_on":     [.en: "Your data syncs across your Apple devices via iCloud.", .fr: "Tes données se synchronisent entre tes appareils Apple via iCloud.", .es: "Tus datos se sincronizan entre tus dispositivos Apple con iCloud.", .de: "Deine Daten werden über iCloud zwischen deinen Apple-Geräten synchronisiert.", .pt: "Os teus dados sincronizam entre os teus dispositivos Apple via iCloud."],
        "settings_cycle":     [.en: "Default cycle", .fr: "Cycle par défaut", .es: "Ciclo por defecto", .de: "Standard-Zyklus", .pt: "Ciclo predefinido"],
        "settings_about":     [.en: "About", .fr: "À propos", .es: "Acerca de", .de: "Über", .pt: "Acerca de"],
        "settings_support":   [.en: "Support & ideas", .fr: "Support et idées", .es: "Soporte e ideas", .de: "Support & Ideen", .pt: "Suporte e ideias"],
        "made_by":            [.en: "An app by", .fr: "Une app de", .es: "Una app de", .de: "Eine App von", .pt: "Uma app de"],
        "settings_version":   [.en: "Version", .fr: "Version", .es: "Versión", .de: "Version", .pt: "Versão"],
        "disclaimer_body":    [.en: "Period tracker made easy provides estimates based on what you log. It is not a medical device and not a method of contraception.", .fr: "Period tracker made easy fournit des estimations basées sur tes saisies. Ce n'est pas un dispositif médical ni une méthode de contraception.", .es: "Period tracker made easy ofrece estimaciones según lo que registras. No es un dispositivo médico ni un método anticonceptivo.", .de: "Period tracker made easy liefert Schätzungen auf Basis deiner Einträge. Es ist kein Medizinprodukt und keine Verhütungsmethode.", .pt: "O Period tracker made easy fornece estimativas com base no que registas. Não é um dispositivo médico nem um método contracetivo."],

        // MARK: Notification content
        "notif_period_title":      [.en: "Your period is coming 🌸", .fr: "Tes règles approchent 🌸", .es: "Se acerca tu regla 🌸", .de: "Deine Periode kommt 🌸", .pt: "O teu período aproxima-se 🌸"],
        "notif_period_body":       [.en: "Your period is expected tomorrow.", .fr: "Tes règles sont prévues demain.", .es: "Tu regla se espera mañana.", .de: "Deine Periode wird morgen erwartet.", .pt: "O teu período é esperado amanhã."],
        "notif_period_body_named": [.en: "%@: your period is expected tomorrow.", .fr: "%@ : tes règles sont prévues demain.", .es: "%@: tu regla se espera mañana.", .de: "%@: deine Periode wird morgen erwartet.", .pt: "%@: o teu período é esperado amanhã."],
        "notif_ovulation_title":   [.en: "Ovulation tomorrow ✨", .fr: "Ovulation demain ✨", .es: "Ovulación mañana ✨", .de: "Eisprung morgen ✨", .pt: "Ovulação amanhã ✨"],
        "notif_ovulation_body":    [.en: "Your fertile window peaks — ovulation is expected tomorrow.", .fr: "Ta fenêtre fertile est à son maximum — ovulation prévue demain.", .es: "Tu ventana fértil está en su punto máximo: ovulación mañana.", .de: "Deine fruchtbaren Tage erreichen ihren Höhepunkt – Eisprung morgen.", .pt: "A tua janela fértil está no auge — ovulação amanhã."],
        "notif_ovulation_body_named": [.en: "%@: ovulation is expected tomorrow.", .fr: "%@ : ovulation prévue demain.", .es: "%@: ovulación mañana.", .de: "%@: Eisprung morgen.", .pt: "%@: ovulação amanhã."],

        // MARK: Lock
        "lock_reason": [.en: "Unlock Period tracker made easy to view your data", .fr: "Déverrouille Period tracker made easy pour voir tes données", .es: "Desbloquea Period tracker made easy para ver tus datos", .de: "Entsperre Period tracker made easy, um deine Daten zu sehen", .pt: "Desbloqueia o Period tracker made easy para ver os teus dados"],
        "lock_title":  [.en: "Period tracker made easy is locked", .fr: "Period tracker made easy est verrouillé", .es: "Period tracker made easy está bloqueado", .de: "Period tracker made easy ist gesperrt", .pt: "O Period tracker made easy está bloqueado"],
        "lock_unlock": [.en: "Unlock", .fr: "Déverrouiller", .es: "Desbloquear", .de: "Entsperren", .pt: "Desbloquear"],

        // MARK: Widget
        "widget_desc":    [.en: "Days until your period or ovulation.", .fr: "Le nombre de jours avant tes règles ou ton ovulation.", .es: "Días hasta tu regla u ovulación.", .de: "Tage bis zu Periode oder Eisprung.", .pt: "Dias até o teu período ou ovulação."],
        "widget_no_data": [.en: "Open Period tracker made easy", .fr: "Ouvre Period tracker made easy", .es: "Abre Period tracker made easy", .de: "Period tracker made easy öffnen", .pt: "Abrir o Period tracker made easy"],

        // MARK: Journal & Insights
        "tab_insights":     [.en: "Insights", .fr: "Analyses", .es: "Análisis", .de: "Analysen", .pt: "Análises"],

        // Flow
        "flow_none":   [.en: "None", .fr: "Aucun", .es: "Ninguno", .de: "Keine", .pt: "Nenhum"],
        "flow_light":  [.en: "Light", .fr: "Léger", .es: "Ligero", .de: "Leicht", .pt: "Leve"],
        "flow_medium": [.en: "Medium", .fr: "Moyen", .es: "Medio", .de: "Mittel", .pt: "Médio"],
        "flow_heavy":  [.en: "Heavy", .fr: "Abondant", .es: "Abundante", .de: "Stark", .pt: "Intenso"],

        // Mood
        "mood_awful": [.en: "Awful", .fr: "Horrible", .es: "Fatal", .de: "Mies", .pt: "Péssimo"],
        "mood_bad":   [.en: "Bad", .fr: "Mauvaise", .es: "Mal", .de: "Schlecht", .pt: "Mau"],
        "mood_okay":  [.en: "Okay", .fr: "Correcte", .es: "Normal", .de: "Okay", .pt: "Okay"],
        "mood_good":  [.en: "Good", .fr: "Bonne", .es: "Bien", .de: "Gut", .pt: "Bom"],
        "mood_great": [.en: "Great", .fr: "Super", .es: "Genial", .de: "Super", .pt: "Ótimo"],

        // Symptoms
        "symptom_cramps":        [.en: "Cramps", .fr: "Crampes", .es: "Cólicos", .de: "Krämpfe", .pt: "Cólicas"],
        "symptom_headache":      [.en: "Headache", .fr: "Maux de tête", .es: "Dolor de cabeza", .de: "Kopfschmerzen", .pt: "Dor de cabeça"],
        "symptom_bloating":      [.en: "Bloating", .fr: "Ballonnements", .es: "Hinchazón", .de: "Blähungen", .pt: "Inchaço"],
        "symptom_tenderbreasts": [.en: "Tender breasts", .fr: "Seins sensibles", .es: "Senos sensibles", .de: "Spannende Brüste", .pt: "Seios sensíveis"],
        "symptom_acne":          [.en: "Acne", .fr: "Acné", .es: "Acné", .de: "Akne", .pt: "Acne"],
        "symptom_fatigue":       [.en: "Fatigue", .fr: "Fatigue", .es: "Fatiga", .de: "Müdigkeit", .pt: "Fadiga"],
        "symptom_backache":      [.en: "Backache", .fr: "Mal de dos", .es: "Dolor de espalda", .de: "Rückenschmerzen", .pt: "Dor nas costas"],
        "symptom_nausea":        [.en: "Nausea", .fr: "Nausée", .es: "Náuseas", .de: "Übelkeit", .pt: "Náusea"],
        "symptom_cravings":      [.en: "Cravings", .fr: "Fringales", .es: "Antojos", .de: "Heißhunger", .pt: "Desejos"],
        "symptom_insomnia":      [.en: "Insomnia", .fr: "Insomnie", .es: "Insomnio", .de: "Schlaflosigkeit", .pt: "Insónia"],
        "symptom_moodswings":    [.en: "Mood swings", .fr: "Sautes d'humeur", .es: "Cambios de humor", .de: "Stimmungsschwankungen", .pt: "Alterações de humor"],
        "symptom_discharge":     [.en: "Discharge", .fr: "Pertes", .es: "Flujo", .de: "Ausfluss", .pt: "Corrimento"],

        // Journal UI
        "journal_title":       [.en: "Journal", .fr: "Journal", .es: "Diario", .de: "Tagebuch", .pt: "Diário"],
        "journal_flow":        [.en: "Flow", .fr: "Flux", .es: "Flujo", .de: "Blutung", .pt: "Fluxo"],
        "journal_mood":        [.en: "Mood", .fr: "Humeur", .es: "Ánimo", .de: "Stimmung", .pt: "Humor"],
        "journal_symptoms":    [.en: "Symptoms", .fr: "Symptômes", .es: "Síntomas", .de: "Symptome", .pt: "Sintomas"],
        "journal_note":        [.en: "Note", .fr: "Note", .es: "Nota", .de: "Notiz", .pt: "Nota"],
        "journal_note_ph":     [.en: "Add a note…", .fr: "Ajouter une note…", .es: "Añadir una nota…", .de: "Notiz hinzufügen…", .pt: "Adicionar uma nota…"],
        "journal_today":       [.en: "Today's journal", .fr: "Journal du jour", .es: "Diario de hoy", .de: "Heutiges Tagebuch", .pt: "Diário de hoje"],
        "journal_empty_today": [.en: "Nothing logged yet", .fr: "Rien noté aujourd'hui", .es: "Nada registrado aún", .de: "Noch nichts erfasst", .pt: "Nada registado ainda"],
        "journal_add":         [.en: "Log how I feel", .fr: "Noter comment je me sens", .es: "Registrar cómo me siento", .de: "Wie ich mich fühle", .pt: "Registar como me sinto"],

        // Insights
        "insights_title":     [.en: "Insights", .fr: "Analyses", .es: "Análisis", .de: "Analysen", .pt: "Análises"],
        "insights_summary":   [.en: "Summary", .fr: "Résumé", .es: "Resumen", .de: "Übersicht", .pt: "Resumo"],
        "insights_need_data": [.en: "Log a few cycles to see trends.", .fr: "Enregistre quelques cycles pour voir des tendances.", .es: "Registra algunos ciclos para ver tendencias.", .de: "Erfasse ein paar Zyklen für Trends.", .pt: "Regista alguns ciclos para ver tendências."],
        "stats_avg_cycle":    [.en: "Avg cycle", .fr: "Cycle moyen", .es: "Ciclo medio", .de: "Ø Zyklus", .pt: "Ciclo médio"],
        "stats_range":        [.en: "Range", .fr: "Amplitude", .es: "Rango", .de: "Spanne", .pt: "Amplitude"],
        "stats_avg_period":   [.en: "Avg period", .fr: "Règles moy.", .es: "Regla media", .de: "Ø Periode", .pt: "Período médio"],
        "stats_reg_high":     [.en: "Very regular cycle", .fr: "Cycle très régulier", .es: "Ciclo muy regular", .de: "Sehr regelmäßiger Zyklus", .pt: "Ciclo muito regular"],
        "stats_reg_med":      [.en: "Fairly regular cycle", .fr: "Cycle plutôt régulier", .es: "Ciclo bastante regular", .de: "Ziemlich regelmäßiger Zyklus", .pt: "Ciclo bastante regular"],
        "stats_reg_low":      [.en: "Irregular cycle", .fr: "Cycle irrégulier", .es: "Ciclo irregular", .de: "Unregelmäßiger Zyklus", .pt: "Ciclo irregular"],
        "stats_reg_unknown":  [.en: "Not enough data", .fr: "Pas assez de données", .es: "Datos insuficientes", .de: "Zu wenig Daten", .pt: "Dados insuficientes"],
        "chart_cycle_length": [.en: "Cycle length", .fr: "Longueur des cycles", .es: "Duración del ciclo", .de: "Zykluslänge", .pt: "Duração do ciclo"],
        "chart_mood":         [.en: "Mood trend", .fr: "Tendance de l'humeur", .es: "Tendencia del ánimo", .de: "Stimmungsverlauf", .pt: "Tendência do humor"],
        "chart_symptoms":     [.en: "Frequent symptoms", .fr: "Symptômes fréquents", .es: "Síntomas frecuentes", .de: "Häufige Symptome", .pt: "Sintomas frequentes"],
        "chart_average":      [.en: "Avg", .fr: "Moy.", .es: "Med.", .de: "Ø", .pt: "Méd."],

        // MARK: Account
        "account_section":       [.en: "Account", .fr: "Compte", .es: "Cuenta", .de: "Konto", .pt: "Conta"],
        "account_title":         [.en: "My account", .fr: "Mon compte", .es: "Mi cuenta", .de: "Mein Konto", .pt: "A minha conta"],
        "account_signin":        [.en: "Sign in", .fr: "Se connecter", .es: "Iniciar sesión", .de: "Anmelden", .pt: "Iniciar sessão"],
        "account_signin_intro":  [.en: "An account is optional — your data stays on your device and syncs via iCloud.", .fr: "Le compte est optionnel : tes données restent sur ton appareil et se synchronisent via iCloud.", .es: "La cuenta es opcional: tus datos permanecen en tu dispositivo y se sincronizan con iCloud.", .de: "Ein Konto ist optional – deine Daten bleiben auf dem Gerät und werden über iCloud synchronisiert.", .pt: "A conta é opcional — os teus dados ficam no dispositivo e sincronizam via iCloud."],
        "account_more_soon":     [.en: "Google and email coming soon", .fr: "Google et e-mail bientôt", .es: "Google y correo pronto", .de: "Google und E-Mail folgen bald", .pt: "Google e e-mail em breve"],
        "account_apple_user":    [.en: "Apple user", .fr: "Utilisateur Apple", .es: "Usuario de Apple", .de: "Apple-Nutzer", .pt: "Utilizador Apple"],
        "account_via_apple":     [.en: "Signed in with Apple", .fr: "Connecté avec Apple", .es: "Conectado con Apple", .de: "Mit Apple angemeldet", .pt: "Ligado com a Apple"],
        "account_signout":       [.en: "Sign out", .fr: "Se déconnecter", .es: "Cerrar sesión", .de: "Abmelden", .pt: "Terminar sessão"],
        "account_delete":        [.en: "Delete account & data", .fr: "Supprimer mon compte et mes données", .es: "Eliminar cuenta y datos", .de: "Konto & Daten löschen", .pt: "Eliminar conta e dados"],
        "account_delete_q":      [.en: "Delete permanently?", .fr: "Supprimer définitivement ?", .es: "¿Eliminar definitivamente?", .de: "Endgültig löschen?", .pt: "Eliminar definitivamente?"],
        "account_delete_msg":    [.en: "All your data will be erased from this device and iCloud. This cannot be undone.", .fr: "Toutes tes données seront effacées de cet appareil et d'iCloud. Action irréversible.", .es: "Todos tus datos se borrarán de este dispositivo y de iCloud. No se puede deshacer.", .de: "Alle deine Daten werden von diesem Gerät und aus iCloud gelöscht. Nicht rückgängig machbar.", .pt: "Todos os teus dados serão apagados deste dispositivo e do iCloud. Ação irreversível."],
        "account_delete_footer": [.en: "Deletion permanently erases all your data (device + iCloud). Nothing is kept on a server.", .fr: "La suppression efface définitivement toutes tes données (appareil + iCloud). Rien n'est conservé sur un serveur.", .es: "La eliminación borra permanentemente todos tus datos (dispositivo + iCloud). No se guarda nada en un servidor.", .de: "Das Löschen entfernt dauerhaft alle Daten (Gerät + iCloud). Nichts wird auf einem Server gespeichert.", .pt: "A eliminação apaga definitivamente todos os teus dados (dispositivo + iCloud). Nada fica num servidor."],


        // MARK: Legal & sync
        "privacy_policy": [.en: "Privacy Policy", .fr: "Politique de confidentialité", .es: "Política de privacidad", .de: "Datenschutzerklärung", .pt: "Política de privacidade"],
        "terms_of_use":   [.en: "Terms of Use", .fr: "Conditions d'utilisation", .es: "Términos de uso", .de: "Nutzungsbedingungen", .pt: "Termos de utilização"],
        "sync_status_off": [.en: "Sign in to iCloud in device Settings to sync your data.", .fr: "Connecte-toi à iCloud dans les Réglages de l'appareil pour synchroniser tes données.", .es: "Inicia sesión en iCloud en los Ajustes del dispositivo para sincronizar tus datos.", .de: "Melde dich in den Geräte-Einstellungen bei iCloud an, um deine Daten zu synchronisieren.", .pt: "Inicia sessão no iCloud nas Definições do dispositivo para sincronizar os teus dados."],

        // MARK: Commitment (why Period tracker made easy is free)
        "continue":        [.en: "Continue", .fr: "Continuer", .es: "Continuar", .de: "Weiter", .pt: "Continuar"],
        "free_title":      [.en: "Period tracker made easy is 100% free", .fr: "Period tracker made easy est 100 % gratuite", .es: "Period tracker made easy es 100 % gratuita", .de: "Period tracker made easy ist 100 % kostenlos", .pt: "O Period tracker made easy é 100% gratuito"],
        "free_intro":      [.en: "Crazy Bee Labs is committed to keeping its wellness apps — Period tracker made easy, Pillo and Respire — free, so taking care of yourself stays within everyone's reach.", .fr: "Crazy Bee Labs s'engage à garder ses apps bien-être — Period tracker made easy, Pillo et Respire — gratuites, pour que prendre soin de soi reste accessible à toutes.", .es: "Crazy Bee Labs se compromete a mantener gratuitas sus apps de bienestar —Period tracker made easy, Pillo y Respire— para que cuidarse siga al alcance de todas.", .de: "Crazy Bee Labs verpflichtet sich, seine Wohlfühl-Apps – Period tracker made easy, Pillo und Respire – kostenlos zu halten, damit Selbstfürsorge für alle zugänglich bleibt.", .pt: "A Crazy Bee Labs compromete-se a manter as suas apps de bem-estar — Period tracker made easy, Pillo e Respire — gratuitas, para que cuidar de si continue ao alcance de todas."],
        "free_row_ads":    [.en: "No ads, no subscription — ever.", .fr: "Sans publicité ni abonnement, jamais.", .es: "Sin anuncios ni suscripción, nunca.", .de: "Keine Werbung, kein Abo – niemals.", .pt: "Sem anúncios nem subscrição, nunca."],
        "free_row_privacy":[.en: "Your health data stays private, on your device and iCloud.", .fr: "Tes données de santé restent privées, sur ton appareil et ton iCloud.", .es: "Tus datos de salud permanecen privados, en tu dispositivo e iCloud.", .de: "Deine Gesundheitsdaten bleiben privat, auf deinem Gerät und in iCloud.", .pt: "Os teus dados de saúde ficam privados, no teu dispositivo e no iCloud."],
        "free_row_suite":  [.en: "Brought to you by Crazy Bee Labs, alongside Pillo and Respire.", .fr: "Offerte par Crazy Bee Labs, aux côtés de Pillo et Respire.", .es: "Ofrecida por Crazy Bee Labs, junto a Pillo y Respire.", .de: "Präsentiert von Crazy Bee Labs, zusammen mit Pillo und Respire.", .pt: "Oferecida pela Crazy Bee Labs, ao lado de Pillo e Respire."],
        "free_link":       [.en: "Our commitment", .fr: "Notre engagement", .es: "Nuestro compromiso", .de: "Unser Versprechen", .pt: "O nosso compromisso"],

        // MARK: PMS
        "phase_pms":  [.en: "PMS", .fr: "SPM", .es: "SPM", .de: "PMS", .pt: "TPM"],
        "legend_pms": [.en: "PMS window", .fr: "Fenêtre SPM", .es: "Ventana SPM", .de: "PMS-Fenster", .pt: "Janela TPM"],
        "notif_pms":  [.en: "PMS reminder", .fr: "Rappel SPM", .es: "Aviso de SPM", .de: "PMS-Erinnerung", .pt: "Lembrete de TPM"],
        "notif_pms_title":      [.en: "PMS window ahead", .fr: "Fenêtre SPM", .es: "Ventana SPM", .de: "PMS-Fenster", .pt: "Janela TPM"],
        "notif_pms_body":       [.en: "Your period is close — PMS symptoms may show up over the next few days.", .fr: "Tes règles approchent : des symptômes du SPM peuvent apparaître ces prochains jours.", .es: "Tu regla se acerca: pueden aparecer síntomas del SPM estos días.", .de: "Deine Periode naht – in den nächsten Tagen können PMS-Symptome auftreten.", .pt: "O teu período aproxima-se — podem surgir sintomas de TPM nos próximos dias."],
        "notif_pms_body_named": [.en: "%@: PMS symptoms may show up over the next few days.", .fr: "%@ : des symptômes du SPM peuvent apparaître ces prochains jours.", .es: "%@: pueden aparecer síntomas del SPM estos días.", .de: "%@: in den nächsten Tagen können PMS-Symptome auftreten.", .pt: "%@: podem surgir sintomas de TPM nos próximos dias."],

        // MARK: Modes (tracking / conceiving / pregnancy)
        "profile_mode":        [.en: "Mode", .fr: "Mode", .es: "Modo", .de: "Modus", .pt: "Modo"],
        "mode_tracking":       [.en: "Cycle tracking", .fr: "Suivi du cycle", .es: "Seguimiento del ciclo", .de: "Zyklus verfolgen", .pt: "Seguimento do ciclo"],
        "mode_conceiving":     [.en: "Trying to conceive", .fr: "Essai bébé", .es: "Buscando embarazo", .de: "Kinderwunsch", .pt: "A tentar engravidar"],
        "mode_pregnancy":      [.en: "Pregnancy", .fr: "Grossesse", .es: "Embarazo", .de: "Schwangerschaft", .pt: "Gravidez"],
        "mode_tracking_help":  [.en: "Predictions for your period and ovulation.", .fr: "Prédictions de tes règles et de ton ovulation.", .es: "Predicciones de tu regla y ovulación.", .de: "Vorhersagen für Periode und Eisprung.", .pt: "Previsões do período e da ovulação."],
        "mode_conceiving_help":[.en: "The fertile window is shown first, to help you conceive.", .fr: "La fenêtre fertile est mise en avant pour t'aider à concevoir.", .es: "La ventana fértil se muestra primero, para ayudarte a concebir.", .de: "Die fruchtbaren Tage stehen im Vordergrund.", .pt: "A janela fértil aparece primeiro, para ajudar a conceber."],
        "mode_pregnancy_help": [.en: "Weeks and due date replace cycle predictions, and cycle reminders pause.", .fr: "Les semaines et le terme remplacent les prédictions, et les rappels de cycle sont suspendus.", .es: "Las semanas y la fecha de parto sustituyen las predicciones; los avisos del ciclo se pausan.", .de: "Wochen und Termin ersetzen die Vorhersagen; Zyklus-Erinnerungen pausieren.", .pt: "As semanas e a data prevista substituem as previsões; os lembretes do ciclo ficam em pausa."],

        // Conceiving
        "conceive_fertile_now": [.en: "You're in your fertile window — the best days to conceive", .fr: "Tu es dans ta fenêtre fertile — les meilleurs jours pour concevoir", .es: "Estás en tu ventana fértil: los mejores días para concebir", .de: "Du bist in deinen fruchtbaren Tagen – die besten Tage zum Empfangen", .pt: "Estás na tua janela fértil — os melhores dias para conceber"],
        "hero_until_fertile":   [.en: "until your fertile window", .fr: "avant ta fenêtre fertile", .es: "hasta tu ventana fértil", .de: "bis zu deinen fruchtbaren Tagen", .pt: "até à tua janela fértil"],
        "conceive_late_hint":   [.en: "your period is late — a test may tell you more", .fr: "tes règles sont en retard — un test peut t'en dire plus", .es: "tu regla se retrasa: una prueba puede decirte más", .de: "deine Periode ist überfällig – ein Test kann mehr sagen", .pt: "o teu período está atrasado — um teste pode dizer mais"],
        "fertile_until":        [.en: "Fertile until", .fr: "Fertile jusqu'au", .es: "Fértil hasta", .de: "Fruchtbar bis", .pt: "Fértil até"],

        // Pregnancy
        "unit_week":            [.en: "week", .fr: "semaine", .es: "semana", .de: "Woche", .pt: "semana"],
        "unit_weeks":           [.en: "weeks", .fr: "semaines", .es: "semanas", .de: "Wochen", .pt: "semanas"],
        "preg_caption":         [.en: "of pregnancy", .fr: "de grossesse", .es: "de embarazo", .de: "schwanger", .pt: "de gravidez"],
        "preg_caption_days_fmt":[.en: "and %d days of pregnancy", .fr: "et %d jours de grossesse", .es: "y %d días de embarazo", .de: "und %d Tage schwanger", .pt: "e %d dias de gravidez"],
        "preg_week_fmt":        [.en: "Week %d", .fr: "Semaine %d", .es: "Semana %d", .de: "Woche %d", .pt: "Semana %d"],
        "preg_trimester_fmt":   [.en: "Trimester %d", .fr: "Trimestre %d", .es: "Trimestre %d", .de: "%d. Trimester", .pt: "Trimestre %d"],
        "preg_due_date":        [.en: "Due date", .fr: "Terme prévu", .es: "Fecha prevista", .de: "Entbindungstermin", .pt: "Data prevista"],
        "preg_days_left":       [.en: "Days to go", .fr: "Jours restants", .es: "Días restantes", .de: "Tage verbleibend", .pt: "Dias restantes"],
        "preg_start":           [.en: "First day of last period", .fr: "1er jour des dernières règles", .es: "Primer día de la última regla", .de: "1. Tag der letzten Periode", .pt: "1.º dia do último período"],
        "preg_end":             [.en: "End pregnancy tracking", .fr: "Terminer le suivi de grossesse", .es: "Finalizar el seguimiento del embarazo", .de: "Schwangerschafts-Tracking beenden", .pt: "Terminar o acompanhamento da gravidez"],
        "preg_end_q":           [.en: "End pregnancy tracking?", .fr: "Terminer le suivi de grossesse ?", .es: "¿Finalizar el seguimiento del embarazo?", .de: "Schwangerschafts-Tracking beenden?", .pt: "Terminar o acompanhamento da gravidez?"],
        "preg_end_msg":         [.en: "Cycle tracking resumes. Nothing is deleted — your history stays as it is.", .fr: "Le suivi du cycle reprend. Rien n'est supprimé : ton historique reste intact.", .es: "El seguimiento del ciclo se reanuda. No se elimina nada: tu historial permanece intacto.", .de: "Das Zyklus-Tracking wird fortgesetzt. Nichts wird gelöscht – dein Verlauf bleibt erhalten.", .pt: "O seguimento do ciclo é retomado. Nada é eliminado — o teu histórico mantém-se."],
        "onb_mode_title":       [.en: "What would you like to track?", .fr: "Que veux-tu suivre ?", .es: "¿Qué quieres seguir?", .de: "Was möchtest du verfolgen?", .pt: "O que queres acompanhar?"],
        "onb_mode_body":        [.en: "You can change this at any time.", .fr: "Tu pourras changer à tout moment.", .es: "Puedes cambiarlo cuando quieras.", .de: "Du kannst das jederzeit ändern.", .pt: "Podes mudar a qualquer momento."],
        "onb_preg_title":       [.en: "Your pregnancy", .fr: "Ta grossesse", .es: "Tu embarazo", .de: "Deine Schwangerschaft", .pt: "A tua gravidez"],

        // MARK: Apple Health
        "health_section":      [.en: "Apple Health", .fr: "Apple Santé", .es: "Salud de Apple", .de: "Apple Health", .pt: "Saúde da Apple"],
        "health_sync":         [.en: "Sync with Apple Health", .fr: "Synchroniser avec Santé", .es: "Sincronizar con Salud", .de: "Mit Health synchronisieren", .pt: "Sincronizar com a Saúde"],
        "health_import":       [.en: "Import from Apple Health", .fr: "Importer depuis Santé", .es: "Importar desde Salud", .de: "Aus Health importieren", .pt: "Importar da Saúde"],
        "health_footer":       [.en: "Your period days are written to Health, and cycle starts recorded there can be imported. Only the selected person is synced.", .fr: "Tes jours de règles sont écrits dans Santé, et les débuts de cycle qui s'y trouvent peuvent être importés. Seule la personne sélectionnée est synchronisée.", .es: "Tus días de regla se escriben en Salud y los inicios de ciclo registrados allí se pueden importar. Solo se sincroniza la persona seleccionada.", .de: "Deine Periodentage werden in Health geschrieben; dort erfasste Zyklusstarts lassen sich importieren. Nur die ausgewählte Person wird synchronisiert.", .pt: "Os teus dias de período são escritos na Saúde e os inícios de ciclo aí registados podem ser importados. Apenas a pessoa selecionada é sincronizada."],
        "health_unavailable":  [.en: "Apple Health isn't available on this device.", .fr: "Apple Santé n'est pas disponible sur cet appareil.", .es: "Salud de Apple no está disponible en este dispositivo.", .de: "Apple Health ist auf diesem Gerät nicht verfügbar.", .pt: "A Saúde da Apple não está disponível neste dispositivo."],
        "health_imported_fmt": [.en: "%d period start(s) imported", .fr: "%d début(s) de règles importé(s)", .es: "%d inicio(s) de regla importado(s)", .de: "%d Periodenbeginn(e) importiert", .pt: "%d início(s) de período importado(s)"],
    ]
}
