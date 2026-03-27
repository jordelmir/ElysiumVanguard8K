import Foundation
import CoreVideo

/// Delegate for handling periodic vsync pulses from the display link.
@MainActor
public protocol VideoDisplayLinkDelegate: AnyObject {
    /// Fired exactly when the display is ready to accept a new frame.
    /// - Parameter hostTime: The predicted mach_absolute_time for the next vsync.
    func displayLink(didFireWithHostTime hostTime: CFTimeInterval)
}

/// A macOS-specific hardware-synced vsync timer ensuring 0-stutter frame pacing.
public final class VideoDisplayLink: @unchecked Sendable {
    private var displayLink: CVDisplayLink?
    private weak var delegate: VideoDisplayLinkDelegate?
    private var isRunning = false
    
    // Lock for safe start/stop checking across threads
    private let lock = NSLock()

    public init() {
        var linkOut: CVDisplayLink?
        // Note: For multi-monitor, you might want to bind this to the specific NSScreen later.
        let status = CVDisplayLinkCreateWithActiveCGDisplays(&linkOut)
        if status == kCVReturnSuccess, let link = linkOut {
            self.displayLink = link
            setupCallback()
        } else {
            print("[VideoDisplayLink] Failed to create CVDisplayLink")
        }
    }

    public func setDelegate(_ delegate: VideoDisplayLinkDelegate) {
        self.delegate = delegate
    }

    private func setupCallback() {
        guard let displayLink = displayLink else { return }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, callbackContext) -> CVReturn in
            let link = Unmanaged<VideoDisplayLink>.fromOpaque(callbackContext!).takeUnretainedValue()
            
            // Re-calculate the host refresh time in seconds (CoreVideo gives us mach time)
            let hostTime = Double(inOutputTime.pointee.hostTime) / Double(VideoDisplayLink.timebaseInfo.denom) * Double(VideoDisplayLink.timebaseInfo.numer) / 1_000_000_000.0
            
            // Dispatch to the MainActor for rendering integration
            Task { @MainActor in
                link.delegate?.displayLink(didFireWithHostTime: hostTime)
            }
            return kCVReturnSuccess
        }, context)
    }

    public func start() {
        lock.lock(); defer { lock.unlock() }
        guard let displayLink = displayLink, !isRunning else { return }
        CVDisplayLinkStart(displayLink)
        isRunning = true
    }

    public func stop() {
        lock.lock(); defer { lock.unlock() }
        guard let displayLink = displayLink, isRunning else { return }
        CVDisplayLinkStop(displayLink)
        isRunning = false
    }

    deinit {
        stop()
    }
    
    // For converting mach_absolute_time to seconds
    private static var timebaseInfo: mach_timebase_info_data_t = {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        return info
    }()
}
