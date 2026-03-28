import Foundation
import CoreGraphics

public struct VideoItem: Identifiable, Codable, Hashable, Sendable {
    public let id: UUID
    public let url: URL
    public var title: String
    public var duration: Double
    public var width: Int
    public var height: Int
    public var codec: String
    public var fps: Double
    public var fileSize: Int64
    public var dateAdded: Date
    public var lastPlayed: Date?
    public var playbackPosition: Double?
    public var thumbnailPath: String?

    public init(
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

    public var resolutionLabel: String {
        FormatUtils.resolutionString(width: width, height: height)
    }

    public var durationLabel: String {
        FormatUtils.timeString(from: duration)
    }

    public var fileSizeLabel: String {
        FormatUtils.fileSizeString(from: fileSize)
    }

    public var codecLabel: String {
        FormatUtils.codecDisplayName(codec)
    }

    public var dateAddedLabel: String {
        FormatUtils.dateString(from: dateAdded)
    }

    public var aspectRatio: CGFloat {
        guard height > 0 else { return 16.0 / 9.0 }
        return CGFloat(width) / CGFloat(height)
    }

    public var hasResumePosition: Bool {
        guard let pos = playbackPosition else { return false }
        return pos > 5 && pos < (duration - 10)
    }

    public static let supportedExtensions: Set<String> = [
        "mp4", "m4v", "mov", "avi", "mkv", "wmv", "flv", "webm",
        "mpg", "mpeg", "3gp", "ts", "mts", "m2ts", "vob", "ogv"
    ]

    public static func isVideoFile(_ url: URL) -> Bool {
        supportedExtensions.contains(url.pathExtension.lowercased())
    }
}
