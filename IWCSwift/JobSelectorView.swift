import SwiftUI

struct JobSelectorView: View {
    @EnvironmentObject private var auth: AuthManager
    private var password: String { auth.apiPassword }
    @State private var bookings: [Booking] = []
    @State private var sessions: [UpsellSession] = []
    @State private var loading = true
    @State private var selectedBooking: Booking? = nil

    private var today: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private var completedIds: Set<String> {
        Set(sessions.map { $0.booking_id })
    }

    private var activeBookings: [Booking] {
        bookings.filter { !completedIds.contains($0.id) }
    }

    private var completedBookings: [Booking] {
        bookings.filter { completedIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                RadialGradient(
                    colors: [Color(hex: "180a3a"), Color(hex: "06050f")],
                    center: UnitPoint(x: 0.35, y: 0.25),
                    startRadius: 0, endRadius: 800
                ).ignoresSafeArea()

                if loading {
                    ProgressView().tint(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("SIMPLE WINDOW CLEANING")
                                    .font(.system(size: 11, weight: .semibold))
                                    .tracking(4)
                                    .foregroundColor(.white.opacity(0.25))
                                Text("Job Closeout")
                                    .font(.system(size: 36, weight: .heavy))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 44)

                            if bookings.isEmpty {
                                Text("No jobs scheduled for today")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.45))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 56)
                                    .background(Color.white.opacity(0.03))
                                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.07)))
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                if !activeBookings.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("SELECT A JOB")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(3.5)
                                            .foregroundColor(.white.opacity(0.3))

                                        ForEach(activeBookings) { booking in
                                            JobCard(booking: booking, session: nil) {
                                                selectedBooking = booking
                                            }
                                        }
                                    }
                                }

                                if !completedBookings.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("COMPLETED TODAY")
                                            .font(.system(size: 10, weight: .bold))
                                            .tracking(3.5)
                                            .foregroundColor(Color(hex: "34d399").opacity(0.7))

                                        ForEach(completedBookings) { booking in
                                            JobCard(
                                                booking: booking,
                                                session: sessions.first { $0.booking_id == booking.id }
                                            ) { selectedBooking = booking }
                                        }
                                    }
                                }
                            }

                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 40)
                    }
                }
            }
            .navigationDestination(item: $selectedBooking) { booking in
                JobDetailView(booking: booking, password: password)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let emp = auth.currentEmployee {
                        Text(emp.name)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation { auth.logout() }
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.25))
                    }

                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        async let b = APIClient.fetchBookings(password: password)
        async let s = APIClient.fetchSessions(password: password)
        let (fetchedBookings, fetchedSessions) = (try? await b, try? await s)
        await MainActor.run {
            let todayStr = today
            bookings = (fetchedBookings ?? []).filter { $0.service_date == todayStr }
            sessions = fetchedSessions ?? []
            loading = false
        }
    }
}

struct JobCard: View {
    let booking: Booking
    let session: UpsellSession?
    let onTap: () -> Void

    private var isCompleted: Bool { session != nil }

    var body: some View {
        Button { onTap() } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 10) {
                        Text(booking.displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        if isCompleted {
                            Text("Closed Out")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(2)
                                .foregroundColor(Color(hex: "34d399"))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color(hex: "34d399").opacity(0.4)))
                        }
                    }

                    Text(booking.address ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))

                    HStack(spacing: 4) {
                        Text(booking.service_time.map(formatTime) ?? "")
                        Text("·")
                        Text("\(booking.window_count ?? 0) windows")
                        if let s = session, s.onsite_windows_added > 0 {
                            Text("+ \(s.onsite_windows_added) added")
                                .foregroundColor(Color(hex: "34d399").opacity(0.7))
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.25))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let price = booking.total_price {
                        Text("$\(price, specifier: "%.2f")")
                            .font(.system(size: 28, weight: .heavy))
                            .foregroundColor(Color(hex: "34d399"))
                    }
                    if let s = session, let charged = s.total_charged, charged > 0 {
                        Text("+$\(charged, specifier: "%.2f") adds")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "34d399"))
                    }
                    Text(isCompleted ? "view record" : "booked total")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .background(Color.white.opacity(isCompleted ? 0.015 : 0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isCompleted ? Color(hex: "34d399").opacity(0.2) : Color.white.opacity(0.09))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }

    private func formatTime(_ t: String) -> String {
        let parts = t.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return t }
        let h = parts[0], m = parts[1]
        let period = h >= 12 ? "PM" : "AM"
        let hour = h > 12 ? h - 12 : h == 0 ? 12 : h
        return "\(hour):\(String(format: "%02d", m)) \(period)"
    }
}
