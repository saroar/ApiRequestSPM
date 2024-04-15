import AsyncHTTPClient
import Foundation
import NIOCore
import NIOFoundationCompat
import NIOSSL


// MARK: - LoginResponse
// {'accessToken': None, 'isAuthenticated': False, 'nearestVACCountryCode': None, 'FailedAttemptCount': 1, 'isAppointmentBooked': False, 'isLastTransactionPending': False, 'isAppointmentExpired': False, 'isLimitedDashboard': False, 'isROCompleted': False, 'isSOCompleted': False, 'roleName': None, 'isUkraineScheme': False, 'isUkraineSchemeDocumentUpload': False, 'loginUser': None, 'dialCode': None, 'contactNumber': None, 'remainingCount': 2, 'accountLockHours': 2, 'enableOTPAuthentication': False, 'isNewUser': False, 'taResetPWDToken': None, 'firstName': None, 'lastName': None, 'dateOfBirth': None, 'isPasswordExpiryMessage': False, 'PasswordExpirydays': 0, 'error': {'code': 410, 'description': 'Invalid Logins'}}
struct LoginResponse: Decodable {

    let accessToken: String?
    let isAuthenticated: Bool
    let nearestVACCountryCode: String?
    let failedAttemptCount: Int
    let isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard: Bool
    let isROCompleted, isSOCompleted: Bool
    let roleName: String?
    let isUkraineScheme, isUkraineSchemeDocumentUpload: Bool
    let loginUser, dialCode, contactNumber: String?
    let remainingCount, accountLockHours: Int
    let enableOTPAuthentication, isNewUser: Bool
    let taResetPWDToken, firstName, lastName, dateOfBirth: String?
    let isPasswordExpiryMessage: Bool
    let passwordExpirydays: Int
    let error: ErrorDetail?

    enum CodingKeys: String, CodingKey {
        case accessToken, isAuthenticated, nearestVACCountryCode
        case failedAttemptCount = "FailedAttemptCount"
        case isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard, isROCompleted, isSOCompleted, roleName, isUkraineScheme, isUkraineSchemeDocumentUpload, loginUser, dialCode, contactNumber, remainingCount, accountLockHours, enableOTPAuthentication, isNewUser, taResetPWDToken, firstName, lastName, dateOfBirth, isPasswordExpiryMessage
        case passwordExpirydays = "PasswordExpirydays"
        case error
    }

}


struct Login {

    //    self.login_payload["captcha_version"] = "cloudflare-v1"
    //    self.login_payload["captcha_api_key"] = captcha_api_key
    //    current_time = time.strftime("GA;%Y-%m-%dT%H:%M:%SZ", time.localtime())
    //    self.client_source = get_crypt_pass(current_time)

    func currentTime() -> String {
        let formatter = DateFormatter()
        // Keep 'Z' in the format string, but understand it's purely literal here, not indicating UTC.
        formatter.dateFormat = "GA;yyyy-MM-dd'T'HH:mm:ss'Z'"
        // Omit setting the formatter's timeZone to use the device's local time zone.
        let currentDate = Date()
        let currentTime = formatter.string(from: currentDate)
        return currentTime
    }

    func start() async throws {
        let countryCode = "uzb"
        let missionCode = "ltp"

        let email_text = "stephen84murchisonhvs@outlook.com"
        let vfs_password = "k@yv#IC0u"

        let urlString = "http://andrey:test@94.228.196.119:5000"
        // "http://user161718:ti4g59@194.26.193.33:1158"
        // "http://andrey:test@94.228.196.119:5000"

        guard let proxyData = ProxyData(from: urlString)
        else {
            print("Failed to create ProxyData from URL.")
            return
        }

        print("Proxy Data:")
        print("Host: \(proxyData.host)")
        print("Port: \(proxyData.port)")
        print("Username: \(proxyData.username)")
        print("Password: \(proxyData.password)")

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
            )
        )
        configuration.httpVersion = .automatic

        // Initialize HTTP client with proxy configuration
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton, configuration: configuration)

        do {
            var request = HTTPClientRequest(url: "https://lift-api.vfsglobal.com/user/login")
            request.method = .POST

            // Headers from the Python code
            let headers =  [
                "authority": "lift-api.vfsglobal.com",
                "Accept": "application/json, text/plain, */*",
                "Accept-Language": "en-GB",
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "DNT": "1",
                "Origin": "https://visa.vfsglobal.com",
                "Pragma": "no-cache",
                "Referer": "https://visa.vfsglobal.com/",
                "Sec-Fetch-Dest": "empty",
                "Sec-Fetch-Mode": "cors",
                "Sec-Fetch-Site": "same-site",
                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
                "sec-ch-ua": "\"Chromium\";v=\"118\", \"Google Chrome\";v=\"118\", \"Not=A?Brand\";v=\"99\"",
                "sec-ch-ua-mobile": "?0",
                "sec-ch-ua-platform": "macOS",
                "Content-Type": "application/json;charset=UTF-8",
            ]

            // Adding headers to the request
            headers.forEach { header in
                request.headers.add(name: header.key, value: header.value)
            }

            request.headers.add(name: "route", value: "\(countryCode)/en/\(missionCode)")
            request.headers.replaceOrAdd(name: "Content-Type", value: "application/x-www-form-urlencoded")

            guard let password = PasswordEncrypt.getEncryptedPasswordBase64(password: vfs_password)
            else {
                print("Isuuse is in password encript")
                try await httpClient.shutdown()
                return
            }

            let loginCFSolution = LoginCFSolution(url: "https://visa.vfsglobal.com/\(countryCode)/en/\(missionCode)/login")
            let solution_token = try await loginCFSolution.heroAndreykaSolveCaptcha()

            guard
                let token = solution_token?.token
            else {
                print("Token is empty")
                try await httpClient.shutdown()
                return
            }

            // Start measuring time
            let startTime = Date()

            let loginPayload = LoginPayload(
                username: email_text,
                password: password,
                missioncode: missionCode,
                countrycode: countryCode,
                captcha_api_key: token
            )

            let allocator = ByteBufferAllocator()
            var buffer = allocator.buffer(capacity: 0)
            let requestBodyString = loginPayload.toURLEncodedFormData()

            print("requestBodyString", requestBodyString)
            buffer.writeString(requestBodyString)
            request.body = .bytes(buffer)

//            let currentTime = currentTime()
//            guard let clientsource = PasswordEncript.getEncryptedPasswordBase64(password: currentTime) else {
//                return
//            }
//            request.headers.add(name: "clientsource", value: clientsource)

            let response = try await httpClient.execute(request, timeout: .seconds(30))

            // Assuming 'request' is of type HTTPClient.Request
            let headersDictionary = Dictionary(uniqueKeysWithValues: request.headers.map { ($0.name, $0.value) })
            if let jsonData = try? JSONSerialization.data(withJSONObject: headersDictionary, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("Headers: \(jsonString)")
            } else {
                print("Failed to print headers.")
            }

            if response.status == .ok {

                let bodyData = try await response.body.collect(upTo: 4096 * 4096)
                // Convert ByteBuffer to Data
                let data = Data(buffer: bodyData)

                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON string: \(jsonString)")
                }

                do {
                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
                    dump(loginResponse)
                } catch {
                    print("Decode error: \(error)")
                }

                // Calculate the elapsed time
                let elapsedTime = Date().timeIntervalSince(startTime)

                // Print the elapsed time
                print("Elapsed time: \(elapsedTime) seconds")
            } else {
                print("\(#function) Response error: \(response)")
            }

        } catch {
            print("\(#function) Errors: \(error)")
        }


        try await httpClient.shutdown()

    }

//    self.login,
//    self.application,
//    self.check_is_slot_available_request,
//    self.applicants,
//    self.fees,
//    self.calendar_slot_schedule

}


