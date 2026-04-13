//
//  PickView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI
import SwiftData
import CoreLocation

enum RestaurantSourceMode: String, CaseIterable, Identifiable {
    case local = "Local"
    case nearby = "Nearby"

    var id: String { rawValue }
}

struct PickView: View {
    @Query(sort: \Restaurant.createdAt, order: .reverse) private var allRestaurants: [Restaurant]

    @StateObject private var locationManager = AppLocationManager()

    @AppStorage("defaultSourceMode") private var defaultSourceModeRawValue: String = RestaurantSourceMode.local.rawValue
    @AppStorage("rouletteSpinDuration") private var rouletteSpinDuration: Double = 2.8

    @State private var availableChoices: [RestaurantCandidate] = []
    @State private var selectedCandidate: RestaurantCandidate? = nil
    @State private var showResult = false
    @State private var showRoulette = false

    @State private var selectedSourceMode: RestaurantSourceMode = .local

    @State private var isLoadingNearby = false
    @State private var nearbyErrorMessage: String? = nil
    @State private var pendingNearbySearchAfterPermission = false
    @State private var nearbyStatusMessage: String? = nil

    @State private var selectedIDs: Set<UUID> = []
    @State private var selectedOrder: [UUID] = []
    @State private var selectionLimitMessage: String? = nil

    private let maxSelections = 10
    private let nearbyService = NearbyRestaurantService()

    private var selectedChoices: [RestaurantCandidate] {
        let lookup = Dictionary(uniqueKeysWithValues: availableChoices.map{($0.id, $0)})
        return selectedOrder.compactMap { lookup[$0] }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                Group {
                    if selectedSourceMode == .local {
                        if allRestaurants.isEmpty {
                            emptyState
                        } else {
                            content
                        }
                    } else {
                        nearbyContent
                    }
                }
            }
            .navigationTitle("Choose Lunch")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedSourceMode == .local {
                        Button("Refresh") {
                            loadLocalChoices()
                        }
                    } else {
                        Button("Search") {
                            Task { await loadNearbyChoices() }
                        }
                    }
                }
            }
            .onAppear {
                let savedMode = RestaurantSourceMode(rawValue: defaultSourceModeRawValue) ?? .local
                if selectedSourceMode != savedMode {
                    selectedSourceMode = savedMode
                }

                if savedMode == .local {
                    loadLocalChoices()
                } else {
                    availableChoices = []
                    selectedIDs = []
                    selectedOrder = []
                    nearbyErrorMessage = nil
                    nearbyStatusMessage = nil
                }
            }
            .onChange(of: selectedSourceMode) { _, newMode in
                selectedIDs = []
                selectedOrder = []

                switch newMode {
                case .local:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    loadLocalChoices()

                case .nearby:
                    availableChoices = []
                    nearbyErrorMessage = nil
                    nearbyStatusMessage = nil
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                guard selectedSourceMode == .nearby else { return }
                guard pendingNearbySearchAfterPermission else { return }

                switch newStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = "Permission granted. Starting nearby search..."
                    Task { await loadNearbyChoices() }

                case .denied, .restricted:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    nearbyErrorMessage = "Location access is denied. Enable it in Settings to use Nearby mode."

                case .notDetermined:
                    nearbyStatusMessage = "Waiting for location permission..."

                @unknown default:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    nearbyErrorMessage = "An unknown location authorization state occurred."
                }
            }
            .navigationDestination(isPresented: $showResult) {
                if let selectedCandidate {
                    ResultView(candidate: selectedCandidate)
                }
            }
            .sheet(isPresented: $showRoulette) {
                RouletteView(
                    choices: selectedChoices,
                    spinDuration: rouletteSpinDuration
                ) { winner in
                    selectedCandidate = winner
                    showResult = true
                }
            }
            .alert("Nearby Search", isPresented: Binding(
                get: { nearbyErrorMessage != nil },
                set: { newValue in
                    if !newValue { nearbyErrorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) { nearbyErrorMessage = nil }
            } message: {
                Text(nearbyErrorMessage ?? "")
            }
            .alert("Selection Limit", isPresented: Binding(
                get: { selectionLimitMessage != nil },
                set: { newValue in
                    if !newValue { selectionLimitMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) { selectionLimitMessage = nil }
            } message: {
                Text(selectionLimitMessage ?? "")
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            sourcePickerCard

            ContentUnavailableView(
                "No restaurants yet",
                systemImage: "fork.knife.circle",
                description: Text("Go to Restaurants to add places, then come back here to choose.")
            )
            .padding()

            Spacer()
        }
        .padding(.top, 8)
    }

    private var content: some View {
        VStack(spacing: 12) {
            sourcePickerCard
            selectionSummaryCard
            listContent
        }
        .padding(.top, 8)
    }

    private var nearbyContent: some View {
        VStack(spacing: 12) {
            sourcePickerCard

            if isLoadingNearby {
                nearbyStatusCard
                Spacer()
                ProgressView("Working...")
                Spacer()
            } else if availableChoices.isEmpty {
                VStack(spacing: 14) {
                    if nearbyStatusMessage != nil {
                        nearbyStatusCard
                    }

                    Spacer()

                    Image(systemName: "location.magnifyingglass")
                        .font(.system(size: 42))
                        .foregroundStyle(.orange)

                    Text("Find restaurants near you")
                        .font(.title3)
                        .fontWeight(.bold)

                    Text("Use your current location to find nearby restaurants for a random lunch pick.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Button {
                        Task { await loadNearbyChoices() }
                    } label: {
                        Label("Find Nearby Restaurants", systemImage: "location.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .accessibilityHint("Uses your current location to search for nearby restaurants.")

                    Spacer()
                }
            } else {
                VStack(spacing: 12) {
                    nearbyStatusCard
                    selectionSummaryCard
                    listContent
                }
            }
        }
        .padding(.top, 8)
    }

    private var listContent: some View {
        VStack(spacing: 12) {
            Text("Available choices: \(availableChoices.count)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            List {
                Section("Select up to 10 restaurants") {
                    ForEach(availableChoices) { candidate in
                        Button {
                            toggleSelection(for: candidate)
                        } label: {
                            RestaurantRow(
                                candidate: candidate,
                                isSavedLocally: isCandidateSavedLocally(candidate),
                                isSelected: selectedIDs.contains(candidate.id),
                                selectionMode: true,
                                isSelectionDisabled: selectedIDs.count >= maxSelections && !selectedIDs.contains(candidate.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("Selects or deselects this restaurant for the roulette.")
                    }
                }

                Section {
                    Button {
                        showRoulette = true
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "shuffle")
                            Text("Choose for me")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(selectedChoices.count < 2)
                    .accessibilityLabel("Choose a restaurant for me")
                    .accessibilityHint("Starts the roulette using the selected restaurants.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
    }

    private var sourcePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Restaurant source")
                .font(.headline)

            Picker("Restaurant source", selection: $selectedSourceMode) {
                ForEach(RestaurantSourceMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
        )
        .padding(.horizontal)
    }

    private var selectionSummaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Selected for roulette")
                    .font(.headline)

                Spacer()

                Text("\(selectedChoices.count) / \(maxSelections)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("\(selectedChoices.count) selected")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(selectedChoices.count == maxSelections
                                  ? Color.orange.opacity(0.18)
                                  : Color.secondary.opacity(0.12))
                    )
                    .foregroundStyle(selectedChoices.count == maxSelections ? .orange : .primary)
            }

            Text(selectedChoices.count < 2
                 ? "Select at least 2 restaurants to start the roulette."
                 : "Your selected restaurants will be used in the roulette.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if selectedChoices.count == maxSelections {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)

                    Text("Maximum selected")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 10) {
                Button("Clear selection") {
                    selectedIDs.removeAll()
                    selectedOrder.removeAll()
                }
                .disabled(selectedIDs.isEmpty)

                Spacer()

                Button {
                    showRoulette = true
                } label: {
                    Label("Choose for me", systemImage: "shuffle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedChoices.count < 2)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.thinMaterial)
        )
        .padding(.horizontal)
    }
    
    private var nearbyStatusCard: some View {
        Group {
            if let nearbyStatusMessage, !nearbyStatusMessage.isEmpty {
                HStack(spacing: 12) {
                    ProgressView()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Searching nearby")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(nearbyStatusMessage)
                            .font(.subheadline)
                    }

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.thinMaterial)
                )
                .padding(.horizontal)
            }
        }
    }

    @MainActor
    private func loadLocalChoices() {
        availableChoices = allRestaurants.map { RestaurantCandidate(from: $0) }
        selectedIDs.removeAll()
        selectedOrder.removeAll()
    }

    @ViewBuilder
    private func selectedChip(for candidate: RestaurantCandidate) -> some View {
        let orderIndex = (selectedOrder.firstIndex(of: candidate.id) ?? 0) + 1

        HStack(spacing: 6) {
            Text("\(orderIndex). \(candidate.name)")
                .font(.caption)
                .lineLimit(1)

            Button {
                selectedIDs.remove(candidate.id)
                selectedOrder.removeAll { $0 == candidate.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(candidate.name) from selection")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.16))
        )
    }
    
    private func loadNearbyChoices() async {
        isLoadingNearby = true
        nearbyErrorMessage = nil
        nearbyStatusMessage = "Preparing nearby search..."
        availableChoices = []
        selectedIDs = []
        selectedOrder = []

        defer { isLoadingNearby = false }

        do {
            nearbyStatusMessage = "Getting your current location..."
            let location = try await locationManager.requestCurrentLocation()

            nearbyStatusMessage = "Searching nearby restaurants..."
            let results = try await nearbyService.searchNearbyRestaurants(from: location, limit: 20)

            if results.isEmpty {
                nearbyStatusMessage = nil
                nearbyErrorMessage = "No nearby restaurants were found for your current location."
            } else {
                availableChoices = results
                syncSelectionOrder()
                nearbyStatusMessage = "Found \(results.count) nearby restaurant\(results.count == 1 ? "" : "s")."
            }
        } catch let error as LocationError {
            switch error {
            case .waitingForPermission:
                pendingNearbySearchAfterPermission = true
                nearbyStatusMessage = "Requesting location permission..."
                locationManager.requestPermissionIfNeeded()

            case .permissionDenied, .locationUnavailable, .unknown:
                pendingNearbySearchAfterPermission = false
                nearbyStatusMessage = nil
                nearbyErrorMessage = error.localizedDescription
            }
        } catch {
            pendingNearbySearchAfterPermission = false
            nearbyStatusMessage = nil
            nearbyErrorMessage = error.localizedDescription
        }
    }

    private func toggleSelection(for candidate: RestaurantCandidate) {
        if selectedIDs.contains(candidate.id) {
            selectedIDs.remove(candidate.id)
            selectedOrder.removeAll { $0 == candidate.id }
            return
        }

        guard selectedIDs.count < maxSelections else {
            selectionLimitMessage = "You can select up to 10 restaurants."
            return
        }

        selectedIDs.insert(candidate.id)
        selectedOrder.append(candidate.id)
    }

    private func syncSelectionOrder() {
        let availableIDSet = Set(availableChoices.map(\.id))
        selectedIDs = selectedIDs.intersection(availableIDSet)
        selectedOrder = selectedOrder.filter { availableIDSet.contains($0) && selectedIDs.contains($0) }
    }
    
    @MainActor
    private func isCandidateSavedLocally(_ candidate: RestaurantCandidate) -> Bool {
        guard candidate.source == .nearby else { return false }

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
}
