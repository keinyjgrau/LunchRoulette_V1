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

    @State private var name = ""
    @State private var detailsText = ""
    @State private var foodType = ""
    @State private var avgCost = ""
    @State private var address = ""
    @State private var ratingText = ""
    @State private var frequencyText = ""
    @State private var distanceText = ""

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    var body: some View {
        Form {
            Section("Required") {
                TextField("Name", text: $name)
            }

            Section("Photo") {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Pick Photo")
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
                }
            }

            Section("Details") {
                TextField("Type of food", text: $foodType)
                TextField("Average cost (e.g. $$)", text: $avgCost)
                TextField("Address", text: $address)

                TextField("Rating (0–5, optional)", text: $ratingText)
                    .keyboardType(.decimalPad)

                TextField("Frequency (optional)", text: $frequencyText)
                    .keyboardType(.numberPad)

                TextField("Distance miles (optional)", text: $distanceText)
                    .keyboardType(.decimalPad)

                TextEditor(text: $detailsText)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle("Add Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    await MainActor.run { self.photoData = data }
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        let rating = Double(ratingText.replacingOccurrences(of: ",", with: "."))
        let frequency = Int(frequencyText)
        let distance = Double(distanceText.replacingOccurrences(of: ",", with: "."))

        let r = Restaurant(
            name: trimmedName,
            detailsText: detailsText.isEmpty ? nil : detailsText,
            foodType: foodType.isEmpty ? nil : foodType,
            avgCost: avgCost.isEmpty ? nil : avgCost,
            address: address.isEmpty ? nil : address,
            rating: rating,
            frequency: frequency,
            distanceMiles: distance,
            photoData: photoData
        )

        modelContext.insert(r)
        dismiss()
    }
}