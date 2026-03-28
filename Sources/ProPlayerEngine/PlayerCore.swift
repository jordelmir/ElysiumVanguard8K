import Foundation
@preconcurrency import AVFoundation

/// Pure async actor for heavy media operations.
/// No callbacks, no state — just functions.
public actor PlayerCore {

    /// Pre-processes an asset and returns thread-safe metadata.
    public func loadMetadata(at url: URL) async throws -> MediaMetadata {
        let asset = AVURLAsset(url: url)
        let isPlayable = try await asset.load(.isPlayable)
        let duration = try await asset.load(.duration).seconds
        
        var audio: [AVMediaSelectionOption] = []
        var subtitles: [AVMediaSelectionOption] = []
        
        if let group = try await asset.loadMediaSelectionGroup(for: .audible) {
            audio = group.options
        }
        if let group = try await asset.loadMediaSelectionGroup(for: .legible) {
            subtitles = group.options
        }
        
        return MediaMetadata(
            isPlayable: isPlayable,
            duration: duration.isFinite ? duration : 0,
            audioOptions: audio,
            subtitleOptions: subtitles
        )
    }

    /// Selects a media option within an item's selection group.
    public func selectOption(_ option: AVMediaSelectionOption?, in item: AVPlayerItem, characteristic: AVMediaCharacteristic) async {
        do {
            guard let group = try await item.asset.loadMediaSelectionGroup(for: characteristic) else { return }
            item.select(option, in: group)
        } catch {}
    }
}

// MARK: - Sendable Types for Actor Boundaries

public struct MediaMetadata: Sendable {
    public let isPlayable: Bool
    public let duration: Double
    public let audioOptions: [AVMediaSelectionOption]
    public let subtitleOptions: [AVMediaSelectionOption]
}
