import SwiftUI

enum AppMode { case customer, dispatch }

@main
struct IWCSwiftApp: App {
    @StateObject private var auth = AuthManager.shared
    @State private var appMode: AppMode? = nil

    var body: some Scene {
        WindowGroup {
            if !auth.isConfigured {
                SetupView()
                    .environmentObject(auth)

            } else if auth.currentEmployee != nil {
                ZStack {
                    Group {
                        if appMode == .dispatch {
                            DispatchView(onExit: {
                                appMode = nil
                                auth.logout()
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
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [Color(hex: "180a3a"), Color(hex: "06050f")],
                center: UnitPoint(x: 0.35, y: 0.25),
                startRadius: 0, endRadius: 800
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Text("Hey \(employeeName.components(separatedBy: " ").first ?? employeeName) 👋")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                Text("What are we doing?")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.bottom, 56)

                VStack(spacing: 16) {
                    ModeButton(
                        icon:  "map.fill",
                        label: "Dispatch",
                        sub:   "Calendar & scheduling",
                        color: Color(hex: "3AAAC4")
                    ) { onSelect(.dispatch) }

                    ModeButton(
                        icon:  "person.fill",
                        label: "Hand to Customer",
                        sub:   "Job closeout walkthrough",
                        color: Color(hex: "7c3aed")
                    ) { onSelect(.customer) }
                }
                .frame(maxWidth: 380)

                Spacer()

                Text("Simple Window Cleaning · Santa Cruz, CA")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.08))
                    .padding(.bottom, 28)
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
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Text(sub)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(color.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
