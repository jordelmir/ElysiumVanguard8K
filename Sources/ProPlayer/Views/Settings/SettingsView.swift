import SwiftUI

struct SettingsView: View {
    @Binding var settings: PlayerSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            generalTab.tabItem { Label("General", systemImage: "gear") }
            videoTab.tabItem { Label("Video", systemImage: "play.rectangle") }
            audioTab.tabItem { Label("Audio", systemImage: "speaker.wave.3") }
            subtitlesTab.tabItem { Label("Subtitles", systemImage: "captions.bubble") }
        }
        .frame(width: 480, height: 380)
        .padding()
        .onChange(of: settings) { _, newValue in
            newValue.save()
        }
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section("Playback") {
                Toggle("Resume from last position", isOn: $settings.resumePlayback)
                Toggle("Auto-play next in playlist", isOn: $settings.autoPlayNext)
                Toggle("Show on-screen display", isOn: $settings.showOSD)

                HStack {
                    Text("Controls auto-hide delay")
                    Spacer()
                    Picker("", selection: $settings.controlsAutoHideDelay) {
                        Text("2s").tag(2.0)
                        Text("3s").tag(3.0)
                        Text("5s").tag(5.0)
                        Text("Never").tag(999.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }

            Section("Default Screen Mode") {
                Picker("Screen mode", selection: $settings.defaultGravityMode) {
                    ForEach(VideoGravityMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Video

    private var videoTab: some View {
        Form {
            Section("Screenshots") {
                HStack {
                    Text("Save location")
                    Spacer()
                    Text(settings.screenshotSavePath)
                        .font(ProTheme.Fonts.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseDirectories = true
                        panel.canChooseFiles = false
                        if panel.runModal() == .OK, let url = panel.url {
                            settings.screenshotSavePath = url.path
                        }
                    }
                }
            }

            Section("Library") {
                Picker("Default sort", selection: $settings.librarySortOption) {
                    ForEach(LibrarySortOption.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Picker("Default view", selection: $settings.libraryViewMode) {
                    ForEach(LibraryViewMode.allCases, id: \.rawValue) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Audio

    private var audioTab: some View {
        Form {
            Section("Volume") {
                HStack {
                    Text("Default volume")
                    Slider(value: Binding(
                        get: { Double(settings.defaultVolume) },
                        set: { settings.defaultVolume = Float($0) }
                    ), in: 0...1)
                    Text("\(Int(settings.defaultVolume * 100))%")
                        .font(ProTheme.Fonts.mono)
                        .frame(width: 40)
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Subtitles

    private var subtitlesTab: some View {
        Form {
            Section("Appearance") {
                HStack {
                    Text("Font size")
                    Slider(value: $settings.subtitleFontSize, in: 14...48, step: 2)
                    Text("\(Int(settings.subtitleFontSize))pt")
                        .font(ProTheme.Fonts.mono)
                        .frame(width: 40)
                }

                HStack {
                    Text("Background opacity")
                    Slider(value: $settings.subtitleBackgroundOpacity, in: 0...1)
                    Text("\(Int(settings.subtitleBackgroundOpacity * 100))%")
                        .font(ProTheme.Fonts.mono)
                        .frame(width: 40)
                }
            }
        }
        .formStyle(.grouped)
    }
}
