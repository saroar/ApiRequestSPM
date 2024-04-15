
import Foundation

enum APIEndpoint: String {
    static let baseURL = "https://lift-api.vfsglobal.com"

    case userLogin = "/user/login"
    case appointmentApplication = "/appointment/application"
    case checkSlotAvailability = "/appointment/CheckIsSlotAvailable"
    case appointmentApplicants = "/appointment/applicants"
    case appointmentFees = "/appointment/fees"
    case appointmentCalendar = "/appointment/calendar"
    case appointmentTimeSlot = "/appointment/timeslot"
    case mapVAS = "/vas/mapvas"
    case partnerServiceMap = "/vas/MapTMIPartnerService"
    case appointmentSchedule = "/appointment/schedule"
    case appointmentApplicantOTP = "/appointment/applicantotp"
    case appointmentDownloadPDF = "/appointment/downloadpdf"

    case getIP = "http://httpbin.org/ip"
    case clientApplications = "http://167.99.251.49:8012/client_applications/api/client_applications"
    case userAccounts = "http://167.99.251.49:8012/client_applications/api/user_logins"
    case proxies = "http://167.99.251.49:8012/vfs_bot/api/proxies"

    var fullPath: String {
        return APIEndpoint.baseURL + rawValue
    }

}

struct IPResponse: Codable {
    let origin: String
}

struct ProxyData {
    let host: String
    let port: Int
    let username: String
    let password: String

    init?(from urlString: String) {
        guard let urlComponents = URLComponents(string: urlString),
              let host = urlComponents.host,
              let port = urlComponents.port,
              let user = urlComponents.user,
              let password = urlComponents.password else {
            print("Invalid URL or missing components")
            return nil
        }

        self.host = host
        self.port = port
        self.username = user
        self.password = password
    }
}

enum SMSDetailType: Int, Decodable {
    case online = 0
    case mobile = 1
    case gsmDevice = 2
}

struct UserDTO: Decodable {
    var id: Int
    var username: String
    var email: String
    var first_name: String?
    var last_name: String?

    var full_name: String {
        return username + " \(first_name ?? "")  \(last_name ?? "")"
    }
}

struct ClientApplicationDTO: Decodable {
    let id: Int
    let user: UserDTO
    let countryCode: String
    let visaCategoryCode: String
    let missionCode: String
    let centerCode: String
    let isActive: Bool
    let isProcessing: Bool
    let isApplicationCompleted: Bool
    let firstName: String
    let lastName: String
    let gender: Int
    let nationalityCode: String
    let dialCode: String
    let contactNumber: String
    let addressline1: String?
    let passportNumber: String
    let passportExpirtyDate: Date
    let dateOfBirth: Date
    let fromDate: Date
    let toDate: Date
    let value: Int
    var emailId: String
    let ipAddress: String?
    let urn: String?
    let arn: String?
    var loginUser: String?
    let isPaid: Bool
    let missionDetailId: String?
    let referenceNumber: String?
    let middleName: String?
    let groupName: String?
    let note: String?
    let errorDescription: String?
    let bookingDate: Date?
    let createdAt: Date
    let updatedAt: Date
    let deleted_at: Date?


    var full_name: String {
        self.firstName + " " + self.lastName
    }

    var full_contact_number: String {
        self.dialCode + self.contactNumber
    }

}

public struct CAQuery: Encodable {

    public var countryCode: CountryCode
    public var missionCode: CountryCode

    public init(countryCode: CountryCode, missionCode: CountryCode) {
        self.countryCode = countryCode
        self.missionCode = missionCode
    }

}

/// appointment/CheckIsSlotAvailable'
/// Response {"earliestDate":"04/04/2024 00:00:00","earliestSlotLists":[{"applicant":"1","date":"04/04/2024 00:00:00"}],"error":null}

/// appointment/applicants
/// request "passportExpirtyDate":"17/01/2031","dateOfBirth":"17/12/2014"

/// calendar request "fromDate":"20/03/2024"
/// response "date": "05/07/2024"

/// request "slotDate":"28/03/2024"


// MARK: - UserAccount
struct UserAccountDTO: Decodable {
    let id: Int
    let userMobileNumber: UserMobileNumberDTO
    let emailText, vfsPassword, mailPassword, countryCode: String
    let missionCode: String
    let isReg, isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userMobileNumber = "user_mobile_number"
        case emailText = "email_text"
        case vfsPassword = "vfs_password"
        case mailPassword = "mail_password"
        case countryCode = "country_code"
        case missionCode = "mission_code"
        case isReg = "is_reg"
        case isActive = "is_active"
    }

    func encriptedPassword() -> String? {
        guard let password = PasswordEncrypt.getEncryptedPasswordBase64(password: self.vfsPassword)
        else {
            print("Isuuse is in password encript")
            return nil
        }

        return password
    }
}

// MARK: - UserMobileNumber
struct UserMobileNumberDTO: Decodable {
    let id, dialCode: Int
    let mobileNumber: String
    let type: SMSDetailType
    let token: String
    let description: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case dialCode = "dial_code"
        case mobileNumber = "mobile_number"
        case type, token, description
        case createdAt = "created_at"
    }
}


struct ProxyDTO: Decodable {
    let countryCode: String
    let missionCode: String
    let proxyList: [String]

    enum CodingKeys: String, CodingKey {
        case countryCode = "country_code"
        case missionCode = "mission_code"
        case proxyList = "proxy_list"
    }
}
