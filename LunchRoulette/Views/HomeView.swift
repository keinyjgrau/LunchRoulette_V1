//
//  HomeView.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue

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
                    Color.black.opacity(0.14),
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.30)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    Text(AppText.homeTitle(appLanguage))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

                    Text(AppText.homeSubtitle(appLanguage))
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 10)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.16), radius: 8, y: 5)
                .padding(.horizontal, 24)

                Spacer()

                VStack(spacing: 10) {
                    homeButton(
                        title: AppText.homeChooseLunch(appLanguage),
                        systemImage: "fork.knife",
                        isPrimary: true,
                        action: onChooseLunch
                    )

                    homeButton(
                        title: AppText.homeRestaurants(appLanguage),
                        systemImage: "list.bullet.rectangle",
                        isPrimary: false,
                        action: onManageRestaurants
                    )

                    homeButton(
                        title: AppText.homeSettings(appLanguage),
                        systemImage: "gearshape",
                        isPrimary: false,
                        action: onOpenSettings
                    )
                }
                .tint(.orange)
                .padding(.horizontal, 24)

                Spacer(minLength: 4)

                VStack(spacing: 2) {
                    Image(systemName: "sparkles")
                        .font(.caption2)
                        .foregroundStyle(.orange)

                    Text(AppText.homeFooter(appLanguage))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }
                .padding(.bottom, 2)
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
            .padding(.vertical, 12)
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
                        : Color.white.opacity(0.20),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isPrimary ? .black.opacity(0.16) : .clear,
                radius: isPrimary ? 6 : 0,
                y: isPrimary ? 3 : 0
            )
        }
        .buttonStyle(.plain)
    }
}
