# 🚀 ProPlayer Elite — The Native Gold Standard for macOS Rendering

ProPlayer Elite is a professional-grade media engine architected from the ground up for **Apple Silicon**. It bypasses standard AVPlayer limitations by leveraging a custom **Metal v13.0** rendering pipeline, delivering industry-leading visual fidelity with near-zero system overhead.

---

## 💎 The "Elite" Rendering Pipeline (Metal v13.0)

While traditional players rely on basic bilinear scaling, ProPlayer Elite implements a sophisticated multi-stage spatial-temporal fragment shader:

- **Ultra 5K & Extreme 8K Upscaling**: Powered by an edge-adaptive EASU (Edge Adaptive Spatial Upsampling) kernel. It identifies contrast edges in real-time to prevent haloing and ringing.
- **Robust CAS (Contrast Adaptive Sharpening)**: A specialized RCAS pass that restores high-frequency detail based on local luminance variance.
- **ACES Filmic Tone Mapping**: Industry-standard HDR-to-SDR conversion. Provides "filmic" highlights and preserves shadow detail even on non-HDR displays.
- **Temporal Noise Reduction (TNR)**: A dual-buffer feedback loop that filters compression artifacts by analyzing inter-frame motion vectors.
- **Film Grain Synthesis**: Luminance-adaptive stochastically generated 35mm-style grain for a premium cinematic texture.

---

## 🏗️ Technical Architecture

### Core Engine (`ProPlayerEngine`)
- **Metal Integration**: 100% GPU-accelerated frame processing.
- **CVPixelBuffer Zero-Copy**: Utilizes `CVMetalTextureCache` for direct memory access between the video decoder and the GPU, eliminating CPU-side frame copying.
- **Swift 6 Strict Concurrency**: Actors-based isolation to guarantee 0 data races in the high-frequency rendering loop.

### UI Architecture (`ProPlayer App`)
- **SwiftUI + AppKit Bridge**: A modern declarative UI layer backed by deep AppKit window management for **Immersive FullScreen** support.
- **Responsive Layout**: Designed for the "Desktop First" experience, supporting drag-and-drop, advanced keyboard shortcuts (J/K/L, Space, [, ]), and native macOS gestures.

---

## 🔒 Security & Privacy (The "Golden Master" Audit)

- **Zero Data Leaks**: Strict `.gitignore` policy excluding all `.env`, sensitive Apple Developer certificates, and build artifacts.
- **Offline First**: No telemetry, no external trackers. Your media data never leaves your machine.
- **Sandbox Ready**: Architected to comply with macOS App Sandbox requirements.

---

## 🛠️ Build & Development

The project includes a specialized automation script for creating production-ready `.app` bundles that support native macOS Spaces.

```bash
# Build the Elite Golden Master
sh build_elite_v11.sh
```

---

## 📜 Professional Documentation
- [Usage Guide](file:///PRO_USAGE_GUIDE.md): Detailed explanation of all "Elite" settings and thermal performance tips.
- [Walkthrough](file:///walkthrough.md): Full development history and milestone logs.

---

### 🏷️ SEO & Metadata
**Keywords**: Video Player, macOS, Metal, Swift 6, 8K Video, FSR, ACES, HDR, Apple Silicon, M1, M2, M3, Professional Rendering.

**Repository Topics**: `macos`, `swift`, `metal`, `video-player`, `4k-video`, `8k-video`, `apple-silicon`, `rendering-engine`, `proplayer`.

---

Developed with ❤️ by **ProPlayer Elite Team**. 
*The ultimate convergence of minimalism and raw power.*
