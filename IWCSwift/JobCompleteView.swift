import SwiftUI

struct JobCompleteView: View {
    let booking: Booking
    let password: String
    let technicianName: String

    // Carried from arrive view — editable here before submit
    @State var onsiteAdded: Int
    @State var onsiteInteriorAdded: Int
    @State var screenCount: Int
    @State var prebookChosen: Bool

    @State private var saving = false
    @State private var submitted = false
    @State private var errorMsg: String? = nil
    @State private var prebookDate: String? = nil

    init(booking: Booking, password: String, technicianName: String, onsiteAdded: Int, onsiteInteriorAdded: Int, screenCount: Int, prebookChosen: Bool) {
        self.booking = booking
        self.password = password
        self.technicianName = technicianName
        _onsiteAdded = State(initialValue: onsiteAdded)
        _onsiteInteriorAdded = State(initialValue: onsiteInteriorAdded)
        _screenCount = State(initialValue: screenCount)
        _prebookChosen = State(initialValue: prebookChosen)
    }

    // ── Base values (never change) ───────────────────────────────────────────
    private let onsiteRate   = 12.50
    private let retailRate   = 20.0
    private let screenRate   = 2.0

    private var baseWindows: Int    { booking.window_count ?? 0 }
    private var baseTotal: Double   { booking.total_price ?? 0 }
    // Same formula as web closeout: reverse-engineer minimum windows from price
    // Minimum ("$22") windows each earn one free interior
    private var freeInterior: Int {
        guard baseWindows > 0 else { return 1 }
        let minW = max(1.0, ((baseTotal - 20.0 * Double(baseWindows)) / 2.0).rounded())
        return Int(minW)
    }

    // ── Session totals ───────────────────────────────────────────────────────
    private var todayCharged: Double  { Double(onsiteAdded) * onsiteRate + Double(onsiteInteriorAdded) * onsiteRate + Double(screenCount) * screenRate }
    private var totalWindows: Int     { baseWindows + onsiteAdded + onsiteInteriorAdded + freeInterior }

    // ── Updated next visit math (the "review" calculation) ──────────────────
    // Add-on credit: 50% off for up to min(baseWindows, 5) qualifying on-site adds
    private var qualifyingAdds: Int      { min(onsiteAdded, min(baseWindows, 5)) }
    private var addPromoCredit: Double   { Double(qualifyingAdds) * (onsiteRate / 2) }
    private var reviewRetailValue: Double { Double(totalWindows) * retailRate }
    // Previous discounts: $2 pre-book + free interior window value
    private var reviewPrevDiscounts: Double { 2.0 + Double(freeInterior) * retailRate }
    private var reviewNextVisit: Double  { max(20, reviewRetailValue - reviewPrevDiscounts - addPromoCredit) }
    private var reviewThermAvg: Double   { totalWindows > 0 ? reviewNextVisit / Double(totalWindows) : 0 }
    private var reviewDeltaPct: Int      { Int(round((1 - reviewThermAvg / retailRate) * 100)) }

    // Avg per window across full session (for API payload)
    private var sessionAvg: Double {
        totalWindows > 0 ? (baseTotal + todayCharged) / Double(totalWindows) : 0
    }

    var body: some View {
        Group {
            if submitted {
                SubmittedView(booking: booking, prebookDate: prebookDate)
                    .videoBackground()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        CompanyHeader(booking: booking, techName: technicianName)
                        completedLabel
                        mainColumns
                        if onsiteAdded > 0 || onsiteInteriorAdded > 0 || screenCount > 0 {
                            adjustPanel
                                .padding(.horizontal, 24)
                                .padding(.top, 16)
                        }
                        submitSection
                    }
                }
                .videoBackground()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(submitted)
        .toolbar { ToolbarItem(placement: .navigationBarTrailing) { SoundToggle() } }
    }

    // ── "COMPLETED" badge row ────────────────────────────────────────────────
    private var completedLabel: some View {
        HStack {
            Text("SESSION COMPLETE")
                .font(.system(size: 9, weight: .bold))
                .tracking(3)
                .foregroundColor(Color(hex: "059669"))
            Circle()
                .fill(Color(hex: "34d399"))
                .frame(width: 6, height: 6)
            Spacer()
            Text("Review & adjust before confirming")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "3AAAC4").opacity(0.6))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
        .background(Color(hex: "F0F9FC"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(Color(hex: "D8EFF6")), alignment: .bottom)
    }

    // ── Two-column main section ──────────────────────────────────────────────
    private var mainColumns: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: full session summary
            CompletedServiceSummary(
                booking: booking,
                freeInterior: freeInterior,
                onsiteAdded: onsiteAdded,
                onsiteInteriorAdded: onsiteInteriorAdded,
                screenCount: screenCount,
                todayCharged: todayCharged,
                baseTotal: baseTotal
            )
            .frame(maxWidth: .infinity)

            // Right: updated next visit estimate
            UpdatedOfferPanel(
                totalWindows: totalWindows,
                reviewNextVisit: reviewNextVisit,
                reviewRetailValue: reviewRetailValue,
                reviewPrevDiscounts: reviewPrevDiscounts,
                addPromoCredit: addPromoCredit,
                qualifyingAdds: qualifyingAdds,
                reviewThermAvg: reviewThermAvg,
                reviewDeltaPct: reviewDeltaPct,
                retailRate: retailRate,
                prebookChosen: $prebookChosen
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // ── Adjust panel: tweak before submit ───────────────────────────────────
    private var adjustPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ADJUST IF NEEDED")
                .font(.system(size: 8, weight: .bold))
                .tracking(2.5)
                .foregroundColor(Color(hex: "1278A0"))

            HStack(spacing: 20) {
                AddOnStepper(label: "Exterior added", sublabel: "$12.50 each", value: $onsiteAdded, color: Color(hex: "7EC8E3"))
                Rectangle().fill(Color(hex: "D8EFF6")).frame(width: 1, height: 70)
                AddOnStepper(label: "Interior added", sublabel: "$12.50 each", value: $onsiteInteriorAdded, color: Color(hex: "34d399"))
                Rectangle().fill(Color(hex: "D8EFF6")).frame(width: 1, height: 70)
                AddOnStepper(label: "Screens handled", sublabel: "$2.00 each", value: $screenCount, color: Color(hex: "F59E0B"))
            }
        }
        .padding(18)
        .background(Color(hex: "F0F9FC"))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "B8DCE8")))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // ── Submit section ───────────────────────────────────────────────────────
    private var submitSection: some View {
        VStack(spacing: 12) {
            if let err = errorMsg {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "f87171"))
                    .padding(.horizontal)
            }

            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 10) {
                    if saving {
                        ProgressView().tint(.white)
                    }
                    Text(saving ? "Saving…" : "Confirm & Save Session")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    if !saving {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(colors: [Color(hex: "059669"), Color(hex: "0D9488")], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(saving)

            Text("This records today's service and locks the next visit offer shown above.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "3AAAC4").opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 48)
    }

    private func submit() async {
        saving = true
        errorMsg = nil
        do {
            try await APIClient.submitUpsell(
                password: password,
                bookingId: booking.id,
                technicianName: technicianName,
                baseWindows: baseWindows,
                baseTotal: baseTotal,
                onsiteAdded: onsiteAdded,
                freeGiven: freeInterior,
                totalWindows: totalWindows,
                todayCharged: todayCharged,
                avgPerWindow: sessionAvg,
                recurringAccepted: prebookChosen,
                screenCount: screenCount > 0 ? screenCount : nil,
                screenTotal: screenCount > 0 ? Double(screenCount) * screenRate : nil,
                interiorAdded: onsiteInteriorAdded,
                interiorTotal: Double(onsiteInteriorAdded) * onsiteRate
            )
            if let date = try? await APIClient.createPrebook(
                password: password,
                bookingId: booking.id,
                windowCount: totalWindows,
                totalPrice: reviewNextVisit
            ) {
                await MainActor.run { prebookDate = date }
            }
            await MainActor.run { submitted = true }
        } catch {
            await MainActor.run {
                errorMsg = "Save failed: \(error.localizedDescription)"
                saving = false
            }
        }
    }
}

// MARK: - Completed service summary (left column)

struct CompletedServiceSummary: View {
    let booking: Booking
    let freeInterior: Int
    let onsiteAdded: Int
    let onsiteInteriorAdded: Int
    let screenCount: Int
    let todayCharged: Double
    let baseTotal: Double

    private var baseWindows: Int { booking.window_count ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Service Summary")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white)
                Spacer()
                Text("COMPLETED ✓")
                    .font(.system(size: 7))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(LinearGradient(colors: [Color(hex: "0A3D5C"), Color(hex: "1278A0")], startPoint: .leading, endPoint: .trailing))

            VStack(alignment: .leading, spacing: 0) {
                DocRow(label: "ORDERED", value: "\(baseWindows) ext · prepaid $\(String(format: "%.2f", baseTotal))")
                DocRow(label: "FREE INTERIOR", value: "\(freeInterior) window included", valueColor: Color(hex: "059669"))
                if onsiteAdded > 0 {
                    DocRow(
                        label: "ON-SITE EXTERIOR",
                        value: "\(onsiteAdded) × $12.50 = $\(String(format: "%.2f", Double(onsiteAdded) * 12.5))",
                        valueColor: Color(hex: "1278A0")
                    )
                }
                if onsiteInteriorAdded > 0 {
                    DocRow(
                        label: "ON-SITE INTERIOR",
                        value: "\(onsiteInteriorAdded) × $12.50 = $\(String(format: "%.2f", Double(onsiteInteriorAdded) * 12.5))",
                        valueColor: Color(hex: "34d399")
                    )
                }
                if screenCount > 0 {
                    DocRow(
                        label: "SCREENS",
                        value: "\(screenCount) × $2.00 = $\(String(format: "%.2f", Double(screenCount) * 2.0))",
                        valueColor: Color(hex: "1278A0")
                    )
                }

                Divider().background(Color(hex: "EBF5FA")).padding(.vertical, 8)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY'S ADDITIONAL")
                            .font(.system(size: 8, weight: .bold))
                            .tracking(1.5)
                            .foregroundColor(Color(hex: "3AAAC4"))
                        Text("Pre-paid $\(String(format: "%.2f", baseTotal)) at booking")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "059669"))
                    }
                    Spacer()
                    Text("$\(String(format: "%.2f", todayCharged))")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(todayCharged > 0 ? Color(hex: "0A2740") : Color(hex: "059669"))
                }
                .padding(.top, 2)

                if todayCharged == 0 {
                    Text("Nothing additional due today")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "059669"))
                        .padding(.top, 2)
                }
            }
            .padding(14)
            .background(Color(hex: "F5FBFD"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "B8DCE8")))
        .padding(.trailing, 10)
    }
}

// MARK: - Updated next visit offer panel (right column)

struct UpdatedOfferPanel: View {
    let totalWindows: Int
    let reviewNextVisit: Double
    let reviewRetailValue: Double
    let reviewPrevDiscounts: Double
    let addPromoCredit: Double
    let qualifyingAdds: Int
    let reviewThermAvg: Double
    let reviewDeltaPct: Int
    let retailRate: Double
    @Binding var prebookChosen: Bool

    var body: some View {
        VStack(spacing: 0) {
                // Header strip
                HStack {
                    Text("Next Visit · \(totalWindows) windows · all adds included")
                        .font(.system(size: 9, weight: .bold))
                        .tracking(1)
                        .foregroundColor(.white)
                    Spacer()
                    Text("UPDATED ✓")
                        .font(.system(size: 7))
                        .foregroundColor(Color(hex: "34d399").opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(colors: [Color(hex: "0A3D5C"), Color(hex: "1278A0")], startPoint: .leading, endPoint: .trailing)
                )

                // Body
                HStack(alignment: .top, spacing: 12) {
                    // Thermometer with updated avg
                    Thermometer(avg: reviewThermAvg, retailRate: retailRate)
                        .frame(width: 56)

                    // Breakdown
                    VStack(alignment: .leading, spacing: 0) {
                        OfferRow(label: "Next visit retail · \(totalWindows) win × $20", value: "$\(String(format: "%.2f", reviewRetailValue))")
                        OfferRow(label: "Previous discounts (pre-book + interior)", value: "−$\(String(format: "%.2f", reviewPrevDiscounts))", valueColor: Color(hex: "059669"))
                        if addPromoCredit > 0 {
                            OfferRow(
                                label: "Add-on credit (\(qualifyingAdds) win · 50% off first year)",
                                value: "−$\(String(format: "%.2f", addPromoCredit))",
                                valueColor: Color(hex: "059669")
                            )
                        }

                        Divider().background(Color(hex: "EBF5FA")).padding(.vertical, 8)

                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("NEXT VISIT TOTAL")
                                    .font(.system(size: 8, weight: .bold))
                                    .tracking(1.5)
                                    .foregroundColor(Color(hex: "0A2740"))
                                Text("\(reviewDeltaPct)% below retail · all credits applied")
                                    .font(.system(size: 8))
                                    .foregroundColor(Color(hex: "059669"))
                            }
                            Spacer()
                            Text("$\(String(format: "%.2f", reviewNextVisit))")
                                .font(.system(size: 30, weight: .heavy))
                                .foregroundColor(Color(hex: "0A3D5C"))
                        }

                        // Pre-book toggle
                        Button {
                            withAnimation { prebookChosen.toggle() }
                        } label: {
                            HStack(spacing: 10) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(hex: prebookChosen ? "1278A0" : "B8DCE8"), lineWidth: 1.5)
                                        .frame(width: 20, height: 20)
                                        .background(prebookChosen ? Color(hex: "1278A0") : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    if prebookChosen {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                Text("Pre-book this offer · email reminder before pass expires")
                                    .font(.system(size: 11))
                                    .foregroundColor(prebookChosen ? Color(hex: "0A2740") : Color(hex: "3AAAC4"))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 10)
                        .padding(12)
                        .background(prebookChosen ? Color(hex: "EBF7FA") : Color.clear)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(hex: prebookChosen ? "3AAAC4" : "D8EFF6")))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 4)
                    }
                }
                .padding(14)
                .background(Color(hex: "F0F9FC"))
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: "B8DCE8")))
        .padding(.leading, 10)
    }
}

// MARK: - Post-submit thank-you

struct SubmittedView: View {
    let booking: Booking
    let prebookDate: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer().frame(height: 60)

                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundColor(Color(hex: "34d399"))
                    Text("Session Saved")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundColor(.white)
                    Text("Thank you, \(booking.displayName.split(separator: " ").first.map(String.init) ?? "")!")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.6))
                }

                if let date = prebookDate {
                    PrebookAnnouncementCard(isoDate: date)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 8) {
                    Text("SIMPLE WINDOW CLEANING")
                        .font(.system(size: 10, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(.white.opacity(0.2))
                    Text("Santa Cruz · Silicon Valley")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.15))
                }

                Button {
                    UIApplication.shared.open(URL(string: "https://www.ladderlesswindows.com/commercial")!)
                } label: {
                    Text("Done · Book My Neighbor")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12)))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Shared prebook announcement card

struct PrebookAnnouncementCard: View {
    let isoDate: String

    private var displayDate: String {
        let iso = DateFormatter(); iso.dateFormat = "yyyy-MM-dd"
        guard let d = iso.date(from: isoDate) else { return isoDate }
        let fmt = DateFormatter(); fmt.dateFormat = "MMMM d, yyyy"
        return fmt.string(from: d)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 20))
                    .foregroundColor(Color(hex: "3AAAC4"))
                Text("SPOT RESERVED")
                    .font(.system(size: 10, weight: .bold))
                    .tracking(3)
                    .foregroundColor(Color(hex: "3AAAC4"))
            }

            Text("A spot has been saved in exactly 1 year to utilize these rewards.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(displayDate)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(Color(hex: "7ED8EA"))

            VStack(spacing: 5) {
                Text("We'll send reminders before this date.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Text("Confirm or move — no obligation.")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
                Text("Auto-cancels without a confirm.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.3))
            }
            .multilineTextAlignment(.center)
        }
        .padding(22)
        .background(Color(hex: "0A2740").opacity(0.8))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "3AAAC4").opacity(0.35), lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    NavigationStack {
        JobCompleteView(
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
            password: "",
            technicianName: "CJ Vin",
            onsiteAdded: 3,
            onsiteInteriorAdded: 2,
            screenCount: 2,
            prebookChosen: true
        )
    }
}
