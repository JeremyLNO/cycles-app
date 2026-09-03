import Foundation

/// Supportive, women-focused wellness tips tailored to the current cycle phase.
/// General well-being only — not medical advice (see the disclaimer in Settings).
enum HealthTips {
    /// All tips for a phase, in the given language.
    static func tips(for phase: CyclePhase, _ lang: AppLanguage = .current) -> [String] {
        table[phase]?[lang] ?? table[phase]?[.en] ?? []
    }

    /// One tip for the phase, varying with the day of the cycle.
    static func tip(for phase: CyclePhase, day: Int, _ lang: AppLanguage = .current) -> String? {
        let arr = tips(for: phase, lang)
        guard !arr.isEmpty else { return nil }
        return arr[abs(day) % arr.count]
    }

    static let table: [CyclePhase: [AppLanguage: [String]]] = [
        .menstruation: [
            .en: ["Favour iron-rich foods (lentils, spinach) to make up for losses.",
                  "Rest and stay hydrated — a warm bottle can ease cramps."],
            .fr: ["Privilégie les aliments riches en fer (lentilles, épinards) pour compenser les pertes.",
                  "Repose-toi et hydrate-toi : une bouillotte peut soulager les crampes."],
            .es: ["Prioriza alimentos ricos en hierro (lentejas, espinacas) para reponer pérdidas.",
                  "Descansa e hidrátate: una bolsa de calor puede aliviar los cólicos."],
            .de: ["Bevorzuge eisenreiche Lebensmittel (Linsen, Spinat), um Verluste auszugleichen.",
                  "Ruh dich aus und trinke genug — eine Wärmflasche lindert Krämpfe."],
            .pt: ["Prefere alimentos ricos em ferro (lentilhas, espinafres) para repor as perdas.",
                  "Descansa e hidrata-te: uma bolsa de água quente alivia as cólicas."],
        ],
        .follicular: [
            .en: ["Your energy is rising — a great time for more intense workouts.",
                  "Use this phase to plan and start new projects."],
            .fr: ["Ton énergie remonte : c'est le bon moment pour des entraînements plus intenses.",
                  "Profite de cette phase pour planifier et lancer de nouveaux projets."],
            .es: ["Tu energía sube: buen momento para entrenamientos más intensos.",
                  "Aprovecha esta fase para planificar y empezar nuevos proyectos."],
            .de: ["Deine Energie steigt — ideal für intensivere Workouts.",
                  "Nutze diese Phase, um zu planen und Neues zu beginnen."],
            .pt: ["A tua energia sobe: ótimo momento para treinos mais intensos.",
                  "Aproveita esta fase para planear e iniciar novos projetos."],
        ],
        .fertile: [
            .en: ["Libido may rise. If you're avoiding pregnancy, use protection.",
                  "Stay well hydrated and notice any changes in cervical mucus."],
            .fr: ["Ta libido peut augmenter. Si tu souhaites éviter une grossesse, protège-toi.",
                  "Reste bien hydratée et observe d'éventuels changements de glaire cervicale."],
            .es: ["La libido puede aumentar. Si evitas el embarazo, usa protección.",
                  "Mantente hidratada y observa cambios en el moco cervical."],
            .de: ["Die Libido kann steigen. Wenn du nicht schwanger werden willst, verhüte.",
                  "Trinke ausreichend und achte auf Veränderungen des Zervixschleims."],
            .pt: ["A libido pode aumentar. Se queres evitar a gravidez, usa proteção.",
                  "Mantém-te hidratada e observa mudanças no muco cervical."],
        ],
        .ovulation: [
            .en: ["Peak fertility today. Log your symptoms to refine predictions.",
                  "A mild ache on one side of the lower belly can accompany ovulation."],
            .fr: ["Pic de fertilité aujourd'hui. Note tes symptômes pour affiner les prévisions.",
                  "Une légère douleur d'un côté du bas-ventre peut accompagner l'ovulation."],
            .es: ["Pico de fertilidad hoy. Registra tus síntomas para afinar las predicciones.",
                  "Un leve dolor en un lado del bajo vientre puede acompañar la ovulación."],
            .de: ["Heute höchste Fruchtbarkeit. Erfasse Symptome für genauere Prognosen.",
                  "Ein leichtes Ziehen auf einer Seite des Unterbauchs kann den Eisprung begleiten."],
            .pt: ["Pico de fertilidade hoje. Regista os sintomas para afinar as previsões.",
                  "Uma ligeira dor de um lado do baixo-ventre pode acompanhar a ovulação."],
        ],
        .luteal: [
            .en: ["Cravings or mood swings (PMS) are common — magnesium can help.",
                  "Regular sleep and gentle activity help you through this phase."],
            .fr: ["Fringales ou sautes d'humeur (SPM) sont fréquentes : le magnésium peut aider.",
                  "Un sommeil régulier et des activités douces aident à traverser cette phase."],
            .es: ["Antojos o cambios de humor (SPM) son comunes: el magnesio puede ayudar.",
                  "Dormir bien y hacer actividad suave ayudan en esta fase."],
            .de: ["Heißhunger oder Stimmungsschwankungen (PMS) sind normal — Magnesium hilft.",
                  "Regelmäßiger Schlaf und sanfte Bewegung helfen durch diese Phase."],
            .pt: ["Desejos ou alterações de humor (TPM) são comuns: o magnésio pode ajudar.",
                  "Dormir bem e fazer atividade suave ajudam nesta fase."],
        ],
        .pms: [
            .en: ["Your period is close: cut back on salt and caffeine to ease bloating.",
                  "Tender breasts, irritability, cravings — classic PMS. Be kind to yourself.",
                  "Keep a pad or cup handy: your period is expected in the coming days."],
            .fr: ["Tes règles approchent : réduis le sel et la caféine pour limiter les ballonnements.",
                  "Seins sensibles, irritabilité, fringales : le SPM classique. Sois douce avec toi.",
                  "Garde une protection à portée de main : tes règles sont prévues dans quelques jours."],
            .es: ["Tu regla se acerca: reduce la sal y la cafeína para aliviar la hinchazón.",
                  "Senos sensibles, irritabilidad, antojos: el SPM clásico. Cuídate.",
                  "Ten a mano una compresa o copa: tu regla llegará en unos días."],
            .de: ["Deine Periode naht: weniger Salz und Koffein lindern Blähungen.",
                  "Spannende Brüste, Reizbarkeit, Heißhunger — typisches PMS. Sei gut zu dir.",
                  "Halte Binde oder Tasse bereit: deine Periode kommt in den nächsten Tagen."],
            .pt: ["O teu período aproxima-se: reduz o sal e a cafeína para aliviar o inchaço.",
                  "Seios sensíveis, irritabilidade, desejos: a TPM clássica. Cuida de ti.",
                  "Tem um penso ou copo à mão: o teu período chega nos próximos dias."],
        ],
    ]
}
