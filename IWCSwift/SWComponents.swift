import SwiftUI
import CoreImage.CIFilterBuiltins
import AVFoundation

// Shared utility views used across SimpleWindowsHomeView, EventWindowsHomeView, SWMediaFeed

// MARK: - Window pane icon (2×2 grid shape)

struct SWWindowIcon: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addRoundedRect(in: rect, cornerSize: CGSize(width: 4, height: 4))
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

// MARK: - Media expand sheet (shared by SW and EW home views)

enum MediaType: Identifiable {
    case slides, video
    var id: Int { self == .slides ? 0 : 1 }
}

struct MediaExpandView: View {
    let media: MediaType
    @Environment(\.dismiss) private var dismiss

    private let slideImages = ["example1a","example2a","example3a","example4a"]

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()
            if media == .slides {
                TabView {
                    ForEach(slideImages, id: \.self) { name in
                        Image(name).resizable().scaledToFit()
                    }
                }
                .tabViewStyle(.page)
            } else {
                InlineVideoView(url: Bundle.main.url(forResource: "ontheway", withExtension: "mp4"))
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxHeight: .infinity)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28)).foregroundColor(.white.opacity(0.65))
                    .padding()
            }
        }
    }
}

// MARK: - On-device QR code generator

struct QRCodeView: View {
    let value: String
    let size: CGFloat

    private var qrImage: UIImage {
        let ctx    = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message         = Data(value.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage else { return UIImage() }
        let scaled = out.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cg = ctx.createCGImage(scaled, from: scaled.extent) else { return UIImage() }
        return UIImage(cgImage: cg)
    }

    var body: some View {
        Image(uiImage: qrImage)
            .interpolation(.none)
            .resizable()
            .frame(width: size, height: size)
    }
}
