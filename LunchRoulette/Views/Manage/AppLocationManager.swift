//
//  AppLocationManager.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-17.
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class AppLocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var currentLocation: CLLocation?
    @Published var lastErrorMessage: String?

    private let manager = CLLocationManager()
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }

    func requestPermissionIfNeeded() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func requestCurrentLocation() async throws -> CLLocation {
        let status = manager.authorizationStatus

        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            throw LocationError.waitingForPermission

        case .restricted, .denied:
            throw LocationError.permissionDenied

        case .authorizedAlways, .authorizedWhenInUse:
            return try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                self.manager.requestLocation()
            }

        @unknown default:
            throw LocationError.unknown
        }
    }
}

extension AppLocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
            return
        }

        currentLocation = location
        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        lastErrorMessage = error.localizedDescription
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

enum LocationError: LocalizedError {
    case waitingForPermission
    case permissionDenied
    case locationUnavailable
    case unknown

    var errorDescription: String? {
        switch self {
        case .waitingForPermission:
            return "Waiting for location permission."
        case .permissionDenied:
            return "Location access is denied. Enable it in Settings to use Nearby mode."
        case .locationUnavailable:
            return "Current location is not available right now."
        case .unknown:
            return "An unknown location error occurred."
        }
    }
}
