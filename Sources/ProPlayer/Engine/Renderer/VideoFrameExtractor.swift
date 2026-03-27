import Foundation
import CoreMedia
@preconcurrency import AVFoundation

/// Handles the raw extraction of CVPixelBuffers from the AVPlayer pipeline.
@MainActor
public final class VideoFrameExtractor: ObservableObject {
    private var videoOutput: AVPlayerItemVideoOutput?
    private weak var playerItem: AVPlayerItem?
    
    /// The latest decoded hardware frame mapped to the precise VSync time.
    @Published public private(set) var currentPixelBuffer: CVPixelBuffer?
    
    public init() {}
    
    /// Attaches the extractor to a new player item.
    public func attach(to item: AVPlayerItem?) {
        // Clean up old output
        if let output = videoOutput, let oldItem = playerItem {
            oldItem.remove(output)
            videoOutput = nil
        }
        
        guard let item = item else {
            self.playerItem = nil
            self.currentPixelBuffer = nil
            return
        }
        
        self.playerItem = item
        
        // We use bi-planar 420 YpCbCr natively for speed, but let's stick to 32BGRA
        // initially so we can use CoreImage easily before switching to raw Metal YUV.
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            String(kCVPixelBufferPixelFormatTypeKey): Int(kCVPixelFormatType_32BGRA),
            String(kCVPixelBufferMetalCompatibilityKey): true
        ])
        // Note: You must suppress automatic display to get correct manual times
        output.suppressesPlayerRendering = true 
        
        item.add(output)
        self.videoOutput = output
    }
    
    /// Queries the video output for the closest frame matching the hardware presentation time.
    /// Call this inside the displayLink vsync callback.
    public func extractFrame(forHostTime hostTime: CFTimeInterval) {
        guard let output = videoOutput else { return }
        
        // Convert the host display time to the item's internal media time clock
        let itemTime = output.itemTime(forHostTime: hostTime)
        guard itemTime.isValid && itemTime.isNumeric else { return }
        
        if output.hasNewPixelBuffer(forItemTime: itemTime) {
            var presentationTime = CMTime.zero
            if let pixelBuffer = output.copyPixelBuffer(forItemTime: itemTime, itemTimeForDisplay: &presentationTime) {
                // Publish new frame to the UI / Shader Pipeline
                self.currentPixelBuffer = pixelBuffer
            }
        }
    }
}
