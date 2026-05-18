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
            wheelBase
                .rotationEffect(.degrees(wheelRotation))
            ballOrbit
            pointer
        }
        .frame(width: 314, height: 314)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Casino roulette")
        .accessibilityValue(accessibilityWheelValue)
    }

    private var outerWoodRing: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(red: 0.44, green: 0.24, blue: 0.11),
                        Color(red: 0.20, green: 0.08, blue: 0.03)
                    ],
                    center: .center,
                    startRadius: 30,
                    endRadius: 170
                )
            )
            .overlay(
                Circle()
                    .stroke(Color(red: 0.88, green: 0.72, blue: 0.28), lineWidth: 10)
            )
            .shadow(color: .black.opacity(0.35), radius: 10, y: 8)
    }

    private var wheelBase: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.12, green: 0.06, blue: 0.03))
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
                .stroke(Color(red: 0.88, green: 0.72, blue: 0.28), lineWidth: 3)
                .frame(width: 286, height: 286)

            ForEach(0..<36, id: \.self) { spoke in
                Capsule()
                    .fill(Color(red: 0.86, green: 0.68, blue: 0.22).opacity(0.35))
                    .frame(width: 2, height: 130)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(spoke) * 10))
            }

            Circle()
                .fill(Color(red: 0.30, green: 0.12, blue: 0.05))
                .frame(width: 112, height: 112)
                .overlay(
                    Circle()
                        .stroke(Color(red: 0.88, green: 0.72, blue: 0.28), lineWidth: 4)
                )

            ForEach(0..<8, id: \.self) { arm in
                Capsule()
                    .fill(Color(red: 0.86, green: 0.68, blue: 0.22))
                    .frame(width: 70, height: 7)
                    .rotationEffect(.degrees(Double(arm) * 45))
            }

            Circle()
                .fill(Color(red: 0.90, green: 0.74, blue: 0.26))
                .frame(width: 24, height: 24)
                .shadow(radius: 2)
        }
    }

    private var ballOrbit: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let radius = size / 2 - 24
            let x = cos(ballAngle.radians) * radius
            let y = sin(ballAngle.radians) * radius

            ZStack {
                Circle()
                    .fill(.white.opacity(0.12))
                    .frame(width: 26, height: 26)
                    .position(x: geo.size.width / 2 + x, y: geo.size.height / 2 + y)

                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                    .position(x: geo.size.width / 2 + x, y: geo.size.height / 2 + y)
            }
            .accessibilityHidden(true)
        }
    }

    private var pointer: some View {
        VStack(spacing: 0) {
            TrianglePointer()
                .fill(Color(red: 0.92, green: 0.74, blue: 0.22))
                .frame(width: 30, height: 24)
                .shadow(radius: 2, y: 1)

            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.92, green: 0.74, blue: 0.22))
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
                .fill(Color(red: 0.05, green: 0.42, blue: 0.20))
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
                    .fill(color)

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
