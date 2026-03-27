import SwiftUI

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
                PlayerView(viewModel: playerVM)
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .preferredColorScheme(.dark)
        .animation(ProTheme.Animations.standard, value: currentView == .player)
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
            ToolbarItemGroup(placement: .navigation) {
                if currentView == .player {
                    Button {
                        withAnimation { currentView = .library }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .help("Back to Library")
                }
            }

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

        // Play
        playerVM.openFile(url: url)
        withAnimation { currentView = .player }
    }
}
