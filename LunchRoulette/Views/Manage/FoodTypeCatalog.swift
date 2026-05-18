//
//  FoodTypeCatalog.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-25.
//


import Foundation

enum FoodTypeCatalog {
    static let storageKey = "foodTypeOptions"

    static let defaultTypes: [String] = [
        "American",
        "Bakery",
        "Barbecue",
        "Breakfast",
        "Burgers",
        "Cafe",
        "Chinese",
        "Fast Food",
        "Healthy",
        "Indian",
        "Italian",
        "Japanese",
        "Mexican",
        "Pizza",
        "Puerto Rican",
        "Seafood",
        "Steakhouse",
        "Sushi",
        "Thai",
        "Vegetarian",
        "Other"
    ]

    static func decode(_ rawValue: String) -> [String] {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return defaultTypes }

        let values = trimmed
            .split(separator: "|")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return values.isEmpty ? defaultTypes : values
    }

    static func encode(_ values: [String]) -> String {
        values.joined(separator: "|")
    }

    static func normalizedUnique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in values {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }

            let key = trimmed.lowercased()
            guard !seen.contains(key) else { continue }

            seen.insert(key)
            result.append(trimmed)
        }

        return result.sorted()
    }
}
