//
//  ManageRestaurantsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI
import SwiftData

struct ManageRestaurantsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Restaurant.createdAt, order: .reverse) private var restaurants: [Restaurant]

    @State private var showingAdd = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                Group {
                    if restaurants.isEmpty {
                        ContentUnavailableView(
                            "No restaurants yet",
                            systemImage: "plus.app",
                            description: Text("Tap + to add your first restaurant.")
                        )
                        .padding()
                    } else {
                        List {
                            ForEach(restaurants) { r in
                                NavigationLink {
                                    EditRestaurantView(restaurant: r)
                                } label: {
                                    RestaurantRow(candidate: RestaurantCandidate(from: r))
                                }
                            }
                            .onDelete(perform: delete)
                        }
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                    }
                }
            }
            .navigationTitle("Restaurants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAdd = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                NavigationStack {
                    AddRestaurantView()
                }
            }
        }
        
    }

    private func delete(_ indexSet: IndexSet) {
        for index in indexSet {
            modelContext.delete(restaurants[index])
        }
    }
}
