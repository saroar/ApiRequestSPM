
import Foundation

struct ApplicantPayload: Encodable {
    var urn: String = ""
    var arn: String = ""
    var loginUser: String
    var firstName: String
    var employerFirstName: String = ""
    var middleName: String = ""
    var lastName: String
    var employerLastName: String = ""
    var salutation: String = ""
    var gender: Int
    var nationalId: String? = nil
    var visaToken: String? = nil
    var employerContactNumber: String = ""
    var contactNumber: String
    var dialCode: String
    var employerDialCode: String = ""
    var passportNumber: String
    var confirmPassportNumber: String = ""
    var passportExpirtyDate: String
    var dateOfBirth: String
    var emailId: String
    var employerEmailId: String = ""
    var nationalityCode: String
    var state: String? = nil
    var city: String? = nil
    var isEndorsedChild: Bool = false
    var applicantType: Int = 0
    var addressline1: String? = nil
    var addressline2: String? = nil
    var pincode: String? = nil
    var referenceNumber: String? = nil
    var vlnNumber: String? = nil
    var applicantGroupId: Int = 0
    var parentPassportNumber: String = ""
    var parentPassportExpiry: String = ""
    var dateOfDeparture: String? = nil
    var gwfNumber: String = ""
    var entryType: String = ""
    var eoiVisaType: String = ""
    var passportType: String = ""
    var vfsReferenceNumber: String = ""
    var familyReunificationCertificateNumber: String = ""
    var pvRequestRefNumber: String = ""
    var pvStatus: String = ""
    var pvStatusDescription: String = ""
    var pvCanAllowRetry: Bool = true
    var pvIsVerified: Bool = false
    var ipAddress: String
}

struct ApplicantListPayload: Encodable {
    var countryCode: String
    var missionCode: String
    var centerCode: String
    var loginUser: String
    var visaCategoryCode: String
    var isEdit: Bool = false
    var feeEntryTypeCode: String? = nil
    var feeExemptionTypeCode: String? = nil
    var feeExemptionDetailsCode: String? = nil
    var applicantList: [ApplicantPayload]
    var languageCode: String
    var isWaitlist: Bool = false
}


//let applicant = Applicant(
//    loginUser: "linda23hectoro2l@outlook.com",
//    firstName: "TES",
//    lastName: "TAY",
//    gender: 1,
//    contactNumber: "123312421",
//    dialCode: "1",
//    passportNumber: "123415321",
//    passportExpiryDate: "17/01/2031",
//    dateOfBirth: "17/12/2014",
//    emailId: "ami@gmail.com",
//    nationalityCode: "AIA",
//    ipAddress: "79.168.11.42"
//)
//
//let applicantJson = ApplicantJson(
//    countryCode: "usa",
//    missionCode: "prt",
//    centerCode: "PONY",
//    loginUser: "linda23hectoro2l@outlook.com",
//    visaCategoryCode: "LS",
//    applicantList: [applicant],
//    languageCode: "en-US"
//)

struct ApplicantResponse: Codable {
    let urn: String?
    let applicantList: [ApplicantListResponse]?
    let status: String?
    let error: ErrorDetail? // Use ErrorDetail here
}

struct ApplicantListResponse: Codable {
    let arn: String
    let firstName: String
    let lastName: String
    let passportNumber: String
    let isPackagePurchaseMandatory: Bool
    let isPhotoUpload: Bool
}

//Raw JSON string: {"urn":null,"applicantList":null,"status":null,"error":{"code":1009,"description":"Invalid passport expiry date."}}
