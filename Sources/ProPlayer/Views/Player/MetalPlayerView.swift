import SwiftUI
import CoreVideo
import Combine
import MetalKit
import ProPlayerEngine

struct MetalPlayerView: NSViewRepresentable {
    @ObservedObject var engine: PlayerEngine
    
    func makeNSView(context: Context) -> MTKView {
        // Use the engine's existing renderer instead of creating a new one
        let renderer = engine.renderer
        context.coordinator.renderer = renderer
        
        // Link the engine's frame extractor output to the renderer's input
        context.coordinator.setupObservation(for: engine, renderer: renderer)
        
        // Configure the MTKView for continuous playback
        let mtkView = renderer.mtkView
        mtkView.autoresizingMask = [.width, .height]
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        // Sync gravity mode and rendering tier from engine to renderer
        if let renderer = context.coordinator.renderer {
            renderer.gravityMode = engine.gravityMode
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    @MainActor
    class Coordinator: NSObject {
        var renderer: MetalVideoRenderer?
        private var cancellable: AnyCancellable?
        
        func setupObservation(for engine: PlayerEngine, renderer: MetalVideoRenderer) {
            cancellable = engine.frameExtractor.$currentPixelBuffer
                .receive(on: DispatchQueue.main)
                .sink { [weak renderer] buffer in
                    renderer?.currentPixelBuffer = buffer
                }
        }
    }
}
