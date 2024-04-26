
import Foundation

// MARK: - CountryMission
public struct CountryMission: Codable {
    public let id: Int
    public let countryCode, missionCode: String
    public let isActive: Bool
    public let startTimeUTC, endTimeUTC: Date
    public let activeClientsCount: Int
    public let requestSleepSec: Int
    public let earliestDateRetryInSec: Int

    // Computed properties for formatting dates, not included in Codable operations
    public var formattedStartTime: String {
        return convertToLocalTimeString(date: startTimeUTC, countryCode: countryCode)
    }

    public var formattedEndTime: String {
        return convertToLocalTimeString(date: endTimeUTC, countryCode: countryCode)
    }

    enum CodingKeys: String, CodingKey {
        case id, countryCode, missionCode
        case isActive = "is_active"
        case startTimeUTC = "start_time_utc"
        case endTimeUTC = "end_time_utc"
        case activeClientsCount = "active_clients_count"
        case requestSleepSec = "request_sleep_sec"
        case earliestDateRetryInSec = "earliest_date_retry_in_sec"
    }


}

extension CountryMission {
    private func getCurrentLocalTimeString(countryCode: String) -> String {
        let timeZone = timeZoneForCountryCode(countryCode.uppercased())
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // E.g., "Jan 1, 2024"
        formatter.timeStyle = .short   // E.g., "1:30 PM"
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US")  // Ensures formatting conventions of the U.S. (e.g., AM/PM notation)

        return formatter.string(from: Date())  // Using Date() to get the current date and time
    }

    private func convertToLocalTimeString(date: Date, countryCode: String) -> String {
        let timeZone = timeZoneForCountryCode(countryCode)
        let formatter = DateFormatter()
        formatter.dateStyle = .medium  // E.g., "Jan 1, 2024"
        formatter.timeStyle = .short   // E.g., "1:30 PM"
        formatter.timeZone = timeZone
//        converter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        let localDateString = formatter.string(from: date)
        return localDateString
    }

    private func timeZoneForCountryCode(_ countryCode: String) -> TimeZone {
        // Map of country codes to time zone identifiers
        let timeZoneMap = [
            "BGD": "Asia/Dhaka", // Bangladesh Standard Time
            "IND": "Asia/Kolkata",  // India Standard Time
            "USA": "America/New_York",  // Eastern Standard Time
            "ARE": "Asia/Dubai",  // United Arab Emirates
            "GBR": "Europe/London",  // United Kingdom
            "NPL": "Asia/Kathmandu",  // Nepal
            "SGP": "Asia/Singapore",  // Singapore
        ]

        let timeZoneIdentifier = timeZoneMap[countryCode] ?? "UTC"  // Default to UTC if no mapping exists
        return TimeZone(identifier: timeZoneIdentifier) ?? TimeZone(secondsFromGMT: 0)!
    }


    public struct DisplayMission: Codable {
        var id: Int
        var countryCode, missionCode: String
        var countryFlag, missionFlag: String
        var currentTime: String
        var is_active: Bool
        var formattedStartTime: String
        var formattedEndTime: String
        var active_clients_count: Int
        var request_sleep_sec: Int
        var earliest_date_retry_in_sec: Int
    }

    public func newData() -> DisplayMission {

        let enumCountryCode = CountryCode(rawValue: countryCode)
        let enumMissionCode = CountryCode(rawValue: missionCode)

        let countryFlag = isoToFlag(enumCountryCode!.twoLetterISO)
        let missionFlag = isoToFlag(enumMissionCode!.twoLetterISO)

        return .init(
            id: id,
            countryCode: "\(countryCode.uppercased())",
            missionCode: "\(missionCode.uppercased())",
            countryFlag: "\(countryFlag)",
            missionFlag: "\(missionFlag)", 
            currentTime: getCurrentLocalTimeString(countryCode: countryCode),
            is_active: isActive,
            formattedStartTime: formattedStartTime,
            formattedEndTime: formattedEndTime,
            active_clients_count: activeClientsCount,
            request_sleep_sec: requestSleepSec,
            earliest_date_retry_in_sec: earliestDateRetryInSec
        )
    }

    private func isoToFlag(_ isoCode: String) -> String {
        guard isoCode.count == 2 && isoCode.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil else {
            return "🏳️"  // Return a default flag or symbol for invalid codes
        }

        let baseScalar = UnicodeScalar("🇦").value - UnicodeScalar("A").value
        var flagString = ""

        for char in isoCode.uppercased() {
            guard let scalar = UnicodeScalar(baseScalar + UnicodeScalar(String(char))!.value) else {
                return "🏳️"
            }
            flagString.unicodeScalars.append(scalar)
        }

        return String(flagString)
    }
}

public typealias CountryMissions = [CountryMission]
