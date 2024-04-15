import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient
import Logging

public struct BotManager {

    enum BMError: Error {
        case fetchError, decoderError
    }

    private var networkService: NetworkService
    private var caQuery: CAQuery

    public init(
        networkService: NetworkService,
        caQuery: CAQuery

    ) {
        self.networkService = networkService
        self.caQuery = caQuery
    }

    private func fetchProxies() async throws -> ProxyDTO {

        do {
            let proxies: ProxyDTO = try await self.networkService
                .getRequest(
                    from: .proxies,
                    queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
                )
            return proxies
        } catch {
            logger.error("\(#function) An error occurred: \(error)")
            throw BMError.decoderError
        }

    }

    private func fetchUserAccounts() async throws -> [UserAccountDTO] {

        do {
            let ua: [UserAccountDTO] = try await self.networkService
                .getRequest(
                    from: .userAccounts,
                    queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
                )
            return ua
        } catch {
            logger.error("\(#function) An error occurred: \(error)")
            throw BMError.decoderError
        }

    }

    private func fetchClientApplication() async throws -> [ClientApplicationDTO] {

        do {
            let cas: [ClientApplicationDTO] = try await self.networkService
                .getRequest(
                    from: .clientApplications,
                    queryParameters: CAQuery(countryCode: self.caQuery.countryCode, missionCode: self.caQuery.missionCode)
                )
            return cas
        } catch {
            logger.error("\(#function) An error occurred: \(error)")
            throw BMError.decoderError
        }

    }

    public func run() async throws {
        do {
            // Start both tasks concurrently
            let userAccounts = try await fetchUserAccounts()
            let numAccounts = userAccounts.count
//            dump(userAccount)

            let clientApplications = try await fetchClientApplication()
            let numClientApplications = clientApplications.count
//            dump(clientApplications)

            let proxies = try await fetchProxies()
            let numProxies = proxies.proxyList.count
//            dump(proxies)

            for idx in 0...numProxies {
                let randomValue = Int.random(in: 1...100)
                let account = userAccounts[randomValue % numAccounts]
                dump(account)

//                let account = userAccounts[idx % numAccounts]
                let clientApplication = clientApplications[idx % numClientApplications]
                let proxy = proxies.proxyList[idx % numProxies]

                Task {
                    try await setupAndStart(proxy: proxy, user_account_dto: account, client_application_dto: clientApplication)
                }

                try await Task.sleep(for: .seconds(10))

            }


        } catch {
            // Handle any errors thrown by either fetchUserAccount or fetchClientApplication
            logger.error("Error fetching data: \(error)")
            try await self.networkService.shutdown()
            throw BMError.fetchError
        }
    }

    func setupAndStart(
        proxy: String,
        user_account_dto: UserAccountDTO,
        client_application_dto: ClientApplicationDTO
    ) async throws -> Void {

//            let countryCode = "usa"
//            let missionCode = "prt"
//            let vacCode = "VACH"
//            let visaCategoryCode = "LS"

        // With Payment
    //    let countryCode = "usa"
    //    let missionCode = "prt"
    //    let vacCode = "POSF"
    //    let visaCategoryCode = "NVD"

//        let proxies: [String] = [
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302391-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302392-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302393-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302394-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302395-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302396-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302397-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302398-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//            "http://customer-alif_ind_pol-cc-us-sessid-0380302399-sesstime-3:nebsygqivxahkapmU7@pr.oxylabs.io:7777",
//        ]
//        let randomNumber = Int.random(in: 0...8)
//        let proxyUrl = proxies[randomNumber]

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

        var botSteps = BotSteps(
            proxy: proxyUrl,
            user_login_dto: user_account_dto,
            client_application_dto: client_application_dto,
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

                if botSteps.earliestDateSlotsResponse?.error != nil {
                    logger.error("EarliestDateSlotsResponse mkae many request")
                    await botSteps.shutdown()
                }

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

    }

}
