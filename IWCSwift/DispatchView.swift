import SwiftUI
import WebKit

struct DispatchView: View {
    let password: String
    let onCheckIn: (Booking) -> Void
    let onExit: () -> Void

    @State private var pollTask: Task<Void, Never>? = nil

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
        .onAppear { startPolling() }
        .onDisappear { pollTask?.cancel() }
    }

    private func startPolling() {
        pollTask?.cancel()
        pollTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                guard !Task.isCancelled else { return }
                if let booking = try? await APIClient.fetchActiveCheckin(password: password) {
                    await MainActor.run { onCheckIn(booking) }
                    return
                }
            }
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
