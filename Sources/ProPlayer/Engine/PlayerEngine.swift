import Foundation
import AVFoundation
import Combine
import AppKit

@MainActor
final class PlayerEngine: ObservableObject {

    // MARK: - Published State

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var bufferedTime: Double = 0
    @Published var volume: Float = 0.8 { didSet { player.volume = volume } }
    @Published var isMuted = false { didSet { player.isMuted = isMuted } }
    @Published var playbackSpeed: Float = 1.0 { didSet { player.rate = isPlaying ? playbackSpeed : 0 } }
    @Published var videoSize: CGSize = .zero
    @Published var isLoading = false
    @Published var currentItemTitle: String = ""
    @Published var errorMessage: String?

    // A-B Loop
    @Published var loopA: Double?
    @Published var loopB: Double?
    var isLooping: Bool { loopA != nil && loopB != nil }

    // MARK: - Player

    let player = AVPlayer()
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var statusObservation: NSKeyValueObservation?
    private var timeRangeObservation: NSKeyValueObservation?
    private var presentationSizeObservation: NSKeyValueObservation?

    // MARK: - Init

    init() {
        player.volume = volume
        setupTimeObserver()
    }

    deinit {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
        }
        statusObservation?.invalidate()
        timeRangeObservation?.invalidate()
        presentationSizeObservation?.invalidate()
    }

    // MARK: - Time Observer

    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentTime = time.seconds

                // A-B Loop handling
                if let a = self.loopA, let b = self.loopB, time.seconds >= b {
                    self.seek(to: a)
                }
            }
        }
    }

    // MARK: - Load Media

    func loadFile(url: URL) {
        isLoading = true
        errorMessage = nil
        currentItemTitle = url.deletingPathExtension().lastPathComponent

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)

        // Observe status
        statusObservation?.invalidate()
        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    self.duration = item.duration.seconds.isFinite ? item.duration.seconds : 0
                    self.isLoading = false
                case .failed:
                    self.errorMessage = item.error?.localizedDescription ?? "Failed to load video"
                    self.isLoading = false
                default:
                    break
                }
            }
        }

        // Observe buffered time ranges
        timeRangeObservation?.invalidate()
        timeRangeObservation = item.observe(\.loadedTimeRanges, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self = self else { return }
                if let range = item.loadedTimeRanges.first?.timeRangeValue {
                    self.bufferedTime = range.start.seconds + range.duration.seconds
                }
            }
        }

        // Observe presentation size
        presentationSizeObservation?.invalidate()
        presentationSizeObservation = item.observe(\.presentationSize, options: [.new]) { [weak self] item, _ in
            Task { @MainActor in
                guard let self = self else { return }
                let size = item.presentationSize
                if size.width > 0 && size.height > 0 {
                    self.videoSize = size
                }
            }
        }

        // End of playback
        NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime, object: item)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.isPlaying = false
                    self?.currentTime = 0
                }
            }
            .store(in: &cancellables)

        player.replaceCurrentItem(with: item)
        clearLoop()
    }

    // MARK: - Playback Controls

    func play() {
        player.rate = playbackSpeed
        isPlaying = true
    }

    func pause() {
        player.pause()
        isPlaying = false
    }

    func togglePlayPause() {
        isPlaying ? pause() : play()
    }

    func stop() {
        pause()
        seek(to: 0)
    }

    func seek(to seconds: Double) {
        let clamped = max(0, min(seconds, duration))
        let time = CMTime(seconds: clamped, preferredTimescale: 600)
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = clamped
    }

    func seekRelative(_ delta: Double) {
        seek(to: currentTime + delta)
    }

    func seekToPercent(_ percent: Double) {
        seek(to: duration * max(0, min(1, percent)))
    }

    // MARK: - Volume

    func adjustVolume(by delta: Float) {
        volume = max(0, min(1, volume + delta))
    }

    func toggleMute() {
        isMuted.toggle()
    }

    // MARK: - Speed

    static let availableSpeeds: [Float] = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0, 4.0]

    func cycleSpeedUp() {
        guard let idx = Self.availableSpeeds.firstIndex(of: playbackSpeed),
              idx < Self.availableSpeeds.count - 1 else { return }
        playbackSpeed = Self.availableSpeeds[idx + 1]
    }

    func cycleSpeedDown() {
        guard let idx = Self.availableSpeeds.firstIndex(of: playbackSpeed),
              idx > 0 else { return }
        playbackSpeed = Self.availableSpeeds[idx - 1]
    }

    func setSpeed(_ speed: Float) {
        playbackSpeed = speed
    }

    // MARK: - A-B Loop

    func setLoopA() {
        loopA = currentTime
        if let b = loopB, currentTime >= b {
            loopB = nil
        }
    }

    func setLoopB() {
        guard loopA != nil else { return }
        loopB = currentTime
    }

    func clearLoop() {
        loopA = nil
        loopB = nil
    }

    func toggleLoop() {
        if isLooping {
            clearLoop()
        } else if loopA == nil {
            setLoopA()
        } else {
            setLoopB()
        }
    }

    // MARK: - Screenshot

    func captureScreenshot(savePath: String? = nil) {
        guard let asset = player.currentItem?.asset else { return }
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let time = CMTime(seconds: currentTime, preferredTimescale: 600)
        Task {
            do {
                let (image, _) = try await generator.image(at: time)
                let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
                let basePath = savePath ?? NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true).first ?? "/tmp"
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let filename = "ProPlayer_\(formatter.string(from: Date())).png"
                let fullPath = (basePath as NSString).appendingPathComponent(filename)

                if let tiffData = nsImage.tiffRepresentation,
                   let bitmapRep = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                    try pngData.write(to: URL(fileURLWithPath: fullPath))
                }
            } catch {
                // Silently handle screenshot errors
            }
        }
    }

    // MARK: - Audio Tracks

    func availableAudioTracks() -> [AVMediaSelectionOption] {
        guard let group = player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else {
            return []
        }
        return group.options
    }

    func selectAudioTrack(_ option: AVMediaSelectionOption) {
        guard let group = player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .audible) else { return }
        player.currentItem?.select(option, in: group)
    }

    // MARK: - Subtitle Tracks

    func availableSubtitleTracks() -> [AVMediaSelectionOption] {
        guard let group = player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else {
            return []
        }
        return group.options
    }

    func selectSubtitleTrack(_ option: AVMediaSelectionOption?) {
        guard let group = player.currentItem?.asset.mediaSelectionGroup(forMediaCharacteristic: .legible) else { return }
        if let option = option {
            player.currentItem?.select(option, in: group)
        } else {
            player.currentItem?.select(nil, in: group)
        }
    }

    // MARK: - Progress

    var progressPercent: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }

    var remainingTime: Double {
        max(0, duration - currentTime)
    }
}
