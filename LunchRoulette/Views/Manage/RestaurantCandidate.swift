//
//  RestaurantCandidate.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-17.
//

import Foundation

enum RestaurantCandidateSource: Hashable {
    case local
    case nearby
}

struct RestaurantCandidate: Identifiable, Hashable {
    let id: UUID
    let source: RestaurantCandidateSource

    let name: String
    let detailsText: String?
    let foodType: String?
    let avgCost: String?
    let address: String?
    let rating: Double?
    let frequency: Int?
    let distanceMiles: Double?
    let latitude: Double?
    let longitude: Double?
    let photoData: Data?
    let winningNumber: Int?

    init(
        id: UUID = UUID(),
        source: RestaurantCandidateSource,
        name: String,
        detailsText: String? = nil,
        foodType: String? = nil,
        avgCost: String? = nil,
        address: String? = nil,
        rating: Double? = nil,
        frequency: Int? = nil,
        distanceMiles: Double? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoData: Data? = nil,
        winningNumber: Int? = nil
    ) {
        self.id = id
        self.source = source
        self.name = name
        self.detailsText = detailsText
        self.foodType = foodType
        self.avgCost = avgCost
        self.address = address
        self.rating = rating
        self.frequency = frequency
        self.distanceMiles = distanceMiles
        self.latitude = latitude
        self.longitude = longitude
        self.photoData = photoData
        self.winningNumber = winningNumber
    }
}

extension RestaurantCandidate {
    @MainActor
    init(from restaurant: Restaurant) {
        self.init(
            id: UUID(),
            source: .local,
            name: restaurant.name,
            detailsText: restaurant.detailsText,
            foodType: restaurant.foodType,
            avgCost: restaurant.avgCost,
            address: restaurant.address,
            rating: restaurant.rating,
            frequency: restaurant.frequency,
            distanceMiles: restaurant.distanceMiles,
            latitude: restaurant.latitude,
            longitude: restaurant.longitude,
            photoData: restaurant.photoData,
            winningNumber: nil
        )
    }

    func withWinningNumber(_ number: Int?) -> RestaurantCandidate {
        RestaurantCandidate(
            id: id,
            source: source,
            name: name,
            detailsText: detailsText,
            foodType: foodType,
            avgCost: avgCost,
            address: address,
            rating: rating,
            frequency: frequency,
            distanceMiles: distanceMiles,
            latitude: latitude,
            longitude: longitude,
            photoData: photoData,
            winningNumber: number
        )
    }
}
