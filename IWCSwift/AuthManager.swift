import SwiftUI
import Combine

struct Employee: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let pin: String
    let role: Role

    enum Role { case admin, worker }
}

// ── Update names, PINs, and roles here ───────────────────────────────────────
private let roster: [Employee] = [
    Employee(name: "Flynn Vin", pin: "0000", role: .admin),
    Employee(name: "CJ Vin",   pin: "9999", role: .worker),
]
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    let employees: [Employee] = roster

    @Published var currentEmployee: Employee? = nil

    // API password is separate from employee PINs — set once by admin
    var apiPassword: String {
        UserDefaults.standard.string(forKey: "worker_password") ?? ""
    }
    var isConfigured: Bool { !apiPassword.isEmpty }

    private init() {}

    func login(employee: Employee, pin: String) -> Bool {
        guard pin == employee.pin else { return false }
        currentEmployee = employee
        return true
    }

    func logout() {
        currentEmployee = nil
    }

    func saveAPIPassword(_ pwd: String) {
        UserDefaults.standard.set(pwd, forKey: "worker_password")
    }
}
