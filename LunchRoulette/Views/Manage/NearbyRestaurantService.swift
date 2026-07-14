//
//  NearbyRestaurantService.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-17.
//


import Foundation
import MapKit
import CoreLocation

struct NearbyRestaurantService {
    func searchNearbyRestaurants(from location: CLLocation, limit: Int = 50) async throws -> [RestaurantCandidate] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "restaurant"
        request.resultTypes = .pointOfInterest

        let region = MKCoordinateRegion(
            center: location.coordinate,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        request.region = region

        let response = try await MKLocalSearch(request: request).start()

        let candidates = response.mapItems.compactMap { item -> RestaurantCandidate? in
            guard let name = item.name,
                  !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }

            let placeLocation = item.location
            let meters = location.distance(from: placeLocation)
            let distanceMiles = meters / 1609.344
            let address = formattedAddress(from: item)
            let foodType = categoryText(from: item)

            return RestaurantCandidate(
                source: .nearby,
                name: name,
                detailsText: nil,
                foodType: foodType,
                avgCost: nil,
                address: address,
                rating: nil,
                frequency: nil,
                distanceMiles: distanceMiles,
                latitude: placeLocation.coordinate.latitude,
                longitude: placeLocation.coordinate.longitude,
                photoData: nil
            )
        }

        var seen = Set<String>()

        let uniqueSorted = candidates
            .sorted {
                ($0.distanceMiles ?? .greatestFiniteMagnitude) < ($1.distanceMiles ?? .greatestFiniteMagnitude)
            }
            .filter { candidate in
                let key = "\(candidate.name.lowercased())|\(candidate.address?.lowercased() ?? "")"
                if seen.contains(key) { return false }
                seen.insert(key)
                return true
            }

        return Array(uniqueSorted.prefix(limit))
    }

    private func formattedAddress(from item: MKMapItem) -> String? {
        if #available(iOS 26.0, *) {
            if let short = item.address?.shortAddress,
               !short.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return short
            }

            if let full = item.address?.fullAddress,
               !full.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return full
            }

            return nil
        } else {
            let parts = [
                item.placemark.subThoroughfare,
                item.placemark.thoroughfare,
                item.placemark.locality,
                item.placemark.administrativeArea
            ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

            return parts.isEmpty ? nil : parts.joined(separator: ", ")
        }
    }

    private func categoryText(from item: MKMapItem) -> String? {
        guard let category = item.pointOfInterestCategory else {
            return nil
        }

        if category == .restaurant {
            return nil
        }

        return FoodTypeFormatter.clean(category.rawValue)
    }
}
