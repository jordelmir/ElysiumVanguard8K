import SwiftUI
import AVFoundation
import AVKit
import Vision

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

    static func dismantleNSView(_ nsView: PlayerLayerNSView, coordinator: ()) {
        nsView.playerLayer.player = nil
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
        playerLayer.frame = self.bounds
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

    static func dismantleNSView(_ nsView: SmartFillNSView, coordinator: ()) {
        nsView.playerLayer.player = nil
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
            self.playerLayer.frame = self.bounds
            return
        }

        let viewAspect = self.bounds.width / self.bounds.height
        let videoAspect = self.videoNaturalSize.width / self.videoNaturalSize.height

        // Calculate scale needed to fill, but limit max stretch to ~15%
        let maxStretchFactor: CGFloat = 1.15
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0

        if videoAspect > viewAspect {
            // Video is wider -> need to scale height
            let fitScale = self.bounds.width / self.videoNaturalSize.width
            let fitHeight = self.videoNaturalSize.height * fitScale
            let neededScale = self.bounds.height / fitHeight
            scaleY = min(neededScale, maxStretchFactor)
        } else {
            // Video is taller -> need to scale width
            let fitScale = self.bounds.height / self.videoNaturalSize.height
            let fitWidth = self.videoNaturalSize.width * fitScale
            let neededScale = self.bounds.width / fitWidth
            scaleX = min(neededScale, maxStretchFactor)
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        self.playerLayer.frame = self.bounds
        self.playerLayer.transform = CATransform3DMakeScale(scaleX, scaleY, 1.0)
        CATransaction.commit()
    }
}
