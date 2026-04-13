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
        .navigationTitle("Your Pick")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if candidate.source == .nearby {
                wasImported = alreadyExistsInLocal()
            }
        }
        .alert("Save Restaurant", isPresented: Binding(
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
                        Text("Selected restaurant")
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
            Text("Winning")
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Winning number")
        .accessibilityValue("\(number)")
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            detailRow(title: "Type of food", value: candidate.foodType)
            detailRow(title: "Average cost", value: candidate.avgCost)
            detailRow(title: "Address", value: candidate.address)

            if let miles = candidate.distanceMiles {
                detailRow(title: "Distance", value: String(format: "%.1f miles", miles))
            }

            if let freq = candidate.frequency {
                detailRow(title: "Frequency", value: "\(freq)")
            }

            if let desc = candidate.detailsText, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Description")
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
            Text("Map preview")
                .font(.headline)

            if let coordinate = placeCoordinate {
                Map(initialPosition: initialMapPosition) {
                    Marker(candidate.name, coordinate: coordinate)
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Map preview")
                .accessibilityValue(candidate.address ?? candidate.name)
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
            Text("Save to your list")
                .font(.headline)

            Text("Save this restaurant to your local list so it can appear again in Local mode.")
                .foregroundStyle(.secondary)

            if wasImported {
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .fontWeight(.semibold)
                    .foregroundStyle(.green)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
                    .accessibilityLabel("Saved to your local list")
            } else {
                Button {
                    importToLocal()
                } label: {
                    Label("Save Restaurant", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityHint("Saves this nearby restaurant to your local list.")
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
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 18)
                .fill(.tertiary)
                .frame(height: 240)
                .overlay(
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No photo")
                            .foregroundStyle(.secondary)
                    }
                )
                .accessibilityHidden(true)
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
            importMessage = "This restaurant is already in your local list."
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
        importMessage = "Restaurant saved to your local list."
    }
}
