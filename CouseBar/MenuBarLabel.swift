import SwiftUI

struct MenuBarLabel: View {
    let usage: QuotaSnapshot?

    var body: some View {
        HStack(spacing: 4) {
            Image("CopilotIcon")
                .renderingMode(.template)

            if let usage {
                MenuBarProgressBar(usage: usage)
            }
        }
    }
}

struct MenuBarProgressBar: View {
    let usage: QuotaSnapshot

    private let barWidth: CGFloat = 36
    private let barHeight: CGFloat = 10
    private let cornerRadius: CGFloat = 2

    var body: some View {
        ZStack(alignment: .leading) {
            if usage.isOverLimit {
                overLimitBar
            } else {
                normalBar
            }
        }
        .frame(width: totalWidth, height: barHeight)
    }

    private var totalWidth: CGFloat {
        if usage.isOverLimit {
            let overshoot = min(usage.overageFraction, 1.0) * barWidth
            return barWidth + overshoot
        }
        return barWidth
    }

    private var normalBar: some View {
        ZStack(alignment: .leading) {
            // Background track
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.primary.opacity(0.2))
                .frame(width: barWidth, height: barHeight)

            // Filled portion
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(normalColor)
                .frame(width: max(0, usage.normalFraction * barWidth), height: barHeight)
        }
    }

    private var overLimitBar: some View {
        HStack(spacing: 0) {
            // Full normal portion (100%)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.orange)
                .frame(width: barWidth, height: barHeight)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: cornerRadius,
                    bottomLeadingRadius: cornerRadius,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                ))

            // Red overshoot portion
            let overshootWidth = min(usage.overageFraction, 1.0) * barWidth
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.red)
                .frame(width: max(0, overshootWidth), height: barHeight)
                .clipShape(UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: cornerRadius,
                    topTrailingRadius: cornerRadius
                ))
        }
    }

    private var normalColor: Color {
        let fraction = usage.normalFraction
        if fraction < 0.6 {
            return .green
        } else if fraction < 0.85 {
            return .yellow
        } else {
            return .orange
        }
    }
}
