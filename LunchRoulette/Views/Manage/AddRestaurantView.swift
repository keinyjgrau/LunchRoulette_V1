//
//  AddRestaurantView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI
import SwiftData
import PhotosUI

struct AddRestaurantView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @AppStorage(FoodTypeCatalog.storageKey) private var foodTypeOptionsRawValue: String = FoodTypeCatalog.encode(FoodTypeCatalog.defaultTypes)

    @State private var name = ""
    @State private var selectedFoodType = ""
    @State private var avgCost = ""
    @State private var address = ""
    @State private var ratingText = ""
    @State private var frequencyText = ""
    @State private var distanceText = ""
    @State private var detailsText = ""

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    private var foodTypeOptions: [String] {
        FoodTypeCatalog.decode(foodTypeOptionsRawValue)
    }

    var body: some View {
        Form {
            Section(AppText.required(appLanguage)) {
                TextField(AppText.name(appLanguage), text: $name)
            }

            Section(AppText.photo(appLanguage)) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text(AppText.choosePhoto(appLanguage))
                    }
                }

                if let photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.vertical, 6)

                    Button(role: .destructive) {
                        self.photoData = nil
                    } label: {
                        Label(AppText.removePhoto(appLanguage), systemImage: "trash")
                    }
                } else {
                    Text(AppText.noPhoto(appLanguage))
                        .foregroundStyle(.secondary)
                }
            }

            Section(AppText.details(appLanguage)) {
                Picker(AppText.typeOfFood(appLanguage), selection: $selectedFoodType) {
                    Text(AppText.none(appLanguage)).tag("")
                    ForEach(foodTypeOptions, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                TextField(AppText.averageCost(appLanguage), text: $avgCost)
                TextField(AppText.address(appLanguage), text: $address)

                TextField(AppText.ratingLabel(appLanguage), text: $ratingText)
                    .keyboardType(.decimalPad)

                TextField(AppText.frequency(appLanguage), text: $frequencyText)
                    .keyboardType(.numberPad)

                TextField(AppText.distanceMiles(appLanguage), text: $distanceText)
                    .keyboardType(.decimalPad)

                TextEditor(text: $detailsText)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle(AppText.addRestaurant(appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(AppText.save(appLanguage)) {
                    saveRestaurant()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button(AppText.cancel(appLanguage)) {
                    dismiss()
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        photoData = data
                    }
                }
            }
        }
    }

    private func saveRestaurant() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let trimmedCost = avgCost.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = detailsText.trimmingCharacters(in: .whitespacesAndNewlines)

        let rating = Double(ratingText.replacingOccurrences(of: ",", with: "."))
        let frequency = Int(frequencyText)
        let distance = Double(distanceText.replacingOccurrences(of: ",", with: "."))

        let restaurant = Restaurant(
            name: trimmedName,
            detailsText: trimmedDetails.isEmpty ? nil : trimmedDetails,
            foodType: selectedFoodType.isEmpty ? nil : selectedFoodType,
            avgCost: trimmedCost.isEmpty ? nil : trimmedCost,
            address: trimmedAddress.isEmpty ? nil : trimmedAddress,
            rating: rating,
            frequency: frequency,
            distanceMiles: distance,
            photoData: photoData
        )

        modelContext.insert(restaurant)
        dismiss()
    }
}
