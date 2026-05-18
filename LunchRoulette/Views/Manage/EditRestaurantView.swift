//
//  EditRestaurantView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI
import PhotosUI

struct EditRestaurantView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(FoodTypeCatalog.storageKey) private var foodTypeOptionsRawValue: String = FoodTypeCatalog.encode(FoodTypeCatalog.defaultTypes)

    @Bindable var restaurant: Restaurant

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var tempPhotoData: Data? = nil

    @State private var selectedFoodType = ""
    @State private var avgCostText = ""
    @State private var addressText = ""
    @State private var detailsTextValue = ""

    @State private var ratingText: String = ""
    @State private var frequencyText: String = ""
    @State private var distanceText: String = ""

    private var foodTypeOptions: [String] {
        FoodTypeCatalog.decode(foodTypeOptionsRawValue)
    }

    var body: some View {
        Form {
            Section("Required") {
                TextField("Name", text: $restaurant.name)
            }

            Section("Photo") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Change Photo")
                    }
                }

                if let data = tempPhotoData ?? restaurant.photoData,
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.vertical, 6)

                    Button(role: .destructive) {
                        restaurant.photoData = nil
                        tempPhotoData = nil
                    } label: {
                        Label("Remove Photo", systemImage: "trash")
                    }
                } else {
                    Text("No photo")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Details") {
                Picker("Type of food", selection: $selectedFoodType) {
                    Text("None").tag("")
                    ForEach(foodTypeOptions, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }

                TextField("Average cost", text: $avgCostText)
                TextField("Address", text: $addressText)

                TextField("Rating (0–5)", text: $ratingText)
                    .keyboardType(.decimalPad)

                TextField("Frequency", text: $frequencyText)
                    .keyboardType(.numberPad)

                TextField("Distance miles", text: $distanceText)
                    .keyboardType(.decimalPad)

                TextEditor(text: $detailsTextValue)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle("Edit Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    applyChanges()
                    dismiss()
                }
                .disabled(restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
            selectedFoodType = restaurant.foodType ?? ""
            avgCostText = restaurant.avgCost ?? ""
            addressText = restaurant.address ?? ""
            detailsTextValue = restaurant.detailsText ?? ""

            ratingText = restaurant.rating.map { String($0) } ?? ""
            frequencyText = restaurant.frequency.map { String($0) } ?? ""
            distanceText = restaurant.distanceMiles.map { String($0) } ?? ""
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        tempPhotoData = data
                        restaurant.photoData = data
                    }
                }
            }
        }
    }

    private func applyChanges() {
        let trimmedFoodType = selectedFoodType.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCost = avgCostText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = addressText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDetails = detailsTextValue.trimmingCharacters(in: .whitespacesAndNewlines)

        restaurant.foodType = trimmedFoodType.isEmpty ? nil : trimmedFoodType
        restaurant.avgCost = trimmedCost.isEmpty ? nil : trimmedCost
        restaurant.address = trimmedAddress.isEmpty ? nil : trimmedAddress
        restaurant.detailsText = trimmedDetails.isEmpty ? nil : trimmedDetails

        restaurant.rating = Double(ratingText.replacingOccurrences(of: ",", with: "."))
        restaurant.frequency = Int(frequencyText)
        restaurant.distanceMiles = Double(distanceText.replacingOccurrences(of: ",", with: "."))
    }
}
