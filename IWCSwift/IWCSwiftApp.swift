import SwiftUI

enum AppMode { case customer, dispatch, booking }

@main
struct IWCSwiftApp: App {
    @StateObject private var auth = AuthManager.shared
    @State private var appMode: AppMode? = nil
    @State private var showHome = false

    var body: some Scene {
        WindowGroup {
            if showHome && auth.currentEmployee == nil {
                SimpleWindowsHomeView(onLogin: { showHome = false })
                    .environmentObject(auth)

            } else if !auth.isConfigured {
                SetupView()
                    .environmentObject(auth)

            } else if auth.currentEmployee != nil {
                ZStack {
                    Group {
                        if appMode == .dispatch {
                            DispatchView(password: auth.apiPassword, onExit: {
                                appMode = nil
                                auth.logout()
                            })
                        } else if appMode == .booking {
                            BookingView(onExit: {
                                withAnimation(.easeInOut(duration: 0.35)) { appMode = nil }
                            })
                        } else if appMode == .customer {
                            JobSelectorView()
                                .environmentObject(auth)
                        } else {
                            ModePicker(employeeName: auth.currentEmployee?.name ?? "") { mode in
                                withAnimation(.easeInOut(duration: 0.35)) { appMode = mode }
                            }
                        }
                    }

                    // Faint grid button — lets the admin bail back to dispatch from customer side
                    if appMode == .customer {
                        VStack {
                            HStack {
                                Spacer()
                                Button {
                                    withAnimation(.easeInOut(duration: 0.35)) { appMode = .dispatch }
                                } label: {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white.opacity(0.25))
                                        .padding(10)
                                        .background(Color.black.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .padding(.top, 20)
                                .padding(.trailing, 20)
                            }
                            Spacer()
                        }
                    }
                }

            } else {
                LoginView()
                    .environmentObject(auth)
                    .onAppear { appMode = nil }
            }
        }
    }
}

// MARK: - Mode picker

private struct ModePicker: View {
    let employeeName: String
    let onSelect: (AppMode) -> Void

    var body: some View {
        ZStack {
            VideoBackground(player: VideoPlayerController.shared.player).ignoresSafeArea()
            IWCTheme.videoBg.opacity(0.72).ignoresSafeArea()
            VStack { IWCTheme.videoFadeTop.frame(height: 100); Spacer() }.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    IWCLabel(text: "SIMPLE WINDOW CLEANING")
                    Text("Hey \(employeeName.components(separatedBy: " ").first ?? employeeName)")
                        .font(.system(size: 34, weight: .heavy))
                        .foregroundColor(IWCTheme.textPrimary)
                    Text("What are we doing?")
                        .font(IWCTheme.Font.body(16))
                        .foregroundColor(IWCTheme.textSecondary)
                }
                .padding(.bottom, 52)

                VStack(spacing: 16) {
                    ModeButton(icon: "map.fill",              label: "Dispatch",         sub: "Calendar & scheduling",    color: IWCTheme.teal)  { onSelect(.dispatch) }
                    ModeButton(icon: "calendar.badge.plus",   label: "Book New Visit",   sub: "New customer or return",   color: IWCTheme.amber) { onSelect(.booking) }
                    ModeButton(icon: "person.fill",           label: "Hand to Customer", sub: "Job closeout walkthrough", color: IWCTheme.green) { onSelect(.customer) }
                }
                .frame(maxWidth: 420)

                Spacer()

                IWCLabel(text: "SANTA CRUZ · SILICON VALLEY")
                    .padding(.bottom, 36)
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Book New Visit

private struct BookingView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack {
            VideoBackground(player: VideoPlayerController.shared.player).ignoresSafeArea()
            IWCTheme.videoBg.opacity(0.72).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    IWCLabel(text: "NEW BOOKING")
                    Text("Book a Visit")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(IWCTheme.textPrimary)
                    Text("Schedule or estimate for a customer")
                        .font(IWCTheme.Font.body(15))
                        .foregroundColor(IWCTheme.textSecondary)
                }
                .padding(.bottom, 44)

                VStack(spacing: 14) {
                    Link(destination: URL(string: "https://www.simplewindowcleaning.com")!) {
                        ModeButton(icon: "calendar.badge.plus",
                                   label: "Online Calendar",
                                   sub: "Real-time availability & booking",
                                   color: IWCTheme.teal) {}
                    }
                    Link(destination: URL(string: "tel:+18313311133")!) {
                        ModeButton(icon: "phone.fill",
                                   label: "Call / Text Customer",
                                   sub: "(831) 331-1133",
                                   color: IWCTheme.amber) {}
                    }
                    Link(destination: URL(string: "sms:+18313311133")!) {
                        ModeButton(icon: "message.fill",
                                   label: "Send Booking Link",
                                   sub: "Text them the booking URL",
                                   color: IWCTheme.green) {}
                    }
                }
                .frame(maxWidth: 420)
                .allowsHitTesting(true)

                Spacer()

                Button(action: onExit) {
                    Text("← Back")
                        .font(.system(size: 13, weight: .black))
                        .tracking(1.5)
                        .foregroundColor(IWCTheme.textTertiary)
                        .padding(.vertical, 18)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 40)
        }
    }
}

private struct ModeButton: View {
    let icon: String
    let label: String
    let sub: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                ZStack {
                    Circle().fill(color.opacity(0.12)).frame(width: 52, height: 52)
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(IWCTheme.textPrimary)
                    Text(sub)
                        .font(IWCTheme.Font.body(13))
                        .foregroundColor(IWCTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(IWCTheme.textTertiary)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .iwcCard(accent: color.opacity(0.22))
        }
        .buttonStyle(.plain)
    }
}
