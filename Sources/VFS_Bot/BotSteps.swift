import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient
import Logging

let logger = Logger(label: "com.quickprocess.main")

struct BotSteps {

    var proxy: String
    var language_code = "en-US"

    let user_login_dto: UserLoginDTO
    var client_application_dto: ClientApplicationDTO
    var applicantPlayload: ApplicantPayload

    init(
        proxy: String,
        language_code: String = "en-US",
        user_login_dto: UserLoginDTO,
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
            passportExpirtyDate: self.client_application_dto.passportExpiryDate.toFormattedString(),
            dateOfBirth: self.client_application_dto.dateOfBirth.toFormattedString(),
            emailId: self.user_login_dto.emailText,
            nationalityCode: self.client_application_dto.nationalityCode,
            addressline1: " 3726 Woodridge Lane, Memphis, Tennessee",
            ipAddress: ""
        )
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

    // MARK: All Response
    var loginResponse: LoginResponse? = nil
    var ipResponse: IPResponse? = nil
    var applicantResponse: ApplicantResponse? = nil
    var earliestDateSlotsResponse: EarliestDateSlotsResponse? = nil
    var feesResponse: FeesResponse? = nil
    var calendarResponse: CalendarResponse? = nil
    var timeslotsResponse: TimeslotsResponse? = nil
    var scheduleAppointmentResponse: ScheduleAppointmentResponse? = nil


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

        return earliestDate.calculateStartDate()
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

    func appointmentFullDetails(scriptTime: String) -> String {

        guard let center = self.timeslotsResponse?.center,
              let visacategory = self.timeslotsResponse?.visacategory,
              let full_time_details = self.scheduleAppointmentResponse?.full_time_details,
              let requestRefNo = self.scheduleAppointmentResponse?.requestRefNo

        else { return "" }

        let appointmentFullDetails = """
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

    mutating func getProxyIp() async throws -> String? {

        guard let proxyData = ProxyData(from: self.proxy)
        else {
            logger.info("Failed to create ProxyData from URL.")
            return nil
        }

        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.certificateVerification = .none

        let configuration = HTTPClient.Configuration(
            tlsConfiguration: tlsConfiguration,
            proxy: .server(
                host: proxyData.host,
                port: proxyData.port,
                authorization: .basic(
                    username: proxyData.username,
                    password: proxyData.password
                )
            )
        )

        // Initialize HTTP client with proxy configuration
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton, configuration: configuration)

        do {
            var request = HTTPClientRequest(url: "http://httpbin.org/ip")
            request.method = .GET

            let response = try await httpClient.execute(request, timeout: .seconds(30))
            if response.status == .ok{
                let bodyData = try await response.body.collect(upTo: 1024 * 1024)
                let data = Data(buffer: bodyData)

                let ipRes = try JSONDecoder().decode(IPResponse.self, from: data)
                self.ipResponse = ipRes
                dump(ipRes)

                try await httpClient.shutdown()
                return ipRes.origin
            } else {
                // Handle non-OK response
                logger.info("Received non-OK status: \(response.status)")
            }

        } catch {
            // handle error
            logger.info("Error: \(error)")
        }

        try await httpClient.shutdown()
        return nil
    }

    mutating func loginRequest() async throws {

        logger.info("\(#function) Start---")

        let missionCode = self.user_login_dto.missionCode
        let countryCode = self.user_login_dto.countryCode
        let route = "\(countryCode)/en/\(missionCode)"

        var loginPayload = LoginPayload(
            username: self.user_login_dto.emailText,
            password: self.user_login_dto.vfsPassword,
            missioncode: missionCode,
            countrycode: countryCode,
            captcha_api_key: ""
        )

        let solution_token = try await self.cf_solution.heroAndreykaSolveCaptcha()

        guard
            let token = solution_token?.token
        else {
            logger.info("Token is empty")
            try await networkService.shutdown()
            return
        }

        // Start measuring time
        let startTime = Date()

        loginPayload.captcha_api_key = token

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.contentType, "application/x-www-form-urlencoded"),
        ]

        let response = try await networkService.postWithBodyStringRequest(
            to: .userLogin,
            payload: loginPayload,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {
            // handle response

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("Raw JSON string: \(jsonString)")
            }

            do { // will it memory link
                let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                dump(loginResponse)
                self.loginResponse = loginResponse
            } catch {
                logger.info("\(#line) Login Decode error: \(error)")
            }

            // Calculate the elapsed time
            let elapsedTime = Date().timeIntervalSince(startTime)

            // run backgroundmode get ip without block main thread
            // try await getProxyIp()

            // Print the elapsed time
            logger.info("- /user/login Elapsed time: \(elapsedTime) seconds")

        } else {
            let elapsedTime = Date().timeIntervalSince(startTime)
            logger.info("Elapsed time: \(elapsedTime) seconds")
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }
    }

    mutating func applicationRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8"),
        ]

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentApplication,
            payload: applicationPayload,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {
            // handle response

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("Raw JSON string: \(jsonString)")
            }

            logger.info("Application sucess")

            // Calculate the elapsed time
            let elapsedTime = Date().timeIntervalSince(startTime)

            // Print the elapsed time
            logger.info("- /user/application Elapsed time: \(elapsedTime) seconds")
        } else {
            let elapsedTime = Date().timeIntervalSince(startTime)
            logger.info("Application Elapsed time: \(elapsedTime) seconds")
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }
    }

    mutating func checkSlotAvailableRequest() async throws {
        logger.info("\(#function) Start---")

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

        let response = try await networkService.postWithJSONBodyRequest(
            to: .checkSlotAvailability,
            payload: check_slot_available_payload,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {
            // handle response

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("Raw JSON string: \(jsonString)")
            }

            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy HH:mm:ss"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Adjust this as necessary


            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                let response = try decoder.decode(EarliestDateSlotsResponse.self, from: data)
                self.earliestDateSlotsResponse = response
                logger.info("Response with earliestDate: \(dump(response))")
                logger.info("EarliestDate to formDate: \(self.fromDate as Any)")
            } catch {
                logger.info("Decode error: \(error)")
            }

            // Calculate the elapsed time
            let elapsedTime = Date().timeIntervalSince(startTime)

            // Print the elapsed time
            logger.info("- /appointment/CheckIsSlotAvailable Elapsed time: \(elapsedTime) seconds")
        } else {
            let elapsedTime = Date().timeIntervalSince(startTime)
            logger.info("CheckIsSlotAvailable Elapsed time: \(elapsedTime) seconds")
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }
    }

    mutating func applicantRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        applicantPlayload.ipAddress = self.ip_address

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

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentApplicants,
            payload: applicantJson,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {
            // {"data":null,"error":{"code":1041,"description":"No Applicant exists"}}
            // handle response

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            //            if let jsonString = String(data: data, encoding: .utf8) {
            //                logger.info("Raw JSON string: \(jsonString)")
            //            }

            do {
                let response = try JSONDecoder().decode(ApplicantResponse.self, from: data)
                self.applicantResponse = response
                logger.info("Response with applicant: \(dump(response))")
            } catch {
                logger.info("Decode errors:  \(error)")
            }


        } else {
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }

        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("Applicants Request Elapsed time: \(elapsedTime) seconds")
    }

    mutating func feesRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        guard
            let applicantResponse = self.applicantResponse,
            let urn = applicantResponse.urn else {
            logger.info("feesRequest missing urn or applicantResponse")
            return
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

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentFees,
            payload: feesJson,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)


            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("Raw JSON string: \(jsonString)")
            }

            do {
                let response = try JSONDecoder().decode(FeesResponse.self, from: data)
                logger.info("Response with Fees:  \(dump(response))")
                self.feesResponse = response
            } catch {
                logger.info("Decode error: \(error)")
            }

        } else {
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }


        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("Fees Request Elapsed time: \(elapsedTime) seconds")
    }

    mutating func calendarRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        guard
            let fromDate = self.fromDate,
            let urn = self.urn else {
            logger.info("Form Date missing cant make calendar requst")
            return
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

        logger.info("\(calendarJson.toJSONString())")

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentCalendar,
            payload: calendarJson,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                let response = try decoder.decode(CalendarResponse.self, from: data)
                logger.info("Response with Calendar:  \(dump(response))")
                self.calendarResponse = response
            } catch {
                logger.info("Decode error: \(error)")
            }

        } else {
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }


        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("Calendar Request Elapsed time: \(elapsedTime) seconds")
    }

    mutating func timeSlotsRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        guard
            let calendarResponse = self.calendarResponse,
            let urn = self.urn,
            let slotDate = calendarResponse.calendars?.last?.date.toFormattedString()
        else {
            logger.info("\(#function) Urn/SlotDate missing cant get from calendar requst")
            logger.info("self.calendarResponse: \(self.calendarResponse), urn: \(self.urn), slotDate: \(calendarResponse?.calendars?.last?.date.toFormattedString())")
            return
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

        logger.info("\(timeslotJson.toJSONString())")

        let additionalHeaders = [
            (HTTPHeaderField.route, route),
            (HTTPHeaderField.authorize, self.access_token),
            (HTTPHeaderField.contentType, "application/json;charset=UTF-8")
        ]

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentTimeSlot,
            payload: timeslotJson,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)

            do {
                let response = try decoder.decode(TimeslotsResponse.self, from: data)
                logger.info("Response with Calendar: \(dump(response))")
                self.timeslotsResponse = response
            } catch {
                logger.info("Decode error: \(error)")
            }

        } else {
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }


        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("TimeSlots Request Elapsed time: \(elapsedTime) seconds")
    }

    mutating func scheduleRequest() async throws {
        logger.info("\(#function) Start---")

        // Start measuring time
        let startTime = Date()

        guard
            let timeslotsResponse = self.timeslotsResponse,
            let urn = self.urn,
            let allocationId = timeslotsResponse.slots.last?.allocationId,
            let feesResponse = self.feesResponse
        else {
            logger.info("\(#function) Urn/SlotDate missing cant get from calendar requst")
            logger.info("\(#function) TimeslotsResponse: \(self.timeslotsResponse) urn: \(self.urn) feesResponse: \(self.feesResponse)")
            return
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

        let response = try await networkService.postWithJSONBodyRequest(
            to: .appointmentSchedule,
            payload: schedulePayload,
            additionalHeaders: additionalHeaders
        )

        if response.status == .ok {

            let bodyData = try await response.body.collect(upTo: 4096 * 4096)
            // Convert ByteBuffer to Data
            let data = Data(buffer: bodyData)

            // Custom date formatter
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Adjust this as necessary

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(dateFormatter)


            if let jsonString = String(data: data, encoding: .utf8) {
                logger.info("Raw JSON string: \(jsonString)")
            }

            do {
                let response = try decoder.decode(ScheduleAppointmentResponse.self, from: data)
                logger.info("Response with Schedule: \(dump(response))")
                self.scheduleAppointmentResponse = response
            } catch {
                logger.info("Decode error: \(error)")
            }

        } else {
            logger.info("Response error: \(response)")
            try await networkService.shutdown()
        }


        let elapsedTime = Date().timeIntervalSince(startTime)
        logger.info("\(#function) Request Elapsed time: \(elapsedTime) seconds")
    }
}

public func setupAndStart() async throws {

//    let countryCode = "usa"
//    let missionCode = "prt"
//    let vacCode = "PONY"
//    let visaCategoryCode = "PNV"

// With Payment
    let countryCode = "usa"
    let missionCode = "prt"
    let vacCode = "POSF"
    let visaCategoryCode = "NVD"

    let proxyUrl = "http://customer-ind_prt-cc-pt-sessid-0986559363-sesstime-30:Xizwytbogdoh4sycpy@pr.oxylabs.io:7777"
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

    let httpClient = HTTPClient(
        eventLoopGroupProvider: .singleton,
        configuration: configuration
    )

    let networkService = NetworkService(httpClient: httpClient)

    let emailText = "stephen46hickmanvum@outlook.com"
    let vfsPassword = "V2n#e6hH"

    var botSteps = BotSteps(
        proxy: proxyUrl,
        user_login_dto: .init(
            emailText: emailText,
            vfsPassword: vfsPassword,
            countryCode: countryCode,
            missionCode: missionCode
        ),
        client_application_dto: .init(id: 0, userid: 0, countryCode: countryCode, visaCategoryCode: visaCategoryCode, missionCode: missionCode, centerCode: vacCode, isActive: true, isProcessing: false, isApplicationCompleted: false, firstName: "Alex", lastName: "Polashi", gender: 0, nationalityCode: "ALB", dialCode: 880, contactNumber: "018912232342", addressline1: "", passportNumber: "AB0981276", passportExpiryDate: Date().addingYears(3)!, dateOfBirth: Date().addingYears(-26)!, fromDate: .now, toDate: .now, value: 0, emailId: "alibaba@gmail.com", createdAt: .now, updatedAt: .now, ipAddress: "", urn: "", arn: "", loginUser: "", isPaid: false, missionDetailId: "", deletedAt: nil, referenceNumber: "", middleName: "", groupName: "", note: "", errorDescription: "", bookingDate: nil),
        networkService: networkService
    )

//    botSteps.client_application_dto.loginUser = botSteps.user_login_dto.emailText
//    botSteps.client_application_dto.emailId = botSteps.user_login_dto.emailText

//    botSteps.access_token = "EAAAAH72EcSh9gawjbcJG3X+L/HAlfdjreJynWhTXkhx7VmxnEY87hh8EulhVBIjexq0Tq+/IZO2ar/Yw96znbtL+WWntxH39RgrVBKWD0WRwy58ahNKXm4c2eFjED5g6GyW53W7K0HImR4bdPoE1bunFV+5vGotOTDq2aDbwc8SeJL/pp00VgN0e42BaHVBRmrnIraW5bgF1Rw6aLO9RSr2FArtlZ0iHLJeC4tAAdUFdfoc+eekI2uhv4F9TrBPRAjWuWRe90nFPUhHimydY8vvw5xojK65FFWkC1+0Uz4VIIGvL2O2Q/VFq0GDoZNQZvaAMZtE3QxJOQ9QDRj2niGLi3I5h2Bo7JmWpueW5yt+Nt8qw8nB1lOTTmyfD1VwwwNfInPfTyHoEoe4i4CSmUEmGrK10dKcxMOO6uSfM5MzCDN+bSY1U91uVsui3vQbGH/vzWT+61SYTipiDFpE0Xy6X/RxBs5jpigbEyD/GEVZ/LCqfyjgCZDlPoQ/Aonp25k6Oi62dJLpuuYVvojSun4+yfoWiBhy/Uk5UkdyyLGasGpFguG7ksSEb1fQYwlp2TPP2Q=="

    // Start measuring time
    let startTime = Date()

    do {

        try await botSteps.loginRequest()

        if botSteps.access_token != "" {
            botSteps.applicantPlayload.ipAddress = try await botSteps.getProxyIp() ?? ""
            try await botSteps.applicationRequest()
            try await botSteps.checkSlotAvailableRequest()
            try await botSteps.applicantRequest()
            try await botSteps.feesRequest()
            try await botSteps.calendarRequest()
            try await botSteps.timeSlotsRequest()
            try await botSteps.scheduleRequest()
        } else {
            logger.error("Tokens is empty \(botSteps.access_token)")
        }
        try await networkService.shutdown()

        logger.info("\(botSteps.scheduleAppointmentResponse?.paymentLink)")
        logger.info("\(botSteps.appointmentFullDetails(scriptTime: "00"))")

    } catch {
        logger.info("Failed with error: \(error)")
        try await networkService.shutdown()
    }

    let elapsedTime = Date().timeIntervalSince(startTime)
    logger.info("Total Elapsed time: \(elapsedTime) seconds")

}
