//
//  RestaurantSourceMode.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-07-13.
//


import Foundation

enum RestaurantSourceMode: String, CaseIterable, Identifiable {
    case local
    case nearby

    var id: String {
        rawValue
    }

    func title(appLanguage: String) -> String {
        switch self {
        case .local:
            return translate("Local", "Local", appLanguage: appLanguage)

        case .nearby:
            return translate("Nearby", "Cercanos", appLanguage: appLanguage)
        }
    }

    var candidateSource: RestaurantCandidateSource {
        switch self {
        case .local:
            return .local

        case .nearby:
            return .nearby
        }
    }

    private func translate(_ english: String, _ spanish: String, appLanguage: String) -> String {
        if appLanguage == AppLanguageOption.spanish.rawValue {
            return spanish
        }

        if appLanguage == AppLanguageOption.english.rawValue {
            return english
        }

        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        return preferred.hasPrefix("es") ? spanish : english
    }
}