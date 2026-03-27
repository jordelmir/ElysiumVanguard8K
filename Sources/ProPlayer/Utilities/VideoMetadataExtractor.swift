import Foundation
import AVFoundation
import AppKit

enum VideoMetadataExtractor {

    static func extractMetadata(from url: URL) async -> VideoItem {
        let asset = AVURLAsset(url: url)
        var item = VideoItem(url: url, dateAdded: fileCreationDate(url) ?? Date())

        // Get file size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let size = attrs[.size] as? Int64 {
            item.fileSize = size
        }

        // Load asset properties
        do {
            let duration = try await asset.load(.duration)
            item.duration = duration.seconds.isFinite ? duration.seconds : 0

            let tracks = try await asset.load(.tracks)
            if let videoTrack = tracks.first(where: { $0.mediaType == .video }) {
                let size = try await videoTrack.load(.naturalSize)
                let transform = try await videoTrack.load(.preferredTransform)
                let transformedSize = size.applying(transform)
                item.width = Int(abs(transformedSize.width))
                item.height = Int(abs(transformedSize.height))

                let nominalFrameRate = try await videoTrack.load(.nominalFrameRate)
                item.fps = Double(nominalFrameRate)

                // Codec
                let descriptions = try await videoTrack.load(.formatDescriptions)
                if let desc = descriptions.first {
                    let codecType = CMFormatDescriptionGetMediaSubType(desc)
                    item.codec = fourCharCodeToString(codecType)
                }
            }
        } catch {
            // Use defaults if metadata extraction fails
        }

        return item
    }

    static func generateThumbnail(for url: URL, at time: Double = 1.0, size: CGSize = CGSize(width: 320, height: 180)) async -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = size

        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        do {
            let (cgImage, _) = try await generator.image(at: cmTime)
            return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        } catch {
            return nil
        }
    }

    static func saveThumbnail(_ image: NSImage, to path: String) -> Bool {
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

    // MARK: - Helpers

    private static func fourCharCodeToString(_ code: FourCharCode) -> String {
        let bytes: [UInt8] = [
            UInt8((code >> 24) & 0xFF),
            UInt8((code >> 16) & 0xFF),
            UInt8((code >> 8) & 0xFF),
            UInt8(code & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "\(code)"
    }

    private static func fileCreationDate(_ url: URL) -> Date? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        return attrs?[.creationDate] as? Date
    }
}
