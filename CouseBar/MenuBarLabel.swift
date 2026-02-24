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
            let filledWidth = CGFloat(max(0, usage.normalFraction * barWidth))
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(normalColor)
                .frame(width: filledWidth, height: barHeight)
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
            let overshootWidth = CGFloat(min(usage.overageFraction, 1.0) * barWidth)
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.red)
                .frame(width: overshootWidth, height: barHeight)
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

// MARK: - Previews

#Preview("Low Usage (30%)") {
    MenuBarLabel(usage: .lowUsage)
        .padding()
}

#Preview("Medium Usage (65%)") {
    MenuBarLabel(usage: .mediumUsage)
        .padding()
}

#Preview("High Usage (90%)") {
    MenuBarLabel(usage: .highUsage)
        .padding()
}

#Preview("At Limit (100%)") {
    MenuBarLabel(usage: .atLimit)
        .padding()
}

#Preview("Slightly Over (110%)") {
    MenuBarLabel(usage: .slightlyOver)
        .padding()
}

#Preview("Over Limit (154%)") {
    MenuBarLabel(usage: .overLimit)
        .padding()
}

#Preview("No Data") {
    MenuBarLabel(usage: nil)
        .padding()
}

#Preview("All States") {
    VStack(alignment: .leading, spacing: 12) {
        LabeledContent("30%") { MenuBarLabel(usage: .lowUsage) }
        LabeledContent("65%") { MenuBarLabel(usage: .mediumUsage) }
        LabeledContent("90%") { MenuBarLabel(usage: .highUsage) }
        LabeledContent("100%") { MenuBarLabel(usage: .atLimit) }
        LabeledContent("110%") { MenuBarLabel(usage: .slightlyOver) }
        LabeledContent("154%") { MenuBarLabel(usage: .overLimit) }
        LabeledContent("No data") { MenuBarLabel(usage: nil) }
    }
    .padding()
}
