import SwiftUI
import Combine

struct EventWindowsHomeView: View {
    let onDismiss: () -> Void

    @State private var wordIndex       = 0
    @State private var appeared        = false
    @State private var showMediaExpand: MediaType? = nil

    private let words = ["Housecleaners.", "Same or Less.", "Guaranteed."]
    private let timer = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VideoBackground(player: VideoPlayerController.shared.player).ignoresSafeArea()
            IWCTheme.videoBg.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        Spacer(minLength: 8)
                        headerRow
                            .padding(.horizontal, 22)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        SWMediaFeed()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)

                        actionCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)

                        Spacer(minLength: 8)
                    }
                }
                dismissButton
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                wordIndex = (wordIndex + 1) % words.count
            }
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(IWCTheme.green)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 1) {
                    IWCLabel(text: "EVENT", color: IWCTheme.green.opacity(0.5))
                    Text("Windows")
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(IWCTheme.textPrimary)
                    Text("Santa Cruz · Scotts Valley · Watsonville")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(IWCTheme.textTertiary)
                        .tracking(0.2)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                IWCLabel(text: "ONLY")
                ZStack(alignment: .trailing) {
                    ForEach(words.indices, id: \.self) { i in
                        if i == wordIndex {
                            Text(words[i])
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(IWCTheme.green)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal:   .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .frame(height: 26, alignment: .trailing)
                .frame(minWidth: 130, alignment: .trailing)
                Text("Text GO · (831) 331-1133")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(IWCTheme.textTertiary)
                    .tracking(0.2)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(IWCTheme.bgCard.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(IWCTheme.green.opacity(0.22), lineWidth: 1))
        )
    }

    // MARK: - Action card

    private var actionCard: some View {
        VStack(spacing: 0) {
            // Book button — green
            Button {} label: {
                VStack(spacing: 5) {
                    Text("Tap here to Book Interiors before the Exterior or to get a free estimate for house cleaning / Air BNB turnovers.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                    Text("Simple Windows gives us this free marketing for getting the interior work out of their model. Please use them too!")
                        .font(.system(size: 9, weight: .medium).italic())
                        .foregroundColor(.black.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(IWCTheme.green)
                .clipShape(RoundedRectangle(cornerRadius: IWCTheme.Radius.md))
                .shadow(color: IWCTheme.green.opacity(0.3), radius: 16, y: 6)
            }
            .buttonStyle(.plain)

            Divider().background(IWCTheme.border).padding(.vertical, 14)

            // Bottom: SW affiliate left + QR right
            HStack(alignment: .top, spacing: 12) {
                swAffiliateCard
                // QR — links to SW phone
                VStack(spacing: 6) {
                    QRCodeView(value: "tel:+18313311133", size: 118)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(6)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    VStack(spacing: 2) {
                        IWCLabel(text: "BOOK EXTERIORS")
                        IWCLabel(text: "FIRST?")
                    }
                }
                .frame(width: 252)
            }
            .sheet(item: $showMediaExpand) { MediaExpandView(media: $0) }
        }
        .padding(20)
        .iwcCard(accent: IWCTheme.green.opacity(0.22), radius: IWCTheme.Radius.lg)
        .padding(.horizontal, 22)
    }

    // MARK: - Simple Windows affiliate card

    private var swAffiliateCard: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Logo header
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(IWCTheme.teal.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(IWCTheme.teal.opacity(0.22), lineWidth: 1))
                    SWWindowIcon().stroke(IWCTheme.teal, lineWidth: 1.4).padding(7)
                }
                .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    IWCLabel(text: "AFFILIATE", color: IWCTheme.teal.opacity(0.45))
                    Text("Simple Windows")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(IWCTheme.textPrimary)
                }
                Spacer()
                Text("Book →")
                    .font(.system(size: 9, weight: .black)).tracking(1)
                    .foregroundColor(IWCTheme.teal.opacity(0.7))
                    .padding(.horizontal, 9).padding(.vertical, 5)
                    .overlay(Capsule().stroke(IWCTheme.teal.opacity(0.25), lineWidth: 1))
            }

            // Profile photo + bullets
            HStack(alignment: .top, spacing: 10) {
                Image("example1a")
                    .resizable().scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(IWCTheme.teal.opacity(0.18), lineWidth: 1))
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(["Exterior Windows","Water-Fed Pole","Same Day Available","$20 / Window"], id: \.self) { b in
                        HStack(spacing: 5) {
                            Text("✓").font(.system(size: 10, weight: .black)).foregroundColor(IWCTheme.teal)
                            Text(b).font(.system(size: 10, weight: .medium)).foregroundColor(IWCTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 2)
            }

            // Thumbnail row
            HStack(spacing: 6) {
                Button { showMediaExpand = .slides } label: {
                    ZStack {
                        Image("example1a").resizable().scaledToFill()
                        Color.black.opacity(0.42)
                        VStack(spacing: 3) {
                            HStack(spacing: 2) {
                                ForEach(0..<2, id: \.self) { _ in
                                    VStack(spacing: 2) {
                                        ForEach(0..<2, id: \.self) { _ in
                                            RoundedRectangle(cornerRadius: 1.5)
                                                .fill(Color.white.opacity(0.85)).frame(width: 7, height: 7)
                                        }
                                    }
                                }
                            }
                            Text("PHOTOS").font(.system(size: 7, weight: .black)).tracking(0.8).foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)

                Button { showMediaExpand = .video } label: {
                    ZStack {
                        Color(white: 0.04)
                        InlineVideoView(url: Bundle.main.url(forResource: "ontheway", withExtension: "mp4")).opacity(0.55)
                        Color.black.opacity(0.3)
                        VStack(spacing: 3) {
                            Circle().fill(Color.white.opacity(0.88)).frame(width: 22, height: 22)
                                .overlay(Image(systemName: "play.fill").font(.system(size: 8)).foregroundColor(.black).offset(x: 1))
                            Text("DEMO").font(.system(size: 7, weight: .black)).tracking(0.8).foregroundColor(.white.opacity(0.75))
                        }
                        VStack {
                            HStack {
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "play.fill").font(.system(size: 4)).foregroundColor(.white)
                                    Text("YT").font(.system(size: 5, weight: .black)).foregroundColor(.white)
                                }
                                .padding(.horizontal, 3).padding(.vertical, 1.5)
                                .background(Color.red).clipShape(RoundedRectangle(cornerRadius: 2)).padding(4)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // Book button
            Text("Book Exteriors →")
                .font(.system(size: 10, weight: .black)).tracking(1.2)
                .foregroundColor(IWCTheme.teal.opacity(0.65))
                .frame(maxWidth: .infinity).padding(.vertical, 7)
                .overlay(Capsule().stroke(IWCTheme.teal.opacity(0.25), lineWidth: 1))

            // Caption
            Text("Exterior windows, water-fed pole — fast, affordable, same day.")
                .font(.system(size: 8, weight: .medium).italic())
                .foregroundColor(IWCTheme.textTertiary)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(IWCTheme.teal.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(IWCTheme.teal.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Dismiss

    private var dismissButton: some View {
        Button(action: onDismiss) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 11))
                Text("BACK")
                    .font(.system(size: 13, weight: .black))
                    .tracking(2)
            }
            .foregroundColor(IWCTheme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(IWCTheme.bg.opacity(0.6))
        }
        .buttonStyle(.plain)
    }
}
