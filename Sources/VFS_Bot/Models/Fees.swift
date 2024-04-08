
import Foundation

struct FeesPayload: Encodable {
    let missionCode: String
    let countryCode: String
    let centerCode: String
    let loginUser: String
    let urn: String
    var languageCode: String = "en-US"
}

// MARK: - FeesResponse
struct FeesResponse: Decodable {
    let mission, country, center: String
    var totalamount: Double = 0
    var totalSGSTCollected = 0
    var totalCGSTCollected = 0
    var totalIGSTCollected = 0
    var totalCalamityCessCollected = 0
    var feeDetails: [FeeDetail]? = nil
    var servicesFee: String? = nil
    var additionalFee: String? = nil
    var error: ErrorDetail? = nil
}

// MARK: - FeeDetail
struct FeeDetail: Decodable {
    let feeId, feeTypeId: Int
    let feeName, feeTypeCode: String
    let feeAmount: Double
    let discountAmount: Int
    let currency: String
    var FeeTax: [TaxDetail]
}

struct TaxDetail: Codable {
    var feeId: Int
    var taxId: Int
    var efffectiveDate: String
    var taxPercent: Int
    var taxAmount: Double
    var taxName: String
}

//{"mission":"prt","country":"usa","center":"POSF","totalamount":41.15,"totalSGSTCollected":0,"totalCGSTCollected":0,"totalIGSTCollected":0,"totalCalamityCessCollected":0,"feeDetails":[{"feeId":1942551,"feeTypeId":1,"feeName":"VFS Service Charge","feeTypeCode":"VFSFEE","feeAmount":41.15,"discountAmount":0,"currency":"USD","FeeTax":[]}],"servicesFee":null,"additionalFee":null,"error":null}
//
//Decode error: keyNotFound(CodingKeys(stringValue: "feeTax", intValue: nil), Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "feeDetails", intValue: nil), _JSONKey(stringValue: "Index 0", intValue: 0)], debugDescription: "No value associated with key CodingKeys(stringValue: \"feeTax\", intValue: nil) (\"feeTax\").", underlyingError: nil))

// With Payment
//{
//  "mission": "prt",
//  "country": "usa",
//  "center": "POSF",
//  "totalamount": 41.15,
//  "totalSGSTCollected": 0,
//  "totalCGSTCollected": 0,
//  "totalIGSTCollected": 0,
//  "totalCalamityCessCollected": 0,
//  "feeDetails": [
//    {
//      "feeId": 1942552,
//      "feeTypeId": 1,
//      "feeName": "VFS Service Charge",
//      "feeTypeCode": "VFSFEE",
//      "feeAmount": 41.15,
//      "discountAmount": 0,
//      "currency": "USD",
//      "FeeTax": []
//    }
//  ],
//  "servicesFee": null,
//  "additionalFee": null,
//  "error": null
//}


// Cant be empty
//{
//   "mission":"prt",
//   "country":"usa",
//   "center":"PONY",
//   "totalamount":0,
//   "totalSGSTCollected":0,
//   "totalCGSTCollected":0,
//   "totalIGSTCollected":0,
//   "totalCalamityCessCollected":0,
//   "feeDetails":null,
//   "servicesFee":null,
//   "additionalFee":null,
//   "error":null
//}
