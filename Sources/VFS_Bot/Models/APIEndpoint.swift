import Foundation


enum APIEndpoint {

    enum TelegramMethod: String {
        case sendMessage = "sendMessage"
        case sendDocument = "sendDocument"
        // Add more methods as needed
    }

    case userLogin
    case appointmentApplication
    case checkSlotAvailability
    case appointmentApplicants
    case appointmentFees
    case appointmentCalendar
    case appointmentTimeSlot
    case mapVAS
    case partnerServiceMap
    case appointmentSchedule
    case appointmentApplicantOTP
    case appointmentDownloadPDF

    case getIP

    case clientApplications
    case userAccounts
    case proxies
    case missions

    case telegram(botToken: String, method: TelegramMethod)

    var baseURL: String {
        switch self {
            case .getIP:
                return "http://httpbin.org"
            case .clientApplications, .userAccounts, .proxies, .missions:
                return "http://167.99.251.49:8012"
            case .telegram:
                return "https://api.telegram.org"
            default:
                return "https://lift-api.vfsglobal.com"
        }
    }

    var path: String {
        switch self {
            case .userLogin:
                return "/user/login"
            case .appointmentApplication:
                return "/appointment/application"
            case .checkSlotAvailability:
                return "/appointment/CheckIsSlotAvailable"
            case .appointmentApplicants:
                return "/appointment/applicants"
            case .appointmentFees:
                return "/appointment/fees"
            case .appointmentCalendar:
                return "/appointment/calendar"
            case .appointmentTimeSlot:
                return "/appointment/timeslot"
            case .mapVAS:
                return "/vas/mapvas"
            case .partnerServiceMap:
                return "/vas/MapTMIPartnerService"
            case .appointmentSchedule:
                return "/appointment/schedule"
            case .appointmentApplicantOTP:
                return "/appointment/applicantotp"
            case .appointmentDownloadPDF:
                return "/appointment/downloadpdf"
            case .getIP:
                return "/ip"
            case .clientApplications:
                return "/client_applications/api/client_applications"
            case .userAccounts:
                return "/client_applications/api/user_logins"
            case .proxies:
                return "/vfs_bot/api/proxies"
            case .missions:
                return "/vfs_bot/api/missions" // /vfs_bot/api/missions/?countryCode=usa&missionCode=prt
            case let .telegram(botToken, method):
                return "/bot\(botToken)/\(method.rawValue)"
        }
    }

    var fullPath: String {
        return baseURL + path
    }

}

