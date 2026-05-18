//
//  RouletteView.swift
//  LaunchRoulette
//
//  Created by Keiny.Grau.a1 on 2026-03-16.
//

import SwiftUI

struct RouletteView: View {
    let choices: [RestaurantCandidate]
    let spinDuration: Double
    let lastWinnerRepeatKey: String?
    let onFinished: (RestaurantCandidate) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var wheelRotation: Double = 0
    @State private var ballAngle: Double = -90
    @State private var isSpinning = false
    @State private var finalRestaurant: RestaurantCandidate? = nil
    @State private var winningIndex: Int? = nil
    @State private var highlightedIndex: Int? = nil

    @State private var winnerPulse = false
    @State private var winnerFlash = false
    @State private var winnerPop = false

    private var numberedChoices: [NumberedChoice] {
        choices.enumerated().map { NumberedChoice(number: $0.offset + 1, candidate: $0.element) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                casinoBackground

                VStack(spacing: 18) {
                    Text("Choose for me")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)

                    wheelSection

                    casinoTableSection

                    if let winningIndex, let winner = finalRestaurant {
                        winnerReveal(number: winningIndex + 1, restaurantName: winner.name)
                    }

                    HStack(spacing: 12) {
                        Button {
                            startCasinoSelection()
                        } label: {
                            Label(isSpinning ? "Choosing..." : "Start Roulette", systemImage: "shuffle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(isSpinning || choices.count < 2)
                        .accessibilityHint("Starts the casino-style restaurant selection.")

                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        .tint(.white)
                        .disabled(isSpinning)
                        .accessibilityHint("Closes the roulette without choosing a restaurant.")
                    }
                }
                .padding()

                if winnerFlash {
                    Color.white.opacity(0.12)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Roulette")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var casinoBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.24, blue: 0.12),
                    Color(red: 0.02, green: 0.17, blue: 0.09)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Rectangle()
                .stroke(Color.white.opacity(0.05), lineWidth: 2)
                .padding(10)

            VStack {
                HStack {
                    Circle().fill(.white.opacity(0.03)).frame(width: 120, height: 120)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle().fill(.white.opacity(0.025)).frame(width: 170, height: 170)
                }
            }
            .padding(24)
        }
        .ignoresSafeArea()
    }

    private var wheelSection: some View {
        ZStack {
            outerWoodRing
            goldOuterLip
            wheelBase
                .rotationEffect(.degrees(wheelRotation))
            centerShadow
            ballOrbit
            pointer
        }
        .frame(width: 320, height: 320)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Casino roulette")
        .accessibilityValue(accessibilityWheelValue)
    }

    private var outerWoodRing: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.46, green: 0.27, blue: 0.13),
                        Color(red: 0.28, green: 0.14, blue: 0.06),
                        Color(red: 0.16, green: 0.07, blue: 0.03)
                    ],
                    center: .topLeading,
                    startRadius: 20,
                    endRadius: 190
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.35), lineWidth: 3)
                    .blur(radius: 1)
            )
            .shadow(color: .black.opacity(0.45), radius: 14, y: 10)
    }

    private var goldOuterLip: some View {
        Circle()
            .stroke(
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.86, blue: 0.46),
                        Color(red: 0.78, green: 0.59, blue: 0.16),
                        Color(red: 0.95, green: 0.84, blue: 0.42)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 10
            )
            .frame(width: 308, height: 308)
            .shadow(color: .yellow.opacity(0.15), radius: 4)
    }

    private var wheelBase: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.16, green: 0.08, blue: 0.04),
                            Color(red: 0.09, green: 0.04, blue: 0.02)
                        ],
                        center: .topLeading,
                        startRadius: 30,
                        endRadius: 170
                    )
                )
                .frame(width: 286, height: 286)

            ForEach(Array(numberedChoices.enumerated()), id: \.element.candidate.id) { index, entry in
                CasinoNumberWheelSliceView(
                    title: "\(entry.number)",
                    index: index,
                    total: numberedChoices.count,
                    color: sliceColor(for: index, total: numberedChoices.count)
                )
                .frame(width: 286, height: 286)
            }

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.86, blue: 0.44),
                            Color(red: 0.72, green: 0.53, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 3
                )
                .frame(width: 286, height: 286)

            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 2)
                .frame(width: 274, height: 274)
                .blur(radius: 0.5)

            ForEach(0..<36, id: \.self) { spoke in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.92, green: 0.76, blue: 0.30).opacity(0.55),
                                Color(red: 0.63, green: 0.46, blue: 0.10).opacity(0.20)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 2, height: 130)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(spoke) * 10))
            }

            centerHub
        }
    }

    private var centerHub: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.36, green: 0.16, blue: 0.07),
                            Color(red: 0.22, green: 0.09, blue: 0.04)
                        ],
                        center: .topLeading,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 116, height: 116)

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.86, blue: 0.44),
                            Color(red: 0.72, green: 0.53, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 4
                )
                .frame(width: 116, height: 116)

            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 88, height: 88)
                .offset(x: -8, y: -10)

            ForEach(0..<8, id: \.self) { arm in
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.96, green: 0.81, blue: 0.36),
                                Color(red: 0.69, green: 0.50, blue: 0.13)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 8)
                    .rotationEffect(.degrees(Double(arm) * 45))
                    .shadow(color: .black.opacity(0.15), radius: 1, y: 1)
            }

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.99, green: 0.88, blue: 0.48),
                            Color(red: 0.78, green: 0.59, blue: 0.16)
                        ],
                        center: .topLeading,
                        startRadius: 2,
                        endRadius: 18
                    )
                )
                .frame(width: 26, height: 26)
                .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        }
    }

    private var centerShadow: some View {
        Circle()
            .fill(Color.black.opacity(0.12))
            .frame(width: 70, height: 70)
            .blur(radius: 6)
            .offset(y: 8)
            .accessibilityHidden(true)
    }

    private var ballOrbit: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 25
            let x = cos(ballAngle.radians) * radius
            let y = sin(ballAngle.radians) * radius

            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.20))
                    .frame(width: 16, height: 8)
                    .position(x: geo.size.width / 2 + x + 3, y: geo.size.height / 2 + y + 4)

                Circle()
                    .fill(.white.opacity(0.10))
                    .frame(width: 28, height: 28)
                    .position(x: geo.size.width / 2 + x, y: geo.size.height / 2 + y)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color(red: 0.93, green: 0.93, blue: 0.95)
                            ],
                            center: .topLeading,
                            startRadius: 1,
                            endRadius: 12
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    )
                    .frame(width: 12, height: 12)
                    .position(x: geo.size.width / 2 + x, y: geo.size.height / 2 + y)
            }
            .accessibilityHidden(true)
        }
    }

    private var pointer: some View {
        VStack(spacing: 0) {
            TrianglePointer()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.85, blue: 0.43),
                            Color(red: 0.72, green: 0.53, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 30, height: 24)
                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)

            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.97, green: 0.85, blue: 0.43),
                            Color(red: 0.72, green: 0.53, blue: 0.14)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 6, height: 16)

            Spacer()
        }
        .padding(.top, -8)
        .accessibilityHidden(true)
    }

    private var casinoTableSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Restaurant Table")
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                Text("\(numberedChoices.count) numbers")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }

            casinoBoard
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.42, blue: 0.20),
                            Color(red: 0.04, green: 0.32, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.20), lineWidth: 2)
                )
        )
    }

    private var casinoBoard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                zeroLikeDecorBox(title: "ODD")
                zeroLikeDecorBox(title: "EVEN")
                zeroLikeDecorBox(title: "HIGH")
            }

            VStack(spacing: 0) {
                ForEach(Array(boardRows().enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(row, id: \.candidate.id) { entry in
                            let idx = entry.number - 1
                            numberCell(
                                number: entry.number,
                                isHighlighted: highlightedIndex == idx,
                                isWinner: winningIndex == idx,
                                fillColor: sliceColor(for: idx, total: numberedChoices.count)
                            )
                        }

                        if row.count < boardColumnCount {
                            ForEach(0..<(boardColumnCount - row.count), id: \.self) { _ in
                                placeholderCell
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1.5)
            )

            HStack(spacing: 8) {
                zeroLikeDecorBox(title: "1st")
                zeroLikeDecorBox(title: "2nd")
                zeroLikeDecorBox(title: "3rd")
            }
        }
    }

    private var boardColumnCount: Int {
        if numberedChoices.count <= 6 { return 3 }
        if numberedChoices.count <= 12 { return 4 }
        return 5
    }

    private func boardRows() -> [[NumberedChoice]] {
        stride(from: 0, to: numberedChoices.count, by: boardColumnCount).map {
            Array(numberedChoices[$0..<min($0 + boardColumnCount, numberedChoices.count)])
        }
    }

    @ViewBuilder
    private func zeroLikeDecorBox(title: String) -> some View {
        Text(title)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.03, green: 0.33, blue: 0.16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.22), lineWidth: 1)
                    )
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var placeholderCell: some View {
        Rectangle()
            .fill(Color(red: 0.03, green: 0.33, blue: 0.16))
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func numberCell(number: Int, isHighlighted: Bool, isWinner: Bool, fillColor: Color) -> some View {
        let bg: Color = {
            if isWinner { return Color(red: 0.95, green: 0.68, blue: 0.15) }
            if isHighlighted { return Color.white.opacity(0.18) }
            return fillColor.opacity(0.96)
        }()

        let glowColor: Color = isWinner ? .yellow : .clear

        Text("\(number)")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundStyle(isWinner ? .black : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                Rectangle()
                    .fill(bg)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isWinner ? Color.white : Color.white.opacity(0.22),
                                lineWidth: isWinner ? 2.2 : 0.9
                            )
                    )
            )
            .scaleEffect(isWinner && winnerPop ? 1.08 : 1.0)
            .shadow(
                color: isWinner && winnerPulse ? glowColor.opacity(0.70) : .clear,
                radius: isWinner && winnerPulse ? 12 : 0
            )
            .animation(.spring(response: 0.28, dampingFraction: 0.62), value: winnerPop)
            .animation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true), value: winnerPulse)
            .animation(.easeInOut(duration: 0.14), value: isHighlighted)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Number \(number)")
            .accessibilityValue(isWinner ? "Winner" : (isHighlighted ? "Currently highlighted" : ""))
    }

    @ViewBuilder
    private func winnerReveal(number: Int, restaurantName: String) -> some View {
        VStack(spacing: 6) {
            Text("Winning Number")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            Text("\(number)")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.yellow)

            Text("Selected Restaurant")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
                .padding(.top, 4)

            Text(restaurantName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 8)
        .transition(.opacity.combined(with: .scale))
    }

    private var accessibilityWheelValue: String {
        if let winningIndex {
            return "Winning number \(winningIndex + 1)"
        }
        return "Ready"
    }

    private func startCasinoSelection() {
        guard choices.count >= 2, !isSpinning else { return }

        isSpinning = true
        finalRestaurant = nil
        winningIndex = nil
        highlightedIndex = nil
        winnerPulse = false
        winnerFlash = false
        winnerPop = false

        let winnerIndex: Int = {
            guard choices.count > 1, let lastWinnerRepeatKey else {
                return Int.random(in: 0..<choices.count)
            }

            let eligibleIndices = choices.indices.filter { choices[$0].repeatKey != lastWinnerRepeatKey }

            if let chosen = eligibleIndices.randomElement() {
                return chosen
            } else {
                return Int.random(in: 0..<choices.count)
            }
        }()

        let winner = choices[winnerIndex].withWinningNumber(winnerIndex + 1)

        let sliceAngle = 360.0 / Double(choices.count)
        let winnerCenterAngle = (Double(winnerIndex) * sliceAngle) + (sliceAngle / 2.0)
        let alignmentAngle = -90.0 - winnerCenterAngle
        let extraTurns = Double(Int.random(in: 6...9)) * 360.0

        withAnimation(.easeOut(duration: spinDuration)) {
            wheelRotation += extraTurns + alignmentAngle
            ballAngle += (extraTurns * 1.35) + alignmentAngle
        }

        Task {
            await animateTableHighlights(winnerIndex: winnerIndex)

            await MainActor.run {
                finalRestaurant = winner
                winningIndex = winnerIndex
                highlightedIndex = winnerIndex
                isSpinning = false
            }

            await triggerWinnerEffects()

            try? await Task.sleep(nanoseconds: 1_150_000_000)

            await MainActor.run {
                dismiss()
                onFinished(winner)
            }
        }
    }

    private func animateTableHighlights(winnerIndex: Int) async {
        let minimumSteps = max(numberedChoices.count * 4, 24)
        let landingSteps = minimumSteps + winnerIndex

        for step in 0...landingSteps {
            let index = step % numberedChoices.count
            let progress = Double(step) / Double(max(landingSteps, 1))

            await MainActor.run {
                highlightedIndex = index
            }

            let delay = highlightDelay(progress: progress)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        await MainActor.run {
            highlightedIndex = winnerIndex
        }
    }

    private func triggerWinnerEffects() async {
        await MainActor.run {
            winnerFlash = true
            winnerPop = true
        }

        try? await Task.sleep(nanoseconds: 180_000_000)

        await MainActor.run {
            winnerFlash = false
            winnerPulse = true
        }

        try? await Task.sleep(nanoseconds: 350_000_000)

        await MainActor.run {
            winnerPop = false
        }
    }

    private func highlightDelay(progress: Double) -> Double {
        let minDelay = 0.04
        let maxDelay = max(0.16, spinDuration * 0.11)
        return minDelay + ((maxDelay - minDelay) * progress * progress)
    }

    private func sliceColor(for index: Int, total: Int) -> Color {
        let greenIndices = greenSliceIndices(total: total)
        if greenIndices.contains(index) {
            return Color(red: 0.07, green: 0.55, blue: 0.24)
        }
        return index.isMultiple(of: 2)
            ? Color(red: 0.78, green: 0.10, blue: 0.12)
            : Color(red: 0.10, green: 0.10, blue: 0.12)
    }

    private func greenSliceIndices(total: Int) -> Set<Int> {
        guard total >= 6 else { return [] }
        if total.isMultiple(of: 2) {
            return [0, total / 2]
        } else {
            return [0]
        }
    }
}

private struct NumberedChoice {
    let number: Int
    let candidate: RestaurantCandidate
}

private struct CasinoNumberWheelSliceView: View {
    let title: String
    let index: Int
    let total: Int
    let color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WheelSlicePath(index: index, total: total)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.96),
                                color.opacity(0.78)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                WheelSlicePath(index: index, total: total)
                    .stroke(Color(red: 0.88, green: 0.72, blue: 0.28), lineWidth: 1.2)

                sliceLabel(radius: min(geo.size.width, geo.size.height) / 2)
            }
        }
    }

    @ViewBuilder
    private func sliceLabel(radius: CGFloat) -> some View {
        let sliceAngle = 360.0 / Double(max(total, 1))
        let angle = (Double(index) * sliceAngle) + (sliceAngle / 2.0)
        let labelRadius = radius * 0.79

        Text(title)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .rotationEffect(.degrees(angle + 90))
            .offset(
                x: CGFloat(cos(angle.radians)) * labelRadius,
                y: CGFloat(sin(angle.radians)) * labelRadius
            )
            .accessibilityHidden(true)
    }
}

private struct WheelSlicePath: Shape {
    let index: Int
    let total: Int

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let sliceAngle = 360.0 / Double(max(total, 1))
        let startAngle = (Double(index) * sliceAngle) - 90.0
        let endAngle = startAngle + sliceAngle

        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private extension Double {
    var radians: Double { self * .pi / 180.0 }
}
