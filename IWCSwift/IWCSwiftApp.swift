import SwiftUI

@main
struct IWCSwiftApp: App {
    @StateObject private var auth = AuthManager.shared

    var body: some Scene {
        WindowGroup {
            if !auth.isConfigured {
                SetupView()
                    .environmentObject(auth)
            } else if auth.currentEmployee != nil {
                JobSelectorView()
                    .environmentObject(auth)
            } else {
                LoginView()
                    .environmentObject(auth)
            }
        }
    }
}
