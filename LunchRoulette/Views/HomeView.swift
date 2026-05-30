//
//  HomeView.swift
//  LunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-05-25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue
    @State private var showHelp = false

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
                    HStack {
                        Spacer()

                        Button {
                            showHelp = true
                        } label: {
                            Label(
                                AppText.isSpanish(appLanguage) ? "Ayuda" : "Help",
                                systemImage: "questionmark.circle"
                            )
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.white)
                    }

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
        .sheet(isPresented: $showHelp) {
            NavigationStack {
                HowItWorksView()
            }
        }
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

private struct HowItWorksView: View {
    @AppStorage("appLanguage") private var appLanguage = AppLanguageOption.system.rawValue
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                helpRow(
                    icon: "plus.circle",
                    title: AppText.isSpanish(appLanguage) ? "Agrega restaurantes" : "Add restaurants",
                    text: AppText.isSpanish(appLanguage)
                        ? "Crea tu lista local o busca restaurantes cercanos."
                        : "Build your local list or search for nearby restaurants."
                )

                helpRow(
                    icon: "checkmark.circle",
                    title: AppText.isSpanish(appLanguage) ? "Selecciona hasta 10" : "Select up to 10",
                    text: AppText.isSpanish(appLanguage)
                        ? "Elige los restaurantes que quieras usar en la ruleta."
                        : "Choose the restaurants you want to use in the roulette."
                )

                helpRow(
                    icon: "shuffle",
                    title: AppText.isSpanish(appLanguage) ? "Gira la ruleta" : "Spin the roulette",
                    text: AppText.isSpanish(appLanguage)
                        ? "La ruleta elige un ganador de forma divertida y rápida."
                        : "The roulette picks a winner in a fun, quick way."
                )

                helpRow(
                    icon: "square.and.arrow.down",
                    title: AppText.isSpanish(appLanguage) ? "Guarda cercanos" : "Save nearby places",
                    text: AppText.isSpanish(appLanguage)
                        ? "Guarda restaurantes cercanos en tu lista local para volver a usarlos."
                        : "Save nearby restaurants to your local list to use them again later."
                )
            }
        }
        .navigationTitle(AppText.isSpanish(appLanguage) ? "Cómo funciona" : "How it works")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppText.cancel(appLanguage)) {
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private func helpRow(icon: String, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
