
import Foundation

struct Application: Encodable {
    let countryCode: String
    let missionCode: String
    let loginUser: String
    let languageCode: String
}

struct ApplicationDataResponse: Decodable {
    let data: Datum?
    let error: ErrorDetail?
}


// Response
struct Datum: Decodable {
    let urn, visaCategoryCode, parentVisaCategoryCode, loginUser: String
    let missionCode, countryCode, isEdit, vacCode: String
    let isPaymentDone, transactionID: String?
    let isDocumentAvailable, isShippingLabelAvailable: Bool
    let visaType, applicationType: String?
    let isCompleted, isPrepaidCourier, isWaitlist: Bool
    let waitlistStatus: String?
    let isWaitlistUpdate, isPayAtBankSelected, isRescheduleDisable, isCancellationDisable: Bool
    let payAtBankStatus: String
    let applicants: [Applicant]
    let assignedServiceCenter, startDate, endDate, firstCountryOfEntry: String?
    let coverageType, coverageLevel, isRequiredExtraSports: String?
    let isSlotAvailableForReschedule, isBookedByCC: Bool
    let paymentStatus: String
    let anyGRNumber: String?

    enum CodingKeys: String, CodingKey {
        case urn, visaCategoryCode, parentVisaCategoryCode, loginUser, missionCode, countryCode, isEdit, vacCode, isPaymentDone, transactionID, isDocumentAvailable, isShippingLabelAvailable, visaType, applicationType, isCompleted, isPrepaidCourier, isWaitlist, waitlistStatus, isWaitlistUpdate, isPayAtBankSelected, isRescheduleDisable, isCancellationDisable
        case payAtBankStatus = "PayAtBankStatus"
        case applicants, assignedServiceCenter, startDate, endDate, firstCountryOfEntry, coverageType, coverageLevel, isRequiredExtraSports, isSlotAvailableForReschedule
        case isBookedByCC = "IsBookedByCC"
        case paymentStatus = "PaymentStatus"
        case anyGRNumber
    }
}

// MARK: - Applicant
struct Applicant: Decodable {
    let lastName: String
    let applicantGroupID, gender: Int
    let dialCode: String
    let cityCode: Int
    let vas, fees: String?
    let emailID: String
    let appointment: Appointment
    let parentPassportExpiry, nationalityCode: String
    let applicantType: Int
    let parentPassportNumber, contactNumber, passportNumber, arn: String
    let pincode: String?
    let dateOfBirth, firstName, isEndorsedChild, referenceNumber: String
    let addressline2, addressline1: String
    let stateCode, salutation: Int
    let dateOfDeparture: String
    let middleName, entryType, eoiVisaType, state: String?
    let city: String?
    let isAppointmentCancellationEnable, isVASCancellationEnable: Bool
    let passportExpirtyDate: String

    enum CodingKeys: String, CodingKey {
        case lastName
        case applicantGroupID = "applicantGroupId"
        case gender, dialCode, cityCode, vas, fees
        case emailID = "emailId"
        case appointment, parentPassportExpiry, nationalityCode, applicantType, parentPassportNumber, contactNumber, passportNumber, arn, pincode, dateOfBirth, firstName, isEndorsedChild, referenceNumber, addressline2, addressline1, stateCode, salutation, dateOfDeparture, middleName, entryType, eoiVisaType, state, city
        case isAppointmentCancellationEnable = "IsAppointmentCancellationEnable"
        case isVASCancellationEnable = "IsVASCancellationEnable"
        case passportExpirtyDate
    }
}

// MARK: - Appointment
struct Appointment: Decodable {
    let appointmentTime: String
    let allocationID: Int
    let appoinmentDate, slotType, categoryCode: String
    let visaGroup: String?
    let isCancellationRefundNotApplicable: Bool
    let cancellationWithRefundAfterHours: Int

    enum CodingKeys: String, CodingKey {
        case appointmentTime
        case allocationID = "allocationId"
        case appoinmentDate, slotType, categoryCode, visaGroup, isCancellationRefundNotApplicable, cancellationWithRefundAfterHours
    }
}

//Response empty
//{
//  "data": null,
//  "error": {
//    "code": 1041,
//    "description": "No Applicant exists"
//  }
//}

// WITH Response
//{
//  "data": [
//    {
//      "urn": "XYZ56212433450",
//      "visaCategoryCode": "LS",
//      "parentVisaCategoryCode": "PVAC",
//      "loginUser": "stephen46hickmanvum@outlook.com",
//      "missionCode": "prt",
//      "countryCode": "usa",
//      "isEdit": "0",
//      "vacCode": "POWD",
//      "isPaymentDone": null,
//      "transactionID": null,
//      "isDocumentAvailable": false,
//      "isShippingLabelAvailable": false,
//      "visaType": null,
//      "applicationType": null,
//      "isCompleted": false,
//      "isPrepaidCourier": false,
//      "isWaitlist": false,
//      "waitlistStatus": null,
//      "isWaitlistUpdate": false,
//      "isPayAtBankSelected": false,
//      "isRescheduleDisable": false,
//      "isCancellationDisable": false,
//      "PayAtBankStatus": "Confirmed",
//      "applicants": [
//        {
//          "lastName": "BARAD",
//          "applicantGroupId": 56662971,
//          "gender": 1,
//          "dialCode": "1",
//          "cityCode": 0,
//          "vas": null,
//          "fees": null,
//          "emailId": "stephen46hickmanvum@outlook.com",
//          "appointment": {
//            "appointmentTime": "9:00-9:20",
//            "allocationId": 11656859,
//            "appoinmentDate": "17/06/2024",
//            "slotType": "0",
//            "categoryCode": "VAC SLOTS",
//            "visaGroup": null,
//            "isCancellationRefundNotApplicable": false,
//            "cancellationWithRefundAfterHours": 0
//          },
//          "parentPassportExpiry": "",
//          "nationalityCode": "USA",
//          "applicantType": 0,
//          "parentPassportNumber": "",
//          "contactNumber": "2245779552",
//          "passportNumber": "584400579",
//          "arn": "XYZ56212433450/1",
//          "pincode": null,
//          "dateOfBirth": "04/10/1961",
//          "firstName": "LEONID",
//          "isEndorsedChild": "false",
//          "referenceNumber": "",
//          "addressline2": "",
//          "addressline1": "460 Maple drive wheeling wheeling Illinois 60090",
//          "stateCode": 0,
//          "salutation": 0,
//          "dateOfDeparture": "",
//          "middleName": null,
//          "entryType": null,
//          "eoiVisaType": null,
//          "state": null,
//          "city": null,
//          "IsAppointmentCancellationEnable": true,
//          "IsVASCancellationEnable": false,
//          "passportExpirtyDate": "16/07/2028"
//        }
//      ],
//      "assignedServiceCenter": null,
//      "startDate": null,
//      "endDate": null,
//      "firstCountryOfEntry": null,
//      "coverageType": null,
//      "coverageLevel": null,
//      "isRequiredExtraSports": null,
//      "isSlotAvailableForReschedule": true,
//      "IsBookedByCC": false,
//      "PaymentStatus": "Cash",
//      "anyGRNumber": null
//    }
//  ],
//  "error": null
//}
