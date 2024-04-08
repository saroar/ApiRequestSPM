
import Foundation

struct TimeslotsPayload: Encodable {
    let missionCode: String
    let countryCode: String
    let centerCode: String
    let loginUser: String
    let visaCategoryCode: String
    let slotDate: String
    let urn: String
}


// MARK: - TimeslotsResponse
struct TimeslotsResponse: Decodable {
    let mission, center, visacategory: String
    let date: Date
    let slots: [Slot]
    let error: ErrorDetail?
}

// MARK: - Slot
struct Slot: Decodable {
    let visaGroupName: String
    let allocationId: Int
    let slot, type, allocationCategory, categoryCode: String
}

//{
//  "mission": "Portugal",
//  "center": "VFS Global for Portugal - San Francisco",
//  "visacategory": "NVD",
//  "date": "06/27/2024",
//  "slots": [
//    {
//      "visaGroupName": "SFO- Visa application center",
//      "allocationId": 11447885,
//      "slot": "12:30-13:00",
//      "type": "Normal",
//      "allocationCategory": "Portugal Visa Application - SFO",
//      "categoryCode": "VAC"
//    },
//    {
//      "visaGroupName": "SFO- Visa application center",
//      "allocationId": 11447883,
//      "slot": "12:00-12:30",
//      "type": "Normal",
//      "allocationCategory": "Portugal Visa Application - SFO",
//      "categoryCode": "VAC"
//    },
//    {
//      "visaGroupName": "SFO- Visa application center",
//      "allocationId": 11447882,
//      "slot": "11:40-12:00",
//      "type": "Normal",
//      "allocationCategory": "Portugal Visa Application - SFO",
//      "categoryCode": "VAC"
//    },
//    {
//      "visaGroupName": "SFO- Visa application center",
//      "allocationId": 11447884,
//      "slot": "12:15-12:30",
//      "type": "Normal",
//      "allocationCategory": "Portugal Visa Application - SFO",
//      "categoryCode": "VAC"
//    },
//    {
//      "visaGroupName": "SFO- Visa application center",
//      "allocationId": 11447877,
//      "slot": "9:00-9:30",
//      "type": "Normal",
//      "allocationCategory": "Portugal Visa Application - SFO",
//      "categoryCode": "VAC"
//    }
//  ],
//  "error": null
//}
