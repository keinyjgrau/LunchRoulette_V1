//
//  SeedData.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-17.
//


import Foundation
import SwiftData

enum SeedData {
    static func insertIfNeeded(in context: ModelContext) {
        let descriptor = FetchDescriptor<Restaurant>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        let samples: [Restaurant] = [
            Restaurant(
                name: "La Terraza Grill",
                detailsText: "Casual grill with burgers, sandwiches, and lunch combos.",
                foodType: "American",
                avgCost: "$$",
                address: "123 Main St",
                rating: 4.2,
                frequency: 3,
                distanceMiles: 2.4
            ),
            Restaurant(
                name: "Sushi Wave",
                detailsText: "Fresh sushi rolls and poke bowls, good for quick lunch meetings.",
                foodType: "Japanese",
                avgCost: "$$$",
                address: "45 Ocean Ave",
                rating: 4.7,
                frequency: 1,
                distanceMiles: 4.1
            ),
            Restaurant(
                name: "El Fogón Criollo",
                detailsText: "Puerto Rican favorites with hearty lunch plates.",
                foodType: "Puerto Rican",
                avgCost: "$$",
                address: "78 Plaza Rd",
                rating: 4.6,
                frequency: 5,
                distanceMiles: 3.0
            ),
            Restaurant(
                name: "Pasta e Basta",
                detailsText: "Italian lunch spot with pasta specials and soups.",
                foodType: "Italian",
                avgCost: "$$",
                address: "220 Market St",
                rating: 4.1,
                frequency: 2,
                distanceMiles: 5.2
            ),
            Restaurant(
                name: "Taco Pueblo",
                detailsText: "Tacos, quesadillas, and fast lunch platters.",
                foodType: "Mexican",
                avgCost: "$",
                address: "11 Central Blvd",
                rating: 4.3,
                frequency: 4,
                distanceMiles: 1.8
            ),
            Restaurant(
                name: "Green Bowl Kitchen",
                detailsText: "Healthy bowls, salads, wraps, and vegetarian options.",
                foodType: "Healthy",
                avgCost: "$$",
                address: "9 Garden St",
                rating: 4.4,
                frequency: 2,
                distanceMiles: 2.1
            )
        ]

        for restaurant in samples {
            context.insert(restaurant)
        }

        try? context.save()
    }
}
