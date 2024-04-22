
import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient
import Logging


struct VisaApplicationManagerClient {

    enum VAMCError: Error {
        case shutdown, missionToken, oneOfVarIsEmpty, decodeError, outOfTheRange
    }

    var loginRequest: @Sendable () async throws -> LoginResponse?
    var applicationRequest: @Sendable (String) async throws -> ApplicationDataResponse
    var checkSlotsAvilableWithLoop: @Sendable (String) async throws -> EarliestDateSlotsResponse? // TOEKN
    var applicantRequest: @Sendable (String, Date) async throws -> ApplicantResponse? // TOKEN
    var feesRequest: @Sendable (String, String) async throws -> FeesResponse? // TOKEN URN
    var calendarRequest: @Sendable (String, String, Date) async throws -> CalendarResponse? // TOKEN URN FROM_DATE
    var timeSlotsRequest: @Sendable (String, String, Date) async throws -> TimeslotsResponse? // TOKEN URN SLOT_DATE
    var scheduleRequest: @Sendable (String, String, Int, PaymentDetails) async throws -> ScheduleAppointmentResponse? // TOKEN, URN, AllocationId
    var downloadPDFRequest: @Sendable (String, String) async throws -> Data?

    private init(
        loginRequest: @escaping @Sendable () async throws -> LoginResponse?,
        applicationRequest: @escaping @Sendable (String) async throws -> ApplicationDataResponse,
        checkSlotsAvilableWithLoop: @escaping @Sendable (String) async throws -> EarliestDateSlotsResponse?,
        applicantRequest: @escaping @Sendable (String, Date) async throws -> ApplicantResponse?,
        feesRequest: @escaping @Sendable (String, String) async throws -> FeesResponse?,
        calendarRequest: @escaping @Sendable (String, String, Date) async throws -> CalendarResponse?,
        timeSlotsRequest: @escaping @Sendable (String, String, Date) async throws -> TimeslotsResponse?,
        scheduleRequest: @escaping @Sendable (String, String, Int, PaymentDetails) async throws -> ScheduleAppointmentResponse?,
        downloadPDFRequest: @escaping @Sendable (String, String) async throws -> Data
    ) {
        self.loginRequest = loginRequest
        self.applicationRequest = applicationRequest
        self.checkSlotsAvilableWithLoop = checkSlotsAvilableWithLoop
        self.applicantRequest = applicantRequest
        self.feesRequest = feesRequest
        self.calendarRequest = calendarRequest
        self.timeSlotsRequest = timeSlotsRequest
        self.scheduleRequest = scheduleRequest
        self.downloadPDFRequest = downloadPDFRequest
    }

}

extension VisaApplicationManagerClient {
    public static func live(
        route: String,
        proxy: String,
        networkService: NetworkService,
        languageCode: String = "en-US",
        user_login_dto: UserAccountDTO,
        client_application_dto: ClientApplicationDTO,
        nanoseconds: UInt64,
        captcha_api_key: String,
        ipAddress: String
    ) -> Self {

        let logger = Logger(label: "com.visaApplicationManagerClient.main")

        let applicantPlayload = ApplicantPayload(
            loginUser: user_login_dto.emailText,
            firstName: client_application_dto.firstName,
            lastName: client_application_dto.lastName,
            gender: client_application_dto.gender,
            contactNumber: client_application_dto.contactNumber,
            dialCode: "\(client_application_dto.dialCode)",
            passportNumber: client_application_dto.passportNumber,
            passportExpirtyDate: client_application_dto.passportExpirtyDate.toFormattedString(),
            dateOfBirth: client_application_dto.dateOfBirth.toFormattedString(),
            emailId: user_login_dto.emailText,
            nationalityCode: client_application_dto.nationalityCode,

            addressline1: client_application_dto.countryCode.lowercased() == CountryCode.USA.rawValue.lowercased()
            ? client_application_dto.addressline1
            : nil,

            referenceNumber: client_application_dto.countryCode.lowercased() == CountryCode.UZBEKISTAN.rawValue.lowercased()
            ? client_application_dto.referenceNumber
            : nil,

            ipAddress: ipAddress
        )

        let loginPayload = LoginPayload(
            username: user_login_dto.emailText,
            password: user_login_dto.vfsPassword,
            missioncode: client_application_dto.missionCode,
            countrycode: client_application_dto.countryCode,
            captcha_api_key: captcha_api_key
        )

        var applicationPayload: Application {
            .init(
                countryCode: user_login_dto.countryCode,
                missionCode: user_login_dto.missionCode,
                loginUser: user_login_dto.emailText,
                languageCode: languageCode
            )
        }

        @Sendable 
        func checkSlotAvailableRequest(_ accessToken: String) async throws -> EarliestDateSlotsResponse? {

            let check_slot_available_payload = CheckSlotAvailablePayload(
                loginUser: user_login_dto.emailText,
                missioncode: client_application_dto.missionCode,
                countrycode: client_application_dto.countryCode,
                vacCode: client_application_dto.centerCode,
                visaCategoryCode: client_application_dto.visaCategoryCode
            )

            let additionalHeaders = [
                (HTTPHeaderField.route, route),
                (HTTPHeaderField.authorize, accessToken),
                (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
                (HTTPHeaderField.secGpc, HTTPHeaderField.secGpc.value)
            ]

            let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
            let requestJSONBodyToByteBuffer = try check_slot_available_payload.toByteBuffer()

            let response: EarliestDateSlotsResponse = try await networkService
                .request(
                    endpoint: .checkSlotAvailability,
                    method: .POST,
                    headers: headers,
                    body: requestJSONBodyToByteBuffer
                )

            return response

        }

        return Self(

            loginRequest: {
                logger.info("\(#function.capitalized) Start...")

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.contentType, "application/x-www-form-urlencoded"),
                    (HTTPHeaderField.acceptEncoding, "gzip, deflate")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)

                guard let requestBodyString = loginPayload.toURLEncodedFormData(),
                      let bodyData = requestBodyString.data(using: .utf8)
                else {
                    throw VAMCError.decodeError
                }

                let response: LoginResponse = try await networkService.request(
                    endpoint: .userLogin,
                    method: .POST,
                    headers: headers,
                    body: .init(data: bodyData)
                )

                return response
            },

            applicationRequest: { accessToken in

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBody = try applicationPayload.toByteBuffer()

                let response: ApplicationDataResponse = try await networkService
                    .request(
                        endpoint: .appointmentApplication,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBody
                    )

                return response

            },

            checkSlotsAvilableWithLoop: { accessToken in

                guard let response = try await checkSlotAvailableRequest(accessToken) else {
                    throw VAMCError.oneOfVarIsEmpty
                }

                var count = 0

                while response.error != nil {
                    try await Task.sleep(nanoseconds: nanoseconds)
                    _ = try await checkSlotAvailableRequest(accessToken)
                    count += 1
                    let seconds = Double(nanoseconds) / 1_000_000_000.0
                    logger.info("Retry in \(String(format: "%.2f", seconds)) seconds, count: \(count)")

                }

                return response
            },

            applicantRequest: { accessToken, earliestDate in


        //        if earliestDate > self.client_application_dto.toDate {
        //            logger.warning("Out of the range earliestDate: \(earliestDate) todate: \(self.client_application_dto.toDate)")
        //            throw VAMCError.outOfTheRange
        //        }

                let applicantJson = ApplicantListPayload(
                    countryCode: user_login_dto.countryCode,
                    missionCode: user_login_dto.missionCode,
                    centerCode: client_application_dto.centerCode,
                    loginUser: user_login_dto.emailText,
                    visaCategoryCode: client_application_dto.visaCategoryCode,
                    applicantList: [applicantPlayload],
                    languageCode: languageCode
                )

                //logger.info(applicantJson.toJSONString())

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try applicantJson.toByteBuffer()

                let response: ApplicantResponse = try await networkService
                    .request(
                        endpoint: .appointmentApplicants,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

                if response.error != nil {
                    logger.info("Applicants Res: \(response.toJSONString())")
                }

                return response
            },

            feesRequest: { accessToken, urn in

                let feesJson = FeesPayload(
                    missionCode: client_application_dto.missionCode,
                    countryCode: client_application_dto.countryCode,
                    centerCode: client_application_dto.centerCode,
                    loginUser: user_login_dto.emailText,
                    urn: urn
                )

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try feesJson.toByteBuffer()

                let response: FeesResponse = try await networkService
                    .request(
                        endpoint: .appointmentFees,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

                return response
            },

            calendarRequest: { accessToken, urn, fromDate in

                let calendarJson = CalendarPayload(
                    missionCode: client_application_dto.missionCode,
                    countryCode: client_application_dto.countryCode,
                    centerCode: client_application_dto.centerCode,
                    loginUser: user_login_dto.emailText,
                    visaCategoryCode: client_application_dto.visaCategoryCode,
                    fromDate: fromDate.toFormattedString(),
                    urn: urn
                )

                //logger.info("\(calendarJson.toJSONString())")

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
                    (HTTPHeaderField.acceptEncoding, "identity")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try calendarJson.toByteBuffer()

                let response: CalendarResponse = try await networkService
                    .request(
                        endpoint: .appointmentCalendar,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

        //        logger.info("Response with Calendar:  \(dump(response))")

                return response
            },

            timeSlotsRequest: { accessToken, urn, slotDate in

                let slotDateFormattedString = slotDate.toFormattedString()

                let timeslotJson = TimeslotsPayload(
                    missionCode: client_application_dto.missionCode,
                    countryCode: client_application_dto.countryCode,
                    centerCode: client_application_dto.centerCode,
                    loginUser: user_login_dto.emailText,
                    visaCategoryCode: client_application_dto.visaCategoryCode,
                    slotDate: slotDateFormattedString, // we are taking last slots from list of calendar
                    urn: urn
                )

                //logger.info("\(timeslotJson.toJSONString())")

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try timeslotJson.toByteBuffer()

                let response: TimeslotsResponse = try await networkService
                    .request(
                        endpoint: .appointmentTimeSlot,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

                return response
            },

            scheduleRequest: { accessToken, urn, allocationId, paymentdetails in

                let schedulePayload = SchedulePayload(
                    missionCode: client_application_dto.missionCode,
                    countryCode: client_application_dto.countryCode,
                    centerCode: client_application_dto.centerCode,
                    loginUser: user_login_dto.emailText,
                    urn: urn,
                    paymentdetails: paymentdetails,
                    allocationId: "\(allocationId)",
                    CanVFSReachoutToApplicant: true
                )

                // logger.info(schedulePayload.toJSONString())

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try schedulePayload.toByteBuffer()

                let response: ScheduleAppointmentResponse = try await networkService
                    .request(
                        endpoint: .appointmentSchedule,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

                return response
            }, 

            downloadPDFRequest: { accessToken, urn in

                let schedulePayload = PDFDownloadJSON(
                    countryCode: client_application_dto.countryCode,
                    missionCode: client_application_dto.missionCode,
                    loginUser: user_login_dto.emailText,
                    urn: urn
                )

                 logger.info("\(schedulePayload.toJSONString())")

                let additionalHeaders = [
                    (HTTPHeaderField.route, route),
                    (HTTPHeaderField.authorize, accessToken),
                    (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
                ]

                let headers = HTTPHeaderField.applyVFSHeaders(withOptionalHeaders: additionalHeaders)
                let requestJSONBodyToByteBuffer = try schedulePayload.toByteBuffer()

                let response: Data = try await networkService
                    .request(
                        endpoint: .appointmentDownloadPDF,
                        method: .POST,
                        headers: headers,
                        body: requestJSONBodyToByteBuffer
                    )

                return response
            }
        )
    }

}
