//
//  AppBackground.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-17.
//


import SwiftUI

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .top)
    }
}
