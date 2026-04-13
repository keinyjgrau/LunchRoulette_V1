//
//  Restaurant.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import Foundation
import SwiftData

@Model
final class Restaurant {
    var name: String

    var detailsText: String?
    var foodType: String?
    var avgCost: String?
    var address: String?

    var rating: Double?
    var frequency: Int?
    var distanceMiles: Double?

    var latitude: Double?
    var longitude: Double?

    @Attribute(.externalStorage)
    var photoData: Data?

    var createdAt: Date

    init(
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
        createdAt: Date = Date()
    ) {
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
        self.createdAt = createdAt
    }
}
