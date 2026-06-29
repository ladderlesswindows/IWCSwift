import SwiftUI
import WebKit

// MARK: - DispatchView

struct DispatchView: View {
    let password: String
    let onExit: () -> Void

    @State private var tappedBooking: DispatchBooking? = nil
    @State private var shouldReload = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            AdminWebView(shouldReload: $shouldReload, onBookingTapped: { booking in
                tappedBooking = booking
            })
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
        .sheet(item: $tappedBooking, onDismiss: { shouldReload = true }) { booking in
            BookingMoveSheet(booking: booking, password: password)
        }
    }
}

// MARK: - Admin WebView

private struct AdminWebView: UIViewRepresentable {
    @Binding var shouldReload: Bool
    let onBookingTapped: (DispatchBooking) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBookingTapped: onBookingTapped) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(WeakMessageHandler(context.coordinator), name: "bookingTapped")
        let webView = WKWebView(frame: .zero, configuration: config)
        context.coordinator.webView = webView
        webView.load(URLRequest(url: URL(string: "https://www.ladderlesswindows.com/admin")!))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if shouldReload {
            webView.reload()
            DispatchQueue.main.async { shouldReload = false }
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var onBookingTapped: (DispatchBooking) -> Void
        weak var webView: WKWebView?

        init(onBookingTapped: @escaping (DispatchBooking) -> Void) {
            self.onBookingTapped = onBookingTapped
        }

        func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "bookingTapped",
                  let d = message.body as? [String: Any] else { return }
            let booking = DispatchBooking(
                id:          d["id"]           as? String ?? "",
                firstName:   d["first_name"]   as? String,
                lastName:    d["last_name"]    as? String,
                address:     d["address"]      as? String,
                serviceDate: d["service_date"] as? String,
                serviceTime: d["service_time"] as? String,
                windowCount: (d["window_count"] as? NSNumber)?.intValue,
                totalPrice:  (d["total_price"]  as? NSNumber)?.doubleValue,
                status:      d["status"]       as? String
            )
            DispatchQueue.main.async { self.onBookingTapped(booking) }
        }
    }
}

private class WeakMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?
    init(_ delegate: WKScriptMessageHandler) { self.delegate = delegate }
    func userContentController(_ c: WKUserContentController, didReceive m: WKScriptMessage) {
        delegate?.userContentController(c, didReceive: m)
    }
}

// MARK: - Booking model for dispatch

struct DispatchBooking: Identifiable {
    let id: String
    let firstName: String?
    let lastName: String?
    let address: String?
    let serviceDate: String?
    let serviceTime: String?
    let windowCount: Int?
    let totalPrice: Double?
    let status: String?

    var displayName: String {
        [firstName, lastName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
    }
}

// MARK: - Reschedule sheet

struct BookingMoveSheet: View {
    let booking: DispatchBooking
    let password: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedDate: String
    @State private var selectedTime: String
    @State private var moving = false

    private let timeSlots = ["08:00", "09:00", "10:00", "11:00", "12:00", "13:00", "14:00"]

    init(booking: DispatchBooking, password: String) {
        self.booking  = booking
        self.password = password
        _selectedDate = State(initialValue: booking.serviceDate ?? "")
        _selectedTime = State(initialValue: booking.serviceTime ?? "")
    }

    private var nearbyDates: [String] {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let base = fmt.date(from: booking.serviceDate ?? "") else { return [] }
        return (-4...4).compactMap { offset in
            guard let d = Calendar.current.date(byAdding: .day, value: offset, to: base) else { return nil }
            return fmt.string(from: d)
        }
    }

    private var hasChanged: Bool {
        selectedDate != (booking.serviceDate ?? "") || selectedTime != (booking.serviceTime ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0d0b1a").ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Info card
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(alignment: .top) {
                                Text(booking.displayName.isEmpty ? "Unknown" : booking.displayName)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                Spacer()
                                DispatchStatusBadge(status: booking.status ?? "")
                            }
                            if let addr = booking.address {
                                Text(addr)
                                    .font(.system(size: 13))
                                    .foregroundColor(.white.opacity(0.45))
                            }
                            HStack(spacing: 14) {
                                if let d = booking.serviceDate { infoLabel(displayDate(d), icon: "calendar") }
                                if let t = booking.serviceTime { infoLabel(displayTime(t),  icon: "clock") }
                                if let w = booking.windowCount { infoLabel("\(w)w",          icon: "square.grid.2x2") }
                                if let p = booking.totalPrice  { infoLabel("$\(Int(p))",     icon: "dollarsign") }
                            }
                        }
                        .padding(16)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        // Date row
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("DATE")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(nearbyDates, id: \.self) { date in
                                        DayChip(
                                            date: date,
                                            isSelected: date == selectedDate,
                                            isCurrent:  date == booking.serviceDate
                                        ) { selectedDate = date }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }

                        // Time grid
                        VStack(alignment: .leading, spacing: 10) {
                            sectionLabel("TIME")
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(timeSlots, id: \.self) { time in
                                    TimeChip(
                                        time: time,
                                        isSelected: time == selectedTime,
                                        isCurrent:  time == booking.serviceTime
                                    ) { selectedTime = time }
                                }
                            }
                        }

                        // Move button
                        Button {
                            Task { await moveJob() }
                        } label: {
                            Group {
                                if moving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Move Job")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(hasChanged && !moving ? Color(hex: "3AAAC4") : Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(!hasChanged || moving)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Booking Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    @ViewBuilder
    private func infoLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.4))
    }

    @ViewBuilder
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white.opacity(0.3))
            .kerning(1.5)
    }

    private func moveJob() async {
        moving = true
        try? await APIClient.moveBooking(password: password, bookingId: booking.id, date: selectedDate, time: selectedTime)
        await MainActor.run { moving = false; dismiss() }
    }

    private func displayDate(_ str: String) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: str) else { return str }
        let out = DateFormatter(); out.dateFormat = "MMM d"
        return out.string(from: d)
    }

    private func displayTime(_ str: String) -> String {
        let parts = str.split(separator: ":").compactMap { Int($0) }
        guard let h = parts.first else { return str }
        if h == 0 { return "12am" }
        return h < 12 ? "\(h)am" : h == 12 ? "12pm" : "\(h - 12)pm"
    }
}

// MARK: - Chip subviews

private struct DayChip: View {
    let date: String
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void

    private var weekday: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return "" }
        let out = DateFormatter(); out.dateFormat = "EEE"
        return out.string(from: d).uppercased()
    }
    private var day: String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: date) else { return "" }
        let out = DateFormatter(); out.dateFormat = "d"
        return out.string(from: d)
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(weekday)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.4))
                Text(day)
                    .font(.system(size: 15, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .black : isCurrent ? Color(hex: "3AAAC4") : .white.opacity(0.8))
            }
            .frame(width: 46, height: 50)
            .background(
                isSelected ? Color(hex: "3AAAC4") :
                isCurrent  ? Color(hex: "3AAAC4").opacity(0.12) :
                             Color.white.opacity(0.05)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay {
                if isCurrent && !isSelected {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(hex: "3AAAC4").opacity(0.4), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct TimeChip: View {
    let time: String
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void

    private var label: String {
        let parts = time.split(separator: ":").compactMap { Int($0) }
        guard let h = parts.first else { return time }
        if h == 0 { return "12am" }
        return h < 12 ? "\(h)am" : h == 12 ? "12pm" : "\(h - 12)pm"
    }

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .black : isCurrent ? Color(hex: "7c3aed") : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    isSelected ? Color(hex: "7c3aed") :
                    isCurrent  ? Color(hex: "7c3aed").opacity(0.15) :
                                 Color.white.opacity(0.05)
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct DispatchStatusBadge: View {
    let status: String

    private var color: Color {
        switch status {
        case "confirmed":                  return .green
        case "prebooked", "lead_pending":  return Color(hex: "3AAAC4")
        case "pending":                    return .orange
        default:                           return .gray
        }
    }

    var body: some View {
        Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.15))
            .clipShape(Capsule())
    }
}
