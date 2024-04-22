
import Foundation

// MARK: - CountryMission
struct CountryMission: Codable {
    let id: Int
    let countryCode, missionCode: String
    let isActive: Bool
    let startTimeUTC, endTimeUTC: Date
    let activeClientsCount: Int

    enum CodingKeys: String, CodingKey {
        case id, countryCode, missionCode
        case isActive = "is_active"
        case startTimeUTC = "start_time_utc"
        case endTimeUTC = "end_time_utc"
        case activeClientsCount = "active_clients_count"
    }
}

typealias CountryMissions = [CountryMission]
