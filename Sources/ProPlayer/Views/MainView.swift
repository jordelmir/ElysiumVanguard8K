import SwiftUI
import ProPlayerEngine

struct MainView: View {
    @StateObject private var playerVM = PlayerViewModel()
    @StateObject private var libraryVM = LibraryViewModel()
    @State private var currentView: AppView = .library
    @State private var showingSettings = false

    enum AppView {
        case library
        case player
    }

    var body: some View {
        ZStack {
            switch currentView {
            case .library:
                LibraryView(libraryVM: libraryVM) { url in
                    playVideo(url: url)
                }
                .transition(.opacity)

            case .player:
                PlayerView(viewModel: playerVM) {
                    playerVM.stop()
                    withAnimation { currentView = .library }
                    restoreWindowChrome()
                }
                .transition(.opacity)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .frame(minWidth: 800, minHeight: 500)
        .preferredColorScheme(.dark)
        .animation(ProTheme.Animations.standard, value: currentView == .player)
        .toolbar(currentView == .player ? .hidden : .visible, for: .windowToolbar)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url, VideoItem.isVideoFile(url) else { return }
                    Task { @MainActor in
                        playVideo(url: url)
                    }
                }
            }
            return true
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(settings: $playerVM.settings)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if currentView == .library {
                    Button {
                        if let urls = libraryVM.showOpenFileDialog() {
                            if urls.count == 1 {
                                playVideo(url: urls[0])
                            } else {
                                libraryVM.addVideoFiles(urls)
                            }
                        }
                    } label: {
                        Image(systemName: "folder")
                    }
                    .help("Open File")
                }

                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
            }
        }
    }

    private func playVideo(url: URL) {
        // Add to library if not already there
        libraryVM.addVideoFiles([url])

        // Configure window for immersive video playback
        configureWindowForPlayback()

        // Play
        playerVM.openFile(url: url)
        withAnimation { currentView = .player }
    }
    
    /// Makes the window's title bar fully transparent and extends content into it
    private func configureWindowForPlayback() {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        window.isMovableByWindowBackground = true
        
        // Ensure the green traffic light button triggers True Full Screen (hiding Apple Menu Bar) instead of Zoom (+)
        window.collectionBehavior.insert(.fullScreenPrimary)
        
        // Ensure traffic light buttons are visible so the user can click the Full Screen button
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
    }
    
    /// Restores window chrome when leaving player mode
    private func restoreWindowChrome() {
        guard let window = NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.windows.first(where: { $0.isVisible }) else { return }
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
    }
}
