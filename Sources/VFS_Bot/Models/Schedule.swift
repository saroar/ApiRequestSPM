
import Foundation

enum PaymentMode: String, Codable {
    case VAC, Online
}

struct SchedulePayload: Codable {
    let missionCode: String
    let countryCode: String
    let centerCode: String
    let loginUser: String
    let urn: String
    var notificationType: String = "none"
    let paymentdetails: PaymentDetails
    let allocationId: String
    let CanVFSReachoutToApplicant: Bool
}

struct PaymentDetails: Codable {

    let paymentmode: PaymentMode
    var RequestRefNo: String = ""
    var clientId: String = ""
    var merchantId: String = ""
    let amount: Double
    let currency: String
    
    init(
        paymentmode: PaymentMode,
        RequestRefNo: String = "",
        clientId: String = "",
        merchantId: String = "",
        amount: Double,
        currency: String
    ) {

//        let feeAmount = feeDetailsFirst?.feeAmount ?? 0.0
//        let paymentmode: PaymentMode = feeAmount == 0.0 ? .VAC : .Online
//        let currency = feeDetailsFirst?.currency ?? ""

        self.paymentmode = paymentmode
        self.RequestRefNo = RequestRefNo
        self.clientId = clientId
        self.merchantId = merchantId
        self.amount = amount
        self.currency = currency
    }

}


// With Payment
//{
//  "missionCode": "prt",
//  "countryCode": "usa",
//  "centerCode": "POSF",
//  "loginUser": "RICHARD85HUBERXEQ@OUTLOOK.COM",
//  "urn": "XYZ56176047857",
//  "notificationType": "none",
//  "paymentdetails": {
//    "paymentmode": "Online",
//    "RequestRefNo": "",
//    "clientId": "",
//    "merchantId": "",
//    "amount": 41.15,
//    "currency": "USD"
//  },
//  "allocationId": "11447884",
//  "CanVFSReachoutToApplicant": true
//}


struct ScheduleAppointmentResponse: Decodable {
    let isAppointmentBooked: Bool
    let isPaymentRequired: Bool
    let requestRefNo: Int
    let url: String?
    let digitalSignature: String?
    let tokenExpiryDate: String?
    let appointmentDate: String
    let appointmentTime: String
    let error: ErrorDetail?
    let payLoad: String?

    enum CodingKeys: String, CodingKey {
        case isAppointmentBooked = "IsAppointmentBooked"
        case isPaymentRequired = "IsPaymentRequired"
        case requestRefNo = "RequestRefNo"
        case url = "URL"
        case digitalSignature = "DigitalSignature"
        case tokenExpiryDate = "TokenExpiryDate"
        case appointmentDate, appointmentTime, error, payLoad
    }

    var paymentLink: String {

        guard let url = url, let payLoad = self.payLoad else { return "" }

        var components = URLComponents(string: url)
        components?.queryItems = [URLQueryItem(name: "payLoad", value: payLoad)]
        return components?.url?.absoluteString ?? ""
    }

    var full_time_details: String {
        return  "\(self.appointmentDate) - \(self.appointmentTime)"
    }
}

//{
//  "IsAppointmentBooked": true,
//  "IsPaymentRequired": true,
//  "RequestRefNo": 1018081206,
//  "URL": "https://online.vfsglobal.com/PG-Component/Payment/PayRequest",
//  "DigitalSignature": "PNIoPXS9BOg2fet_oQmw6RwADfTzZBOvb2-W60KBLc_m7j1MRqGgT0yMfmwYfqXXUDSOzf7ZE_HVBbbHadpxWQ,,",
//  "TokenExpiryDate": null,
//  "appointmentDate": "27/06/2024",
//  "appointmentTime": "12:15",
//  "error": null,
//  "payLoad": "FIe6JK75n0ZY3ZbpAXwBW1PwPZnQLCs3iC0aGh4ZjnkDBMENDfueEsmGsymNzS1nxhPUiRIDULh2EhMaEXoFkBHuqOtDHSw0rl3gVypQZWgG/$vZgMEkCfNBLy5QOh92iiE0tYMtVVzPUAUhZRcywMDqkfYlDrF7g54tg4SELKMCf6YVxgKsyJV$AOZoo9tz4iRgrCjTgDhmrcSdf37df0/RYknpILoNQJoJbr9OZC2xJeeJEvdmu06q0f9JLaP8DubW07is9Vq5vNL4/yrJqm3FSX8dxDp155poL/6VBv4gA5ZDhIuFT6QP1wA7KdgrfucAS91b$5qk3wEDtnHsrnFeuzWuIssrLRsRb5aV4R7$ObdWxTUOsUZzzY4UXxYyYrLCy9jpsMy$cCxcH/zNuSo2Kj73b9aBkg8v/81AMZVo8egkP8qhAnCeVR1Nd0RtSSyjCnACiscrpM3Z5Xs$tRnnpp$6jKYvRA4osZfnpYy11XzUGPHWQa6f6OkL8uNX|5|Lh4H3dqhwfoTcUmTF2H9rg==|0j1ANJu49RbOyTHunqbd2dmf6JIF3Pr8COZWV$8iIc/Fvvca5z6xGlZdZpjmq2Z2mVx7EQ341pg1XY8xSmPYavJTHgEq7nGkYQIpMiJ$J9XMyX4UUo3Yz2NaxNucJIQSp9XoGzRKWLfpqaFFjiDeHjNOY0WuxnvUkt8OPvorZ4YHp4jb5S5qa243/kTSyqHFpcIuBc7yJDCQral9GGf1pmULqCd9nj1VXjkYSr7tOksi$hHN9r2JPG3ev$eq$MFgZl9fUfY5LlEJUx7vvNyygj3lOOSx3PMB21TmHoxP4EpRruofY9MfyQTdxpgD/cR8/wF3IbPUJRZzvlDfvLrRUJrTaVcpUbLad6nXmBGcqGplUO4cgOyAf9Iioogmtz1CyJuFtuR8y$Kpc4ePfWjCKZ0ANU47R$KsPWkAu6JfN$Ua0NgD28MU4bR/Rb1SmBVy"
//}


//{
//   "IsAppointmentBooked":true,
//   "IsPaymentRequired":false,
//   "RequestRefNo":0,
//   "URL":null,
//   "DigitalSignature":null,
//   "TokenExpiryDate":null,
//   "appointmentDate":"26/04/2024",
//   "appointmentTime":"12:30",
//   "error":null,
//   "payLoad":null
//}


//https://online.vfsglobal.com/PG-Component/Payment/PayRequest?payload=N1XVvL8vd/tVcN8K8AJwJdL7VCHtzm0iQteqxj4U6eRpebBRPPUc9mdU/UFzhH1bwdeR9xLhDYWDXL0FkOCAQYCXloSF5K4E3cD0KjT5QZCeCLTXfjM4wCEUbEAHZiMsm6swBXSKvsAU5H$Daoqh0oKTkjLhoD0/ffQUO8oi9SEmvyP/C1/Aue26QJ9mFh5m63gQB0fKlg40dLIodLqGzpVF676$miil4U9VwUU99UY6OetYFoethKGLG8s4hfevmqgu8Q$vAESqowpxJ1KM/E$irGoldcg99hFoCAh53T6jNj7OqVsc3D/57azHtaC3VjM0YpK$vC06VDjbYOOiFpneWvQtalW9sGZJA0VKzCOf9fDbzLNO8j7pm0rhWLWK4MR/T8vqrWGru6ro2VzbU51ad7yhazXL9Ai3Y44BR0F/KwACmIQ$kZvseW3Ep9nndKS1gM$5H$60gTbZC1J9T$jwbnYD59Y3te1MzEMGguQ5sMGvnb5aI2gYvLimgLfh|5|Q9iqgBW1xyEiuWBz9jo4Bw==|C/eFL2wnl0siyt28TFtobBiUxKiBNVVJxnv$ndEGmq/nq1suv0ISkJsLBpQofS1Bj3mPJxPov3oHiM1xc$ko$WI47kiU1tiM2j/5z99x$c67MZSBr02r6RQQaxFTwWjoUl5yPig1bctq8fhqFhlqhiOTAHgXUUwc05D/mA5uXrzRnguz8lAczolj2nMEYBZpazY6ijfwBY2wUdNGjR5lYwPF4YVxhmv3KnVL6r0ryij02DcBFikvK2uAFDQwbdg68hw4tjDVIVuouq$khJVsjhV6bexxhTmk7YntADcAIqCQbi0nSVq/6/6Lg6n2DO$eo6U6bdICInr6m0qGzyV4UsaWtH2WNI9e6GNuQ7$86N/VHSocXGIbsceVN$SJUbmSWdch8rSUuCW43huvb5h7NtDEH8QlgNWP71dnKClklYZ61n/gp0eURnYATmViYHuA6Yoo73CEAFSFnHvExYbRVA==

