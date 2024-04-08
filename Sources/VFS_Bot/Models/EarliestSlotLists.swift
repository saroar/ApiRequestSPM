
import Foundation

// Two Type Response
// {"earliestDate":"04/04/2024 00:00:00","earliestSlotLists":[{"applicant":"1","date":"04/04/2024 00:00:00"}],"error":null}
// {"earliestDate": null, "earliestSlotLists": [], "error": { "code": 1035, "description": "No slots available"}}

struct EarliestDateSlotsResponse: Decodable {
    let earliestDate: Date?
    let earliestSlotLists: [EarliestDateSlotApplicant]
    let error: ErrorDetail?
}

struct EarliestDateSlotApplicant: Decodable {
    let applicant: String
    let date: Date?
}
