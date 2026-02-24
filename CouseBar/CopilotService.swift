import Foundation

// MARK: - API Response Models

struct CopilotUserResponse: Decodable {
    let login: String?
    let copilotPlan: String?
    let quotaResetDate: String?
    let quotaSnapshots: QuotaSnapshots?

    enum CodingKeys: String, CodingKey {
        case login
        case copilotPlan = "copilot_plan"
        case quotaResetDate = "quota_reset_date"
        case quotaSnapshots = "quota_snapshots"
    }
}

struct QuotaSnapshots: Decodable {
    let premiumInteractions: QuotaSnapshot?

    enum CodingKeys: String, CodingKey {
        case premiumInteractions = "premium_interactions"
    }
}

struct QuotaSnapshot: Decodable {
    let entitlement: Int
    let overageCount: Int
    let overagePermitted: Bool
    let percentRemaining: Double
    let quotaRemaining: Double
    let remaining: Int
    let unlimited: Bool

    enum CodingKeys: String, CodingKey {
        case entitlement
        case overageCount = "overage_count"
        case overagePermitted = "overage_permitted"
        case percentRemaining = "percent_remaining"
        case quotaRemaining = "quota_remaining"
        case remaining
        case unlimited
    }

    var used: Int {
        entitlement - remaining
    }

    var percentUsed: Double {
        guard entitlement > 0 else { return 0 }
        return 100.0 - percentRemaining
    }

    var isOverLimit: Bool {
        remaining < 0
    }

    var overageAmount: Int {
        max(0, -remaining)
    }

    /// Fraction used capped at 1.0 for the "normal" portion of the bar
    var normalFraction: Double {
        guard entitlement > 0 else { return 0 }
        return min(1.0, Double(used) / Double(entitlement))
    }

    /// Fraction of overshoot beyond 100% (e.g. 0.54 means 54% overshoot)
    var overageFraction: Double {
        guard entitlement > 0, isOverLimit else { return 0 }
        return Double(overageAmount) / Double(entitlement)
    }
}

// MARK: - Copilot Token

struct CopilotApp: Decodable {
    let oauthToken: String

    enum CodingKeys: String, CodingKey {
        case oauthToken = "oauth_token"
    }
}

// MARK: - Service

@Observable
final class CopilotService {
    var usage: QuotaSnapshot?
    var login: String?
    var plan: String?
    var resetDate: String?
    var lastUpdated: Date?
    var error: String?
    var isLoading = false

    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 15 * 60 // 15 minutes

    init() {
        startAutoRefresh()
    }

    func startAutoRefresh() {
        // Initial fetch
        Task { await refresh() }

        // Set up recurring timer
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { await self.refresh() }
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let token = try readToken()
            let response = try await fetchUsage(token: token)
            usage = response.quotaSnapshots?.premiumInteractions
            login = response.login
            plan = response.copilotPlan
            resetDate = response.quotaResetDate
            lastUpdated = Date()
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Private

    private func readToken() throws -> String {
        let path = NSString("~/.config/github-copilot/apps.json").expandingTildeInPath
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        let apps = try JSONDecoder().decode([String: CopilotApp].self, from: data)
        guard let firstApp = apps.values.first else {
            throw CopilotError.noToken
        }
        return firstApp.oauthToken
    }

    private func fetchUsage(token: String) async throws -> CopilotUserResponse {
        guard let url = URL(string: "https://api.github.com/copilot_internal/user") else {
            throw CopilotError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw CopilotError.apiError
        }

        return try JSONDecoder().decode(CopilotUserResponse.self, from: data)
    }
}

enum CopilotError: LocalizedError {
    case noToken
    case invalidURL
    case apiError

    var errorDescription: String? {
        switch self {
        case .noToken: "No Copilot OAuth token found in ~/.config/github-copilot/apps.json"
        case .invalidURL: "Invalid API URL"
        case .apiError: "GitHub API request failed"
        }
    }
}
