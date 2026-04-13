//
//  RootTabsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI

struct RootTabsView: View {
    var body: some View {
        TabView {
            PickView()
                .tabItem {
                    Label("Pick", systemImage: "fork.knife")
                }

            ManageRestaurantsView()
                .tabItem {
                    Label("Manage", systemImage: "list.bullet.rectangle")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .tint(.orange)
    }
}
