import Foundation

struct Playlist: Identifiable, Codable {
    let id: UUID
    var name: String
    var items: [VideoItem]
    var currentIndex: Int
    var repeatMode: RepeatMode
    var shuffleEnabled: Bool
    var dateCreated: Date
    var dateModified: Date

    enum RepeatMode: String, Codable, CaseIterable {
        case off = "Off"
        case one = "Repeat One"
        case all = "Repeat All"

        var icon: String {
            switch self {
            case .off: return "repeat"
            case .one: return "repeat.1"
            case .all: return "repeat"
            }
        }
    }

    init(
        id: UUID = UUID(),
        name: String = "Untitled Playlist",
        items: [VideoItem] = [],
        currentIndex: Int = 0,
        repeatMode: RepeatMode = .off,
        shuffleEnabled: Bool = false
    ) {
        self.id = id
        self.name = name
        self.items = items
        self.currentIndex = currentIndex
        self.repeatMode = repeatMode
        self.shuffleEnabled = shuffleEnabled
        self.dateCreated = Date()
        self.dateModified = Date()
    }

    var currentItem: VideoItem? {
        guard items.indices.contains(currentIndex) else { return nil }
        return items[currentIndex]
    }

    var hasNext: Bool {
        currentIndex < items.count - 1 || repeatMode == .all
    }

    var hasPrevious: Bool {
        currentIndex > 0 || repeatMode == .all
    }

    var totalDuration: Double {
        items.reduce(0) { $0 + $1.duration }
    }

    mutating func next() -> VideoItem? {
        if shuffleEnabled {
            guard items.count > 1 else { return items.first }
            var newIndex = currentIndex
            while newIndex == currentIndex {
                newIndex = Int.random(in: 0..<items.count)
            }
            currentIndex = newIndex
        } else if currentIndex < items.count - 1 {
            currentIndex += 1
        } else if repeatMode == .all {
            currentIndex = 0
        } else {
            return nil
        }
        return currentItem
    }

    mutating func previous() -> VideoItem? {
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = max(0, items.count - 1)
        } else {
            return nil
        }
        return currentItem
    }

    mutating func addItem(_ item: VideoItem) {
        items.append(item)
        dateModified = Date()
    }

    mutating func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
        if currentIndex >= items.count {
            currentIndex = max(0, items.count - 1)
        }
        dateModified = Date()
    }

    mutating func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        dateModified = Date()
    }
}
