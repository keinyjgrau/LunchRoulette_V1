//
//  ManageRestaurantsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI
import SwiftData

struct ManageRestaurantsView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue

    @Query(sort: \Restaurant.createdAt, order: .reverse) private var restaurants: [Restaurant]
    @Environment(\.modelContext) private var modelContext

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                Group {
                    if restaurants.isEmpty {
                        ContentUnavailableView(
                            AppText.noRestaurantsYet(appLanguage),
                            systemImage: "plus.app",
                            description: Text(AppText.noRestaurantsDesc(appLanguage))
                        )
                        .padding()
                    } else {
                        List {
                            ForEach(restaurants) { restaurant in
                                NavigationLink {
                                    EditRestaurantView(restaurant: restaurant)
                                } label: {
                                    RestaurantRow(candidate: RestaurantCandidate(from: restaurant))
                                }
                            }
                            .onDelete(perform: deleteRestaurants)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle(AppText.restaurants(appLanguage))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(AppText.addRestaurant(appLanguage))
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    AddRestaurantView()
                }
            }
        }
    }

    private func deleteRestaurants(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(restaurants[index])
        }
    }
}
