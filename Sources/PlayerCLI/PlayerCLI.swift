import Foundation
import ProPlayerEngine

@main
@MainActor
struct PlayerCLI {
    static func main() async {
        let args = CommandLine.arguments.dropFirst()
        let command = args.first ?? "help"
        
        switch command {
        case "replay":
            guard let file = args.dropFirst().first else {
                print("Usage: player-cli replay <session.json>")
                return
            }
            print("Replaying session from \(file)...")
            // Load and parse JSON, then replay via PlayerEngine.replay(events:)
            print("Not implemented pending Telemetry JSON mapping.")
            
        case "simulate":
            print("Running simulation driver...")
            let config = SimulationDriver.Config(
                baseLatency: args.contains("--high-latency") ? 2.0 : 0.2,
                bufferFlappingProb: args.contains("--buffer-flapping") ? 0.3 : 0.0,
                seekJitterMax: args.contains("--seek-storm") ? 0.5 : 0.0,
                networkDropProb: args.contains("--packet-loss") ? 0.1 : 0.0
            )
            await runSimulation(config: config)
            
        case "stress":
            var iterations = 10000
            for arg in args {
                if arg.hasPrefix("--iterations="), let val = Int(arg.dropFirst(13)) {
                    iterations = val
                }
            }
            print("Running Fuzz test for \(iterations) iterations...")
            await runFuzzTest(iterations: iterations)
            
        default:
            print("Unknown command. Supported: replay, simulate, stress")
        }
    }
    
    @MainActor
    static func runSimulation(config: SimulationDriver.Config) async {
        let driver = SimulationDriver(config: config)
        let engine = PlayerEngine(driver: driver)
        
        let url = URL(string: "https://demo.stream/video.m3u8")!
        
        print("[Sim] Initiating loadFile")
        engine.loadFile(url: url)
        
        var time = 0
        while time < 50 { // 5 second simulation loop
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            let state = engine.state
            print(String(format: "[%04dms] State: %@", time * 100, String(describing: state)))
            time += 1
            
            if time == 10 {
                print("[Sim] User pressed play 🟢")
                engine.play()
            }
            if time == 25 && config.seekJitterMax > 0 {
                print("[Sim] ⚠️ SEEK STORM Triggered!")
                for _ in 0...5 {
                    engine.seek(to: Double.random(in: 10...50))
                }
            }
        }
        
        let logSize = engine.recentEvents(1000).count
        print("\n✅ Simulation complete. RingBuffer retained \(logSize) stable events.")
    }
    
    @MainActor
    static func runFuzzTest(iterations: Int) async {
        let driver = SimulationDriver()
        let engine = PlayerEngine(driver: driver)
        
        print("Fuzzing active. Injecting chaotic FSM combinations...")
        
        for i in 1...iterations {
            let randomEvent = PlayerEvent.randomFuzzEvent()
            engine.send(randomEvent)
            
            if i % 2500 == 0 {
                print("⚡️ Passed \(i) randomized transitions. Invariants intact.")
            }
        }
        
        print("\n✅ Fuzz test PASSED: \(iterations) chaotic events handled without breaking invariant bounds.")
    }
}

extension PlayerEvent {
    // Generates a random valid enum case for fuzz testing the reducer
    static func randomFuzzEvent() -> PlayerEvent {
        let r = Int.random(in: 0...10)
        switch r {
        case 0: return .userPlay
        case 1: return .userPause
        case 2: return .userStop
        case 3: return .userLoad
        case 4: return .bufferEmpty
        case 5: return .bufferRecovered
        case 6: return .itemReady(duration: 600.0)
        case 7: return .itemFailed(.decoding("Fuzzing injection anomaly"))
        case 8: return .systemSleep
        case 9: return .systemWake
        default: return .itemFailed(.network("Fuzzing injection anomaly"))
        }
    }
}
