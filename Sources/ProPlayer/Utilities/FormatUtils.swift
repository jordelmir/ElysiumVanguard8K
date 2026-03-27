import Foundation

enum FormatUtils {

    // MARK: - Time Formatting

    static func timeString(from seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00" }
        let totalSeconds = Int(max(0, seconds))
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%02d:%02d", minutes, secs)
    }

    static func detailedTimeString(from seconds: Double) -> String {
        guard seconds.isFinite && !seconds.isNaN else { return "00:00:00.000" }
        let totalSeconds = max(0, seconds)
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        let secs = Int(totalSeconds) % 60
        let ms = Int((totalSeconds.truncatingRemainder(dividingBy: 1)) * 1000)
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, secs, ms)
    }

    // MARK: - File Size Formatting

    static func fileSizeString(from bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Resolution Formatting

    static func resolutionString(width: Int, height: Int) -> String {
        if height >= 2160 { return "4K (\(width)×\(height))" }
        if height >= 1440 { return "2K (\(width)×\(height))" }
        if height >= 1080 { return "1080p (\(width)×\(height))" }
        if height >= 720 { return "720p (\(width)×\(height))" }
        if height >= 480 { return "480p (\(width)×\(height))" }
        return "\(width)×\(height)"
    }

    // MARK: - Codec Name Formatting

    static func codecDisplayName(_ codecType: String) -> String {
        switch codecType.lowercased() {
        case "avc1", "h264", "h.264": return "H.264 / AVC"
        case "hvc1", "hev1", "h265", "h.265", "hevc": return "H.265 / HEVC"
        case "av01", "av1": return "AV1"
        case "vp9", "vp09": return "VP9"
        case "mp4v": return "MPEG-4"
        case "apcn", "apch", "apcs", "apco", "ap4h": return "Apple ProRes"
        case "aac", "mp4a": return "AAC"
        case "ac-3", "ec-3": return "Dolby Digital"
        case "alac": return "Apple Lossless"
        case "flac": return "FLAC"
        case "opus": return "Opus"
        default: return codecType
        }
    }

    // MARK: - Date Formatting

    static func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func relativeDateString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Speed Formatting

    static func speedString(_ speed: Float) -> String {
        if speed == 1.0 { return "Normal" }
        if speed == Float(Int(speed)) {
            return "\(Int(speed))×"
        }
        return String(format: "%.2g×", speed)
    }
}
