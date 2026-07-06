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
        "onb_welcome_title": [.en: "Welcome to Cycles", .fr: "Bienvenue dans Cycles", .es: "Bienvenida a Cycles", .de: "Willkommen bei Cycles", .pt: "Bem-vinda ao Cycles"],
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
        "disclaimer_body":    [.en: "Cycles provides estimates based on what you log. It is not a medical device and not a method of contraception.", .fr: "Cycles fournit des estimations basées sur tes saisies. Ce n'est pas un dispositif médical ni une méthode de contraception.", .es: "Cycles ofrece estimaciones según lo que registras. No es un dispositivo médico ni un método anticonceptivo.", .de: "Cycles liefert Schätzungen auf Basis deiner Einträge. Es ist kein Medizinprodukt und keine Verhütungsmethode.", .pt: "O Cycles fornece estimativas com base no que registas. Não é um dispositivo médico nem um método contracetivo."],

        // MARK: Notification content
        "notif_period_title":      [.en: "Your period is coming 🌸", .fr: "Tes règles approchent 🌸", .es: "Se acerca tu regla 🌸", .de: "Deine Periode kommt 🌸", .pt: "O teu período aproxima-se 🌸"],
        "notif_period_body":       [.en: "Your period is expected tomorrow.", .fr: "Tes règles sont prévues demain.", .es: "Tu regla se espera mañana.", .de: "Deine Periode wird morgen erwartet.", .pt: "O teu período é esperado amanhã."],
        "notif_period_body_named": [.en: "%@: your period is expected tomorrow.", .fr: "%@ : tes règles sont prévues demain.", .es: "%@: tu regla se espera mañana.", .de: "%@: deine Periode wird morgen erwartet.", .pt: "%@: o teu período é esperado amanhã."],
        "notif_ovulation_title":   [.en: "Ovulation tomorrow ✨", .fr: "Ovulation demain ✨", .es: "Ovulación mañana ✨", .de: "Eisprung morgen ✨", .pt: "Ovulação amanhã ✨"],
        "notif_ovulation_body":    [.en: "Your fertile window peaks — ovulation is expected tomorrow.", .fr: "Ta fenêtre fertile est à son maximum — ovulation prévue demain.", .es: "Tu ventana fértil está en su punto máximo: ovulación mañana.", .de: "Deine fruchtbaren Tage erreichen ihren Höhepunkt – Eisprung morgen.", .pt: "A tua janela fértil está no auge — ovulação amanhã."],
        "notif_ovulation_body_named": [.en: "%@: ovulation is expected tomorrow.", .fr: "%@ : ovulation prévue demain.", .es: "%@: ovulación mañana.", .de: "%@: Eisprung morgen.", .pt: "%@: ovulação amanhã."],

        // MARK: Lock
        "lock_reason": [.en: "Unlock Cycles to view your data", .fr: "Déverrouille Cycles pour voir tes données", .es: "Desbloquea Cycles para ver tus datos", .de: "Entsperre Cycles, um deine Daten zu sehen", .pt: "Desbloqueia o Cycles para ver os teus dados"],
        "lock_title":  [.en: "Cycles is locked", .fr: "Cycles est verrouillé", .es: "Cycles está bloqueado", .de: "Cycles ist gesperrt", .pt: "O Cycles está bloqueado"],
        "lock_unlock": [.en: "Unlock", .fr: "Déverrouiller", .es: "Desbloquear", .de: "Entsperren", .pt: "Desbloquear"],

        // MARK: Widget
        "widget_desc":    [.en: "Days until your period or ovulation.", .fr: "Le nombre de jours avant tes règles ou ton ovulation.", .es: "Días hasta tu regla u ovulación.", .de: "Tage bis zu Periode oder Eisprung.", .pt: "Dias até o teu período ou ovulação."],
        "widget_no_data": [.en: "Open Cycles", .fr: "Ouvre Cycles", .es: "Abre Cycles", .de: "Cycles öffnen", .pt: "Abrir o Cycles"],

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
    ]
}
