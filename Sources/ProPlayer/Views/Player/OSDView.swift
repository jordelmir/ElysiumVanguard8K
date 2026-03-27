import SwiftUI
import ProPlayerEngine

struct OSDView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(ProTheme.Fonts.osd)
            .foregroundColor(ProTheme.Colors.textPrimary)
            .shadow(color: ProTheme.Colors.accentBlue.opacity(0.8), radius: 8)
            .padding(.horizontal, ProTheme.Spacing.xl)
            .padding(.vertical, ProTheme.Spacing.md)
            .glassBackground(cornerRadius: ProTheme.Radius.large, opacity: 0.6)
            .overlay(
                RoundedRectangle(cornerRadius: ProTheme.Radius.large)
                    .stroke(ProTheme.Colors.accentBlue.opacity(0.3), lineWidth: 1)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

struct VideoInfoOverlay: View {
    let engine: PlayerEngine

    var body: some View {
        VStack(alignment: .leading, spacing: ProTheme.Spacing.sm) {
            Text("Video Information")
                .font(ProTheme.Fonts.headline)
                .foregroundColor(ProTheme.Colors.accentBlue)
                .shadow(color: ProTheme.Colors.accentBlue.opacity(0.5), radius: 4)

            Divider().background(ProTheme.Colors.accentBlue.opacity(0.5))

            infoRow("Title", engine.currentItemTitle)
            infoRow("Time", "\(FormatUtils.timeString(from: engine.currentTime)) / \(FormatUtils.timeString(from: engine.duration))")
            infoRow("Resolution", "\(Int(engine.videoSize.width))×\(Int(engine.videoSize.height))")
            infoRow("Speed", FormatUtils.speedString(engine.playbackSpeed))
            infoRow("Volume", "\(Int(engine.volume * 100))%")

            if engine.isLooping, let a = engine.loopA, let b = engine.loopB {
                infoRow("Loop", "\(FormatUtils.timeString(from: a)) → \(FormatUtils.timeString(from: b))")
            }
        }
        .padding(ProTheme.Spacing.lg)
        .frame(width: 300, alignment: .leading)
        .glassBackground(cornerRadius: ProTheme.Radius.medium, opacity: 0.6)
        .transition(.move(edge: .trailing).combined(with: .opacity))
    }

    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(ProTheme.Fonts.caption)
                .foregroundColor(ProTheme.Colors.textSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(ProTheme.Fonts.mono)
                .foregroundColor(ProTheme.Colors.textPrimary)
        }
    }
}
