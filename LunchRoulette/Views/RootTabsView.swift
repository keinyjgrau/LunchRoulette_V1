//
//  RootTabsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI

private enum AppTab: Hashable {
    case home
    case pick
    case manage
    case settings
}

struct RootTabsView: View {
    @State private var selectedTab: AppTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(
                    onChooseLunch: { selectedTab = .pick },
                    onManageRestaurants: { selectedTab = .manage },
                    onOpenSettings: { selectedTab = .settings }
                )
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(AppTab.home)

            PickView()
                .tabItem {
                    Label("Pick", systemImage: "fork.knife")
                }
                .tag(AppTab.pick)

            ManageRestaurantsView()
                .tabItem {
                    Label("Manage", systemImage: "list.bullet.rectangle")
                }
                .tag(AppTab.manage)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.orange)
    }
}
