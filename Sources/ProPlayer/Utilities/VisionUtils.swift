import Foundation
import Vision
import AVFoundation

enum VisionUtils {
    
    /// Detects the "active" region of a video frame by finding the bounding box of non-black content.
    /// This helps in removing black bars for a perfect "Smart Fill".
    static func detectContentBounds(in pixelBuffer: CVPixelBuffer) async -> CGRect? {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        
        // We use Saliency or Attention Based requests to find where the "action" is.
        // But for black bars, a simpler approach is analyzing the pixel intensity or using 
        // a custom CoreML model. For this PoC, we'll use a simple "Saliency" request 
        // as a proxy for the actual content area.
        
        let request = VNGenerateAttentionBasedSaliencyImageRequest()
        
        do {
            try requestHandler.perform([request])
            
            guard let result = request.results?.first as? VNSaliencyImageObservation,
                  let salientObject = result.salientObjects?.first else {
                return nil
            }
            
            return salientObject.boundingBox
        } catch {
            print("Vision detection failed: \(error)")
            return nil
        }
    }
}
