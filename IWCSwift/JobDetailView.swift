import SwiftUI

// MARK: - Main customer presentation view

struct JobDetailView: View {
    let booking: Booking
    let password: String

    @EnvironmentObject private var auth: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var arrivalConfirmed = false
    @State private var showBackConfirm = false
    @State private var screenHandlingChosen = false
    @State private var continuePressed = false
    @State private var notifyPressed = false
    @State private var serviceSummaryMinimized = false
    @State private var companyHeaderExpanded = true
    @State private var companyAtBottom = false
    @State private var windowPanelExpanded = true
    @State private var recurringAccepted = true
    @State private var onsiteAdded = 0
    @State private var onsiteInteriorAdded = 0
    @State private var onsiteScreensAdded = 0
    @State private var tookScreenLesson = false
    @State private var arrivalScreens = 0

    private var windowsAdded: Bool { onsiteAdded > 0 || onsiteInteriorAdded > 0 || onsiteScreensAdded > 0 }

    private var baseWindows: Int    { booking.window_count ?? 0 }
    private var baseTotal: Double   { booking.total_price ?? 0 }
    // Mirror web closeout math: minimum windows = those priced at $22 (vs $20 for extras)
    // Each minimum window earns one free interior — formula reverse-engineers minW from total
    private var freeInterior: Int {
        guard baseWindows > 0 else { return 1 }
        let minW = max(1.0, ((baseTotal - 20.0 * Double(baseWindows)) / 2.0).rounded())
        return Int(minW)
    }
    // Next visit offer: base price minus $2 pre-book discount, never below $20
    private var nextVisitOffer: Double { max(20, baseTotal - 2) }
    private var nextVisitWindows: Int  { baseWindows + freeInterior }

    // Rewards: up to min(baseWindows, 5) exterior adds earn 50% off next visit
    private var qualifyingAdds: Int  { min(onsiteAdded + onsiteInteriorAdded, 5) }
    private var rewardCredit: Double { Double(qualifyingAdds) * 6.25 }

    // Updated next visit estimate after adds — builds on original offer
    private var updatedNextVisitWindows: Int { nextVisitWindows + onsiteAdded + onsiteInteriorAdded }
    private var updatedNextVisitOffer: Double {
        let addRate = baseWindows > 0 ? baseTotal / Double(baseWindows) : 20.0
        let addsTotal = Double(onsiteAdded + onsiteInteriorAdded) * addRate
        let screenAdj: Double = onsiteScreensAdded > 0
            ? (tookScreenLesson ? -Double(onsiteScreensAdded) : Double(onsiteScreensAdded) * 2.0)
            : 0
        return max(20, nextVisitOffer + addsTotal - rewardCredit + screenAdj)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Company header — top position (opening page: always expanded, slides down on tap)
                if !companyAtBottom || screenHandlingChosen {
                    CompanyHeader(
                        booking: booking,
                        techName: auth.currentEmployee?.name ?? "Technician",
                        isExpanded: screenHandlingChosen ? companyHeaderExpanded : true,
                        onTap: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                                if screenHandlingChosen {
                                    companyHeaderExpanded.toggle()
                                } else {
                                    companyAtBottom = true
                                }
                            }
                        },
                        onNameTap: { showBackConfirm = true }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Preorder Review — collapses to bar after Continue
                WindowAnimationPanel(
                    baseWindows: baseWindows,
                    freeInterior: freeInterior,
                    onsiteAdded: onsiteAdded,
                    onsiteInteriorAdded: onsiteInteriorAdded,
                    arrivalScreens: $arrivalScreens,
                    arrivalConfirmed: $arrivalConfirmed,
                    screenHandlingChosen: $screenHandlingChosen,
                    isLocked: arrivalConfirmed,
                    isMinimized: !windowPanelExpanded,
                    onTapBar: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                            windowPanelExpanded.toggle()
                        }
                    }
                )

                // Two columns: Today's Summary + Next Visit Offer (pre-continue) or Rewards (post-continue)
                HStack(alignment: .top, spacing: 16) {
                    if screenHandlingChosen {
                        ServiceSummaryPanel(
                            booking: booking,
                            freeInterior: freeInterior,
                            onsiteAdded: onsiteAdded,
                            onsiteInteriorAdded: onsiteInteriorAdded,
                            screenCount: arrivalScreens,
                            onsiteScreensAdded: onsiteScreensAdded,
                            recurringAccepted: recurringAccepted,
                            nextVisitOffer: nextVisitOffer,
                            isMinimized: serviceSummaryMinimized,
                            onTapBar: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                    serviceSummaryMinimized.toggle()
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }

                    if !continuePressed {
                        OfferPanel(
                            baseWindows: baseWindows,
                            baseTotal: baseTotal,
                            freeInterior: freeInterior,
                            nextVisitOffer: nextVisitOffer,
                            nextVisitWindows: nextVisitWindows
                        )
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        RewardsPanel(
                            qualifyingAdds: qualifyingAdds,
                            rewardCredit: rewardCredit,
                            onsiteAdded: onsiteAdded,
                            onsiteInteriorAdded: onsiteInteriorAdded,
                            onsiteScreensAdded: onsiteScreensAdded,
                            tookScreenLesson: tookScreenLesson
                        )
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Company header — bottom position (only on open page after tap)
                if companyAtBottom && !screenHandlingChosen {
                    CompanyHeader(
                        booking: booking,
                        techName: auth.currentEmployee?.name ?? "Technician",
                        isExpanded: true,
                        onTap: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.72)) {
                                companyAtBottom = false
                            }
                        },
                        onNameTap: { showBackConfirm = true }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Pre-book checkbox + Continue — between handling choice and add-windows step
                if screenHandlingChosen && !continuePressed {
                    VStack(spacing: 12) {
                        PrebookRow(recurringAccepted: $recurringAccepted, nextVisitOffer: nextVisitOffer)

                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                continuePressed = true
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text("Continue")
                                    .font(.system(size: 17, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                ZStack {
                                    LinearGradient(colors: [Color(hex: "0A3D5C"), Color(hex: "1278A0")],
                                                   startPoint: .leading, endPoint: .trailing)
                                    LinearGradient(colors: [.white.opacity(0.15), .clear],
                                                   startPoint: .top, endPoint: .center)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: Color(hex: "3AAAC4").opacity(0.35), radius: 20, x: 0, y: 0)
                            .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Add windows + rewards + final action — slides in after Continue
                if continuePressed {
                    VStack(spacing: 16) {
                        // Updated next visit estimate — slides in after Notify Technician
                        if notifyPressed {
                            AddOnsEstimatePanel(
                                baseWindows: baseWindows,
                                baseTotal: baseTotal,
                                onsiteAdded: onsiteAdded,
                                onsiteInteriorAdded: onsiteInteriorAdded,
                                onsiteScreensAdded: onsiteScreensAdded,
                                tookScreenLesson: tookScreenLesson,
                                qualifyingAdds: qualifyingAdds,
                                rewardCredit: rewardCredit,
                                updatedWindowCount: updatedNextVisitWindows,
                                updatedOffer: updatedNextVisitOffer
                            )
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Add windows + CTA column
                        HStack(alignment: .top, spacing: 16) {
                            AddOnPanel(
                                onsiteAdded: $onsiteAdded,
                                onsiteInteriorAdded: $onsiteInteriorAdded,
                                onsiteScreensAdded: $onsiteScreensAdded,
                                tookScreenLesson: $tookScreenLesson,
                                baseWindows: baseWindows,
                                freeInterior: freeInterior,
                                prebookedWindowsBase: nextVisitWindows,
                                arrivalScreensBase: arrivalScreens,
                                showReset: notifyPressed,
                                onReset: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                                        onsiteAdded = 0
                                        onsiteInteriorAdded = 0
                                        onsiteScreensAdded = 0
                                        tookScreenLesson = false
                                        notifyPressed = false
                                        continuePressed = false
                                        screenHandlingChosen = false
                                        arrivalConfirmed = false
                                        serviceSummaryMinimized = false
                                        companyHeaderExpanded = true
                                        companyAtBottom = false
                                        windowPanelExpanded = true
                                        recurringAccepted = true
                                        arrivalScreens = 0
                                    }
                                }
                            )
                            .frame(maxWidth: .infinity)

                            // CTA column — square card, same shell as sibling panels
                            Group {
                                if notifyPressed {
                                    NavigationLink(value: "complete") {
                                        VStack(spacing: 10) {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 30, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                            Text("Lock\nIt In")
                                                .font(.system(size: 17, weight: .black))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .background(
                                        ZStack {
                                            LinearGradient(colors: [Color(hex: "059669").opacity(0.9), Color(hex: "0D9488").opacity(0.9)],
                                                           startPoint: .top, endPoint: .bottom)
                                            LinearGradient(colors: [.white.opacity(0.12), .clear],
                                                           startPoint: .top, endPoint: .center)
                                        }
                                    )
                                    .shadow(color: Color(hex: "34d399").opacity(0.35), radius: 18)
                                } else if windowsAdded {
                                    Button {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                            notifyPressed = true
                                            serviceSummaryMinimized = true
                                            windowPanelExpanded = false
                                        }
                                    } label: {
                                        VStack(spacing: 10) {
                                            Spacer()
                                            Image(systemName: "bell.fill")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                            Text("Notify\nTech")
                                                .font(.system(size: 17, weight: .black))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    .background(
                                        ZStack {
                                            LinearGradient(colors: [Color(hex: "0A3D5C").opacity(0.9), Color(hex: "1278A0").opacity(0.9)],
                                                           startPoint: .top, endPoint: .bottom)
                                            LinearGradient(colors: [.white.opacity(0.12), .clear],
                                                           startPoint: .top, endPoint: .center)
                                        }
                                    )
                                    .shadow(color: Color(hex: "3AAAC4").opacity(0.35), radius: 18)
                                } else {
                                    NavigationLink(value: "complete") {
                                        VStack(spacing: 10) {
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 28, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                            Text("Just Pre-\nbooked")
                                                .font(.system(size: 17, weight: .black))
                                                .foregroundColor(.white)
                                                .shadow(color: .black.opacity(0.3), radius: 4)
                                                .multilineTextAlignment(.center)
                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    }
                                    .background(
                                        ZStack {
                                            LinearGradient(colors: [Color(hex: "0A3D5C").opacity(0.9), Color(hex: "1278A0").opacity(0.9)],
                                                           startPoint: .top, endPoint: .bottom)
                                            LinearGradient(colors: [.white.opacity(0.12), .clear],
                                                           startPoint: .top, endPoint: .center)
                                        }
                                    )
                                    .shadow(color: Color(hex: "3AAAC4").opacity(0.35), radius: 18)
                                }
                            }
                            .frame(width: 110)
                            .frame(maxHeight: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1))
                            .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 48)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.4, dampingFraction: 0.65), value: notifyPressed)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: onsiteAdded)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: onsiteInteriorAdded)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: onsiteScreensAdded)
                    .animation(.spring(response: 0.3, dampingFraction: 0.65), value: tookScreenLesson)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .videoBackground()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert("Back to list?", isPresented: $showBackConfirm) {
            Button("Back to list", role: .destructive) { dismiss() }
            Button("Stay", role: .cancel) { }
        }
        .navigationDestination(for: String.self) { _ in
            JobCompleteView(
                booking: booking,
                password: password,
                technicianName: auth.currentEmployee?.name ?? "Technician",
                onsiteAdded: onsiteAdded,
                onsiteInteriorAdded: onsiteInteriorAdded,
                screenCount: onsiteScreensAdded,
                prebookChosen: recurringAccepted
            )
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: screenHandlingChosen)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: continuePressed)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: companyHeaderExpanded)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: windowPanelExpanded)
        .animation(.spring(response: 0.4, dampingFraction: 0.65), value: serviceSummaryMinimized)
        .onChange(of: screenHandlingChosen) { _, newVal in
            if newVal {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    companyHeaderExpanded = false
                }
            }
        }
        .onChange(of: recurringAccepted) { _, newValue in
            guard newValue else { return }
            Task {
                try? await APIClient.recordPrebookIntent(
                    password: password,
                    bookingId: booking.id,
                    nextVisitPrice: nextVisitOffer
                )
            }
        }
    }
}

// MARK: - Text outline (Photoshop-style stroke via 4-direction zero-radius shadows)

extension View {
    func textOutline(_ color: Color = .black, strength: Double = 0.65) -> some View {
        self
            .shadow(color: color.opacity(strength), radius: 0, x: -1, y:  0)
            .shadow(color: color.opacity(strength), radius: 0, x:  1, y:  0)
            .shadow(color: color.opacity(strength), radius: 0, x:  0, y: -1)
            .shadow(color: color.opacity(strength), radius: 0, x:  0, y:  1)
            .shadow(color: color.opacity(strength * 0.5), radius: 3)
    }
}

// MARK: - Company + Technician header

struct CompanyHeader: View {
    let booking: Booking
    let techName: String
    var isExpanded: Bool = true
    var onTap: () -> Void = {}
    var onNameTap: () -> Void = {}

    private var docDate: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: Date())
    }

    var body: some View {
        if isExpanded {
            expandedBody
        } else {
            collapsedBar
        }
    }

    private var collapsedBar: some View {
        HStack(spacing: 12) {
            Image("icon")
                .resizable()
                .scaledToFill()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            Button(action: onNameTap) {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "7ED8EA"))
                    Text("Simple Window Cleaning")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .textOutline()
                }
            }
            .buttonStyle(.plain)
            Text("· \(techName)")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "7ED8EA"))
            Spacer()
            SoundToggle()
            Button(action: onTap) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "7ED8EA"))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var expandedBody: some View {
        VStack(spacing: 0) {
            // Ocean stripe — shimmer-across-water effect, tappable to minimize
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0A3D5C"), Color(hex: "1278A0"), Color(hex: "3AAAC4"),
                        Color(hex: "7ED8EA"), Color(hex: "B8F4FF"), Color(hex: "7ED8EA"),
                        Color(hex: "3AAAC4"), Color(hex: "1278A0")
                    ],
                    startPoint: .leading, endPoint: .trailing
                )
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(height: 18)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            // Row 1: company + tech + date
            HStack(spacing: 16) {
                Image("icon")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1.5))

                VStack(alignment: .leading, spacing: 2) {
                    Text("SERVICE RECORD")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(Color(hex: "7ED8EA"))
                        .textOutline()
                    Button(action: onNameTap) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "7ED8EA"))
                                .textOutline()
                            Text("Simple Window Cleaning")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .textOutline()
                        }
                    }
                    .buttonStyle(.plain)
                    Text("SANTA CRUZ · SILICON VALLEY · EST. 2016")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "7ED8EA").opacity(0.7))
                        .textOutline()
                }

                Spacer()

                // Technician card
                HStack(spacing: 10) {
                    Image("badge")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 38)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5))

                    VStack(alignment: .leading, spacing: 3) {
                        Text("TECHNICIAN")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundColor(Color(hex: "7ED8EA"))
                        TechRow(label: "NAME",     value: techName)
                        TechRow(label: "CERT",     value: "Ladder-Free Specialist")
                        TechRow(label: "BG CHECK", value: "Current (1/26)")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "3AAAC4").opacity(0.08))
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1))

                VStack(alignment: .trailing, spacing: 4) {
                    SoundToggle()
                    Text("VERIFIED ✓")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "34d399"))
                        .textOutline()
                    Text(docDate)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .textOutline()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // Row 2: customer info fields
            HStack(spacing: 0) {
                InfoField(label: "CLIENT",   value: booking.displayName)
                Spacer()
                InfoField(label: "ADDRESS",  value: booking.address ?? "—")
                Spacer()
                InfoField(label: "DATE",     value: displayDate(booking.service_date ?? ""))
                Spacer()
                InfoField(label: "TIME",     value: displayTime(booking.service_time ?? ""))
                Spacer()
                InfoField(label: "WINDOWS",  value: "\(booking.window_count ?? 0) exterior")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}

struct TechRow: View {
    let label: String
    let value: String
    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .tracking(1)
                .foregroundColor(Color(hex: "7ED8EA"))
            Text(value)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Customer info row

struct CustomerInfoRow: View {
    let booking: Booking

    var body: some View {
        HStack(spacing: 32) {
            Group {
                InfoField(label: "CLIENT", value: booking.displayName)
                InfoField(label: "ADDRESS", value: booking.address ?? "—")
                InfoField(label: "DATE", value: displayDate(booking.service_date ?? ""))
                InfoField(label: "TIME", value: displayTime(booking.service_time ?? ""))
                InfoField(label: "WINDOWS", value: "\(booking.window_count ?? 0) exterior")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial)
        .overlay(Divider().opacity(0.3), alignment: .bottom)
    }
}

struct InfoField: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(hex: "7ED8EA"))
                .textOutline()
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .textOutline()
                .lineLimit(1)
        }
    }
}

// MARK: - Window animation panel (full width, between company bubble and columns)

struct WindowAnimationPanel: View {
    let baseWindows: Int
    let freeInterior: Int
    let onsiteAdded: Int
    var onsiteInteriorAdded: Int = 0
    @Binding var arrivalScreens: Int
    @Binding var arrivalConfirmed: Bool
    @Binding var screenHandlingChosen: Bool
    let isLocked: Bool
    var isMinimized: Bool = false
    var onTapBar: () -> Void = {}

    private var totalWindows: Int { baseWindows + freeInterior + onsiteAdded + onsiteInteriorAdded }

    var body: some View {
        VStack(spacing: 0) {
            // Header strip — tappable chevron when minimized
            HStack {
                Text("Preorder Review · \(baseWindows) exterior + \(freeInterior) free interior\(freeInterior != 1 ? "s" : "")")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                Image(systemName: isMinimized ? "chevron.down" : "chevron.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(hex: "0A3D5C").opacity(0.9), Color(hex: "1278A0").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .contentShape(Rectangle())
            .onTapGesture { onTapBar() }

        if !isMinimized {

            HStack(alignment: .center, spacing: 0) {
                // Window animation — live: purchased + added as base, free interiors as free
                SlidingWindowRow(baseWindows: baseWindows + onsiteAdded + onsiteInteriorAdded, freeWindows: freeInterior)
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.45, dampingFraction: 0.65), value: onsiteAdded + onsiteInteriorAdded)

                // Total windows
                VStack(spacing: 4) {
                    Text("TOTAL")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(Color(hex: "7ED8EA"))
                    Text("\(totalWindows)")
                        .font(.system(size: 44, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: totalWindows)
                    Text("windows")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "7ED8EA").opacity(0.7))
                }
                .frame(width: 90)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 60)
                    .padding(.horizontal, 12)

                // Screens arrival check + confirm checkbox
                VStack(spacing: 6) {
                    Text("PREORDER SCREENS")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(2.5)
                        .foregroundColor(Color(hex: "7ED8EA"))
                    if isLocked {
                        Text("\(arrivalScreens)")
                            .font(.system(size: 44, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4)
                            .frame(minWidth: 30)
                        Text("confirmed ✓")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "34d399"))
                    } else {
                        HStack(spacing: 10) {
                            Button { if arrivalScreens > 0 { arrivalScreens -= 1 } } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(arrivalScreens > 0 ? Color(hex: "7EC8E3") : Color.white.opacity(0.2))
                            }
                            Text("\(arrivalScreens)")
                                .font(.system(size: 44, weight: .black))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4)
                                .frame(minWidth: 30)
                            Button { if arrivalScreens < totalWindows { arrivalScreens += 1 } } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(arrivalScreens < totalWindows ? Color(hex: "7EC8E3") : Color.white.opacity(0.2))
                            }
                        }
                        Text("on preordered windows")
                            .font(.system(size: 10))
                            .foregroundColor(Color(hex: "7ED8EA").opacity(0.7))

                        // Confirm checkbox — locks screens and shows handling step
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                arrivalConfirmed = true
                            }
                        } label: {
                            HStack(spacing: 6) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color(hex: "7ED8EA"), lineWidth: 1.5)
                                        .frame(width: 16, height: 16)
                                }
                                Text("Confirm")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: "7ED8EA"))
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .frame(width: 120)
                .padding(.trailing, 14)
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, isLocked && !screenHandlingChosen ? 8 : 16)

            // Screen handling choice — pops in center of box after screens confirmed
            if isLocked && !screenHandlingChosen {
                Divider()
                    .opacity(0.3)
                    .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    // Option: worker handles removal
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                            screenHandlingChosen = true
                        }
                    } label: {
                        VStack(spacing: 5) {
                            HStack(spacing: 7) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color(hex: "7ED8EA"), lineWidth: 1.5)
                                        .frame(width: 14, height: 14)
                                }
                                Text("Screen handling")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                            Text("I'll remove it · $2 lesson included")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "7ED8EA"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(Color(hex: "3AAAC4").opacity(0.08))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    // Option: no handling needed
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
                            screenHandlingChosen = true
                        }
                    } label: {
                        VStack(spacing: 5) {
                            HStack(spacing: 7) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color(hex: "7ED8EA"), lineWidth: 1.5)
                                        .frame(width: 14, height: 14)
                                }
                                Text("No handling needed")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 4)
                            }
                            Text("1st floor exterior only")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "7ED8EA"))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 10)
                        .background(Color(hex: "3AAAC4").opacity(0.08))
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .transition(.scale(scale: 0.88, anchor: .center).combined(with: .opacity))
            }
        } // end if !isMinimized
        }
        .background(Color(hex: "3AAAC4").opacity(0.06))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "3AAAC4").opacity(0.22), radius: 24, x: 0, y: 8)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

// MARK: - Today's Summary (left column)

struct ServiceSummaryPanel: View {
    let booking: Booking
    let freeInterior: Int
    let onsiteAdded: Int
    var onsiteInteriorAdded: Int = 0
    let screenCount: Int
    var onsiteScreensAdded: Int = 0
    let recurringAccepted: Bool
    let nextVisitOffer: Double
    var isMinimized: Bool = false
    var onTapBar: () -> Void = {}

    private var baseWindows: Int   { booking.window_count ?? 0 }
    private var baseTotal: Double  { booking.total_price ?? 0 }
    private var todayDue: Double   { Double(onsiteAdded) * 12.50 + Double(onsiteInteriorAdded) * 12.50 + Double(onsiteScreensAdded) * 2.0 }

    var body: some View {
        if isMinimized { minimizedBar } else { expandedBody }
    }

    private var minimizedBar: some View {
        Button(action: onTapBar) {
            HStack(spacing: 10) {
                Text("Today's Summary")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Text("·")
                    .foregroundColor(.white.opacity(0.4))
                Text(todayDue > 0
                     ? "$\(String(format: "%.2f", todayDue)) due today"
                     : "Paid online ✓")
                    .font(.system(size: 12))
                    .foregroundColor(todayDue > 0 ? Color(hex: "7ED8EA") : Color(hex: "34d399"))
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "7ED8EA"))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.thinMaterial)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            .shadow(color: Color(hex: "3AAAC4").opacity(0.22), radius: 24, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var expandedBody: some View {
        VStack(spacing: 0) {
            // Blue header strip — tappable to minimize
            HStack {
                Text("Today's Summary")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                Image(systemName: "chevron.up")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(hex: "0A3D5C").opacity(0.9), Color(hex: "1278A0").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )
            .contentShape(Rectangle())
            .onTapGesture { onTapBar() }

            VStack(alignment: .leading, spacing: 0) {
                DocRow(label: "ORDERED", value: "\(baseWindows) ext · prepaid $\(String(format: "%.2f", baseTotal))")
                DocRow(label: "COMPLIMENTARY", value: "\(freeInterior) interior window free", valueColor: Color(hex: "34d399"))
                if onsiteAdded > 0 {
                    DocRow(label: "ON-SITE EXT", value: "\(onsiteAdded) × $12.50", valueColor: Color(hex: "7ED8EA"))
                }
                if onsiteInteriorAdded > 0 {
                    DocRow(label: "ON-SITE INT", value: "\(onsiteInteriorAdded) × $12.50", valueColor: Color(hex: "7ED8EA"))
                }
                if onsiteScreensAdded > 0 {
                    DocRow(label: "SCREEN HANDLING", value: "\(onsiteScreensAdded) × $2.00 = $\(String(format: "%.2f", Double(onsiteScreensAdded) * 2.0))", valueColor: Color(hex: "7ED8EA"))
                }

                Divider().opacity(0.3).padding(.vertical, 8)

                HStack {
                    Text("TODAY'S BALANCE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.5)
                        .foregroundColor(Color(hex: "7ED8EA"))
                    Spacer()
                    Text(todayDue == 0 ? "$0.00" : "$\(String(format: "%.2f", todayDue))")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                }
                .padding(.top, 2)

                if todayDue == 0 {
                    Text("Paid online · nothing due today")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "34d399"))
                        .padding(.top, 2)
                }

                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .background(Color(hex: "3AAAC4").opacity(0.06))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "3AAAC4").opacity(0.22), radius: 24, x: 0, y: 8)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct DocRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .tracking(1)
                .foregroundColor(Color(hex: "7ED8EA"))
                .frame(width: 140, alignment: .leading)
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
                .frame(maxWidth: .infinity)
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.vertical, 5)
    }
}

// MARK: - Offer panel (right column) with thermometer

struct OfferPanel: View {
    let baseWindows: Int
    let baseTotal: Double
    let freeInterior: Int
    let nextVisitOffer: Double
    let nextVisitWindows: Int

    private let retailRate = 20.0
    private var originalRetailValue: Double { Double(nextVisitWindows) * retailRate }
    private var avgPerWindow: Double        { nextVisitWindows > 0 ? nextVisitOffer / Double(nextVisitWindows) : 0 }

    var body: some View {
        VStack(spacing: 0) {
            // Header strip
            HStack {
                Text("Next Visit · \(nextVisitWindows) windows")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                Text("VERIFIED ✓")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(hex: "059669").opacity(0.9), Color(hex: "0D9488").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )

                // Body
                HStack(alignment: .top, spacing: 14) {
                    Thermometer(avg: avgPerWindow, retailRate: retailRate)

                    VStack(alignment: .leading, spacing: 0) {
                        OfferRow(label: "vs retail · \(nextVisitWindows) win × $20", value: "$\(String(format: "%.2f", originalRetailValue))")
                        OfferRow(label: "Pre-book discount", value: "−$2.00", valueColor: Color(hex: "34d399"))
                        OfferRow(label: "Free interior included", value: "−$\(String(format: "%.2f", Double(freeInterior) * retailRate))", valueColor: Color(hex: "34d399"))

                        Divider().opacity(0.3).padding(.vertical, 8)

                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NEXT VISIT TOTAL")
                                    .font(.system(size: 12, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(.white)
                                    .textOutline()
                                Text("Discounts + free window applied")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "7ED8EA"))
                                    .textOutline()
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", nextVisitOffer))")
                                .font(.system(size: 30, weight: .black))
                                .foregroundColor(.white)
                                .textOutline()
                        }

                        Text("$\(String(format: "%.2f", avgPerWindow)) avg/win · \(Int(round((1 - avgPerWindow / retailRate) * 100)))% below retail")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "34d399"))
                            .textOutline()
                            .padding(.top, 4)
                    }
                }
                .padding(14)

                Spacer(minLength: 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "34d399").opacity(0.3), radius: 18, x: 0, y: 0)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct OfferRow: View {
    let label: String
    let value: String
    var valueColor: Color = .white
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "7ED8EA"))
                .textOutline()
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(valueColor)
                .textOutline()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Thermometer (self-contained, no overflow)

struct Thermometer: View {
    let avg: Double
    let retailRate: Double

    private let floorRate = 8.0
    // Fill relative to $8 floor — $8 = empty (green), $20 = full (purple)
    private var fill: Double { min(1, max(0, (avg - floorRate) / (retailRate - floorRate))) }

    // Thresholds calibrated to 8–20 range
    private var levelColor: Color {
        if fill > 0.58 { return Color(hex: "7C3AED") }  // above ~$15
        if fill > 0.25 { return Color(hex: "F59E0B") }  // above ~$11
        return Color(hex: "059669")
    }
    private var savings: Int { Int(round((1 - avg / retailRate) * 100)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WINDOW COST")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.5)
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 8)

            HStack(alignment: .center, spacing: 10) {
                VStack(spacing: 4) {
                    Text("$\(Int(retailRate))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))

                    GeometryReader { geo in
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "7C3AED").opacity(0.08), Color(hex: "F59E0B").opacity(0.06), Color(hex: "059669").opacity(0.08)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1))

                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "7C3AED"), Color(hex: "F59E0B"), Color(hex: "059669")],
                                    startPoint: .top, endPoint: .bottom
                                ))
                                .frame(height: geo.size.height * fill)
                                .animation(.spring(response: 0.7, dampingFraction: 0.75), value: fill)
                        }
                        .frame(width: 12)
                    }
                    .frame(width: 12, height: 80)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("$\(String(format: "%.2f", avg))")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: avg)
                    Text("per window")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.7))
                    if savings > 0 {
                        Text("\(savings)% off retail")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(10)
        .background(Color(hex: "3AAAC4").opacity(0.08))
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(Color.white.opacity(0.18), lineWidth: 1))
        .shadow(color: levelColor.opacity(0.2), radius: 12)
    }
}

// MARK: - Add-on panel (exterior + interior + screens, slides in after Continue)

struct AddOnPanel: View {
    @Binding var onsiteAdded: Int
    @Binding var onsiteInteriorAdded: Int
    @Binding var onsiteScreensAdded: Int
    @Binding var tookScreenLesson: Bool
    let baseWindows: Int
    let freeInterior: Int
    var prebookedWindowsBase: Int = 0
    var arrivalScreensBase: Int = 0
    var showReset: Bool = false
    var onReset: () -> Void = {}

    private var runningWindows: Int { prebookedWindowsBase + onsiteAdded + onsiteInteriorAdded }
    private var runningScreens: Int { arrivalScreensBase + onsiteScreensAdded }

    var body: some View {
        VStack(spacing: 0) {
            // Green header matching RewardsPanel
            HStack {
                Text("Add Windows")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                HStack(spacing: 6) {
                    Text("\(runningWindows)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: runningWindows)
                    Text("win")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                    Rectangle().fill(Color.white.opacity(0.35)).frame(width: 1, height: 14)
                    Text("\(runningScreens)")
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                        .animation(.spring(response: 0.3, dampingFraction: 0.65), value: runningScreens)
                    Text("scr")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                LinearGradient(colors: [Color(hex: "059669").opacity(0.9), Color(hex: "0D9488").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )

            VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                AddOnStepper(label: "Exterior", sublabel: "$12.50 ea", value: $onsiteAdded, color: Color(hex: "7EC8E3"))
                    .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 75)

                VStack(alignment: .leading, spacing: 6) {
                    AddOnStepper(label: "Interior", sublabel: "$12.50 ea", value: $onsiteInteriorAdded, color: Color(hex: "34d399"))
                    if freeInterior > 0 {
                        Text("\(freeInterior) free included")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "34d399"))
                            .textOutline()
                    }
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 75)

                VStack(alignment: .leading, spacing: 6) {
                    AddOnStepper(label: "Screens", sublabel: "$2.00 ea", value: $onsiteScreensAdded, color: Color(hex: "F59E0B"))
                    if onsiteScreensAdded > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                tookScreenLesson.toggle()
                            }
                        } label: {
                            HStack(spacing: 5) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .stroke(Color(hex: tookScreenLesson ? "34d399" : "B8DCE8"), lineWidth: 1.5)
                                        .frame(width: 13, height: 13)
                                        .background(tookScreenLesson ? Color(hex: "34d399") : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                                    if tookScreenLesson {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Take lesson")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(tookScreenLesson ? Color(hex: "34d399") : .white)
                                        .textOutline()
                                    Text("$1 credit · no future fee")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(hex: "7ED8EA"))
                                        .textOutline()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .transition(.scale(scale: 0.88, anchor: .leading).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)

                if showReset {
                    Rectangle().fill(Color.white.opacity(0.15)).frame(width: 1, height: 75)

                    Button(action: onReset) {
                        VStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4)
                            Text("Reset\nOffer")
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.white)
                                .textOutline()
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 75)
                        .background(
                            ZStack {
                                LinearGradient(colors: [Color(hex: "0A3D5C").opacity(0.7), Color(hex: "1278A0").opacity(0.6)],
                                               startPoint: .top, endPoint: .bottom)
                                LinearGradient(colors: [.white.opacity(0.1), .clear],
                                               startPoint: .top, endPoint: .center)
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: "3AAAC4").opacity(0.5), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                }
            }

            } // end inner VStack
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "34d399").opacity(0.3), radius: 18, x: 0, y: 0)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct AddOnStepper: View {
    let label: String
    let sublabel: String
    @Binding var value: Int
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .textOutline()
            Text(sublabel)
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "7ED8EA"))
                .textOutline()
            HStack(spacing: 16) {
                Button { if value > 0 { value -= 1 } } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(value > 0 ? color : Color.white.opacity(0.2))
                        .shadow(color: value > 0 ? color.opacity(0.5) : .clear, radius: 8)
                }
                Text("\(value)")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.white)
                    .textOutline()
                    .frame(minWidth: 32)
                    .scaleEffect(value > 0 ? 1.04 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.5), value: value)
                Button { value += 1 } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 34))
                        .foregroundColor(color)
                        .shadow(color: color.opacity(0.5), radius: 8)
                }
            }
        }
    }
}

// MARK: - Rewards panel (right column alongside AddOnPanel)

struct RewardsPanel: View {
    let qualifyingAdds: Int
    let rewardCredit: Double
    let onsiteAdded: Int
    let onsiteInteriorAdded: Int
    let onsiteScreensAdded: Int
    let tookScreenLesson: Bool

    private var totalAdded: Int      { onsiteAdded + onsiteInteriorAdded }
    private var qualifyingExt: Int   { min(onsiteAdded, qualifyingAdds) }
    private var qualifyingInt: Int   { qualifyingAdds - qualifyingExt }
    private var overflowAdds: Int    { totalAdded - qualifyingAdds }
    private var screenCredit: Double { tookScreenLesson ? Double(onsiteScreensAdded) : 0 }
    private var totalCredit: Double  { rewardCredit + screenCredit }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Next Visit Rewards")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                Text("EARN 50%")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(hex: "059669").opacity(0.9), Color(hex: "0D9488").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )

            VStack(alignment: .leading, spacing: 6) {
                if totalAdded == 0 && onsiteScreensAdded == 0 {
                    Text("Add windows above to earn 50% back on next visit. Up to 5 qualify — exterior or interior.")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "7ED8EA").opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                        .textOutline()
                } else {
                    if qualifyingExt > 0 {
                        HStack {
                            Text("\(qualifyingExt) exterior")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .textOutline()
                            Spacer()
                            Text("$\(String(format: "%.2f", Double(qualifyingExt) * 6.25)) off")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "34d399"))
                                .textOutline()
                        }
                    }
                    if qualifyingInt > 0 {
                        HStack {
                            Text("\(qualifyingInt) interior")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .textOutline()
                            Spacer()
                            Text("$\(String(format: "%.2f", Double(qualifyingInt) * 6.25)) off")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "34d399"))
                                .textOutline()
                        }
                    }
                    if overflowAdds > 0 {
                        Text("+\(overflowAdds) more · full price next visit")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                            .textOutline()
                    }
                    if onsiteScreensAdded > 0 && tookScreenLesson {
                        HStack {
                            Text("\(onsiteScreensAdded) screen lesson")
                                .font(.system(size: 10))
                                .foregroundColor(.white)
                                .textOutline()
                            Spacer()
                            Text("+$\(onsiteScreensAdded) credit")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(hex: "34d399"))
                                .textOutline()
                        }
                    }
                    if totalCredit > 0 {
                        Divider().opacity(0.3)
                        HStack(alignment: .firstTextBaseline) {
                            Text("total credit next visit")
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "7ED8EA"))
                                .textOutline()
                            Spacer()
                            Text("−$\(String(format: "%.2f", totalCredit))")
                                .font(.system(size: 20, weight: .black))
                                .foregroundColor(Color(hex: "34d399"))
                                .textOutline()
                        }
                    }
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "34d399").opacity(0.3), radius: 18, x: 0, y: 0)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Updated offer panel (full-width, slides in after Notify Technician)

struct AddOnsEstimatePanel: View {
    let baseWindows: Int
    let baseTotal: Double
    let onsiteAdded: Int
    let onsiteInteriorAdded: Int
    let onsiteScreensAdded: Int
    let tookScreenLesson: Bool
    let qualifyingAdds: Int
    let rewardCredit: Double
    let updatedWindowCount: Int
    let updatedOffer: Double

    private var addRate: Double    { baseWindows > 0 ? baseTotal / Double(baseWindows) : 20.0 }
    private var addsTotal: Double  { Double(onsiteAdded + onsiteInteriorAdded) * addRate }
    private var updatedAvg: Double { updatedWindowCount > 0 ? updatedOffer / Double(updatedWindowCount) : 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Updated Next Visit · \(updatedWindowCount) windows")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                Spacer()
                Text("REWARDS APPLIED ✓")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                LinearGradient(colors: [Color(hex: "059669").opacity(0.9), Color(hex: "0D9488").opacity(0.9)],
                               startPoint: .leading, endPoint: .trailing)
            )

            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    OfferRow(label: "Original service", value: "+$\(String(format: "%.2f", baseTotal))")
                    if onsiteAdded + onsiteInteriorAdded > 0 {
                        OfferRow(label: "\(onsiteAdded) ext + \(onsiteInteriorAdded) int added",
                                 value: "+$\(String(format: "%.2f", addsTotal))")
                    }
                    if rewardCredit > 0 {
                        OfferRow(label: "50% reward · \(qualifyingAdds) qualifying",
                                 value: "−$\(String(format: "%.2f", rewardCredit))",
                                 valueColor: Color(hex: "34d399"))
                    }
                    OfferRow(label: "Pre-book discount", value: "−$2.00", valueColor: Color(hex: "34d399"))
                    if onsiteScreensAdded > 0 {
                        if tookScreenLesson {
                            OfferRow(label: "Screen lesson credit × \(onsiteScreensAdded)",
                                     value: "−$\(onsiteScreensAdded).00",
                                     valueColor: Color(hex: "34d399"))
                        } else {
                            OfferRow(label: "Screen handling × \(onsiteScreensAdded)",
                                     value: "+$\(String(format: "%.2f", Double(onsiteScreensAdded) * 2))")
                        }
                    }

                    Divider().opacity(0.3).padding(.vertical, 6)

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("UPDATED NEXT VISIT")
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1.5)
                                .foregroundColor(Color(hex: "34d399"))
                                .textOutline()
                            Text("$\(String(format: "%.2f", updatedAvg))/win · adjust adds above · Lock It In to confirm")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "7ED8EA"))
                                .textOutline()
                        }
                        Spacer()
                        Text("$\(String(format: "%.2f", updatedOffer))")
                            .font(.system(size: 32, weight: .black))
                            .foregroundColor(Color(hex: "34d399"))
                            .textOutline()
                    }
                }
                .frame(maxWidth: .infinity)

                MiniWindowGrid(count: updatedWindowCount)
                    .frame(width: 110)
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
            .stroke(Color.white.opacity(0.25), lineWidth: 1))
        .shadow(color: Color(hex: "34d399").opacity(0.3), radius: 18, x: 0, y: 0)
        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Mini window grid (replaces thermometer in AddOnsEstimatePanel)

struct MiniWindowIcon: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.white.opacity(0.06))
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(Color(hex: "7EC8E3").opacity(0.65), lineWidth: 1)
            // Horizontal pane divider
            Rectangle()
                .fill(Color(hex: "7EC8E3").opacity(0.3))
                .frame(height: 1)
            // Vertical pane divider
            Rectangle()
                .fill(Color(hex: "7EC8E3").opacity(0.3))
                .frame(width: 1)
        }
        .frame(width: 18, height: 22)
    }
}

struct MiniWindowGrid: View {
    let count: Int
    private let maxVisible = 9
    private let cols = 3

    private func opacity(for index: Int) -> Double {
        guard count > maxVisible else { return 1.0 }
        // Last 3 of the 9 visible fade out to hint at more
        if index < 6 { return 1.0 }
        let t = Double(index - 6) / 3.0
        return max(0.12, 1.0 - t * 0.88)
    }

    var body: some View {
        let visible = min(count, maxVisible)
        VStack(alignment: .leading, spacing: 4) {
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(18), spacing: 5), count: cols),
                spacing: 5
            ) {
                ForEach(0..<visible, id: \.self) { i in
                    MiniWindowIcon()
                        .opacity(opacity(for: i))
                        .animation(.easeOut(duration: 0.25).delay(Double(i) * 0.04), value: count)
                }
            }
            if count > maxVisible {
                Text("+\(count - maxVisible) more")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "7ED8EA").opacity(0.55))
                    .textOutline()
            }
            Text("\(count) win next visit")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "34d399"))
                .textOutline()
                .padding(.top, 2)
        }
    }
}

// MARK: - Pre-book row (standalone, used in the handling-choice → continue step)

struct PrebookRow: View {
    @Binding var recurringAccepted: Bool
    let nextVisitOffer: Double

    var body: some View {
        Button {
            withAnimation { recurringAccepted.toggle() }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color(hex: recurringAccepted ? "7ED8EA" : "B8DCE8"), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                        .background(recurringAccepted ? Color(hex: "1278A0") : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    if recurringAccepted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pre-book next visit · $\(String(format: "%.2f", nextVisitOffer))")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4)
                    Text("Saves 50% reward for a year · reserves a spot · email to re-confirm or cancel anytime")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "7ED8EA"))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Text("$\(String(format: "%.2f", nextVisitOffer))")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            }
            .padding(16)
            .background(recurringAccepted ? Color(hex: "3AAAC4").opacity(0.12) : Color.white.opacity(0.06))
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(recurringAccepted ? Color.white.opacity(0.35) : Color.white.opacity(0.15),
                            lineWidth: recurringAccepted ? 1.5 : 1)
            )
            .shadow(color: recurringAccepted ? Color(hex: "3AAAC4").opacity(0.35) : .clear, radius: 20, x: 0, y: 0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Helpers

private func displayDate(_ d: String) -> String {
    guard !d.isEmpty else { return "—" }
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    guard let date = f.date(from: d) else { return d }
    f.dateStyle = .medium
    f.timeStyle = .none
    return f.string(from: date)
}

private func displayTime(_ t: String) -> String {
    let parts = t.split(separator: ":").compactMap { Int($0) }
    guard parts.count >= 2 else { return t }
    let h = parts[0], m = parts[1]
    let period = h >= 12 ? "PM" : "AM"
    let hour = h > 12 ? h - 12 : h == 0 ? 12 : h
    return "\(hour):\(String(format: "%02d", m)) \(period)"
}

#Preview {
    NavigationStack {
        JobDetailView(
            booking: Booking(
                id: "preview",
                first_name: "Sarah",
                last_name: "Mitchell",
                address: "1420 Seabright Ave, Santa Cruz CA",
                service_date: "2026-06-26",
                service_time: "09:00",
                window_count: 8,
                total_price: 96.00,
                status: "confirmed"
            ),
            password: ""
        )
    }
}
