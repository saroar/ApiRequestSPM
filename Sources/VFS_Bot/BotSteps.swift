import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient
import Logging


var logger = Logger(label: "com.quickprocess.main")


struct BotSteps {

    enum BSError: Error {
        case shutdown, oneOfVarIsEmpty, decodeError, outOfTheRange
    }

    var proxy: String
    var language_code = "en-US"

    let user_login_dto: UserAccountDTO
    var client_application_dto: ClientApplicationDTO
    var applicantPlayload: ApplicantPayload
    var loginPayload: LoginPayload

    init(
        proxy: String,
        language_code: String = "en-US",
        user_login_dto: UserAccountDTO,
        client_application_dto: ClientApplicationDTO,
        networkService: NetworkService
    ) {

        self.proxy = proxy
        self.language_code = language_code

        self.user_login_dto = user_login_dto
        self.client_application_dto = client_application_dto
        self.networkService = networkService

        self.applicantPlayload = .init(
            loginUser: self.user_login_dto.emailText,
            firstName: self.client_application_dto.firstName,
            lastName: self.client_application_dto.lastName,
            gender: self.client_application_dto.gender,
            contactNumber: self.client_application_dto.contactNumber,
            dialCode: "\(self.client_application_dto.dialCode)",
            passportNumber: self.client_application_dto.passportNumber,
            passportExpirtyDate: self.client_application_dto.passportExpirtyDate.toFormattedString(),
            dateOfBirth: self.client_application_dto.dateOfBirth.toFormattedString(),
            emailId: self.user_login_dto.emailText,
            nationalityCode: self.client_application_dto.nationalityCode,
            addressline1: " 3726 Woodridge Lane, Memphis, Tennessee",
            ipAddress: ""
        )

        self.loginPayload = LoginPayload(
            username: self.user_login_dto.emailText,
            password: self.user_login_dto.vfsPassword,
            missioncode: self.client_application_dto.missionCode,
            countrycode: self.client_application_dto.countryCode,
            captcha_api_key: ""
        )

        logger.logLevel = .debug
    }

    var route: String {
        return "\(self.client_application_dto.countryCode)/en/\(self.client_application_dto.missionCode)"
    }

    var pageurl: String {
        "https://visa.vfsglobal.com/\(self.route)/login"
    }

    var cf_solution: LoginCFSolution { .init(url: self.pageurl, proxy: self.proxy) }

    var applicationPayload: Application {
        .init(
            countryCode: self.user_login_dto.countryCode,
            missionCode: self.user_login_dto.missionCode,
            loginUser: self.user_login_dto.emailText,
            languageCode: self.language_code
        )
    }

    var access_token: String {
        self.loginResponse?.accessToken ?? ""
    }

    var ip_address: String {
        self.ipResponse?.origin ?? "127.0.0.1"
    }

    var fromDate: Date? {
        guard
            let earliestDateSlotsR = self.earliestDateSlotsResponse,
            let earliestDate = earliestDateSlotsR.earliestDate
        else {
            return nil
        }

        let earliestDateCalculateStartDate = earliestDate.calculateStartDate()

        logger.info("earliestDate: \(earliestDate), fromDate: \(earliestDateCalculateStartDate)")
        return earliestDateCalculateStartDate
    }

    var urn: String? {
        guard
            let applicantResponse = self.applicantResponse,
            let urn = applicantResponse.urn else {
            logger.info("URN missing from applicantResponse!")
            return nil
        }

        return urn
    }

    private var networkService: NetworkService

    // MARK: All Response
    var loginResponse: LoginResponse? = nil
    var ipResponse: IPResponse? = nil
    var applicantResponse: ApplicantResponse? = nil
    var earliestDateSlotsResponse: EarliestDateSlotsResponse? = nil
    var feesResponse: FeesResponse? = nil
    var calendarResponse: CalendarResponse? = nil
    var timeslotsResponse: TimeslotsResponse? = nil
    var scheduleAppointmentResponse: ScheduleAppointmentResponse? = nil

    func appointmentFullDetails(scriptTime: String) -> String {

        guard let center = self.timeslotsResponse?.center,
              let visacategory = self.timeslotsResponse?.visacategory,
              let full_time_details = self.scheduleAppointmentResponse?.full_time_details,
              let requestRefNo = self.scheduleAppointmentResponse?.requestRefNo

        else {
            logger.error("\(#function) some of data is missing")
            return ""
        }

        let appointmentFullDetails = """
            \n
            FirstName: \(self.client_application_dto.firstName)
            Lastname: \(self.client_application_dto.lastName)
            Visa Category Code: \(self.client_application_dto.visaCategoryCode)
            Country&City: \(center)
            Visa Category: \(visacategory)
            Email: \(self.user_login_dto.emailText)
            EPassword: \(self.user_login_dto.mailPassword)
            Vfs Password: \(self.user_login_dto.vfsPassword)
            User Mobile Number: \(self.client_application_dto.full_contact_number)
            Booking was successful: \(full_time_details)
            Reference number: \(requestRefNo)
            Agent Name: {agent_name}
            Script took: \(scriptTime)
        """

        return appointmentFullDetails

    }

    func currentTime() -> String {

        let formatter = DateFormatter()
        // Keep 'Z' in the format string, but understand it's purely literal here, not indicating UTC.
        formatter.dateFormat = "GA;yyyy-MM-dd'T'HH:mm:ss'Z'"
        // Omit setting the formatter's timeZone to use the device's local time zone.
        let currentDate = Date()
        let currentTime = formatter.string(from: currentDate)
        return currentTime
    }

    func getProxyIp() async throws -> IPResponse {
        do {
            let ipRes: IPResponse = try await self.networkService.getIPRequest(from: APIEndpoint.getIP.rawValue)
            return ipRes
        } catch {
            logger.error("\(#function) An error occurred: \(error)")

//            self.applicantPlayload.ipAddress = "98.167.101.137"
            return IPResponse(origin: "98.167.101.137")
        }
    }


    func loginRequest() async throws -> LoginResponse? {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.contentType, "application/x-www-form-urlencoded"),
            (HTTPHeaderField.acceptEncoding, "gzip, deflate")
        ]

        let response: LoginResponse = try await networkService.postWithBodyStringRequest(
            to: .userLogin,
            payload: loginPayload,
            additionalHeaders: additionalHeaders
        )

        return response
    }

    func applicationRequest() async throws -> ApplicationDataResponse {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
        ]

        let response: ApplicationDataResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentApplication,
            payload: applicationPayload,
            additionalHeaders: additionalHeaders
        )

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("Applicants Rtime: \(elapsedTime) sec")

        return response

    }

    private func checkSlotAvailableRequest() async throws -> EarliestDateSlotsResponse? {
        logger.info("\(#function.capitalized) Start...")

        let check_slot_available_payload = CheckSlotAvailablePayload(
            loginUser: self.user_login_dto.emailText,
            missioncode: self.client_application_dto.missionCode,
            countrycode: self.client_application_dto.countryCode,
            vacCode: self.client_application_dto.centerCode,
            visaCategoryCode: self.client_application_dto.visaCategoryCode
        )

        // Start measuring time
        let startTime = Date()

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
            (HTTPHeaderField.secGpc, HTTPHeaderField.secGpc.value)
        ]

        let response: EarliestDateSlotsResponse = try await networkService.postWithJSONBodyRequest(
            to: .checkSlotAvailability,
            payload: check_slot_available_payload,
            additionalHeaders: additionalHeaders
        )

        // Custom date formatter
//        let dateFormatter = DateFormatter.sharedDateMDYHMSFormatter
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .formatted(dateFormatter)

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("CheckSlots Rtime: \(elapsedTime) sec")
        return response

    }

    func checkSlotsAvilableWithLoop() async throws -> EarliestDateSlotsResponse? {
        let response = try await self.checkSlotAvailableRequest()
        var count = 0

        while self.earliestDateSlotsResponse?.earliestDate == nil {
            let seconds = 2
            try await Task.sleep(nanoseconds: 500_00)
            _ = try await self.checkSlotAvailableRequest()
            count += 1
            logger.info("Retry in \(seconds) count: \(count)")
        }

        return response

    }

    func applicantRequest() async throws -> ApplicantResponse? {
        logger.info("\(#function.capitalized) Start...")

        guard
            let earliestDate = self.earliestDateSlotsResponse?.earliestDate
        else {
            throw BSError.oneOfVarIsEmpty
        }


//        if earliestDate > self.client_application_dto.toDate {
//            logger.warning("Out of the range earliestDate: \(earliestDate) todate: \(self.client_application_dto.toDate)")
//            throw BSError.outOfTheRange
//        }

        // Start measuring time
        let startTime = Date()

        let applicantJson = ApplicantListPayload(
            countryCode: self.user_login_dto.countryCode,
            missionCode: self.user_login_dto.missionCode,
            centerCode: self.client_application_dto.centerCode,
            loginUser: self.user_login_dto.emailText,
            visaCategoryCode: self.client_application_dto.visaCategoryCode,
            applicantList: [self.applicantPlayload],
            languageCode: "en-US"
        )

        //        logger.info(applicantJson.toJSONString())

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response: ApplicantResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentApplicants,
            payload: applicantJson,
            additionalHeaders: additionalHeaders
        )

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("Applicants Rtime: \(elapsedTime) sec")

        return response

    }

    func feesRequest() async throws -> FeesResponse? {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        guard
            let applicantResponse = self.applicantResponse,
            let urn = applicantResponse.urn else {
            logger.info("feesRequest missing urn or applicantResponse")
            throw BSError.oneOfVarIsEmpty
        }

        let feesJson = FeesPayload(
            missionCode: self.client_application_dto.missionCode,
            countryCode: self.client_application_dto.countryCode,
            centerCode: self.client_application_dto.centerCode,
            loginUser: self.user_login_dto.emailText,
            urn: urn
        )

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response: FeesResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentFees,
            payload: feesJson,
            additionalHeaders: additionalHeaders
        )

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("Fees Rtime: \(elapsedTime) sec")
        return response
    }

    func calendarRequest() async throws -> CalendarResponse? {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        guard
            let fromDate = self.fromDate,
            let urn = self.urn else {
            logger.error("Form Date missing cant make calendar requst")
            throw BSError.oneOfVarIsEmpty
        }

        let calendarJson = CalendarPayload(
            missionCode: self.client_application_dto.missionCode,
            countryCode: self.client_application_dto.countryCode,
            centerCode: self.client_application_dto.centerCode,
            loginUser: self.user_login_dto.emailText,
            visaCategoryCode: self.client_application_dto.visaCategoryCode,
            fromDate: fromDate.toFormattedString(),
            urn: urn
        )

        //logger.info("\(calendarJson.toJSONString())")

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
            (HTTPHeaderField.acceptEncoding, "identity")
        ]

        let response: CalendarResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentCalendar,
            payload: calendarJson,
            additionalHeaders: additionalHeaders
        )

//        let response = try JSONDecoder
//            .wiht(dateFormatter: .sharedDateMDYFormatter)
//            .decode(CalendarResponse.self, from: data)

//        logger.info("Response with Calendar:  \(dump(response))")

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("Calendar Rtime: \(elapsedTime) sec")

        return response

    }

    func timeSlotsRequest() async throws -> TimeslotsResponse? {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        guard
            let calendarResponse = self.calendarResponse,
            let urn = self.urn,
            let slotDate = calendarResponse.calendars?.last?.date.toFormattedString()
        else {
            let error =
                """
                self.calendarResponse: \(self.calendarResponse.debugDescription),
                urn: \(self.urn ?? ""),
                slotDate: \(calendarResponse?.calendars?.last?.date.toFormattedString() ?? "")
                """

            logger.error("\(error)")
            throw BSError.oneOfVarIsEmpty
        }


        let timeslotJson = TimeslotsPayload(
            missionCode: self.client_application_dto.missionCode,
            countryCode: self.client_application_dto.countryCode,
            centerCode: self.client_application_dto.centerCode,
            loginUser: self.user_login_dto.emailText,
            visaCategoryCode: self.client_application_dto.visaCategoryCode,
            slotDate: slotDate, // we are taking last slots from list of calendar
            urn: urn
        )

        //logger.info("\(timeslotJson.toJSONString())")

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response: TimeslotsResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentTimeSlot,
            payload: timeslotJson,
            additionalHeaders: additionalHeaders
        )

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.debug("TimeSlots Rtime: \(elapsedTime) sec")

        return response
    }

    func scheduleRequest() async throws -> ScheduleAppointmentResponse? {
        logger.info("\(#function.capitalized) Start...")

        // Start measuring time
        let startTime = Date()

        guard
            let timeslotsResponse = self.timeslotsResponse,
            let urn = self.urn,
            let allocationId = timeslotsResponse.slots.last?.allocationId,
            let feesResponse = self.feesResponse
        else {
            let error = """
                \(#function)
                TSR \(self.timeslotsResponse.debugDescription)
                urn: \(self.urn ?? "")
                feesR: \(self.feesResponse.debugDescription)
                """
            logger.warning("\(error)")
            throw BSError.oneOfVarIsEmpty
        }

        let feeDetailsFirst = feesResponse.feeDetails?.first
        let feeAmount = feeDetailsFirst?.feeAmount ?? 0.0
        let currency = feeDetailsFirst?.currency ?? ""
        let paymentmode: PaymentMode = feeAmount == 0.0 ? .VAC : .Online

        let schedulePayload = SchedulePayload(
            missionCode: self.client_application_dto.missionCode,
            countryCode: self.client_application_dto.countryCode,
            centerCode: self.client_application_dto.centerCode,
            loginUser: self.user_login_dto.emailText,
            urn: urn,
            paymentdetails: .init(
                paymentmode: paymentmode,
                amount: feeAmount,
                currency: currency
            ),
            allocationId: "\(allocationId)",
            CanVFSReachoutToApplicant: true
        )

        //        logger.info(schedulePayload.toJSONString())

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response: ScheduleAppointmentResponse = try await networkService.postWithJSONBodyRequest(
            to: .appointmentSchedule,
            payload: schedulePayload,
            additionalHeaders: additionalHeaders
        )

//        let response = try JSONDecoder
//            .wiht(dateFormatter: .sharedDateMDYFormatter)
//            .decode(ScheduleAppointmentResponse.self, from: data)

        return response

    }

    func shutdown() async {
        do {
            try await networkService.shutdown()
        } catch {
            logger.error("\(#line) \(#function) shutdown issue: \(error)")
        }
    }
}

func setupAndStart() async throws -> Void {

        let countryCode = "usa"
        let missionCode = "prt"
        let vacCode = "VACH"
        let visaCategoryCode = "LS"

    // With Payment
//    let countryCode = "usa"
//    let missionCode = "prt"
//    let vacCode = "POSF"
//    let visaCategoryCode = "NVD"

    let proxies: [String] = [
        "http://customer-alif_ind_pol-cc-us-sessid-0380302391-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302392-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302393-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302394-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302395-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302396-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302397-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302398-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
        "http://customer-alif_ind_pol-cc-us-sessid-0380302399-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
    ]
    let randomNumber = Int.random(in: 0...8)
    let proxyUrl = proxies[randomNumber]
    guard let proxyData = ProxyData(from: proxyUrl)
    else {
        logger.info("Failed to create ProxyData from URL.")
        return
    }

    logger.info("Proxy Data:")
    logger.info("Host: \(proxyData.host)")
    logger.info("Port: \(proxyData.port)")
    logger.info("Username: \(proxyData.username)")
    logger.info("Password: \(proxyData.password)")

    var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
    tlsConfiguration.certificateVerification = .none

    var configuration = HTTPClient.Configuration(
        tlsConfiguration: tlsConfiguration,
        proxy: .server(
            host: proxyData.host,
            port: proxyData.port,
            authorization: .basic(
                username: proxyData.username,
                password: proxyData.password
            )
        ),
        ignoreUncleanSSLShutdown: true
    )

    configuration.httpVersion = .http1Only
    configuration.decompression = .enabled(limit: .ratio(100))

    let httpClient = HTTPClient(
        eventLoopGroupProvider: .singleton,
        configuration: configuration
    )

    let networkService = NetworkService(httpClient: httpClient)

    let emailText = "james98brown72c@outlook.com"
    let vfsPassword = "kN5fL*6$"
    let mailPassword = "balbalbalbal"

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yy-MM-dd" //"dd-MM-yy"

    // Create a string representing the date
    let fromDateString = "01-07-24"
    let toDateString = "20-07-24"

    // Convert the string to a Date object
    let fromDate = dateFormatter.date(from: fromDateString)!
    let toDate = dateFormatter.date(from: toDateString)!


    var botSteps = BotSteps(
        proxy: proxyUrl,
        user_login_dto: .init(id: 0, userMobileNumber: .init(id: 0, dialCode: 33, mobileNumber: "124342131", type: .mobile, token: "", description: "", createdAt: ""), emailText: emailText, vfsPassword: vfsPassword, mailPassword: mailPassword, countryCode: countryCode, missionCode: missionCode, isReg: true, isActive: true),
        client_application_dto: .init(
            id: 0, user: .init(id: 01, username: "Demo", email: "demo@gmail.com"),
            countryCode: countryCode, visaCategoryCode: visaCategoryCode, missionCode: missionCode, centerCode: vacCode, isActive: true, isProcessing: false, isApplicationCompleted: false, firstName: "Ali", lastName: "Khana", gender: 0, nationalityCode: "ALB", dialCode: "880", contactNumber: "321234123", addressline1: "", passportNumber: "SS332123", passportExpirtyDate: Date().addingYears(6)!, dateOfBirth: Date().addingYears(-27)!, fromDate: fromDate, toDate: toDate, value: 0, emailId: "khan@gmail.com", ipAddress: "", urn: "", arn: "", loginUser: "", isPaid: false, missionDetailId: "", referenceNumber: "", middleName: "", groupName: "", note: "", errorDescription: "", bookingDate: nil,

            createdAt: .now, updatedAt: .now, deleted_at: nil
        ),
        networkService: networkService
    )

    do {

        botSteps.ipResponse = try await botSteps.getProxyIp()
        botSteps.applicantPlayload.ipAddress = botSteps.ip_address

        let solution_token = try await botSteps.cf_solution.heroAndreykaSolveCaptcha()

        guard
            let token = solution_token?.token
        else {
            logger.error("Fetch Token is failed")
            return
        }

        botSteps.loginPayload.captcha_api_key = token

        // Start measuring time
        let startTime = Date()

        botSteps.loginResponse = try await botSteps.loginRequest()

        if botSteps.access_token != "" {
            _ = try await botSteps.applicationRequest()
            botSteps.earliestDateSlotsResponse = try await botSteps.checkSlotsAvilableWithLoop()
            botSteps.applicantResponse = try await botSteps.applicantRequest()
            botSteps.feesResponse = try await botSteps.feesRequest()
            botSteps.calendarResponse = try await botSteps.calendarRequest()
            botSteps.timeslotsResponse = try await botSteps.timeSlotsRequest()
            botSteps.scheduleAppointmentResponse = try await botSteps.scheduleRequest()
        } else {
            logger.error("Access Token is empty \(botSteps.access_token)")
            await botSteps.shutdown()
        }


        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("Total Elapsed time: \(elapsedTime) seconds")

        logger.info("\(botSteps.scheduleAppointmentResponse?.paymentLink ?? "")")
        logger.info("\(botSteps.appointmentFullDetails(scriptTime: elapsedTime.description))")

    } catch {
        logger.error("\(#function) Failed with error: \(error.localizedDescription)")
        await botSteps.shutdown()
    }

    return

}
