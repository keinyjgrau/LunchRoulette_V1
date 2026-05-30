//
//  SettingsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-20.
//


import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue
    @AppStorage("rouletteSpinDuration") private var rouletteSpinDuration: Double = 2.8
    @AppStorage("defaultSourceMode") private var defaultSourceModeRawValue: String = RestaurantSourceMode.local.rawValue
    @AppStorage(FoodTypeCatalog.storageKey) private var foodTypeOptionsRawValue: String = FoodTypeCatalog.encode(FoodTypeCatalog.defaultTypes)

    @StateObject private var accountBindingManager = AccountBindingManager()
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
                    Section(AppText.preferences(appLanguage)) {
                        Picker(AppText.defaultRestaurantSource(appLanguage), selection: selectedSourceModeBinding) {
                            ForEach(RestaurantSourceMode.allCases) { mode in
                                Text(mode.rawValue == "Local" ? AppText.local(appLanguage) : AppText.nearby(appLanguage)).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        Picker(AppText.language(appLanguage), selection: $appLanguage) {
                            Text(AppText.system(appLanguage)).tag(AppLanguageOption.system.rawValue)
                            Text(AppText.english(appLanguage)).tag(AppLanguageOption.english.rawValue)
                            Text(AppText.spanish(appLanguage)).tag(AppLanguageOption.spanish.rawValue)
                        }
                    }

                    Section(AppText.roulette(appLanguage)) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(AppText.spinDuration(appLanguage))
                                Spacer()
                                Text(String(format: "%.1f s", rouletteSpinDuration))
                                    .foregroundStyle(.secondary)
                            }

                            Slider(value: $rouletteSpinDuration, in: 1.2...4.5, step: 0.1)

                            HStack {
                                Text(AppText.faster(appLanguage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text(AppText.slower(appLanguage))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section(AppText.isSpanish(appLanguage) ? "Vincular Cuenta" : "Bind Account") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Game Center")
                                Spacer()
                                if accountBindingManager.isGameCenterAuthenticated {
                                    Text(AppText.saved(appLanguage))
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(Color.green.opacity(0.15)))
                                        .foregroundStyle(.green)
                                }
                            }

                            if let gameCenterDisplayName = accountBindingManager.gameCenterDisplayName,
                               !gameCenterDisplayName.isEmpty {
                                Text(gameCenterDisplayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Button {
                                accountBindingManager.bindGameCenter()
                            } label: {
                                Label(
                                    accountBindingManager.isGameCenterAuthenticated
                                    ? (AppText.isSpanish(appLanguage) ? "Verificar Game Center" : "Check Game Center")
                                    : (AppText.isSpanish(appLanguage) ? "Vincular con Game Center" : "Bind with Game Center"),
                                    systemImage: "gamecontroller"
                                )
                            }
                            .disabled(accountBindingManager.isBusy)

                            Button {
                                accountBindingManager.facebookPlaceholder()
                            } label: {
                                Label(
                                    AppText.isSpanish(appLanguage) ? "Vincular con Facebook (próximamente)" : "Bind with Facebook (coming soon)",
                                    systemImage: "person.crop.circle.badge.plus"
                                )
                            }

                            if let bindMessage = accountBindingManager.bindMessage, !bindMessage.isEmpty {
                                Text(bindMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    Section(AppText.foodTypes(appLanguage)) {
                        HStack {
                            TextField(AppText.addNewFoodType(appLanguage), text: $newFoodType)

                            Button(AppText.add(appLanguage)) {
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

                    Section(AppText.about(appLanguage)) {
                        LabeledContent(AppText.app(appLanguage), value: "Lunch Roulette")
                        LabeledContent(AppText.version(appLanguage), value: "1.0")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle(AppText.settings(appLanguage))
            .onAppear {
                accountBindingManager.refreshState()
            }
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
