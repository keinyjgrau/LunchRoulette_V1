//
//  SettingsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-20.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("rouletteSpinDuration") private var rouletteSpinDuration: Double = 2.8
    @AppStorage("defaultSourceMode") private var defaultSourceModeRawValue: String = RestaurantSourceMode.local.rawValue
    @AppStorage(FoodTypeCatalog.storageKey) private var foodTypeOptionsRawValue: String = FoodTypeCatalog.encode(FoodTypeCatalog.defaultTypes)

    @State private var newFoodType = ""

    private var selectedSourceModeBinding: Binding<RestaurantSourceMode> {
        Binding(
            get: {
                RestaurantSourceMode(rawValue: defaultSourceModeRawValue) ?? .local
            },
            set: { newValue in
                defaultSourceModeRawValue = newValue.rawValue
            }
        )
    }

    private var foodTypeOptions: [String] {
        FoodTypeCatalog.decode(foodTypeOptionsRawValue)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                List {
                    Section("Preferences") {
                        Picker("Default restaurant source", selection: selectedSourceModeBinding) {
                            ForEach(RestaurantSourceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .accessibilityHint("Sets which restaurant source opens by default on the Choose screen.")
                    }

                    Section("Roulette") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Spin duration")
                                Spacer()
                                Text(String(format: "%.1f s", rouletteSpinDuration))
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $rouletteSpinDuration, in: 1.2...4.5, step: 0.1)
                                .accessibilityLabel("Spin duration")
                                .accessibilityValue("\(String(format: "%.1f", rouletteSpinDuration)) seconds")
                                .accessibilityHint("Adjusts how long the roulette spins before choosing a restaurant.")

                            HStack {
                                Text("Faster")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("Slower")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Food Types") {
                        HStack {
                            TextField("Add new food type", text: $newFoodType)

                            Button("Add") {
                                addFoodType()
                            }
                            .disabled(newFoodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }

                        ForEach(foodTypeOptions, id: \.self) { type in
                            HStack {
                                Text(type)
                                Spacer()
                            }
                        }
                        .onDelete(perform: deleteFoodTypes)
                    }

                    Section("About") {
                        LabeledContent("App", value: "Lunch Roulette")
                        LabeledContent("Version", value: "1.0")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
        }
    }

    private func addFoodType() {
        let trimmed = newFoodType.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = foodTypeOptions
        updated.append(trimmed)
        updated = FoodTypeCatalog.normalizedUnique(updated)

        foodTypeOptionsRawValue = FoodTypeCatalog.encode(updated)
        newFoodType = ""
    }

    private func deleteFoodTypes(at offsets: IndexSet) {
        var updated = foodTypeOptions
        updated.remove(atOffsets: offsets)
        updated = FoodTypeCatalog.normalizedUnique(updated)
        foodTypeOptionsRawValue = FoodTypeCatalog.encode(updated)
    }
}
