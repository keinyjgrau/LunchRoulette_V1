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
                        "\(rawNearbyChoices.count) nearby restaurants found",
                        "\(rawNearbyChoices.count) restaurantes cercanos encontrados"
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .cardBackground()
    }

    private var nearbyFiltersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(t("Filters", "Filtros"))
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Toggle(t("Distance", "Distancia"), isOn: $useDistanceFilter)

                if useDistanceFilter {
                    HStack {
                        Text(t("Within", "Hasta"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(Int(nearbyDistanceLimit)) mi")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }

                    Slider(
                        value: $nearbyDistanceLimit,
                        in: 1...100,
                        step: 1
                    )
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Toggle(t("Category", "Categoría"), isOn: $useCategoryFilter)

                if useCategoryFilter {
                    Picker(
                        t("Category", "Categoría"),
                        selection: $selectedCategory
                    ) {
                        ForEach(categoryOptions, id: \.self) { category in
                            Text(category)
                                .tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Toggle(t("Rating", "Calificación"), isOn: $useRatingFilter)

                if useRatingFilter {
                    Picker(
                        t("Minimum rating", "Calificación mínima"),
                        selection: $selectedMinimumRating
                    ) {
                        Text(t("Any", "Cualquiera")).tag(0.0)
                        Text("3.0+").tag(3.0)
                        Text("4.0+").tag(4.0)
                        Text("4.5+").tag(4.5)
                    }
                    .pickerStyle(.segmented)

                    Text(
                        t(
                            "Ratings appear only when Apple Maps provides them.",
                            "Las calificaciones aparecen solo cuando Apple Maps las provee."
                        )
                    )
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .cardBackground()
    }

    private var selectedRestaurantsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(t("Selected", "Seleccionados"))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        clearSelection()
                    }
                } label: {
                    Label(
                        t("Clear", "Limpiar"),
                        systemImage: "arrow.counterclockwise"
                    )
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .foregroundStyle(
                        selectedChoices.isEmpty
                        ? Color.secondary
                        : Color.orange
                    )
                    .background(
                        Capsule()
                            .fill(
                                Color.orange.opacity(
                                    selectedChoices.isEmpty ? 0.06 : 0.14
                                )
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(selectedChoices.isEmpty)
                .accessibilityLabel(
                    t("Clear all selections", "Borrar todas las selecciones")
                )

                Text("\(selectedChoices.count)/\(maxSelections)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(
                        selectedChoices.count >= maxSelections
                        ? .orange
                        : .secondary
                    )
            }

            if selectedChoices.isEmpty {
                Text(
                    t(
                        "Select at least 2 restaurants to spin.",
                        "Selecciona al menos 2 restaurantes para girar."
                    )
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(
                        Array(selectedChoices.enumerated()),
                        id: \.element.id
                    ) { index, candidate in
                        selectedChip(
                            index: index + 1,
                            candidate: candidate
                        )
                    }
                }
            }

            if selectedChoices.count >= maxSelections {
                Text(t("Maximum selected", "Máximo seleccionado"))
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(16)
        .cardBackground()
    }

    private var restaurantSelectionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(
                    selectedSource == .local
                    ? t("Your restaurants", "Tus restaurantes")
                    : t("Nearby list", "Lista cercana")
                )
                .font(.headline)

                Spacer()

                Text("\(availableChoices.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if availableChoices.isEmpty {
                emptyStateView
                    .padding(16)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(
                        Array(availableChoices.enumerated()),
                        id: \.element.id
                    ) { index, candidate in
                        let isSaved = isCandidateSavedLocally(candidate)

                        HStack(spacing: 8) {
                            Button {
                                toggleSelection(for: candidate)
                            } label: {
                                RestaurantRow(
                                    candidate: candidate,
                                    isSavedLocally: isSaved,
                                    isSelected: selectedIDs.contains(candidate.id),
                                    selectionMode: true,
                                    isSelectionDisabled:
                                        selectedIDs.count >= maxSelections
                                        && !selectedIDs.contains(candidate.id)
                                )
                                .padding(.leading, 14)
                                .padding(.vertical, 10)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .frame(maxWidth: .infinity, alignment: .leading)

                            if candidate.source == .nearby {
                                saveNearbyButton(
                                    for: candidate,
                                    isSaved: isSaved
                                )
                                .padding(.trailing, 14)
                            }
                        }

                        if index < availableChoices.count - 1 {
                            Divider()
                                .padding(.leading, 70)
                                .padding(.trailing, 14)
                        }
                    }
                }
            }
        }
        .cardBackground()
    }

    private var spinButtonSection: some View {
        Button {
            startRoulette()
        } label: {
            HStack {
                Image(systemName: "sparkles")

                Text(t("Choose for me", "Escoge por mí"))
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(.orange)
        .disabled(selectedChoices.count < minSelections)
        .opacity(selectedChoices.count < minSelections ? 0.55 : 1)
    }

    private var emptyStateView: some View {
        VStack(spacing: 10) {
            Image(
                systemName:
                    selectedSource == .local
                    ? "fork.knife.circle"
                    : "location.circle"
            )
            .font(.largeTitle)
            .foregroundStyle(.secondary)

            Text(emptyStateTitle)
                .font(.headline)

            Text(emptyStateSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if selectedSource == .nearby {
                Button {
                    Task {
                        await searchNearbyRestaurants(force: true)
                    }
                } label: {
                    Text(t("Search nearby", "Buscar cercanos"))
                }
                .buttonStyle(.bordered)
                .disabled(isSearchingNearby)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    // MARK: - Small Views

    private func selectedChip(
        index: Int,
        candidate: RestaurantCandidate
    ) -> some View {
        HStack(spacing: 6) {
            Text("\(index). \(candidate.name)")
                .font(.caption)
                .fontWeight(.semibold)
                .lineLimit(1)

            Button {
                removeSelection(for: candidate)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func saveNearbyButton(
        for candidate: RestaurantCandidate,
        isSaved: Bool
    ) -> some View {
        Button {
            saveCandidateToLocal(candidate)
        } label: {
            Image(
                systemName:
                    isSaved
                    ? "checkmark.circle.fill"
                    : "plus.circle.fill"
            )
            .font(.title3)
            .foregroundStyle(isSaved ? .green : .orange)
            .frame(width: 38, height: 38)
            .background(
                Circle()
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaved)
        .accessibilityLabel(
            isSaved
            ? t("Saved", "Guardado")
            : t("Save restaurant", "Guardar restaurante")
        )
    }

    // MARK: - Data

    private var rawLocalChoices: [RestaurantCandidate] {
        allRestaurants.map { restaurant in
            RestaurantCandidate(from: restaurant)
        }
    }

    private var availableChoices: [RestaurantCandidate] {
        switch selectedSource {
        case .local:
            rawLocalChoices

        case .nearby:
            filteredNearbyChoices
        }
    }

    private var filteredNearbyChoices: [RestaurantCandidate] {
        rawNearbyChoices.filter { candidate in
            if useDistanceFilter {
                guard let distance = candidate.distanceMiles else {
                    return false
                }

                if distance > nearbyDistanceLimit {
                    return false
                }
            }

            if useCategoryFilter && selectedCategory != "Any" {
                guard
                    let foodType = FoodTypeFormatter.clean(candidate.foodType),
                    foodType == selectedCategory
                else {
                    return false
                }
            }

            if useRatingFilter && selectedMinimumRating > 0 {
                guard let rating = candidate.rating else {
                    return false
                }

                if rating < selectedMinimumRating {
                    return false
                }
            }

            return true
        }
    }

    private var selectedChoices: [RestaurantCandidate] {
        selectedOrder.compactMap { selectedID in
            availableChoices.first { candidate in
                candidate.id == selectedID
            }
        }
    }

    private var categoryOptions: [String] {
        let categories: [String] = rawNearbyChoices
            .compactMap { FoodTypeFormatter.clean($0.foodType) }
            .filter { !$0.isEmpty }

        return ["Any"] + Array(Set(categories)).sorted()
    }

    // MARK: - Actions

    private func toggleSelection(for candidate: RestaurantCandidate) {
        if selectedIDs.contains(candidate.id) {
            removeSelection(for: candidate)
            return
        }

        guard selectedIDs.count < maxSelections else {
            showSelectionLimitAlert = true
            return
        }

        selectedIDs.insert(candidate.id)
        selectedOrder.append(candidate.id)
    }

    private func removeSelection(for candidate: RestaurantCandidate) {
        selectedIDs.remove(candidate.id)
        selectedOrder.removeAll { $0 == candidate.id }
    }

    private func clearSelection() {
        selectedIDs.removeAll()
        selectedOrder.removeAll()
    }

    private func pruneSelectionToAvailable() {
        let validIDs = Set(availableChoices.map(\.id))

        selectedIDs = selectedIDs.intersection(validIDs)
        selectedOrder.removeAll { !validIDs.contains($0) }
    }

    private func startRoulette() {
        let currentAvailableChoices = availableChoices

        let choices = selectedOrder.compactMap { selectedID in
            currentAvailableChoices.first { candidate in
                candidate.id == selectedID
            }
        }

        guard choices.count >= minSelections else {
            return
        }

        rouletteSession = RouletteSession(choices: choices)
    }

    private func presentPendingWinner() {
        guard let pendingWinner else {
            return
        }

        resultCandidate = pendingWinner
        self.pendingWinner = nil
    }

    private func searchNearbyRestaurants(force: Bool) async {
        if isSearchingNearby {
            return
        }

        if !force && !rawNearbyChoices.isEmpty {
            return
        }

        isSearchingNearby = true
        nearbyError = nil

        defer {
            isSearchingNearby = false
        }

        do {
            let location = try await locationProvider.currentLocation()

            let results = try await NearbyRestaurantService()
                .searchNearbyRestaurants(
                    from: location,
                    limit: 50
                )

            rawNearbyChoices = results
            pruneSelectionToAvailable()
        } catch {
            nearbyError = error.localizedDescription
        }
    }

    private func saveCandidateToLocal(_ candidate: RestaurantCandidate) {
        guard candidate.source == .nearby else {
            return
        }

        if isCandidateSavedLocally(candidate) {
            saveMessage = t(
                "This restaurant is already in your local list.",
                "Este restaurante ya está en tu lista local."
            )
            return
        }

        let restaurant = Restaurant(
            name: candidate.name,
            detailsText: candidate.detailsText,
            foodType: FoodTypeFormatter.clean(candidate.foodType),
            avgCost: candidate.avgCost,
            address: candidate.address,
            rating: candidate.rating,
            frequency: candidate.frequency,
            distanceMiles: candidate.distanceMiles,
            latitude: candidate.latitude,
            longitude: candidate.longitude,
            photoData: candidate.photoData
        )

        modelContext.insert(restaurant)

        do {
            try modelContext.save()

            saveMessage = t(
                "Saved to your local list.",
                "Guardado en tu lista local."
            )
        } catch {
            modelContext.delete(restaurant)

            saveMessage = t(
                "The restaurant could not be saved.",
                "No se pudo guardar el restaurante."
            )
        }
    }

    private func isCandidateSavedLocally(
        _ candidate: RestaurantCandidate
    ) -> Bool {
        if candidate.source == .local {
            return true
        }

        let candidateName = normalized(candidate.name)
        let candidateAddress = normalized(candidate.address)

        return allRestaurants.contains { restaurant in
            let localName = normalized(restaurant.name)
            let localAddress = normalized(restaurant.address)

            if !candidateAddress.isEmpty {
                return localName == candidateName
                    && localAddress == candidateAddress
            }

            return localName == candidateName
        }
    }

    // MARK: - Text Helpers

    private var emptyStateTitle: String {
        if selectedSource == .local {
            return t(
                "No local restaurants yet",
                "Todavía no tienes restaurantes locales"
            )
        }

        if isSearchingNearby {
            return t(
                "Searching nearby...",
                "Buscando cercanos..."
            )
        }

        return t(
            "No nearby restaurants found",
            "No se encontraron restaurantes cercanos"
        )
    }

    private var emptyStateSubtitle: String {
        if selectedSource == .local {
            return t(
                "Add restaurants in the Restaurants tab first.",
                "Primero añade restaurantes en la pestaña Restaurantes."
            )
        }

        return t(
            "Try searching again or increasing your distance filter.",
            "Intenta buscar de nuevo o aumentar el filtro de distancia."
        )
    }

    private func t(
        _ english: String,
        _ spanish: String
    ) -> String {
        if appLanguage == AppLanguageOption.spanish.rawValue {
            return spanish
        }

        if appLanguage == AppLanguageOption.english.rawValue {
            return english
        }

        let preferredLanguage =
            Locale.preferredLanguages.first?.lowercased() ?? ""

        return preferredLanguage.hasPrefix("es")
            ? spanish
            : english
    }

    private func normalized(_ value: String?) -> String {
        value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            ) ?? ""
    }
}

// MARK: - Card Style

private extension View {
    func cardBackground() -> some View {
        background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(0.22),
                lineWidth: 1
            )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 14,
            x: 0,
            y: 8
        )
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? 0

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return CGSize(
            width: maxWidth,
            height: currentY + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > bounds.maxX
                && currentX > bounds.minX {
                currentX = bounds.minX
                currentY += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(
                at: CGPoint(
                    x: currentX,
                    y: currentY
                ),
                proposal: ProposedViewSize(size)
            )

            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - Location Provider

@MainActor
private final class PickLocationProvider:
    NSObject,
    CLLocationManagerDelegate {

    private let manager = CLLocationManager()

    private var continuation:
        CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func currentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            guard self.continuation == nil else {
                continuation.resume(
                    throwing: PickLocationError.requestAlreadyInProgress
                )
                return
            }

            self.continuation = continuation

            guard CLLocationManager.locationServicesEnabled() else {
                finish(
                    with: .failure(
                        PickLocationError.locationServicesDisabled
                    )
                )
                return
            }

            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()

            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()

            case .denied, .restricted:
                finish(
                    with: .failure(
                        PickLocationError.permissionDenied
                    )
                )

            @unknown default:
                finish(
                    with: .failure(
                        PickLocationError.unknown
                    )
                )
            }
        }
    }

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .denied, .restricted:
            finish(
                with: .failure(
                    PickLocationError.permissionDenied
                )
            )

        default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            finish(
                with: .failure(
                    PickLocationError.locationUnavailable
                )
            )
            return
        }

        finish(with: .success(location))
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        finish(with: .failure(error))
    }

    private func finish(
        with result: Result<CLLocation, Error>
    ) {
        guard let continuation else {
            return
        }

        self.continuation = nil

        switch result {
        case .success(let location):
            continuation.resume(returning: location)

        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

private enum PickLocationError: LocalizedError {
    case locationServicesDisabled
    case permissionDenied
    case locationUnavailable
    case requestAlreadyInProgress
    case unknown

    var errorDescription: String? {
        switch self {
        case .locationServicesDisabled:
            return "Location services are disabled."

        case .permissionDenied:
            return "Location permission is required to search nearby restaurants."

        case .locationUnavailable:
            return "Could not find your current location."

        case .requestAlreadyInProgress:
            return "A location request is already in progress."

        case .unknown:
            return "Could not access your location."
        }
    }
}
