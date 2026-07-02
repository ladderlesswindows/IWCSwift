import SwiftUI
import Combine

// MARK: - Home

struct SimpleWindowsHomeView: View {
    let onLogin: () -> Void

    @State private var wordIndex       = 0
    @State private var showRodeo       = false
    @State private var showEventWindows = false
    @State private var appeared        = false

    private let words  = ["Windows.", "Exterior.", "Fast.", "Affordable.", "Instant."]
    private let timer  = Timer.publish(every: 2.6, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            VideoBackground(player: VideoPlayerController.shared.player).ignoresSafeArea()
            IWCTheme.videoBg.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        Spacer(minLength: 8)

                        // ── Header strip ──
                        headerRow
                            .padding(.horizontal, 22)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 10)

                        // ── Media carousel ──
                        SWMediaFeed()
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 14)

                        // ── Action card ──
                        actionCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 18)

                        Spacer(minLength: 8)
                    }
                }

                loginButton
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear { withAnimation(.easeOut(duration: 0.6)) { appeared = true } }
        .onReceive(timer) { _ in
            withAnimation(.spring(response: 0.42, dampingFraction: 0.72)) {
                wordIndex = (wordIndex + 1) % words.count
            }
        }
        .fullScreenCover(isPresented: $showRodeo) {
            SimpleWindowsRodeoView()
        }
        .fullScreenCover(isPresented: $showEventWindows) {
            EventWindowsHomeView(onDismiss: { showEventWindows = false })
        }
    }

    // MARK: - Action card (book + service + affiliate)

    private var actionCard: some View {
        VStack(spacing: 0) {
            bookButton
            Divider().background(IWCTheme.border).padding(.vertical, 14)
            bottomSection
        }
        .padding(20)
        .iwcCard(accent: IWCTheme.borderAccent, radius: IWCTheme.Radius.lg)
        .padding(.horizontal, 22)
    }

    // MARK: - Header bar (full-width, outside card)

    private var headerRow: some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                SWWindowIcon()
                    .stroke(IWCTheme.teal, lineWidth: 1.6)
                    .frame(width: 26, height: 26)

                VStack(alignment: .leading, spacing: 1) {
                    IWCLabel(text: "SIMPLE")
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
                                .foregroundColor(IWCTheme.teal)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .bottom).combined(with: .opacity),
                                    removal:   .move(edge: .top).combined(with: .opacity)
                                ))
                        }
                    }
                }
                .frame(height: 26, alignment: .trailing)
                .frame(minWidth: 110, alignment: .trailing)
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
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(IWCTheme.borderAccent.opacity(0.18), lineWidth: 1))
        )
    }

    // MARK: - Book button

    private var bookButton: some View {
        Button { showRodeo = true } label: {
            VStack(spacing: 5) {
                Text("Tap here to Book Exterior & Screens instantly now for $20/window, or tap below to book Interior and Housecleaning.")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text("Event Windows is our affiliate program to provide 100% of interior revenue to a local small business, freeing us to keep it Simple.")
                    .font(.system(size: 9, weight: .medium).italic())
                    .foregroundColor(.black.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(1.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 12)
            .background(IWCTheme.teal)
            .clipShape(RoundedRectangle(cornerRadius: IWCTheme.Radius.md))
            .shadow(color: IWCTheme.teal.opacity(0.3), radius: 16, y: 6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Bottom: affiliate (left) + QR (right)

    @State private var showMediaExpand: MediaType? = nil

    private var bottomSection: some View {
        HStack(alignment: .top, spacing: 12) {
            ewAffiliateCard
            // QR — right, links to affiliate page
            VStack(spacing: 6) {
                QRCodeView(value: "https://simplewindows.app/event-windows", size: 118)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(6)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(spacing: 2) {
                    IWCLabel(text: "BOOK INTERIORS")
                    IWCLabel(text: "CLEANING FIRST?")
                }
            }
            .frame(width: 252)
        }
        .sheet(item: $showMediaExpand) { MediaExpandView(media: $0) }
    }

    private var ewAffiliateCard: some View {
        VStack(alignment: .leading, spacing: 8) {

            // Logo header — fixed 30pt
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(IWCTheme.green.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(IWCTheme.green.opacity(0.22), lineWidth: 1))
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(IWCTheme.green)
                }
                .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    IWCLabel(text: "AFFILIATE", color: IWCTheme.green.opacity(0.45))
                    Text("Event Windows")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(IWCTheme.textPrimary)
                }
                Spacer()
                Button { showEventWindows = true } label: {
                    Text("More →")
                        .font(.system(size: 9, weight: .black))
                        .tracking(1)
                        .foregroundColor(IWCTheme.green.opacity(0.7))
                        .padding(.horizontal, 9).padding(.vertical, 5)
                        .overlay(Capsule().stroke(IWCTheme.green.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            // Profile photo (80pt) + bullets
            HStack(alignment: .top, spacing: 10) {
                Image("fakehousecleaner")
                    .resizable().scaledToFill()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(IWCTheme.green.opacity(0.18), lineWidth: 1))
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(["Interior Windows","Full Housecleaning","Local & Trusted","Free Estimate"], id: \.self) { b in
                        HStack(spacing: 5) {
                            Text("✓").font(.system(size: 10, weight: .black)).foregroundColor(IWCTheme.green)
                            Text(b).font(.system(size: 10, weight: .medium)).foregroundColor(IWCTheme.textSecondary)
                        }
                    }
                }
                .padding(.top, 2)
            }

            // Thumbnail row — PHOTOS + DEMO, each 68pt tall
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
                                                .fill(Color.white.opacity(0.85))
                                                .frame(width: 7, height: 7)
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
                        InlineVideoView(url: Bundle.main.url(forResource: "ontheway", withExtension: "mp4"))
                            .opacity(0.55)
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
                                .background(Color.red)
                                .clipShape(RoundedRectangle(cornerRadius: 2))
                                .padding(4)
                            }
                            Spacer()
                        }
                    }
                    .frame(maxWidth: .infinity).frame(height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            // More Info button
            Button { showEventWindows = true } label: {
                Text("More Info")
                    .font(.system(size: 10, weight: .black)).tracking(1.2)
                    .foregroundColor(IWCTheme.green.opacity(0.65))
                    .frame(maxWidth: .infinity).padding(.vertical, 7)
                    .overlay(Capsule().stroke(IWCTheme.green.opacity(0.25), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Caption
            Text("Interior windows, deep cleaning & more — all from local hands.")
                .font(.system(size: 8, weight: .medium).italic())
                .foregroundColor(IWCTheme.textTertiary)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(IWCTheme.green.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(IWCTheme.green.opacity(0.12), lineWidth: 1))
    }

    // MARK: - Login button

    private var loginButton: some View {
        Button(action: onLogin) {
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                Text("LOGIN")
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

// SWWindowIcon, QRCodeView → SWComponents.swift
