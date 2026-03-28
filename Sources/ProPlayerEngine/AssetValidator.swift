import Foundation
@preconcurrency import AVFoundation

/// Deep asset validation result.
public struct AssetValidationResult: Sendable {
    public let isValid: Bool
    public let duration: TimeInterval
    public let hasVideoTrack: Bool
    public let hasAudioTrack: Bool
    public let fileSize: Int64
    public let rejection: AssetRejection?
}

/// Reason for asset rejection.
public enum AssetRejection: Sendable, Equatable {
    case notPlayable
    case zeroDuration
    case noPlayableTracks
    case fileTooLarge(Int64)
    case fileNotReadable
    case timeout
}

/// Validates assets before loading into AVPlayer.
public actor AssetValidator {
    /// Maximum file size: 50 GB
    static let maxFileSize: Int64 = 50 * 1024 * 1024 * 1024
    /// Max time allowed to parse AVAsset headers (seconds)
    static let timeoutSeconds: TimeInterval = 5.0

    public func validate(url: URL) async -> AssetValidationResult {
        // 1. File system checks
        let fm = FileManager.default
        guard fm.isReadableFile(atPath: url.path) else {
            return AssetValidationResult(
                isValid: false, duration: 0, hasVideoTrack: false,
                hasAudioTrack: false, fileSize: 0, rejection: .fileNotReadable
            )
        }
        
        let fileSize: Int64
        do {
            let attrs = try fm.attributesOfItem(atPath: url.path)
            fileSize = attrs[.size] as? Int64 ?? 0
        } catch {
            fileSize = 0
        }
        
        guard fileSize <= Self.maxFileSize else {
            return AssetValidationResult(
                isValid: false, duration: 0, hasVideoTrack: false,
                hasAudioTrack: false, fileSize: fileSize,
                rejection: .fileTooLarge(fileSize)
            )
        }
        
        // 2. AVAsset deep checks (with timeout)
        let asset = AVURLAsset(url: url)
        
        do {
            return try await withThrowingTaskGroup(of: AssetValidationResult.self) { group in
                // Worker task
                group.addTask {
                    let isPlayable = try await asset.load(.isPlayable)
                    guard isPlayable else {
                        return AssetValidationResult(
                            isValid: false, duration: 0, hasVideoTrack: false,
                            hasAudioTrack: false, fileSize: fileSize, rejection: .notPlayable
                        )
                    }
                    
                    let duration = try await asset.load(.duration).seconds
                    guard duration.isFinite && duration > 0 else {
                        return AssetValidationResult(
                            isValid: false, duration: 0, hasVideoTrack: false,
                            hasAudioTrack: false, fileSize: fileSize, rejection: .zeroDuration
                        )
                    }
                    
                    let tracks = try await asset.load(.tracks)
                    let hasVideo = tracks.contains { $0.mediaType == .video }
                    let hasAudio = tracks.contains { $0.mediaType == .audio }
                    
                    guard hasVideo || hasAudio else {
                        return AssetValidationResult(
                            isValid: false, duration: duration, hasVideoTrack: false,
                            hasAudioTrack: false, fileSize: fileSize, rejection: .noPlayableTracks
                        )
                    }
                    
                    return AssetValidationResult(
                        isValid: true, duration: duration, hasVideoTrack: hasVideo,
                        hasAudioTrack: hasAudio, fileSize: fileSize, rejection: nil
                    )
                }
                
                // Timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: UInt64(Self.timeoutSeconds * 1_000_000_000))
                    throw CancellationError()
                }
                
                // The first one to finish wins
                let result = try await group.next()!
                // Cancel the loser
                group.cancelAll()
                return result
            }
        } catch is CancellationError {
            return AssetValidationResult(
                isValid: false, duration: 0, hasVideoTrack: false,
                hasAudioTrack: false, fileSize: fileSize, rejection: .timeout
            )
        } catch {
            return AssetValidationResult(
                isValid: false, duration: 0, hasVideoTrack: false,
                hasAudioTrack: false, fileSize: fileSize, rejection: .notPlayable
            )
        }
    }
}
