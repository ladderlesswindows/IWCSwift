import SwiftUI
import AVFoundation
import Combine

// Looping AVPlayer background — stored on device, no cloud
struct VideoBackground: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerView()
        view.player = player
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        var player: AVPlayer? {
            get { playerLayer.player }
            set {
                playerLayer.player = newValue
                playerLayer.videoGravity = .resizeAspectFill
            }
        }
    }
}

// Shared observable so any view can toggle mute
@MainActor
class VideoPlayerController: ObservableObject {
    static let shared = VideoPlayerController()

    let player: AVPlayer
    @Published var isMuted = true

    private init() {
        guard let url = Bundle.main.url(forResource: "bgvid", withExtension: "mp4") else {
            player = AVPlayer()
            return
        }
        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.player.seek(to: .zero)
            self?.player.play()
        }

        player.play()
    }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
    }
}

// Drop-in modifier: puts the video behind any view
struct WithVideoBackground: ViewModifier {
    @StateObject private var vpc = VideoPlayerController.shared

    func body(content: Content) -> some View {
        ZStack {
            VideoBackground(player: vpc.player)
                .ignoresSafeArea()
                .overlay(Color(hex: "06050f").opacity(0.55).ignoresSafeArea())

            content
        }
    }
}

extension View {
    func videoBackground() -> some View {
        modifier(WithVideoBackground())
    }
}

// Sound toggle button — reuse anywhere
struct SoundToggle: View {
    @StateObject private var vpc = VideoPlayerController.shared

    var body: some View {
        Button { vpc.toggleMute() } label: {
            Image(systemName: vpc.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 14))
                .foregroundColor(vpc.isMuted ? Color(hex: "3AAAC4").opacity(0.5) : Color(hex: "3AAAC4"))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12)))
        }
    }
}
