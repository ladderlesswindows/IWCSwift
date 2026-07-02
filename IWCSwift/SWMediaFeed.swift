import SwiftUI
import Combine
import AVFoundation

// MARK: - Feed model

enum SWFeedItem {
    case video
    case textGraphic(headline: String, sub: String, accent: Color)
    case windowExamples(count: Int, images: [String])
    case review(text: String, author: String, stars: Int)
}

private let feedItems: [SWFeedItem] = [
    .video,
    .textGraphic(
        headline: "Only Windows.",
        sub: "Exterior only.\nInstant booking.\nResidential & commercial.",
        accent: IWCTheme.teal
    ),
    .windowExamples(count: 1, images: ["example1a","example1b","example1c","example1d"]),
    .review(
        text: "Had them do all 14 windows in about 20 minutes. Can't believe how good they look.",
        author: "Sarah M.",
        stars: 5
    ),
    .windowExamples(count: 2, images: ["example2a","example2b","example2d"]),
    .textGraphic(
        headline: "$20 / Win.",
        sub: "Flat rate.\nNo surprises.\nBook again in 30 seconds.",
        accent: IWCTheme.green
    ),
    .windowExamples(count: 3, images: ["example3a","example3b","example3c"]),
    .review(
        text: "Restaurants and businesses love this — done in 20 minutes, windows spotless.",
        author: "Mike T.",
        stars: 5
    ),
    .windowExamples(count: 4, images: ["example4a","example4b","example4c","example4d"]),
]

private let cardW: CGFloat = 282
private let cardH: CGFloat = 158

// MARK: - Main feed

struct SWMediaFeed: View {
    @State private var current: Int = 0
    private let timer = Timer.publish(every: 4.2, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(0..<feedItems.count, id: \.self) { i in
                        card(feedItems[i])
                            .frame(width: cardW, height: cardH)
                            .id(i)
                    }
                    // Clone of first card — scroll into it, then silently reset
                    card(feedItems[0])
                        .frame(width: cardW, height: cardH)
                        .id(feedItems.count)
                }
                .padding(.leading, 22)
                .padding(.trailing, 22)
                .padding(.vertical, 2)
            }
            .onReceive(timer) { _ in
                let next = current + 1
                if next == feedItems.count {
                    // Scroll into clone smoothly
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        current = next
                        proxy.scrollTo(feedItems.count, anchor: .leading)
                    }
                    // Then silently jump back to real card[0]
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        withAnimation(.none) { proxy.scrollTo(0, anchor: .leading) }
                        current = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                        current = next
                        proxy.scrollTo(current, anchor: .leading)
                    }
                }
            }
        }
        .frame(height: cardH + 4)
    }

    @ViewBuilder
    private func card(_ item: SWFeedItem) -> some View {
        switch item {
        case .video:
            VideoFeedCard()
        case let .textGraphic(headline, sub, accent):
            TextGraphicCard(headline: headline, sub: sub, accent: accent)
        case let .windowExamples(count, images):
            WindowExamplesCard(count: count, images: images)
        case let .review(text, author, stars):
            ReviewCard(text: text, author: author, stars: stars)
        }
    }
}

// MARK: - Card base

private func cardBase<Content: View>(_ accent: Color = IWCTheme.borderAccent, @ViewBuilder _ content: () -> Content) -> some View {
    content()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(IWCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.18), lineWidth: 1))
}

// MARK: - Video card

struct VideoFeedCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            InlineVideoView(
                url: Bundle.main.url(forResource: "ontheway", withExtension: "mp4")
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.75)],
                startPoint: .center, endPoint: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 2) {
                IWCLabel(text: "DEMO", color: IWCTheme.teal.opacity(0.9))
                Text("On The Way")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(IWCTheme.teal.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Text / graphic card

private struct TextGraphicCard: View {
    let headline: String
    let sub: String
    let accent: Color

    var body: some View {
        ZStack {
            // Left accent stripe
            HStack(spacing: 0) {
                accent.frame(width: 3)
                Spacer()
            }

            HStack(spacing: 0) {
                // Text left half
                VStack(alignment: .leading, spacing: 6) {
                    Spacer()
                    Text(headline)
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(IWCTheme.textPrimary)
                        .lineLimit(2)
                    Text(sub)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(IWCTheme.textSecondary)
                        .lineSpacing(3)
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.vertical, 16)

                Spacer()

                // Window icon watermark right half
                SWWindowIcon()
                    .stroke(accent.opacity(0.08), lineWidth: 2)
                    .frame(width: 110, height: 110)
                    .padding(.trailing, 12)
            }
        }
        .background(IWCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(accent.opacity(0.2), lineWidth: 1))
    }
}

// MARK: - Window examples card

private struct WindowExamplesCard: View {
    let count: Int
    let images: [String]

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Horizontal filmstrip — one row of photos
            HStack(spacing: 3) {
                ForEach(images.prefix(4), id: \.self) { name in
                    Image(name)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Dark top gradient for label legibility
            LinearGradient(
                colors: [Color.black.opacity(0.65), .clear],
                startPoint: .top, endPoint: .center
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Label
            VStack(alignment: .leading, spacing: 2) {
                IWCLabel(text: "EXAMPLES", color: IWCTheme.amber.opacity(0.7))
                Text("\(count) Win")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.white)
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(IWCTheme.amber.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Review card

private struct ReviewCard: View {
    let text: String
    let author: String
    let stars: Int

    var body: some View {
        ZStack {
            // Watermark quote mark
            Text("\u{201C}")
                .font(.system(size: 140, weight: .black))
                .foregroundColor(IWCTheme.amber.opacity(0.05))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .offset(x: -4, y: 30)

            HStack(alignment: .center, spacing: 14) {
                // Left: stars + author
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 3) {
                        ForEach(0..<stars, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(IWCTheme.amber)
                        }
                    }
                    Text(author)
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(IWCTheme.textSecondary)
                    Spacer()
                }
                .frame(width: 80)
                .padding(.vertical, 20)

                // Divider
                Rectangle()
                    .fill(IWCTheme.border)
                    .frame(width: 1)
                    .padding(.vertical, 18)

                // Right: quote
                Text("\u{201C}\(text)\u{201D}")
                    .font(.system(size: 12, weight: .medium).italic())
                    .foregroundColor(IWCTheme.textPrimary.opacity(0.85))
                    .lineSpacing(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            }
            .padding(.horizontal, 16)
        }
        .background(IWCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(IWCTheme.amber.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Inline video player (AVFoundation UIViewRepresentable)

struct InlineVideoView: UIViewRepresentable {
    let url: URL?

    class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    class Coordinator: NSObject {
        var player: AVPlayer?
        var loopObserver: Any?
        deinit {
            player?.pause()
            if let obs = loopObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        guard let url else { return view }
        let player = AVPlayer(url: url)
        player.isMuted = true
        player.actionAtItemEnd = .none
        context.coordinator.player = player
        context.coordinator.loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in player.seek(to: .zero); player.play() }
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        player.play()
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}
}
