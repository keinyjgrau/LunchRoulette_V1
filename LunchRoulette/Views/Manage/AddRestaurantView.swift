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
            Section("Required") {
                TextField("Name", text: $name)
            }

            Section("Photo") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose Photo")
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

                TextField("Average cost", text: $avgCost)
                TextField("Address", text: $address)

                TextField("Rating (0–5)", text: $ratingText)
                    .keyboardType(.decimalPad)

                TextField("Frequency", text: $frequencyText)
                    .keyboardType(.numberPad)

                TextField("Distance miles", text: $distanceText)
                    .keyboardType(.decimalPad)

                TextEditor(text: $detailsText)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle("Add Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveRestaurant()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
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
