import SwiftUI
import AVFoundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published var engine = PlayerEngine()
    @Published var gravityMode: VideoGravityMode = .fit
    @Published var showControls = true
    @Published var isFullscreen = false
    @Published var osdMessage: String?
    @Published var showingVideoInfo = false
    @Published var currentVideoItem: VideoItem?
    @Published var playlist = Playlist()
    @Published var customZoomScale: CGFloat = 1.0
    @Published var customZoomOffset: CGSize = .zero
    @Published var settings = PlayerSettings.load()

    // Video adjustments
    @Published var brightness: Double = 0
    @Published var contrast: Double = 1
    @Published var saturation: Double = 1

    private var controlsTimer: Timer?

    init() {
        gravityMode = settings.defaultGravityMode
        engine.volume = settings.defaultVolume
    }

    // MARK: - File Loading

    func openFile(url: URL) {
        engine.loadFile(url: url)
        engine.play()
        showOSD("Now Playing: \(url.deletingPathExtension().lastPathComponent)")
        resetControlsTimer()
    }

    func openFiles(urls: [URL]) {
        playlist = Playlist(items: urls.map { VideoItem(url: $0) })
        if let first = urls.first {
            openFile(url: first)
        }
    }

    // MARK: - Playback

    func togglePlayPause() {
        engine.togglePlayPause()
        showOSD(engine.isPlaying ? "▶ Play" : "⏸ Paused")
    }

    func stop() {
        engine.stop()
        showOSD("⏹ Stopped")
    }

    func seekForward(_ seconds: Double = 5) {
        engine.seekRelative(seconds)
        showOSD("⏩ +\(Int(seconds))s")
    }

    func seekBackward(_ seconds: Double = 5) {
        engine.seekRelative(-seconds)
        showOSD("⏪ -\(Int(seconds))s")
    }

    func seekToPercent(_ percent: Double) {
        engine.seekToPercent(percent)
    }

    // MARK: - Volume

    func volumeUp() {
        engine.adjustVolume(by: 0.05)
        showOSD("🔊 Volume: \(Int(engine.volume * 100))%")
    }

    func volumeDown() {
        engine.adjustVolume(by: -0.05)
        showOSD("🔉 Volume: \(Int(engine.volume * 100))%")
    }

    func toggleMute() {
        engine.toggleMute()
        showOSD(engine.isMuted ? "🔇 Muted" : "🔊 Volume: \(Int(engine.volume * 100))%")
    }

    // MARK: - Speed

    func speedUp() {
        engine.cycleSpeedUp()
        showOSD("Speed: \(FormatUtils.speedString(engine.playbackSpeed))")
    }

    func speedDown() {
        engine.cycleSpeedDown()
        showOSD("Speed: \(FormatUtils.speedString(engine.playbackSpeed))")
    }

    // MARK: - Video Gravity

    func cycleGravityMode() {
        let modes = VideoGravityMode.allCases
        guard let idx = modes.firstIndex(of: gravityMode) else { return }
        let nextIdx = (idx + 1) % modes.count
        gravityMode = modes[nextIdx]

        // Reset zoom when leaving custom zoom mode
        if gravityMode != .customZoom {
            customZoomScale = 1.0
            customZoomOffset = .zero
        }

        showOSD("📐 \(gravityMode.rawValue)")
    }

    func setGravityMode(_ mode: VideoGravityMode) {
        gravityMode = mode
        if mode != .customZoom {
            customZoomScale = 1.0
            customZoomOffset = .zero
        }
        showOSD("📐 \(mode.rawValue)")
    }

    // MARK: - A-B Loop

    func toggleLoop() {
        engine.toggleLoop()
        if engine.isLooping {
            showOSD("🔁 Loop: \(FormatUtils.timeString(from: engine.loopA!)) → \(FormatUtils.timeString(from: engine.loopB!))")
        } else if engine.loopA != nil {
            showOSD("🔁 Loop Start: \(FormatUtils.timeString(from: engine.loopA!))")
        } else {
            showOSD("🔁 Loop Cleared")
        }
    }

    // MARK: - Screenshot

    func captureScreenshot() {
        engine.captureScreenshot(savePath: settings.screenshotSavePath)
        showOSD("📸 Screenshot Saved")
    }

    // MARK: - Fullscreen

    func toggleFullscreen() {
        guard let window = NSApp.mainWindow else { return }
        window.toggleFullScreen(nil)
        isFullscreen.toggle()
    }
    
    // MARK: - Picture in Picture
    
    func setupPiP(with layer: AVPlayerLayer) {
        engine.setupPiP(with: layer)
    }
    
    func togglePiP() {
        engine.togglePiP()
    }

    // MARK: - Playlist

    func playNext() {
        if var pl = Optional(playlist), let next = pl.next() {
            playlist = pl
            openFile(url: next.url)
        }
    }

    func playPrevious() {
        if engine.currentTime > 3 {
            engine.seek(to: 0)
            return
        }
        if var pl = Optional(playlist), let prev = pl.previous() {
            playlist = pl
            openFile(url: prev.url)
        }
    }

    // MARK: - Controls Visibility

    func resetControlsTimer() {
        showControls = true
        controlsTimer?.invalidate()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: settings.controlsAutoHideDelay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.engine.isPlaying else { return }
                withAnimation(ProTheme.Animations.smooth) {
                    self.showControls = false
                }
            }
        }
    }

    func handleMouseMoved() {
        resetControlsTimer()
    }

    // MARK: - OSD

    func showOSD(_ message: String) {
        guard settings.showOSD else { return }
        osdMessage = message
        DispatchQueue.main.asyncAfter(deadline: .now() + settings.osdDuration) { [weak self] in
            Task { @MainActor in
                if self?.osdMessage == message {
                    self?.osdMessage = nil
                }
            }
        }
    }

    // MARK: - Video Info

    func toggleVideoInfo() {
        showingVideoInfo.toggle()
    }
}
