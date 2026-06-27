import Foundation
import SwiftUI

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct Booking: Identifiable, Decodable, Hashable {
    let id: String
    let first_name: String?
    let last_name: String?
    let address: String?
    let service_date: String?
    let service_time: String?
    let window_count: Int?
    let total_price: Double?
    let status: String?

    var displayName: String {
        [first_name, last_name].compactMap { $0 }.joined(separator: " ")
    }
}

struct UpsellSession: Identifiable, Decodable {
    let id: String
    let booking_id: String
    let onsite_windows_added: Int
    let total_charged: Double?
}

struct BookingsResponse: Decodable {
    let bookings: [Booking]
}

struct UpsellResponse: Decodable {
    let sessions: [UpsellSession]
}
