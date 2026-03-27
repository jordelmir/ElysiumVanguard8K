import Foundation
import AVFoundation
import Vision

@MainActor
final class VideoContentAnalyzer: ObservableObject {
    @Published var contentBounds: CGRect?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var detectionTask: Task<Void, Never>?
    
    func setup(with item: AVPlayerItem) {
        let output = AVPlayerItemVideoOutput(pixelBufferAttributes: [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ])
        item.add(output)
        self.videoOutput = output
        startDetectionLoop(for: item)
    }
    
    private func startDetectionLoop(for item: AVPlayerItem) {
        detectionTask?.cancel()
        detectionTask = Task {
            while !Task.isCancelled {
                // Analyze every 2 seconds to save GPU/CPU
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                
                guard let output = videoOutput, item.status == .readyToPlay else { continue }
                
                let time = item.currentTime()
                if output.hasNewPixelBuffer(forItemTime: time),
                   let buffer = output.copyPixelBuffer(forItemTime: time, itemTimeForDisplay: nil) {
                    if let bounds = await VisionUtils.detectContentBounds(in: buffer) {
                        await MainActor.run {
                            self.contentBounds = bounds
                        }
                    }
                }
            }
        }
    }
    
    func stop() {
        detectionTask?.cancel()
        videoOutput = nil
    }
}
