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

    @Bindable var restaurant: Restaurant

    @State private var photoItem: PhotosPickerItem? = nil
    @State private var tempPhotoData: Data? = nil

    @State private var ratingText: String = ""
    @State private var frequencyText: String = ""
    @State private var distanceText: String = ""

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
                TextField("Type of food", text: foodTypeBinding)
                TextField("Average cost", text: avgCostBinding)
                TextField("Address", text: addressBinding)

                TextField("Rating (0–5)", text: $ratingText)
                    .keyboardType(.decimalPad)

                TextField("Frequency", text: $frequencyText)
                    .keyboardType(.numberPad)

                TextField("Distance miles", text: $distanceText)
                    .keyboardType(.decimalPad)

                TextEditor(text: detailsTextBinding)
                    .frame(minHeight: 90)
            }
        }
        .navigationTitle("Edit Restaurant")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    applyNumericFields()
                    dismiss()
                }
                .disabled(restaurant.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear {
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

    private var foodTypeBinding: Binding<String> {
        Binding(
            get: { restaurant.foodType ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                restaurant.foodType = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private var avgCostBinding: Binding<String> {
        Binding(
            get: { restaurant.avgCost ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                restaurant.avgCost = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private var addressBinding: Binding<String> {
        Binding(
            get: { restaurant.address ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                restaurant.address = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private var detailsTextBinding: Binding<String> {
        Binding(
            get: { restaurant.detailsText ?? "" },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                restaurant.detailsText = trimmed.isEmpty ? nil : trimmed
            }
        )
    }

    private func applyNumericFields() {
        let rating = Double(ratingText.replacingOccurrences(of: ",", with: "."))
        restaurant.rating = rating

        restaurant.frequency = Int(frequencyText)

        let distance = Double(distanceText.replacingOccurrences(of: ",", with: "."))
        restaurant.distanceMiles = distance
    }
}
