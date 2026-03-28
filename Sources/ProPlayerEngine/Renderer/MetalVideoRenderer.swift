import Metal
import MetalKit
import AVFoundation

public final class MetalVideoRenderer: NSObject, MTKViewDelegate {
    
    struct Uniforms {
        var viewportSize: simd_uint2
        var contentSize: simd_uint2
        var gravityMode: simd_uint1
        var renderingTier: simd_uint1
        var sharpnessWeight: simd_float1
        var ambientIntensity: simd_float1
        var offset: simd_float2
        var time: simd_float1
        var matrixIntensity: simd_float1
    }
    
    private let startTime = Date()
    
    // Settings Reference
    public var gravityMode: VideoGravityMode = .fill
    public var renderingTier: SuperResolutionTier = .upscale4k
    public var ambientIntensity: Double = 0.4
    public var matrixIntensity: Double = 0.0
    public var currentPixelBuffer: CVPixelBuffer? {
        didSet {
            // Trigger a redraw whenever we get a new frame
            mtkView.setNeedsDisplay(mtkView.bounds)
        }
    }
    
    public override init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("[MetalVideoRenderer] Fatal: Metal is unsupported.")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.mtkView = MTKView(frame: .zero, device: device)
        
        super.init()
        
        self.mtkView.delegate = self
        self.mtkView.framebufferOnly = true
        self.mtkView.colorPixelFormat = .bgra8Unorm
        self.mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        // Use enableSetNeedsDisplay for demand-driven rendering
        // Frame updates are triggered by setting currentPixelBuffer
        self.mtkView.enableSetNeedsDisplay = true
        self.mtkView.isPaused = true
        
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
        setupPipeline()
    }
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    public let mtkView: MTKView
    private var textureCache: CVMetalTextureCache?
    
    private var renderPipelineState: MTLRenderPipelineState?
    private var computePipelineState: MTLComputePipelineState? 
    
    private func setupPipeline() {
        let bundle = Bundle.module
        var library: MTLLibrary?
        
        print("[MetalVideoRenderer] Loading library from bundle: \(bundle.bundlePath)")
        
        // Strategy 1: Default Library (pre-compiled metallib)
        if let lib = try? device.makeDefaultLibrary(bundle: bundle) {
            print("[MetalVideoRenderer] Success: makeDefaultLibrary(bundle:)")
            library = lib
        } 
        
        // Strategy 2: Explicit default.metallib
        if library == nil {
            if let path = bundle.path(forResource: "default", ofType: "metallib") {
                print("[MetalVideoRenderer] Found default.metallib: \(path)")
                library = try? device.makeLibrary(filepath: path)
            }
        }
        
        // Strategy 3: Compile from source
        if library == nil {
            if let path = bundle.path(forResource: "Shaders", ofType: "metal") {
                print("[MetalVideoRenderer] Found Shaders.metal: \(path)")
                do {
                    let source = try String(contentsOfFile: path)
                    library = try device.makeLibrary(source: source, options: nil)
                    print("[MetalVideoRenderer] Success: Compiled from source.")
                } catch {
                    print("[MetalVideoRenderer] Error compiling from source: \(error)")
                }
            } else {
                print("[MetalVideoRenderer] Error: Shaders.metal not found in bundle.")
            }
        }
        
        guard let libraryRef = library else {
            print("[MetalVideoRenderer] FATAL: All shader loading strategies failed.")
            return
        }
        
        do {
            let vertexFunction = libraryRef.makeFunction(name: "videoVertexShader")
            let fragmentFunction = libraryRef.makeFunction(name: "videoFragmentShader")
            
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat
            
            renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            
            if let blurFunction = libraryRef.makeFunction(name: "gaussianBlurKernel") {
                computePipelineState = try device.makeComputePipelineState(function: blurFunction)
            }
            
            print("[MetalVideoRenderer] Success: Pipeline established.")
        } catch {
            print("[MetalVideoRenderer] Error creating pipelines: \(error)")
        }
    }
    
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
    
    public func draw(in view: MTKView) {
        guard let pixelBuffer = currentPixelBuffer,
              let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let pipeline = renderPipelineState else { return }
        
        let texture = createTexture(from: pixelBuffer)
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else { return }
        
        renderEncoder.setRenderPipelineState(pipeline)
        renderEncoder.setFragmentTexture(texture, index: 0)
        
        var uniforms = calculateUniforms(pixelBuffer: pixelBuffer)
        
        // Pass uniforms to BOTH vertex and fragment shaders
        renderEncoder.setVertexBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        renderEncoder.setFragmentBytes(&uniforms, length: MemoryLayout<Uniforms>.stride, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func createTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache else { return nil }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var cvTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(kCFAllocatorDefault,
                                                  textureCache,
                                                  pixelBuffer,
                                                  nil,
                                                  mtkView.colorPixelFormat,
                                                  width,
                                                  height,
                                                  0,
                                                  &cvTexture)
        
        guard let cvTexture = cvTexture else { return nil }
        return CVMetalTextureGetTexture(cvTexture)
    }
    
    private func calculateUniforms(pixelBuffer: CVPixelBuffer) -> Uniforms {
        let width = UInt32(CVPixelBufferGetWidth(pixelBuffer))
        let height = UInt32(CVPixelBufferGetHeight(pixelBuffer))
        let viewportWidth = UInt32(mtkView.drawableSize.width)
        let viewportHeight = UInt32(mtkView.drawableSize.height)
        
        let offset = simd_float2(0, 0)
        let time = Float(Date().timeIntervalSince(startTime))
        
        return Uniforms(
            viewportSize: simd_uint2(viewportWidth, viewportHeight),
            contentSize: simd_uint2(width, height),
            gravityMode: simd_uint1(gravityMode.indexValue),
            renderingTier: simd_uint1(renderingTier.indexValue),
            sharpnessWeight: simd_float1(renderingTier.sharpnessWeight),
            ambientIntensity: simd_float1(ambientIntensity),
            offset: offset,
            time: simd_float1(time),
            matrixIntensity: simd_float1(matrixIntensity)
        )
    }
}

// ProPlayerEngine VideoGravityMode Extension
extension VideoGravityMode {
    var indexValue: Int {
        switch self {
        case .fit: return 0
        case .fill: return 1
        case .stretch: return 2
        case .smartFill: return 3
        case .customZoom: return 4
        case .ambient: return 5
        }
    }
}

extension SuperResolutionTier {
    var indexValue: Int {
        switch self {
        case .off: return 0
        case .upscale2k: return 1
        case .upscale4k: return 2
        }
    }
}
