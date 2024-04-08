
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

enum SMSDetailType: Int {
    case online = 0
    case mobile = 1
    case gsmDevice = 2
}

struct UserMobileNumberDTO {
    let dialCode: String
    let mobileNumber: String
    let type: SMSDetailType
    let token: UUID
    let description: String?
}

struct UserLoginDTO {
    let userMobileNumber: UserMobileNumberDTO?
    let emailText: String
    let vfsPassword: String
    let mailPassword: String
    let countryCode: String
    let missionCode: String
    let isReg: Bool
    let isActive: Bool

    init(userMobileNumber: UserMobileNumberDTO? = nil,
         emailText: String,
         vfsPassword: String,
         mailPassword: String = "",
         countryCode: String = "",
         missionCode: String = "",
         isReg: Bool = false,
         isActive: Bool = false) {
        self.userMobileNumber = userMobileNumber
        self.emailText = emailText
        self.vfsPassword = vfsPassword
        self.mailPassword = mailPassword
        self.countryCode = countryCode
        self.missionCode = missionCode
        self.isReg = isReg
        self.isActive = isActive
    }

    func encriptedPassword() -> String? {
        guard let password = PasswordEncript.getEncryptedPasswordBase64(password: self.vfsPassword)
        else {
            print("Isuuse is in password encript")
            return nil
        }

        return password
    }
}

struct ClientApplicationDTO {
    let id: Int
    let userid: Int
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
    let dialCode: Int
    let contactNumber: String
    let addressline1: String?
    let passportNumber: String
    let passportExpiryDate: Date
    let dateOfBirth: Date
    let fromDate: Date
    let toDate: Date
    let value: Int
    var emailId: String
    let createdAt: Date
    let updatedAt: Date
    let ipAddress: String?
    let urn: String?
    let arn: String?
    var loginUser: String?
    let isPaid: Bool
    let missionDetailId: String?
    let deletedAt: Date?
    let referenceNumber: String?
    let middleName: String?
    let groupName: String?
    let note: String?
    let errorDescription: String?
    let bookingDate: Date?


    var full_name: String {
        self.firstName + " " + self.lastName
    }

    var full_contact_number: String {
        "\(self.dialCode)" + self.contactNumber
    }

}


/// appointment/CheckIsSlotAvailable'
/// Response {"earliestDate":"04/04/2024 00:00:00","earliestSlotLists":[{"applicant":"1","date":"04/04/2024 00:00:00"}],"error":null}

/// appointment/applicants
/// request "passportExpirtyDate":"17/01/2031","dateOfBirth":"17/12/2014"

/// calendar request "fromDate":"20/03/2024"
/// response "date": "05/07/2024"

/// request "slotDate":"28/03/2024"


