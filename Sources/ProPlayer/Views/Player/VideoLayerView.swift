import SwiftUI
import AVFoundation
import AVKit

// MARK: - AVPlayerLayer NSView Wrapper

struct VideoLayerView: NSViewRepresentable {
    let player: AVPlayer
    let videoGravity: AVLayerVideoGravity
    var onLayerReady: ((AVPlayerLayer) -> Void)? = nil

    func makeNSView(context: Context) -> PlayerLayerNSView {
        let view = PlayerLayerNSView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = videoGravity
        onLayerReady?(view.playerLayer)
        return view
    }

    func updateNSView(_ nsView: PlayerLayerNSView, context: Context) {
        nsView.playerLayer.player = player
        nsView.playerLayer.videoGravity = videoGravity
    }
}

class PlayerLayerNSView: NSView {
    let playerLayer = AVPlayerLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = playerLayer
        playerLayer.backgroundColor = NSColor.black.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        playerLayer.frame = bounds
        CATransaction.commit()
    }
}

// MARK: - Smart Fill View (custom stretch logic)

struct SmartFillVideoView: NSViewRepresentable {
    let player: AVPlayer
    let videoSize: CGSize
    var onLayerReady: ((AVPlayerLayer) -> Void)? = nil

    func makeNSView(context: Context) -> SmartFillNSView {
        let view = SmartFillNSView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspect
        view.videoNaturalSize = videoSize
        onLayerReady?(view.playerLayer)
        return view
    }

    func updateNSView(_ nsView: SmartFillNSView, context: Context) {
        nsView.playerLayer.player = player
        nsView.videoNaturalSize = videoSize
        nsView.updateSmartFill()
    }
}

class SmartFillNSView: NSView {
    let playerLayer = AVPlayerLayer()
    var videoNaturalSize: CGSize = .zero

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer = playerLayer
        playerLayer.backgroundColor = NSColor.black.cgColor
        playerLayer.videoGravity = .resizeAspect
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        updateSmartFill()
    }

    func updateSmartFill() {
        guard videoNaturalSize.width > 0 && videoNaturalSize.height > 0 else {
            playerLayer.frame = bounds
            return
        }

        let viewAspect = bounds.width / bounds.height
        let videoAspect = videoNaturalSize.width / videoNaturalSize.height

        // Calculate scale needed to fill, but limit max stretch to ~15%
        let maxStretchFactor: CGFloat = 1.15
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0

        if videoAspect > viewAspect {
            // Video is wider -> need to scale height
            let fitScale = bounds.width / videoNaturalSize.width
            let fitHeight = videoNaturalSize.height * fitScale
            let neededScale = bounds.height / fitHeight
            scaleY = min(neededScale, maxStretchFactor)
        } else {
            // Video is taller -> need to scale width
            let fitScale = bounds.height / videoNaturalSize.height
            let fitWidth = videoNaturalSize.width * fitScale
            let neededScale = bounds.width / fitWidth
            scaleX = min(neededScale, maxStretchFactor)
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        playerLayer.frame = bounds
        playerLayer.transform = CATransform3DMakeScale(scaleX, scaleY, 1.0)
        CATransaction.commit()
    }
}
