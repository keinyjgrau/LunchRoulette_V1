//
//  StarsView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//


import SwiftUI

struct StarsView: View {
    let rating: Double // 0...5

    var body: some View {
        let clamped = max(0, min(5, rating))
        let fullStars = Int(clamped)
        let hasHalf = (clamped - Double(fullStars)) >= 0.5

        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { idx in
                if idx < fullStars {
                    Image(systemName: "star.fill")
                } else if idx == fullStars && hasHalf {
                    Image(systemName: "star.leadinghalf.filled")
                } else {
                    Image(systemName: "star")
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue("\(String(format: "%.1f", clamped)) out of 5")
    }
}
