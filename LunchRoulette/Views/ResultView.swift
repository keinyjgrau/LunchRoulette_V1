//
//  ResultView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI
import SwiftData
import MapKit

struct ResultView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue

    let candidate: RestaurantCandidate

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.createdAt, order: .reverse) private var allRestaurants: [Restaurant]

    @State private var importMessage: String? = nil
    @State private var wasImported = false

    private var hasCoordinates: Bool {
        candidate.latitude != nil && candidate.longitude != nil
    }

    private var placeCoordinate: CLLocationCoordinate2D? {
        guard let lat = candidate.latitude, let lon = candidate.longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    private var initialMapPosition: MapCameraPosition {
        if let coordinate = placeCoordinate {
            return .region(
                MKCoordinateRegion(
                    center: coordinate,
                    latitudinalMeters: 1200,
                    longitudinalMeters: 1200
                )
            )
        } else {
            return .automatic
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                detailsCard

                if hasCoordinates {
                    mapCard
                }

                if candidate.source == .nearby {
                    importCard
                }
            }
            .padding()
        }
        .navigationTitle(AppText.yourPick(appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if candidate.source == .nearby {
                wasImported = alreadyExistsInLocal()
            }
        }
        .alert(AppText.saveRestaurant(appLanguage), isPresented: Binding(
            get: { importMessage != nil },
            set: { newValue in
                if !newValue { importMessage = nil }
            }
        )) {
            Button("OK", role: .cancel) {
                importMessage = nil
            }
        } message: {
            Text(importMessage ?? "")
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            photo

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppText.selectedRestaurant(appLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(candidate.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    if let winningNumber = candidate.winningNumber {
                        winningNumberBadge(number: winningNumber)
                    }
                }

                HStack(spacing: 10) {
                    StarsView(rating: candidate.rating ?? 0)
                        .font(.headline)

                    if let foodType = candidate.foodType, !foodType.isEmpty {
                        Text(foodType)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
        )
    }

    @ViewBuilder
    private func winningNumberBadge(number: Int) -> some View {
        VStack(spacing: 4) {
            Text(AppText.winning(appLanguage))
                .font(.caption2)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 50, height: 50)

                Text("\(number)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
        }
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailRow(title: AppText.typeOfFood(appLanguage), value: candidate.foodType)
            detailRow(title: AppText.averageCost(appLanguage), value: candidate.avgCost)
            detailRow(title: AppText.address(appLanguage), value: candidate.address)

            if let miles = candidate.distanceMiles {
                detailRow(title: AppText.distance(appLanguage), value: AppText.distanceValue(miles, appLanguage))
            }

            if let freq = candidate.frequency {
                detailRow(title: AppText.frequency(appLanguage), value: "\(freq)")
            }

            if let desc = candidate.detailsText, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(AppText.description(appLanguage))
                        .font(.headline)

                    Text(desc)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var mapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppText.mapPreview(appLanguage))
                .font(.headline)

            if let coordinate = placeCoordinate {
                Map(initialPosition: initialMapPosition) {
                    Marker(candidate.name, coordinate: coordinate)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var importCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppText.saveToYourList(appLanguage))
                .font(.headline)

            Text(AppText.saveLocalDesc(appLanguage))
                .foregroundStyle(.secondary)

            if wasImported {
                Label(AppText.saved(appLanguage), systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
            } else {
                Button {
                    importToLocal()
                } label: {
                    Label(AppText.saveRestaurant(appLanguage), systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
        )
    }

    @ViewBuilder
    private var photo: some View {
        if let data = candidate.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 240)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18))
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.tertiary)
                .frame(height: 240)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text(AppText.noPhoto(appLanguage))
                            .foregroundStyle(.secondary)
                    }
                )
        }
    }

    @ViewBuilder
    private func detailRow(title: String, value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(value)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func alreadyExistsInLocal() -> Bool {
        let normalizedName = candidate.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedAddress = candidate.address?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return allRestaurants.contains { restaurant in
            let restaurantName = restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let restaurantAddress = restaurant.address?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

            let sameName = restaurantName == normalizedName
            let sameAddress = restaurantAddress == normalizedAddress

            if let normalizedAddress {
                return sameName && sameAddress
            } else {
                return sameName
            }
        }
    }

    private func importToLocal() {
        if alreadyExistsInLocal() {
            wasImported = true
            importMessage = AppText.alreadyInLocal(appLanguage)
            return
        }

        let restaurant = Restaurant(
            name: candidate.name,
            detailsText: candidate.detailsText,
            foodType: candidate.foodType,
            avgCost: candidate.avgCost,
            address: candidate.address,
            rating: candidate.rating,
            frequency: candidate.frequency,
            distanceMiles: candidate.distanceMiles,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            photoData: candidate.photoData
        )

        modelContext.insert(restaurant)
        wasImported = true
        importMessage = AppText.savedToLocal(appLanguage)
    }
}
