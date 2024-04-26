import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient
import Logging

public struct BotManager {

    enum BMError: Error {
        case fetchError, decoderError, tokenMission, oneOfVarIsEmpty
    }

    let logger = Logger(label: "com.botmanager.main")

    let requestSleepSec: Int
    let nanoseconds: UInt64
    private var caQuery: CAQuery
    private var networkService: NetworkService
    private let telegramManager: TelegramManager

    private var proxies: ProxyDTO? = nil
    private var userAccounts: UserAccountsDTO = []
    private var clientApplications: ClientApplicationsDTO = []

    public init(
        requestSleepSec: Int,
        nanoseconds: UInt64,
        caQuery: CAQuery,
        networkService: NetworkService,
        telegramManager: TelegramManager
    ) {
        self.requestSleepSec = requestSleepSec
        self.nanoseconds = nanoseconds
        self.caQuery = caQuery
        self.networkService = networkService
        self.telegramManager =  telegramManager
    }

    private func fetchProxies() async throws -> ProxyDTO {

        do {
            let proxies: ProxyDTO = try await self.networkService.request(
                endpoint: .proxies,
                method: .GET,
                headers: [HTTPHeaderField.contentType.key: HTTPHeaderField.contentType.value],
                queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
            )

            return proxies
        } catch {
            logger.error("\(#function) An error occurred: \(error)")
            try await self.networkService.shutdown()
            throw BMError.decoderError
        }

    }

    private func fetchUserAccounts() async throws -> [UserAccountDTO] {

        do {
            let ua: UserAccountsDTO = try await self.networkService
                .request(
                    endpoint: .userAccounts,
                    method: .GET,
                    headers: [HTTPHeaderField.contentType.key: HTTPHeaderField.contentType.value],
                    queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
                )
            return ua
        } catch {
            logger.error("\(#function) An error occurred: \(error.localizedDescription)")
            try await self.networkService.shutdown()
            throw BMError.decoderError
        }

    }

    private func fetchClientApplication() async throws -> [ClientApplicationDTO] {

        do {
            let cas: ClientApplicationsDTO = try await self.networkService
                .request(
                    endpoint: .clientApplications,
                    method: .GET,
                    headers: [HTTPHeaderField.contentType.key: HTTPHeaderField.contentType.value],
                    queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
                )

            return cas
        } catch {
            logger.error("\(#function) An error occurred: \(error)")
            try await self.networkService.shutdown()
            throw BMError.decoderError
        }

    }

    public func run() async throws {

        let userAccounts = try await fetchUserAccounts()
        // dump(userAccount)

        let clientApplications = try await fetchClientApplication()
        // dump(clientApplications)

        let proxies = try await fetchProxies()
        // dump(proxies)

        do {

            let numAccounts = userAccounts.count
            let numClientApplications = clientApplications.count
            let proxyList = proxies.proxyList
            let numProxies = proxies.proxyList.count


            for idx in 0...numProxies {
                let randomValue = Int.random(in: 1...100)
//                let account = userAccounts[idx % numAccounts]

//                let proxy = proxyList[idx % numProxies]
//                let account = userAccounts[idx % numAccounts]
                let clientApplication = clientApplications[idx % numClientApplications]

                let account = userAccounts[randomValue % numAccounts]
                let proxy = proxyList[randomValue % numProxies]

                Task {
                    try await setupAndStart(
                        proxy: proxy,
                        user_account_dto: account,
                        client_application_dto: clientApplication
                    )
                }

                try await Task.sleep(for: .seconds(self.requestSleepSec))

            }

        } catch {
            // Handle any errors thrown by either fetchUserAccount or fetchClientApplication
            logger.error("Error fetching data: \(error)")
            throw BMError.fetchError
        }

        try await self.networkService.shutdown()
    }

    func downLoadPDF() async throws -> Void {

        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.certificateVerification = .none

        var configuration = HTTPClient.Configuration(
            tlsConfiguration: tlsConfiguration,
            ignoreUncleanSSLShutdown: true
        )

        configuration.httpVersion = .http1Only
        configuration.decompression = .enabled(limit: .ratio(100))

        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )

        let networkService = NetworkService(httpClient: httpClient)

        let tmc = TelegramManagerClient.live(networkService: networkService)

//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "d.MM.yyyy"
//        let formattedDate = dateFormatter.string(from: Date())
//
//        let rootDirectory = getRootDirectory()
//        let pdfDirectory = rootDirectory.appendingPathComponent("Public/PDFs/\(formattedDate)", isDirectory: true)
//        let fileURL = pdfDirectory.appendingPathComponent("awesome.pdf")
//
//        try FileManager.default.createDirectory(
//            atPath: pdfDirectory.path,
//            withIntermediateDirectories: false,
//            attributes: nil
//        )
//
//        let data = Data()
//        do {
//            try data.write(to: fileURL)
//            logger.info("PDF saved successfully at \(fileURL.path)")
//            _ = try await tmc.sendDocument(
//                .UZBEKISTAN,
//                URL(fileURLWithPath: fileURL.path())
//            )
//
//        } catch {
//            print("Error saving PDF: \(error)")
//        }
//
//        return

        var route: String {
            "gbr/en/prt"
        }

        let token = """
                EAAAAPaobnIE5dl9uFBd4/ePbRyLVTib6Y2pK8qnuhakmm/j8YGH2l2d4BZjcGqEe+VbPuz5x0w7c9OT7kVgZjXZxolGQzNNYAGET19q1y7fW52CLqysX1iV3lBCbPoCPBkiD/o4U2spzTWm57fGLPxaXE2XdLtpi8Dv1z8kAguac+7q9qbNzujPT7AqEqjljXortnHE5KDaraOxmkFE3JMydH9+S0kBTT6Ebhw6/9UR66lsWSA+NupnylKzC4BEUoEit48gZGb+zoLGpMiTwg+TnryJQkzehlKDDH+ZZXyK5DWdtbubIlSHFueR2Z7xSUVlFjaPLiUearKla30cbTdg8uxrjLtFwjoAv8R6kq2XB22wm4YE32vLAoEM4ELL9IRtzcDxswyGCgjLkMpQR/ncafGEPYhaIwP8hZ9mALUghwcnXpe2lm1UTyucpNmsd9fDH5K9VIOfxLdTmG+Uc+iwSsXJktbKH2w8BmOph5IOPlOEyBU56b+IbDsxm44hNDCr1OdOlJaOhTTESv7ErrVG9+Aeje4+tci9ReZk1wtI/RQ/UtrXdOeXzKNiZfZZWbGe3LtY1WVOAiz8gqbz7AE4DDU=
                """
        let urn = "ITA97430949446"
        let user_login_dto: UserAccountDTO = .init(id: 0, userMobileNumber: .init(id: 0, dialCode: 0, mobileNumber: "", type: .gsmDevice, token: "", description: "", createdAt: ""), emailText: "jamar43lucierzcc@outlook.com", vfsPassword: "", mailPassword: "", countryCode: "gbr", missionCode: "prt", isReg: true, isActive: true)

        let client_application_dto: ClientApplicationDTO = .init(id: 0, user: .init(id: 0, username: "alif", email: ""), countryCode: "gbr", visaCategoryCode: "", missionCode: "prt", centerCode: "", isActive: true, isProcessing: true, isApplicationCompleted: true, firstName: "", lastName: "", gender: 1, nationalityCode: "", dialCode: "", contactNumber: "", addressline1: "", passportNumber: "", passportExpirtyDate: .now, dateOfBirth: .now, fromDate: .now, toDate: .now, value: 0, emailId: "", ipAddress: "", urn: "ITA97430949446", arn: "", isPaid: false, missionDetailId: "", referenceNumber: "", middleName: "", groupName: "", note: "", errorDescription: "", bookingDate: nil, createdAt: .now, updatedAt: .now, deleted_at: nil)

        let vamClient = VisaApplicationManagerClient.live(
            route: route,
            proxy: "proxy",
            networkService: networkService,
            languageCode: "en-US",
            user_login_dto: user_login_dto,
            client_application_dto: client_application_dto,
            nanoseconds: 1_000_000_000,  // Example nanosecond value for delay handling
            captcha_api_key: "token",
            ipAddress: "ipAddress"
        )


        guard let data = try await vamClient.downloadPDFRequest(token, urn) else {
            logger.error("Issue with getting data from pdf download")
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d.MM.yyyy"
        let formattedDate = dateFormatter.string(from: Date())

        let rootDirectory = getRootDirectory()
        let pdfDirectory = rootDirectory.appendingPathComponent("Public/PDFs/\(formattedDate)", isDirectory: true)
        let fileURL = pdfDirectory.appendingPathComponent(client_application_dto.pdf_name)

        try FileManager.default.createDirectory(
            atPath: pdfDirectory.path,
            withIntermediateDirectories: false,
            attributes: nil
        )

        do {
            try data.write(to: fileURL)
            logger.info("PDF saved successfully at \(fileURL.path)")
            _ = try await tmc.sendDocument(
                .UZBEKISTAN,
                URL(fileURLWithPath: fileURL.path)
            )

        } catch {
            print("Error saving PDF: \(error)")
        }


    }

    func setupAndStart(
        proxy: String,
        user_account_dto: UserAccountDTO,
        client_application_dto: ClientApplicationDTO
    ) async throws -> Void {

        let proxyUrl = proxy

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

        func getIPResponse() async throws -> IPResponse {
            do {
                return try await networkService.request(
                    endpoint: .getIP,
                    method: .GET,
                    headers: [HTTPHeaderField.contentType.key: HTTPHeaderField.contentType.value]
                )
            } catch {
                logger.error("\(#function) An error occurred: \(error)")
                return IPResponse(origin: "98.167.101.137") // Fallback or error response
            }
        }

        let ipAddress = try await getIPResponse()

        let httpClientT = HTTPClient(eventLoopGroupProvider: .singleton)
        let nst = NetworkService(httpClient: httpClientT)
        let tmc = TelegramManagerClient.live(networkService: nst)

        var route: String {
            "\(client_application_dto.countryCode)/en/\(client_application_dto.missionCode)"
        }

        var pageurl: String { return "https://visa.vfsglobal.com/\(route)/login" }
        let cf_solution = LoginCFSolutionClient.live(urlString: pageurl, proxy: nil)
        let solution_token = try await cf_solution.heroAndreykaSolveCaptcha()

        guard
            let token = solution_token?.token
        else {
            logger.error("Fetch Token is failed")
            return
        }

        let vamClient = VisaApplicationManagerClient.live(
            route: route,
            proxy: proxy,
            networkService: networkService,
            languageCode: "en-US",
            user_login_dto: user_account_dto,
            client_application_dto: client_application_dto,
            nanoseconds: nanoseconds,  // Example nanosecond value for delay handling
            captcha_api_key: token,
            ipAddress: ipAddress.origin
        )


        do {
            let loginResponse = try await vamClient.loginRequest()

            guard let lr = loginResponse, let token = lr.accessToken else {
                logger.error("Login issue with \(loginResponse?.error)")
                throw BMError.tokenMission
            }

            // Start measuring time
            let startTime = Date()

            let application = try await vamClient.applicationRequest(token)

            let earliestDateSlotsResponse = try await vamClient.checkSlotsAvilableWithLoop(token)

            if earliestDateSlotsResponse?.error != nil {
                logger.error("EarliestDateSlotsResponse mkae many request")
                try await networkService.shutdown()
            }

            Task {
                try await telegramManager.sendMessage(
                    countryCode: caQuery.countryCode,
                    text: earliestDateSlotsResponse.prettyPrinted()
                )
            }

            guard
                let earliestDate = earliestDateSlotsResponse?.earliestDate
            else {
                throw BMError.oneOfVarIsEmpty
            }

            guard
                let applicantResponse = try await vamClient.applicantRequest(token, earliestDate),
                let urn = applicantResponse.urn else {
                logger.info("feesRequest missing urn or applicantResponse")
                throw BMError.oneOfVarIsEmpty
            }

            let feesResponse = try await vamClient.feesRequest(token, urn)

            var fromDate: Date? {
                guard
                    let earliestDateSlotsR = earliestDateSlotsResponse,
                    let earliestDate = earliestDateSlotsR.earliestDate
                else {
                    return nil
                }

                let earliestDateCalculateStartDate = earliestDate.calculateStartDate()

                logger.info("earliestDate: \(earliestDate), fromDate: \(earliestDateCalculateStartDate)")
                return earliestDateCalculateStartDate
            }

            guard
                let fromDate = fromDate else {
                logger.error("Form Date missing cant make calendar requst")
                throw BMError.oneOfVarIsEmpty
            }

            guard
                let calendarResponse = try await vamClient.calendarRequest(token, urn, fromDate),
                let slotDate = calendarResponse.calendars?.last?.date
            else {
                let error = "calendarResponse or slotDate nilling"
                logger.error("\(error)")
                throw BMError.oneOfVarIsEmpty
            }

            Task {
                try await telegramManager.sendMessage(
                    countryCode: self.caQuery.countryCode,
                    text: calendarResponse.prettyPrinted()
                )
            }

            guard
                let timeslotsResponse = try await vamClient.timeSlotsRequest(token, urn, slotDate),
                let allocationId = timeslotsResponse.slots.last?.allocationId
            else {
                let error = """
                    TSR timeslotsResponse
                    FeesR: feesResponse
                    are nil
                    """
                logger.warning("\(error)")
                throw BMError.oneOfVarIsEmpty
            }


            Task {
                try await telegramManager.sendMessage(
                    countryCode: self.caQuery.countryCode,
                    text: timeslotsResponse.prettyPrinted()
                )
            }

            let feeDetailsFirst = feesResponse?.feeDetails?.first
            let feeAmount = feeDetailsFirst?.feeAmount ?? 0.0
            let currency = feeDetailsFirst?.currency ?? ""
            let paymentmode: PaymentMode = feeAmount == 0.0 ? .VAC : .Online

            let paymentDetails = PaymentDetails(
                paymentmode: paymentmode,
                amount: feeAmount,
                currency: currency
            )

            let scheduleAppointmentResponse = try await vamClient.scheduleRequest(
                token,
                urn,
                allocationId,
                paymentDetails
            )

            let elapsedTime = Date().timeIntervalSince(startTime)
            logger.info("Total Elapsed time: \(elapsedTime) seconds")

            guard let scheduleAppointmentResponse = scheduleAppointmentResponse else {
                throw BMError.fetchError
            }

            if scheduleAppointmentResponse.isAppointmentBooked == false {
                logger.error("Schedule Appointment was failed")
                return
            }


            guard let data = try await vamClient.downloadPDFRequest(token, urn) else {
                logger.error("Issue with getting data from pdf download")
                return
            }

            let appointmentDate = scheduleAppointmentResponse.appointmentDate

            let rootDirectory = getRootDirectory()
            let pdfDirectory = rootDirectory.appendingPathComponent("Public/PDFs/\(appointmentDate)", isDirectory: true)
            let fileURL = pdfDirectory.appendingPathComponent(client_application_dto.pdf_name)

            try FileManager.default.createDirectory(
                atPath: pdfDirectory.path,
                withIntermediateDirectories: false,
                attributes: nil
            )

            Task {
                try await telegramManager.sendMessage(
                    countryCode: caQuery.countryCode,
                    text: appointmentFullDetails(
                        scriptTime: "\(elapsedTime)",
                        user_account_dto: user_account_dto,
                        client_application_dto: client_application_dto,
                        timeslotsResponse: timeslotsResponse,
                        scheduleAppointmentResponse: scheduleAppointmentResponse
                    )
                )

                do {
                    try data.write(to: fileURL)
                    logger.info("PDF saved successfully at \(fileURL.path)")
                    _ = try await tmc.sendDocument(
                        .UZBEKISTAN,
                        URL(fileURLWithPath: fileURL.path)
                    )

                } catch {
                    print("Error saving PDF: \(error)")
                }
            }


        } catch {
            throw BMError.fetchError
        }

    }

    @Sendable
    func appointmentFullDetails(
        scriptTime: String,
        user_account_dto: UserAccountDTO,
        client_application_dto: ClientApplicationDTO,
        timeslotsResponse: TimeslotsResponse,
        scheduleAppointmentResponse: ScheduleAppointmentResponse
    ) -> String {

        let full_time_details = scheduleAppointmentResponse.full_time_details
        let requestRefNo = scheduleAppointmentResponse.requestRefNo
        let center = timeslotsResponse.center
        let visacategory = timeslotsResponse.visacategory

        let appointmentFullDetails = """
            \n
            FirstName: \(client_application_dto.firstName)
            Lastname: \(client_application_dto.lastName)
            Visa Category Code: \(client_application_dto.visaCategoryCode)
            Country&City: \(center)
            Visa Category: \(visacategory)
            Email: \(user_account_dto.emailText)
            EPassword: \(user_account_dto.mailPassword)
            Vfs Password: \(user_account_dto.vfsPassword)
            User Mobile Number: \(client_application_dto.full_contact_number)
            Booking was successful: \(full_time_details)
            Reference number: \(requestRefNo)
            Agent Name: \(client_application_dto.agent_name)
            Script took: \(scriptTime)
        """

        return appointmentFullDetails

    }
}


func getRootDirectory() -> URL {
    let fileManager = FileManager.default

    // Optionally, use an environment variable or a fixed path in production
    if let rootPath = ProcessInfo.processInfo.environment["SPM_ROOT_PATH"] {
        return URL(fileURLWithPath: rootPath, isDirectory: true)
    } else {
        // If running in Xcode, set to a specific directory or use the project's directory
        #if DEBUG
        return URL(fileURLWithPath: "/Users/alif/ManPower/VFS_APPOINTMENT/Swift/VFS_Bot", isDirectory: true)
        #else
        // Default to a safe, known directory or use current directory in production
        return URL(fileURLWithPath: fileManager.currentDirectoryPath, isDirectory: true)
        #endif
    }
}
