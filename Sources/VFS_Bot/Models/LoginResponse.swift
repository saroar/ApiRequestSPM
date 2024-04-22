
import Foundation

// MARK: - LoginResponse
// {'accessToken': None, 'isAuthenticated': False, 'nearestVACCountryCode': None, 'FailedAttemptCount': 1, 'isAppointmentBooked': False, 'isLastTransactionPending': False, 'isAppointmentExpired': False, 'isLimitedDashboard': False, 'isROCompleted': False, 'isSOCompleted': False, 'roleName': None, 'isUkraineScheme': False, 'isUkraineSchemeDocumentUpload': False, 'loginUser': None, 'dialCode': None, 'contactNumber': None, 'remainingCount': 2, 'accountLockHours': 2, 'enableOTPAuthentication': False, 'isNewUser': False, 'taResetPWDToken': None, 'firstName': None, 'lastName': None, 'dateOfBirth': None, 'isPasswordExpiryMessage': False, 'PasswordExpirydays': 0, 'error': {'code': 410, 'description': 'Invalid Logins'}}
struct LoginResponse: Decodable {

    let accessToken: String?
    let isAuthenticated: Bool
    let nearestVACCountryCode: String?
    let failedAttemptCount: Int
    let isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard: Bool
    let isROCompleted, isSOCompleted: Bool
    let roleName: String?
    let isUkraineScheme, isUkraineSchemeDocumentUpload: Bool
    let loginUser, dialCode, contactNumber: String?
    let remainingCount, accountLockHours: Int
    let enableOTPAuthentication, isNewUser: Bool
    let taResetPWDToken, firstName, lastName, dateOfBirth: String?
    let isPasswordExpiryMessage: Bool
    let passwordExpirydays: Int
    let error: ErrorDetail?

    enum CodingKeys: String, CodingKey {
        case accessToken, isAuthenticated, nearestVACCountryCode
        case failedAttemptCount = "FailedAttemptCount"
        case isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard, isROCompleted, isSOCompleted, roleName, isUkraineScheme, isUkraineSchemeDocumentUpload, loginUser, dialCode, contactNumber, remainingCount, accountLockHours, enableOTPAuthentication, isNewUser, taResetPWDToken, firstName, lastName, dateOfBirth, isPasswordExpiryMessage
        case passwordExpirydays = "PasswordExpirydays"
        case error
    }

}
