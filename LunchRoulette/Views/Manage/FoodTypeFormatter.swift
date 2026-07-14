//
//  FoodTypeFormatter.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-07-13.
//


import Foundation

enum FoodTypeFormatter {
    static func clean(_ value: String?) -> String? {
        guard var text = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return nil
        }

        if text == "MKPOICategoryRestaurant" || text == "Restaurant" {
            return nil
        }

        if text.hasPrefix("MKPOICategory") {
            text = text.replacingOccurrences(of: "MKPOICategory", with: "")
        }

        text = text.replacingOccurrences(of: "_", with: " ")

        text = text.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )

        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return text.isEmpty ? nil : text.capitalized
    }
}