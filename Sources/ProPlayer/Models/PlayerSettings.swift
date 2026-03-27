import Foundation
import AVFoundation

// MARK: - Video Gravity Mode

enum VideoGravityMode: String, Codable, CaseIterable, Identifiable {
    case fit = "Fit"
    case fill = "Fill"
    case stretch = "Stretch"
    case smartFill = "Smart Fill"
    case customZoom = "Zoom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .fit: return "rectangle.arrowtriangle.2.inward"
        case .fill: return "rectangle.arrowtriangle.2.outward"
        case .stretch: return "arrow.up.left.and.arrow.down.right"
        case .smartFill: return "sparkles.rectangle.stack"
        case .customZoom: return "plus.magnifyingglass"
        }
    }

    var description: String {
        switch self {
        case .fit: return "Letterboxed — no cropping"
        case .fill: return "Fills screen — crops edges"
        case .stretch: return "Stretches to fill — no black bars"
        case .smartFill: return "Fills with minimal distortion"
        case .customZoom: return "Manual zoom and pan"
        }
    }

    var avGravity: AVLayerVideoGravity {
        switch self {
        case .fit: return .resizeAspect
        case .fill: return .resizeAspectFill
        case .stretch: return .resize
        case .smartFill: return .resizeAspectFill
        case .customZoom: return .resizeAspect
        }
    }
}

// MARK: - Sort Option

enum LibrarySortOption: String, Codable, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case dateAddedOldest = "Date Added (Oldest)"
    case name = "Name"
    case duration = "Duration"
    case fileSize = "File Size"
    case lastPlayed = "Last Played"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .dateAdded: return "calendar.badge.clock"
        case .dateAddedOldest: return "calendar"
        case .name: return "textformat.abc"
        case .duration: return "timer"
        case .fileSize: return "doc"
        case .lastPlayed: return "play.circle"
        }
    }
}

// MARK: - Library View Mode

enum LibraryViewMode: String, Codable, CaseIterable {
    case grid = "Grid"
    case list = "List"

    var icon: String {
        switch self {
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

// MARK: - Player Settings

struct PlayerSettings: Codable, Equatable {
    var defaultGravityMode: VideoGravityMode = .fit
    var resumePlayback: Bool = true
    var autoPlayNext: Bool = true
    var screenshotSavePath: String = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true).first ?? ""
    var showOSD: Bool = true
    var osdDuration: Double = 2.0
    var controlsAutoHideDelay: Double = 3.0
    var librarySortOption: LibrarySortOption = .dateAdded
    var libraryViewMode: LibraryViewMode = .grid

    // Subtitle defaults
    var subtitleFontSize: Double = 24
    var subtitleColor: String = "white"
    var subtitleBackgroundOpacity: Double = 0.6

    // Audio defaults
    var defaultVolume: Float = 0.8

    static func load() -> PlayerSettings {
        guard let data = UserDefaults.standard.data(forKey: "ProPlayerSettings"),
              let settings = try? JSONDecoder().decode(PlayerSettings.self, from: data) else {
            return PlayerSettings()
        }
        return settings
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "ProPlayerSettings")
        }
    }
}
