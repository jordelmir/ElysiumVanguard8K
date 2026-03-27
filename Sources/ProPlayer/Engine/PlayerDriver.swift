import Foundation
@preconcurrency import AVFoundation

/// Protocol abstracting the media playback driver.
/// Enables headless testing, mock injection, and future rendering backends.
@MainActor
public protocol PlayerDriver: AnyObject {
    var player: AVPlayer { get }
    
    func play(rate: Float)
    func pause()
    func seek(to time: CMTime, completion: @escaping @Sendable (Bool) -> Void)
    func replaceItem(with item: AVPlayerItem?)
    
    /// Periodic time observation (returns a removal token).
    func addPeriodicTimeObserver(interval: CMTime, queue: DispatchQueue, handler: @escaping @Sendable (CMTime) -> Void) -> Any
    func removeTimeObserver(_ token: Any)
}

/// Production AVPlayer driver. All AVPlayer access goes through here.
@MainActor
public final class AVPlayerDriver: PlayerDriver {
    public let player = AVPlayer()
    
    public init() {}
    
    public func play(rate: Float) {
        player.rate = rate
    }
    
    public func pause() {
        player.pause()
    }
    
    public func seek(to time: CMTime, completion: @escaping @Sendable (Bool) -> Void) {
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            completion(finished)
        }
    }
    
    public func replaceItem(with item: AVPlayerItem?) {
        player.replaceCurrentItem(with: item)
    }
    
    public func addPeriodicTimeObserver(interval: CMTime, queue: DispatchQueue, handler: @escaping @Sendable (CMTime) -> Void) -> Any {
        player.addPeriodicTimeObserver(forInterval: interval, queue: queue, using: handler)
    }
    
    public func removeTimeObserver(_ token: Any) {
        player.removeTimeObserver(token)
    }
}
