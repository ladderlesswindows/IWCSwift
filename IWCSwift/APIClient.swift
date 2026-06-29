import Foundation

class APIClient {
    static let base = "https://www.ladderlesswindows.com"

    static func headers(password: String) -> [String: String] {
        ["x-admin-pw": password, "Content-Type": "application/json"]
    }

    static func fetchBookings(password: String) async throws -> [Booking] {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/bookings")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(BookingsResponse.self, from: data).bookings
    }

    static func fetchSessions(password: String) async throws -> [UpsellSession] {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/upsell")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(UpsellResponse.self, from: data).sessions
    }

    static func submitUpsell(
        password: String,
        bookingId: String,
        technicianName: String,
        baseWindows: Int,
        baseTotal: Double,
        onsiteAdded: Int,
        freeGiven: Int,
        totalWindows: Int,
        todayCharged: Double,
        avgPerWindow: Double,
        recurringAccepted: Bool,
        screenCount: Int?,
        screenTotal: Double?,
        interiorAdded: Int,
        interiorTotal: Double
    ) async throws {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/upsell")!)
        req.httpMethod = "POST"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "booking_id":            bookingId,
            "technician_name":       technicianName,
            "base_windows":          baseWindows,
            "base_total":            baseTotal,
            "onsite_windows_added":  onsiteAdded,
            "free_windows_given":    freeGiven,
            "total_windows":         totalWindows,
            "total_charged":         todayCharged,
            "avg_per_window":        (avgPerWindow * 100).rounded() / 100,
            "recurring_accepted":    recurringAccepted,
            "deposit_collected":     false,
            "interior_decision":     interiorAdded > 0 ? "today" : "declined",
            "interior_windows":      interiorAdded > 0 ? interiorAdded : nil as Any? as Any,
            "interior_total":        interiorAdded > 0 ? interiorTotal : nil as Any? as Any,
            "screen_count":          screenCount as Any,
            "screen_total":          screenTotal as Any,
        ] as [String: Any])
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    static func recordPrebookIntent(
        password: String,
        bookingId: String,
        nextVisitPrice: Double
    ) async throws {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/prebook-intent")!)
        req.httpMethod = "POST"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "booking_id":       bookingId,
            "next_visit_price": nextVisitPrice,
        ] as [String: Any])
        let (_, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }

    static func moveBooking(password: String, bookingId: String, date: String, time: String) async throws {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/bookings")!)
        req.httpMethod = "PATCH"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["id": bookingId, "service_date": date, "service_time": time])
        _ = try await URLSession.shared.data(for: req)
    }

    static func fetchActiveCheckin(password: String) async throws -> Booking? {
        struct Res: Decodable {
            struct CheckinData: Decodable { let booking: Booking? }
            let checkin: CheckinData?
        }
        var req = URLRequest(url: URL(string: "\(base)/api/tech/checkin/active")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(Res.self, from: data).checkin?.booking
    }

    static func createPrebook(
        password: String,
        bookingId: String,
        windowCount: Int,
        totalPrice: Double
    ) async throws -> String {
        struct Res: Decodable { let id: String; let service_date: String }
        var req = URLRequest(url: URL(string: "\(base)/api/admin/prebook")!)
        req.httpMethod = "POST"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "booking_id":   bookingId,
            "window_count": windowCount,
            "total_price":  totalPrice,
        ] as [String: Any])
        let (data, response) = try await URLSession.shared.data(for: req)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(Res.self, from: data).service_date
    }

    struct CheckInStatusResponse: Decodable {
        struct Row: Decodable { let id: String; let status: String; let tech_name: String? }
        let pending: Row?
        let confirmed: Row?
    }

    static func pollCheckIn(password: String, bookingId: String) async throws -> CheckInStatusResponse {
        let encoded = bookingId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? bookingId
        var req = URLRequest(url: URL(string: "\(base)/api/tech/checkin?booking_id=\(encoded)")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(CheckInStatusResponse.self, from: data)
    }

    static func confirmCheckIn(password: String, id: String) async throws {
        var req = URLRequest(url: URL(string: "\(base)/api/tech/checkin")!)
        req.httpMethod = "PATCH"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: ["id": id])
        _ = try await URLSession.shared.data(for: req)
    }

    static func sendTechAlert(
        password: String,
        bookingId: String,
        customerName: String,
        address: String,
        windowsAdded: Int,
        interiorsAdded: Int,
        screensAdded: Int,
        technicianName: String
    ) async throws {
        var req = URLRequest(url: URL(string: "\(base)/api/tech/notify")!)
        req.httpMethod = "POST"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "booking_id":       bookingId,
            "customer_name":    customerName,
            "address":          address,
            "windows_added":    windowsAdded,
            "interiors_added":  interiorsAdded,
            "screens_added":    screensAdded,
            "technician_name":  technicianName,
        ] as [String: Any])
        _ = try await URLSession.shared.data(for: req)
    }

    struct TechAlert: Decodable {
        let id: String
        let type: String?
        let message: String?
        let created_at: String
    }
    private struct TechAlertsResponse: Decodable { let alerts: [TechAlert] }

    static func sendScreensAlert(
        password: String,
        bookingId: String,
        techName: String,
        confirmedCount: Int,
        preorderCount: Int
    ) async throws {
        let message: String
        if confirmedCount == 0 {
            message = "No screens on preordered windows"
        } else {
            message = "Screens confirmed, \(confirmedCount)/\(preorderCount) need handling"
        }
        var req = URLRequest(url: URL(string: "\(base)/api/tech/alerts")!)
        req.httpMethod = "POST"
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "booking_id": bookingId,
            "type": "screens_confirmed",
            "message": message,
            "technician_name": techName,
        ] as [String: Any])
        _ = try await URLSession.shared.data(for: req)
    }

    static func fetchJobStatusAlerts(password: String, bookingId: String) async throws -> [TechAlert] {
        let encoded = bookingId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? bookingId
        var req = URLRequest(url: URL(string: "\(base)/api/tech/alerts?booking_id=\(encoded)")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(TechAlertsResponse.self, from: data).alerts
    }

    static func verifyPassword(_ password: String) async -> Bool {
        var req = URLRequest(url: URL(string: "\(base)/api/admin/bookings")!)
        headers(password: password).forEach { req.setValue($1, forHTTPHeaderField: $0) }
        guard let (_, response) = try? await URLSession.shared.data(for: req) else { return false }
        return (response as? HTTPURLResponse)?.statusCode == 200
    }
}
