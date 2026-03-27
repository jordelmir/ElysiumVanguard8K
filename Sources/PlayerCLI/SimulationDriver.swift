import Foundation
import CoreMedia
@preconcurrency import AVFoundation
import ProPlayerEngine

@MainActor
final class SimulationDriver: PlayerDriver {
    let player = AVPlayer() // Dummy object to satisfy protocol requirement
    
    struct Config: Sendable {
        var baseLatency: TimeInterval = 0.2
        var bufferFlappingProb: Double = 0.0 // 0 to 1
        var seekJitterMax: TimeInterval = 0.1
        var networkDropProb: Double = 0.0
    }
    
    private let config: Config
    private var callbackHandler: (@Sendable (PlayerEvent) -> Void)?
    
    // Internal state simulation
    private var isPlaying = false
    private var currentTime: CMTime = .zero
    private var activeSeekCount = 0
    private var playTask: Task<Void, Never>?
    
    init(config: Config = Config()) {
        self.config = config
    }
    
    func setHandler(_ handler: @escaping @Sendable (PlayerEvent) -> Void) {
        self.callbackHandler = handler
    }
    
    func replaceItem(with item: AVPlayerItem?) {
        guard item != nil else {
            playTask?.cancel()
            return
        }
        
        let handler = self.callbackHandler
        let cfg = self.config
        
        Task {
            // Simulate network loading
            try? await Task.sleep(nanoseconds: UInt64(cfg.baseLatency * 1_000_000_000))
            
            if Double.random(in: 0...1) < cfg.networkDropProb {
                handler?(.itemFailed(.network("Simulated network drop during load")))
                return
            }
            
            handler?(.itemReady(duration: 600.0)) // 10 minutes simulated content
        }
    }
    
    func play(rate: Float) {
        guard rate > 0 else {
            pause()
            return
        }
        
        isPlaying = true
        let handler = self.callbackHandler
        let cfg = self.config
        
        playTask?.cancel()
        playTask = Task {
            // Apply play request latency
            try? await Task.sleep(nanoseconds: UInt64(cfg.baseLatency * 0.5 * 1_000_000_000))
            guard !Task.isCancelled else { return }
            
            // Continuous playback loop
            while !Task.isCancelled {
                // Buffer Flapping simulation
                if cfg.bufferFlappingProb > 0 && Double.random(in: 0...1) < cfg.bufferFlappingProb {
                    handler?(.bufferEmpty)
                    try? await Task.sleep(nanoseconds: 1_000_000_000) // stall for 1s
                    handler?(.bufferRecovered)
                }
                
                try? await Task.sleep(nanoseconds: 250_000_000) // 250ms tick
            }
        }
    }
    
    func pause() {
        isPlaying = false
        playTask?.cancel()
    }
    
    func seek(to time: CMTime, completion: @escaping @Sendable (Bool) -> Void) {
        let currentSeekId = activeSeekCount + 1
        activeSeekCount = currentSeekId
        
        let jitter = Double.random(in: 0...config.seekJitterMax)
        let delayNs = UInt64((config.baseLatency + jitter) * 1_000_000_000)
        
        Task {
            try? await Task.sleep(nanoseconds: delayNs)
            
            // Out of order seek completion happens if a newer seek was dispatched
            // while we were sleeping, overriding ours.
            let isLatest = (self.activeSeekCount == currentSeekId)
            
            // The FSM seek state protection should handle the boolean correctly
            // but the driver's job is to fulfill the callback regardless.
            completion(isLatest)
        }
    }
    
    func addPeriodicTimeObserver(interval: CMTime, queue: DispatchQueue, handler: @escaping @Sendable (CMTime) -> Void) -> Any {
        let task = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(interval.seconds * 1_000_000_000))
                if self.isPlaying {
                    let simulatedStep = interval.seconds
                    self.currentTime = CMTime(seconds: self.currentTime.seconds + simulatedStep, preferredTimescale: 600)
                    let current = self.currentTime
                    queue.async { handler(current) }
                }
            }
        }
        return task
    }
    
    func removeTimeObserver(_ observer: Any) {
        (observer as? Task<Void, Never>)?.cancel()
    }
}
