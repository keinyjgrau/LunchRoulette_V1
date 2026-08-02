//
//  PickView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI
import SwiftData
import CoreLocation

private struct RouletteSession: Identifiable {
    let id = UUID()
    let choices: [RestaurantCandidate]
}

struct PickView: View {
    @AppStorage("appLanguage")
    private var appLanguage = AppLanguageOption.system.rawValue

    @AppStorage("rouletteSpinDuration")
    private var rouletteSpinDuration = 2.8

    @Environment(\.modelContext)
    private var modelContext

    @Query(sort: \Restaurant.createdAt, order: .reverse)
    private var allRestaurants: [Restaurant]

    @State private var locationProvider = PickLocationProvider()
    @State private var selectedSource: RestaurantCandidateSource = .local

    @State private var rawNearbyChoices: [RestaurantCandidate] = []
    @State private var isSearchingNearby = false
    @State private var nearbyError: String?

    @State private var selectedIDs: Set<RestaurantCandidateID> = []
    @State private var selectedOrder: [RestaurantCandidateID] = []

    @State private var useDistanceFilter = false
    @State private var nearbyDistanceLimit = 10.0
    @State private var useCategoryFilter = false
    @State private var selectedCategory = "Any"
    @State private var useRatingFilter = false
    @State private var selectedMinimumRating = 0.0

    @State private var showSelectionLimitAlert = false
    @State private var saveMessage: String?

    @State private var rouletteSession: RouletteSession?
    @State private var pendingWinner: RestaurantCandidate?
    @State private var resultCandidate: RestaurantCandidate?
    @State private var lastWinnerRepeatKey: String?

    private let maxSelections = 10
    private let minSelections = 2

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(spacing: 16) {
                        sourcePickerSection

                        if selectedSource == .nearby {
                            nearbySearchSection
                            nearbyFiltersSection
                        }

                        selectedRestaurantsSection
                        restaurantSelectionSection
                        spinButtonSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 26)
                }
            }
            .navigationTitle(t("Choose Lunch", "Elegir almuerzo"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if selectedSource == .nearby && rawNearbyChoices.isEmpty {
                    await searchNearbyRestaurants(force: false)
                }
            }
            .onChange(of: selectedSource) { _, newValue in
                clearSelection()

                if newValue == .nearby && rawNearbyChoices.isEmpty {
                    Task {
                        await searchNearbyRestaurants(force: false)
                    }
                }
            }
            .onChange(of: useDistanceFilter) { _, _ in
                pruneSelectionToAvailable()
            }
            .onChange(of: nearbyDistanceLimit) { _, _ in
                pruneSelectionToAvailable()
            }
            .onChange(of: useCategoryFilter) { _, _ in
                pruneSelectionToAvailable()
            }
            .onChange(of: selectedCategory) { _, _ in
                pruneSelectionToAvailable()
            }
            .onChange(of: useRatingFilter) { _, _ in
                pruneSelectionToAvailable()
            }
            .onChange(of: selectedMinimumRating) { _, _ in
                pruneSelectionToAvailable()
            }
            .alert(
                t("Selection limit", "Límite de selección"),
                isPresented: $showSelectionLimitAlert
            ) {
                Button(t("OK", "OK"), role: .cancel) {}
            } message: {
                Text(
                    t(
                        "You can select up to 10 restaurants.",
                        "Puedes seleccionar hasta 10 restaurantes."
                    )
                )
            }
            .alert(
                t("Save restaurant", "Guardar restaurante"),
                isPresented: Binding(
                    get: { saveMessage != nil },
                    set: { isPresented in
                        if !isPresented {
                            saveMessage = nil
                        }
                    }
                )
            ) {
                Button(t("OK", "OK"), role: .cancel) {
                    saveMessage = nil
                }
            } message: {
                Text(saveMessage ?? "")
            }
            .sheet(item: $rouletteSession, onDismiss: presentPendingWinner) { session in
                RouletteView(
                    choices: session.choices,
                    spinDuration: rouletteSpinDuration,
                    lastWinnerRepeatKey: lastWinnerRepeatKey
                ) { winner in
                    lastWinnerRepeatKey = winner.repeatKey
                    pendingWinner = winner
                    rouletteSession = nil
                }
                .interactiveDismissDisabled(true)
            }
            .navigationDestination(item: $resultCandidate) { candidate in
                ResultView(candidate: candidate)
            }
        }
    }

    // MARK: - Main Sections

    private var sourcePickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(t("Restaurant source", "Fuente de restaurantes"))
                .font(.headline)

            Picker(
                t("Restaurant source", "Fuente de restaurantes"),
                selection: $selectedSource
            ) {
                Text(t("Local", "Local"))
                    .tag(RestaurantCandidateSource.local)

                Text(t("Nearby", "Cercanos"))
                    .tag(RestaurantCandidateSource.nearby)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .cardBackground()
    }

    private var nearbySearchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t("Nearby restaurants", "Restaurantes cercanos"))
                        .font(.headline)

                    Text(
                        t(
                            "Search Apple Maps for restaurants near you.",
                            "Busca restaurantes cerca de ti usando Apple Maps."
                        )
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    Task {
                        await searchNearbyRestaurants(force: true)
                    }
                } label: {
                    if isSearchingNearby {
                        ProgressView()
                            .frame(width: 34, height: 34)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.headline)
                            .frame(width: 34, height: 34)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isSearchingNearby)
            }

            if let nearbyError {
                Text(nearbyError)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            if !rawNearbyChoices.isEmpty {
                Text(
                    t(
                        "\(rawNearbyChoices

