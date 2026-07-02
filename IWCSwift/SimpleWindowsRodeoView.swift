import SwiftUI

struct SimpleWindowsRodeoView: View {
    @Environment(\.dismiss) private var dismiss

    private let cards: [(num: String, label: String, headline: String, sub: String, color: Color)] = [
        (
            "01",
            "We know this is different",
            "JUST WINDOWS.",
            "Exterior only — automated pricing for average families and renters. No gutters, no solar, no confusion.",
            IWCTheme.teal
        ),
        (
            "02",
            "What changes for you",
            "AVAILABLE NOW.",
            "Exteriors fast, then automated — not 2–3 months out. Interiors handled separately by our vetted affiliate.",
            IWCTheme.amber
        ),
        (
            "03",
            "Why switch",
            "SAVES YOU TIME.",
            "Seamless booking for regular maintenance. The more often you book, the lower your cost per window.",
            IWCTheme.green
        ),
    ]

    var body: some View {
        ZStack {
            VideoBackground(player: VideoPlayerController.shared.player).ignoresSafeArea()
            IWCTheme.videoBg.opacity(0.90).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        IWCLabel(text: "BEFORE YOU BOOK", color: IWCTheme.teal.opacity(0.6))
                        Text("Not Your First Rodeo?")
                            .font(.system(size: 26, weight: .black))
                            .foregroundColor(IWCTheme.textPrimary)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Text("← Back")
                            .font(.system(size: 11, weight: .black))
                            .tracking(2)
                            .foregroundColor(IWCTheme.textTertiary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 56)
                .padding(.bottom, 20)

                // Cards
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(Array(cards.enumerated()), id: \.offset) { i, card in
                            RodeoCard(card: card)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                // Continue button
                Button {
                    dismiss()
                } label: {
                    Text("Check zip code & book on real-time calendar  →")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(IWCTheme.teal)
                        .clipShape(RoundedRectangle(cornerRadius: IWCTheme.Radius.md))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Card

private struct RodeoCard: View {
    let card: (num: String, label: String, headline: String, sub: String, color: Color)

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(card.num)
                .font(.system(size: 44, weight: .black, design: .monospaced))
                .foregroundColor(card.color.opacity(0.18))
                .frame(width: 52)

            VStack(alignment: .leading, spacing: 4) {
                IWCLabel(text: card.label.uppercased(), color: card.color.opacity(0.6))
                Text(card.headline)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(IWCTheme.textPrimary)
                    .tracking(-0.3)
                Text(card.sub)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(IWCTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(IWCTheme.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: IWCTheme.Radius.md))
        .overlay(RoundedRectangle(cornerRadius: IWCTheme.Radius.md)
            .stroke(card.color.opacity(0.14), lineWidth: 1))
    }
}
