import SwiftUI
import WebKit

struct DispatchView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            AdminWebView()
                .ignoresSafeArea()

            Button(action: onExit) {
                HStack(spacing: 6) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 13, weight: .medium))
                    Text("Exit")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.5))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.35))
                .clipShape(Capsule())
            }
            .padding(.top, 20)
            .padding(.leading, 20)
        }
    }
}

private struct AdminWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.load(URLRequest(url: URL(string: "https://www.ladderlesswindows.com/admin")!))
        return webView
    }
    func updateUIView(_ webView: WKWebView, context: Context) {}
}
