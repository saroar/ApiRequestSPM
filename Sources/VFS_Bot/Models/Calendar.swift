
import Foundation

struct CalendarPayload: Codable {
    let missionCode: String
    let countryCode: String
    let centerCode: String
    let loginUser: String
    let visaCategoryCode: String
    let fromDate: String
    let urn: String
}


struct CalendarResponse: Codable {
    let mission: String?
    let center: String?
    let visaCategory: String?
    let calendars: [CalendarDate]?
    let error: ErrorDetail?
}

struct CalendarDate: Codable {
    let date: Date
    let isWeekend: Bool
}
