//
//  HomeView.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-25.
//

import SwiftUI

struct HomeView: View {
    let onChooseLunch: () -> Void
    let onManageRestaurants: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        ZStack {
            Image("home_bg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.18),
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 56)

                VStack(spacing: 12) {
                    Text("Lunch Roulette")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.20), radius: 4, y: 2)

                    Text("Choose a place to eat with a fun restaurant roulette experience.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 14) {
                    homeButton(
                        title: "Choose Lunch",
                        systemImage: "fork.knife",
                        isPrimary: true,
                        action: onChooseLunch
                    )

                    homeButton(
                        title: "Restaurants",
                        systemImage: "list.bullet.rectangle",
                        isPrimary: false,
                        action: onManageRestaurants
                    )

                    homeButton(
                        title: "Settings",
                        systemImage: "gearshape",
                        isPrimary: false,
                        action: onOpenSettings
                    )
                }
                .tint(.orange)
                .padding(.horizontal, 24)

                Spacer(minLength: 26)

                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundStyle(.orange)

                    Text("Pick your restaurants, spin the wheel, and let luck decide.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func homeButton(
        title: String,
        systemImage: String,
        isPrimary: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        isPrimary
                        ? AnyShapeStyle(Color.orange)
                        : AnyShapeStyle(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        isPrimary
                        ? Color.orange.opacity(0.0)
                        : Color.white.opacity(0.22),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isPrimary ? .black.opacity(0.18) : .clear,
                radius: isPrimary ? 8 : 0,
                y: isPrimary ? 4 : 0
            )
        }
        .buttonStyle(.plain)
    }
}
