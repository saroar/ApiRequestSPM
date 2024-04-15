import Foundation

public enum CountryCode: String, Codable {
    case UK = "gbr"
    case UAE = "are"
    case USA = "usa"
    case ITALY = "ita"
    case NEPAL = "npl"
    case INDIA = "ind"
    case QATAR = "qat"
    case RUSSIA = "rus"
    case POLAND = "pol"
    case CROATIA = "hrv"
    case PORTUGAL = "prt"
    case SINGAPORE = "sgp"
    case LITHUANIA = "ltp"
    case UZBEKISTAN = "uzb"
    case KAZAKHSTAN = "kaz"
    case BANGLADESH = "bgd"
    case TAJIKISTAN = "tjk"
    case SAUDI_ARABIA = "sau"

    var twoLetterISO: String {
        switch self {
            case .UK: return "GB"
            case .UAE: return "AE"
            case .USA: return "US"
            case .ITALY: return "IT"
            case .NEPAL: return "NP"
            case .INDIA: return "IN"
            case .QATAR: return "QA"
            case .RUSSIA: return "RU"
            case .POLAND: return "PL"
            case .CROATIA: return "HR"
            case .PORTUGAL: return "PT"
            case .SINGAPORE: return "SG"
            case .LITHUANIA: return "LT"
            case .BANGLADESH: return "BD"
            case .TAJIKISTAN: return "TJ"
            case .KAZAKHSTAN: return "KZ"
            case .UZBEKISTAN: return "UZ"
            case .SAUDI_ARABIA: return "SA"
        }
    }
}
