//
//  RestaurantRow.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI

struct RestaurantRow: View {
    let candidate: RestaurantCandidate
    let isSavedLocally: Bool
    let isSelected: Bool
    let selectionMode: Bool
    let isSelectionDisabled: Bool

    init(
        candidate: RestaurantCandidate,
        isSavedLocally: Bool = false,
        isSelected: Bool = false,
        selectionMode: Bool = false,
        isSelectionDisabled: Bool = false
    ) {
        self.candidate = candidate
        self.isSavedLocally = isSavedLocally
        self.isSelected = isSelected
        self.selectionMode = selectionMode
        self.isSelectionDisabled = isSelectionDisabled
    }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(candidate.name)
                        .font(.headline)
                        .lineLimit(1)

                    if isSavedLocally && candidate.source == .nearby {
                        Text("Saved")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.15))
                            )
                            .foregroundStyle(.green)
                            .accessibilityHidden(true)
                    }
                }

                HStack(spacing: 8) {
                    if let food = candidate.foodType, !food.isEmpty {
                        Label(food, systemImage: "tag")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let cost = candidate.avgCost, !cost.isEmpty {
                        Label(cost, systemImage: "dollarsign.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    StarsView(rating: candidate.rating ?? 0)
                        .font(.caption)

                    if let miles = candidate.distanceMiles {
                        Text(String(format: "%.1f mi", miles))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            trailingIndicator
                .accessibilityHidden(true)
        }
        .opacity(isSelectionDisabled ? 0.45 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(selectionMode ? "Double-tap to select or deselect." : "Double-tap to view details.")
    }

    @ViewBuilder
    private var trailingIndicator: some View {
        if selectionMode {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .orange : .secondary)
                .font(.title3)
        } else if isSavedLocally && candidate.source == .nearby {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.title3)
        } else {
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = candidate.photoData,
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .accessibilityHidden(true)
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(.tertiary)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
                .accessibilityHidden(true)
        }
    }

    private var accessibilitySummary: String {
        var parts: [String] = [candidate.name]

        if let food = candidate.foodType, !food.isEmpty {
            parts.append(food)
        }

        if let cost = candidate.avgCost, !cost.isEmpty {
            parts.append("Cost \(cost)")
        }

        if let rating = candidate.rating {
            parts.append("Rating \(String(format: "%.1f", rating)) out of 5")
        }

        if let miles = candidate.distanceMiles {
            parts.append("\(String(format: "%.1f", miles)) miles away")
        }

        if isSavedLocally && candidate.source == .nearby {
            parts.append("Saved locally")
        }

        if selectionMode {
            parts.append(isSelected ? "Selected" : "Not selected")
        }

        if isSelectionDisabled {
            parts.append("Selection limit reached")
        }

        return parts.joined(separator: ", ")
    }
}
