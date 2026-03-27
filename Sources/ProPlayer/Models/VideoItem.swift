import Foundation
import CoreGraphics

struct VideoItem: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    var title: String
    var duration: Double
    var width: Int
    var height: Int
    var codec: String
    var fps: Double
    var fileSize: Int64
    var dateAdded: Date
    var lastPlayed: Date?
    var playbackPosition: Double?
    var thumbnailPath: String?

    init(
        id: UUID = UUID(),
        url: URL,
        title: String? = nil,
        duration: Double = 0,
        width: Int = 0,
        height: Int = 0,
        codec: String = "",
        fps: Double = 0,
        fileSize: Int64 = 0,
        dateAdded: Date = Date(),
        lastPlayed: Date? = nil,
        playbackPosition: Double? = nil,
        thumbnailPath: String? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title ?? url.deletingPathExtension().lastPathComponent
        self.duration = duration
        self.width = width
        self.height = height
        self.codec = codec
        self.fps = fps
        self.fileSize = fileSize
        self.dateAdded = dateAdded
        self.lastPlayed = lastPlayed
        self.playbackPosition = playbackPosition
        self.thumbnailPath = thumbnailPath
    }

    var resolutionLabel: String {
        FormatUtils.resolutionString(width: width, height: height)
    }

    var durationLabel: String {
        FormatUtils.timeString(from: duration)
    }

    var fileSizeLabel: String {
        FormatUtils.fileSizeString(from: fileSize)
    }

    var codecLabel: String {
        FormatUtils.codecDisplayName(codec)
    }

    var dateAddedLabel: String {
        FormatUtils.dateString(from: dateAdded)
    }

    var aspectRatio: CGFloat {
        guard height > 0 else { return 16.0 / 9.0 }
        return CGFloat(width) / CGFloat(height)
    }

    var hasResumePosition: Bool {
        guard let pos = playbackPosition else { return false }
        return pos > 5 && pos < (duration - 10)
    }

    static let supportedExtensions: Set<String> = [
        "mp4", "m4v", "mov", "avi", "mkv", "wmv", "flv", "webm",
        "mpg", "mpeg", "3gp", "ts", "mts", "m2ts", "vob", "ogv"
    ]

    static func isVideoFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}
