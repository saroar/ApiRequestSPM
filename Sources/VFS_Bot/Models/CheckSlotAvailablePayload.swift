
import Foundation


struct CheckSlotAvailablePayload: Encodable {
    var loginUser: String
    var missioncode: String
    var countrycode: String
    var vacCode: String
    var visaCategoryCode: String
    var roleName: String = "Individual"
    var payCode: String = ""
}
