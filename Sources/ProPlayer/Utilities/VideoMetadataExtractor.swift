import Foundation
import AVFoundation
import AppKit
import ProPlayerEngine

enum VideoMetadataExtractor {

    static func extractMetadata(from url: URL) async -> VideoItem {
        let asset = AVURLAsset(url: url)
        var item = VideoItem(url: url, dateAdded: fileCreationDate(url) ?? Date())

        // Get file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            item.fileSize = size
        }

        do {
            // Load and analyze properties in parallel
            async let duration = try asset.load(.duration)
            async let tracks = try asset.load(.tracks)
            
            let loadedDuration = try await duration
            item.duration = loadedDuration.seconds

            let videoTracks = try await tracks.filter { $0.mediaType == .video }
            if let videoTrack = videoTracks.first {
                let size = try await videoTrack.load(.naturalSize)
                item.width = Int(size.width)
                item.height = Int(size.height)
                
                // Track metadata like codec
                if let formatDescription = try await videoTrack.load(.formatDescriptions).first {
                    item.codec = CMFormatDescriptionGetMediaType(formatDescription).description
                }
            }
        } catch {
            print("Error loading metadata for \(url): \(error)")
        }

        return item
    }

    /// Generates a thumbnail for a video.
    static func generateThumbnail(for url: URL) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 400, height: 400)

        do {
            let (image, _) = try await generator.image(at: .zero)
            return NSImage(cgImage: image, size: .zero)
        } catch {
            print("Thumbnail generation failed: \(error)")
        }
        
        return nil
    }

    private static func saveNSImage(_ image: NSImage, to path: String) -> Bool {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
            return false
        }
        do {
            try jpegData.write(to: URL(fileURLWithPath: path))
            return true
        } catch {
            return false
        }
    }

    // Parallel extraction helper
    static func extractMetadata(from urls: [URL]) async -> [VideoItem] {
        await withTaskGroup(of: VideoItem?.self) { group in
            for url in urls {
                group.addTask {
                    await extractMetadata(from: url)
                }
            }
            
            var results: [VideoItem] = []
            for await item in group {
                if let item = item { results.append(item) }
            }
            return results
        }
    }

    private static func fileCreationDate(_ url: URL) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attrs?[.creationDate] as? Date
    }
}
