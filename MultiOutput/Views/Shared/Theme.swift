import AVKit
import MediaPlayer
import SwiftUI

enum Theme {
    static let background = Color(red: 0.961, green: 0.961, blue: 0.973)
    static let mint = Color(red: 0.36, green: 0.72, blue: 0.62)
    static let lavender = Color(red: 0.54, green: 0.50, blue: 0.86)
    static let peach = Color(red: 0.93, green: 0.58, blue: 0.44)
    static let sky = Color(red: 0.36, green: 0.62, blue: 0.90)
}

struct Card<Content: View>: View {
    let title: String
    let symbol: String
    var tint = Theme.lavender
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(tint)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

struct Screen<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(spacing: 14) { content }
                .padding(16)
        }
        .background(Theme.background)
        .navigationTitle(title)
    }
}

struct StatusPill: View {
    let text: String
    var tint = Theme.mint

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.14), in: Capsule())
    }
}

struct MetricRow: View {
    let label: String
    let value: String

    var body: some View {
        LabeledContent(label) {
            Text(value).monospacedDigit().multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

/// Bars draw measured levels from the engine, so the display is flat whenever nothing is playing.
struct LevelVisualizer: View {
    let history: [Float]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            ForEach(history.indices, id: \.self) { index in
                Capsule()
                    .fill(Theme.lavender.opacity(0.35 + Double(index) / Double(max(history.count, 1)) * 0.65))
                    .frame(height: max(3, CGFloat(min(history[index] * 3, 1)) * 64))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 64)
        .animation(reduceMotion ? nil : .linear(duration: 0.08), value: history)
        .accessibilityElement()
        .accessibilityLabel("Audio level")
        .accessibilityValue(history.last.map { "\(Int(min($0 * 3, 1) * 100)) percent" } ?? "Silent")
    }
}

/// Apple's system picker, the supported way to choose AirPlay and Bluetooth routes.
struct RoutePickerButton: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.tintColor = UIColor(Theme.lavender)
        view.activeTintColor = UIColor(Theme.mint)
        return view
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

/// Apple's system volume control. Apps can't set hardware volume directly.
struct SystemVolumeSlider: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView { MPVolumeView(frame: .zero) }
    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}
