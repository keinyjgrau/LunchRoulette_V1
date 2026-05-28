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
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue

    @Query(sort: \Restaurant.createdAt, order: .reverse) private var allRestaurants: [Restaurant]

    @StateObject private var locationManager = AppLocationManager()

    @AppStorage("defaultSourceMode") private var defaultSourceModeRawValue: String = RestaurantSourceMode.local.rawValue
    @AppStorage("rouletteSpinDuration") private var rouletteSpinDuration: Double = 2.8

    @State private var rawLocalChoices: [RestaurantCandidate] = []
    @State private var rawNearbyChoices: [RestaurantCandidate] = []
    @State private var availableChoices: [RestaurantCandidate] = []

    @State private var selectedCandidate: RestaurantCandidate? = nil
    @State private var showResult = false
    @State private var showRoulette = false
    @State private var lastWinnerRepeatKey: String? = nil

    @State private var selectedSourceMode: RestaurantSourceMode = .local

    @State private var isLoadingNearby = false
    @State private var nearbyErrorMessage: String? = nil
    @State private var pendingNearbySearchAfterPermission = false
    @State private var nearbyStatusMessage: String? = nil

    @State private var selectedIDs: Set<UUID> = []
    @State private var selectedOrder: [UUID] = []
    @State private var selectionLimitMessage: String? = nil

    @State private var isDistanceFilterOn = false
    @State private var isCategoryFilterOn = false
    @State private var isRatingFilterOn = false

    @State private var nearbyDistanceLimit: Double = 25
    @State private var selectedCategory: String = "Any"
    @State private var minimumRating: Double = 0

    private let maxSelections = 10
    private let nearbyService = NearbyRestaurantService()

    private var selectedChoices: [RestaurantCandidate] {
        let lookup = Dictionary(uniqueKeysWithValues: availableChoices.map { ($0.id, $0) })
        return selectedOrder.compactMap { lookup[$0] }
    }

    private var currentRawChoices: [RestaurantCandidate] {
        selectedSourceMode == .local ? rawLocalChoices : rawNearbyChoices
    }

    private var categoryOptions: [String] {
        let categories: [String] = currentRawChoices.compactMap { candidate in
            guard let value = candidate.foodType?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !value.isEmpty else {
                return nil
            }
            return value
        }

        return [AppText.any(appLanguage)] + Array(Set(categories)).sorted()
    }

    private var anyFilterOn: Bool {
        isDistanceFilterOn || isCategoryFilterOn || isRatingFilterOn
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
            .navigationTitle(AppText.chooseLunchTitle(appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if selectedSourceMode == .local {
                        Button(AppText.refresh(appLanguage)) {
                            loadLocalChoices()
                        }
                    } else {
                        Button(AppText.search(appLanguage)) {
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
                    rawLocalChoices = []
                    rawNearbyChoices = []
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
                selectedCategory = AppText.any(appLanguage)
                minimumRating = 0

                switch newMode {
                case .local:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    nearbyErrorMessage = nil
                    loadLocalChoices()

                case .nearby:
                    rawNearbyChoices = []
                    availableChoices = []
                    nearbyErrorMessage = nil
                    nearbyStatusMessage = nil
                    applyActiveFilters()
                }
            }
            .onChange(of: appLanguage) { _, _ in
                if selectedCategory == "Any" || selectedCategory == "Cualquiera" {
                    selectedCategory = AppText.any(appLanguage)
                }
            }
            .onChange(of: locationManager.authorizationStatus) { _, newStatus in
                guard selectedSourceMode == .nearby else { return }
                guard pendingNearbySearchAfterPermission else { return }

                switch newStatus {
                case .authorizedWhenInUse, .authorizedAlways:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = AppText.permissionGranted(appLanguage)
                    Task { await loadNearbyChoices() }

                case .denied, .restricted:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    nearbyErrorMessage = AppText.locationDenied(appLanguage)

                case .notDetermined:
                    nearbyStatusMessage = AppText.waitingPermission(appLanguage)

                @unknown default:
                    pendingNearbySearchAfterPermission = false
                    nearbyStatusMessage = nil
                    nearbyErrorMessage = AppText.locationDenied(appLanguage)
                }
            }
            .onChange(of: isDistanceFilterOn) { _, _ in applyActiveFilters() }
            .onChange(of: isCategoryFilterOn) { _, _ in applyActiveFilters() }
            .onChange(of: isRatingFilterOn) { _, _ in applyActiveFilters() }
            .onChange(of: nearbyDistanceLimit) { _, _ in applyActiveFilters() }
            .onChange(of: selectedCategory) { _, _ in applyActiveFilters() }
            .onChange(of: minimumRating) { _, _ in applyActiveFilters() }
            .navigationDestination(isPresented: $showResult) {
                if let selectedCandidate {
                    ResultView(candidate: selectedCandidate)
                }
            }
            .sheet(isPresented: $showRoulette) {
                RouletteView(
                    choices: selectedChoices,
                    spinDuration: rouletteSpinDuration,
                    lastWinnerRepeatKey: lastWinnerRepeatKey
                ) { winner in
                    selectedCandidate = winner
                    lastWinnerRepeatKey = winner.repeatKey
                    showResult = true
                }
            }
            .alert(AppText.nearbySearchTitle(appLanguage), isPresented: Binding(
                get: { nearbyErrorMessage != nil },
                set: { newValue in
                    if !newValue { nearbyErrorMessage = nil }
                }
            )) {
                Button("OK", role: .cancel) { nearbyErrorMessage = nil }
            } message: {
                Text(nearbyErrorMessage ?? "")
            }
            .alert(AppText.selectionLimitTitle(appLanguage), isPresented: Binding(
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
            filtersCard

            ContentUnavailableView(
                AppText.noRestaurantsYet(appLanguage),
                systemImage: "fork.knife.circle",
                description: Text(AppText.noRestaurantsDesc(appLanguage))
            )
            .padding()

            Spacer()
        }
        .padding(.top, 8)
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 12) {
                sourcePickerCard
                filtersCard
                selectionSummaryCard
                restaurantSelectionSection
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var nearbyContent: some View {
        Group {
            if isLoadingNearby {
                ScrollView {
                    VStack(spacing: 12) {
                        sourcePickerCard
                        filtersCard
                        nearbyStatusCard

                        VStack(spacing: 16) {
                            Spacer(minLength: 20)
                            ProgressView(AppText.working(appLanguage))
                            Spacer(minLength: 20)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            } else if availableChoices.isEmpty {
                ScrollView {
                    VStack(spacing: 14) {
                        sourcePickerCard
                        filtersCard

                        if nearbyStatusMessage != nil {
                            nearbyStatusCard
                        }

                        Spacer(minLength: 20)

                        Image(systemName: "location.magnifyingglass")
                            .font(.system(size: 42))
                            .foregroundStyle(.orange)

                        Text(AppText.findRestaurantsNearYou(appLanguage))
                            .font(.title3)
                            .fontWeight(.bold)

                        Text(AppText.nearbyIntro(appLanguage))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        Button {
                            Task { await loadNearbyChoices() }
                        } label: {
                            Label(AppText.findNearbyRestaurants(appLanguage), systemImage: "location.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal)

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        sourcePickerCard
                        filtersCard
                        nearbyStatusCard
                        selectionSummaryCard
                        restaurantSelectionSection
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private var restaurantSelectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppText.availableChoices(availableChoices.count, appLanguage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                HStack {
                    Text(AppText.selectUpToTen(appLanguage))
                        .font(.headline)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)

                LazyVStack(spacing: 0) {
                    ForEach(Array(availableChoices.enumerated()), id: \.element.id) { index, candidate in
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
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < availableChoices.count - 1 {
                            Divider()
                                .padding(.leading, 70)
                                .padding(.trailing, 14)
                        }
                    }
                }

                Divider()
                    .padding(.top, 2)

                Button {
                    showRoulette = true
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "shuffle")
                        Text(AppText.chooseForMe(appLanguage))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .disabled(selectedChoices.count < 2)
                .opacity(selectedChoices.count < 2 ? 0.45 : 1.0)
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
            )
            .padding(.horizontal)
        }
    }

    private var sourcePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.restaurantSource(appLanguage))
                .font(.headline)

            Picker(AppText.restaurantSource(appLanguage), selection: $selectedSourceMode) {
                ForEach(RestaurantSourceMode.allCases) { mode in
                    Text(mode.rawValue == "Local" ? AppText.local(appLanguage) : AppText.nearby(appLanguage)).tag(mode)
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

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppText.filters(appLanguage))
                .font(.headline)

            if selectedSourceMode == .nearby {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(AppText.distance(appLanguage))
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Spacer()

                        Toggle("", isOn: $isDistanceFilterOn)
                            .labelsHidden()
                    }

                    if isDistanceFilterOn {
                        HStack {
                            Text("\(Int(nearbyDistanceLimit)) mi")
                                .foregroundStyle(.secondary)
                            Spacer()
                        }

                        Slider(value: $nearbyDistanceLimit, in: 1...100, step: 1)

                        HStack {
                            Text("1 mi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("100 mi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(AppText.category(appLanguage))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Toggle("", isOn: $isCategoryFilterOn)
                        .labelsHidden()
                }

                if isCategoryFilterOn {
                    Picker(AppText.category(appLanguage), selection: $selectedCategory) {
                        ForEach(categoryOptions, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(AppText.minimumRating(appLanguage))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    Toggle("", isOn: $isRatingFilterOn)
                        .labelsHidden()
                }

                if isRatingFilterOn {
                    Picker(AppText.minimumRating(appLanguage), selection: $minimumRating) {
                        Text(AppText.any(appLanguage)).tag(0.0)
                        Text("3.0+").tag(3.0)
                        Text("4.0+").tag(4.0)
                        Text("4.5+").tag(4.5)
                    }
                    .pickerStyle(.segmented)
                }
            }

            if !anyFilterOn {
                Text(AppText.turnOnFilters(appLanguage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
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
                Text(AppText.selectedForRoulette(appLanguage))
                    .font(.headline)

                Spacer()

                Text("\(selectedChoices.count) / \(maxSelections)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(AppText.selectedCountLabel(selectedChoices.count, appLanguage))
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
                 ? AppText.needAtLeastTwo(appLanguage)
                 : AppText.selectedWillBeUsed(appLanguage))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !selectedChoices.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedChoices) { candidate in
                            selectedChip(for: candidate)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            if selectedChoices.count == maxSelections {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)

                    Text(AppText.maximumSelected(appLanguage))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.orange)
                }
            }

            HStack(spacing: 10) {
                Button(AppText.clearSelection(appLanguage)) {
                    selectedIDs.removeAll()
                    selectedOrder.removeAll()
                }
                .disabled(selectedIDs.isEmpty)

                Spacer()

                Button {
                    showRoulette = true
                } label: {
                    Label(AppText.chooseForMe(appLanguage), systemImage: "shuffle")
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
                        Text(AppText.searchingNearby(appLanguage))
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
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.16))
        )
    }

    @MainActor
    private func loadLocalChoices() {
        rawLocalChoices = allRestaurants.map { RestaurantCandidate(from: $0) }
        rawNearbyChoices = []
        selectedIDs.removeAll()
        selectedOrder.removeAll()
        applyActiveFilters()
    }

    private func loadNearbyChoices() async {
        isLoadingNearby = true
        nearbyErrorMessage = nil
        nearbyStatusMessage = AppText.preparingNearbySearch(appLanguage)
        availableChoices = []
        rawNearbyChoices = []
        selectedIDs = []
        selectedOrder = []

        defer { isLoadingNearby = false }

        do {
            nearbyStatusMessage = AppText.gettingCurrentLocation(appLanguage)
            let location = try await locationManager.requestCurrentLocation()

            nearbyStatusMessage = AppText.searchingNearbyRestaurants(appLanguage)
            let results = try await nearbyService.searchNearbyRestaurants(from: location, limit: 50)

            rawNearbyChoices = results
            applyActiveFilters()

            if availableChoices.isEmpty {
                nearbyStatusMessage = nil
                nearbyErrorMessage = anyFilterOn
                    ? AppText.noNearbyMatchedFilters(appLanguage)
                    : AppText.noNearbyFound(appLanguage)
            } else {
                nearbyStatusMessage = AppText.foundNearbyCount(availableChoices.count, appLanguage)
            }
        } catch let error as LocationError {
            switch error {
            case .waitingForPermission:
                pendingNearbySearchAfterPermission = true
                nearbyStatusMessage = AppText.requestLocationPermission(appLanguage)
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

    private func applyActiveFilters() {
        let base = currentRawChoices

        let filtered = base.filter { candidate in
            if selectedSourceMode == .nearby && isDistanceFilterOn {
                guard let distance = candidate.distanceMiles, distance <= nearbyDistanceLimit else {
                    return false
                }
            }

            if isCategoryFilterOn && selectedCategory != AppText.any(appLanguage) {
                guard let category = candidate.foodType, category == selectedCategory else {
                    return false
                }
            }

            if isRatingFilterOn && minimumRating > 0 {
                guard let rating = candidate.rating, rating >= minimumRating else {
                    return false
                }
            }

            return true
        }

        availableChoices = filtered
        syncSelectionOrder()

        if selectedSourceMode == .nearby, !isLoadingNearby, !rawNearbyChoices.isEmpty {
            if availableChoices.isEmpty {
                nearbyStatusMessage = nil
                nearbyErrorMessage = anyFilterOn
                    ? AppText.noNearbyMatchedFilters(appLanguage)
                    : AppText.noNearbyFound(appLanguage)
            } else {
                nearbyErrorMessage = nil
                nearbyStatusMessage = AppText.foundNearbyCount(availableChoices.count, appLanguage)
            }
        }
    }

    private func toggleSelection(for candidate: RestaurantCandidate) {
        if selectedIDs.contains(candidate.id) {
            selectedIDs.remove(candidate.id)
            selectedOrder.removeAll { $0 == candidate.id }
            return
        }

        guard selectedIDs.count < maxSelections else {
            selectionLimitMessage = AppText.selectionLimitMessage(appLanguage)
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
