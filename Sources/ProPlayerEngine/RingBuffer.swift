import Foundation

/// Lock-free ring buffer for O(1) append event logging.
/// Thread-safe through MainActor isolation (same as PlayerEngine).
@MainActor
public final class RingBuffer<T> {
    private var buffer: [T?]
    private var head: Int = 0
    private var count: Int = 0
    let capacity: Int
    
    public init(capacity: Int = 256) {
        self.capacity = capacity
        self.buffer = Array(repeating: nil, count: capacity)
    }
    
    /// O(1) append. Overwrites oldest when full.
    public func append(_ element: T) {
        buffer[head] = element
        head = (head + 1) % capacity
        if count < capacity { count += 1 }
    }
    
    /// Returns all logged elements in chronological order.
    public var elements: [T] {
        if count < capacity {
            return buffer[0..<count].compactMap { $0 }
        }
        let tail = buffer[head..<capacity].compactMap { $0 }
        let front = buffer[0..<head].compactMap { $0 }
        return tail + front
    }
    
    /// Returns the last N elements.
    public func last(_ n: Int) -> [T] {
        let all = elements
        return Array(all.suffix(n))
    }
    
    public func clear() {
        buffer = Array(repeating: nil, count: capacity)
        head = 0
        count = 0
    }
    
    public var isEmpty: Bool { count == 0 }
    
    /// Safe snapshot for export / offline replay.
    /// Returns a copy — safe to serialize or send across actors.
    public func snapshot() -> [T] {
        return elements
    }
}

/// A logged FSM event with monotonic ID for deterministic replay.
public struct LoggedEvent: Sendable {
    public let id: UInt64
    public let timestamp: UInt64 // mach_absolute_time for nanosecond precision
    public let event: PlayerEvent
    public let stateBefore: PlaybackState
    public let stateAfter: PlaybackState
}
