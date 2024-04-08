//import AsyncHTTPClient
//import Foundation
//import NIOCore
//import NIOFoundationCompat
//import NIOSSL
//
//extension Encodable {
//    /// Converts an `Encodable` instance to a `ByteBuffer`.
//    /// - Parameters:
//    ///   - allocator: The `ByteBufferAllocator` used to allocate the `ByteBuffer`.
//    /// - Returns: A `ByteBuffer` containing the JSON-encoded representation of the instance.
//    /// - Throws: An error if the instance could not be encoded.
//    public func toByteBuffer(allocator: ByteBufferAllocator = ByteBufferAllocator()) throws -> ByteBuffer {
//        let jsonData = try JSONEncoder().encode(self)
//        var buffer = allocator.buffer(capacity: jsonData.count)
//        buffer.writeBytes(jsonData)
//        return buffer
//    }
//}
//
//// MARK: - LoginResponse
//// {'accessToken': None, 'isAuthenticated': False, 'nearestVACCountryCode': None, 'FailedAttemptCount': 1, 'isAppointmentBooked': False, 'isLastTransactionPending': False, 'isAppointmentExpired': False, 'isLimitedDashboard': False, 'isROCompleted': False, 'isSOCompleted': False, 'roleName': None, 'isUkraineScheme': False, 'isUkraineSchemeDocumentUpload': False, 'loginUser': None, 'dialCode': None, 'contactNumber': None, 'remainingCount': 2, 'accountLockHours': 2, 'enableOTPAuthentication': False, 'isNewUser': False, 'taResetPWDToken': None, 'firstName': None, 'lastName': None, 'dateOfBirth': None, 'isPasswordExpiryMessage': False, 'PasswordExpirydays': 0, 'error': {'code': 410, 'description': 'Invalid Logins'}}
//struct LoginResponse: Codable {
//
//    // MARK: - Error
//    struct Error: Codable {
//        let code: Int
//        let description: String
//    }
//
//    let accessToken: String
//    let isAuthenticated: Bool
//    let nearestVACCountryCode: String?
//    let failedAttemptCount: Int
//    let isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard: Bool
//    let isROCompleted, isSOCompleted: Bool
//    let roleName: String?
//    let isUkraineScheme, isUkraineSchemeDocumentUpload: Bool
//    let loginUser, dialCode, contactNumber: String?
//    let remainingCount, accountLockHours: Int
//    let enableOTPAuthentication, isNewUser: Bool
//    let taResetPWDToken, firstName, lastName, dateOfBirth: String?
//    let isPasswordExpiryMessage: Bool
//    let passwordExpirydays: Int
//    let error: Error?
//
//    enum CodingKeys: String, CodingKey {
//        case accessToken, isAuthenticated, nearestVACCountryCode
//        case failedAttemptCount = "FailedAttemptCount"
//        case isAppointmentBooked, isLastTransactionPending, isAppointmentExpired, isLimitedDashboard, isROCompleted, isSOCompleted, roleName, isUkraineScheme, isUkraineSchemeDocumentUpload, loginUser, dialCode, contactNumber, remainingCount, accountLockHours, enableOTPAuthentication, isNewUser, taResetPWDToken, firstName, lastName, dateOfBirth, isPasswordExpiryMessage
//        case passwordExpirydays = "PasswordExpirydays"
//        case error
//    }
//}
//
//struct LoginPayload: Codable {
//    let username: String
//    let password: String
//    let missioncode: String
//    let countrycode: String
//    var captcha_version: String = "cloudflare-v1"
//    let captcha_api_key: String
//}
//
//struct Login {
//
////    self.login_payload["captcha_version"] = "cloudflare-v1"
////    self.login_payload["captcha_api_key"] = captcha_api_key
////    current_time = time.strftime("GA;%Y-%m-%dT%H:%M:%SZ", time.localtime())
////    self.client_source = get_crypt_pass(current_time)
//
//    func currentTime() -> String {
//        let formatter = DateFormatter()
//        // Keep 'Z' in the format string, but understand it's purely literal here, not indicating UTC.
//        formatter.dateFormat = "GA;yyyy-MM-dd'T'HH:mm:ss'Z'"
//        // Omit setting the formatter's timeZone to use the device's local time zone.
//        let currentDate = Date()
//        let currentTime = formatter.string(from: currentDate)
//        return currentTime
//    }
//
//    func start() async throws {
//        let countryCode = "uzb"
//        let missionCode = "ltp"
//
//        let email_text = "lori26waldvogelfd4@outlook.com"
//        let vfs_password = "qnMB$@001"
//
//        let urlString = "http://andrey:test@94.228.196.119:5000"
//        // "http://customer-uzb_ltp-cc-uz:vibtazkUgva8behpod@pr.oxylabs.io:7777"
//        //"http://andrey:test@94.228.196.119:5000"
//
//        guard let proxyData = ProxyData(from: urlString)
//        else {
//            print("Failed to create ProxyData from URL.")
//            return
//        }
//
//        print("Proxy Data:")
//        print("Host: \(proxyData.host)")
//        print("Port: \(proxyData.port)")
//        print("Username: \(proxyData.username)")
//        print("Password: \(proxyData.password)")
//
//        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
//        tlsConfiguration.certificateVerification = .none
//
//        var configuration = HTTPClient.Configuration(
//            tlsConfiguration: tlsConfiguration,
//            proxy: .server(
//                host: proxyData.host,
//                port: proxyData.port,
//                authorization: .basic(
//                    username: proxyData.username,
//                    password: proxyData.password
//                )
//            )
//        )
//        configuration.httpVersion = .automatic
//
//        // Initialize HTTP client with proxy configuration
//        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton, configuration: configuration)
//
//        do {
//            var request = HTTPClientRequest(url: "https://lift-api.vfsglobal.com/user/login")
//            request.method = .POST
//
//            // Headers from the Python code
//            let headers =  [
//                "authority": "lift-api.vfsglobal.com",
//                "Accept": "application/json, text/plain, */*",
//                "Accept-Language": "en-GB",
//                "Cache-Control": "no-cache",
//                "Connection": "keep-alive",
//                "DNT": "1",
//                "Origin": "https://visa.vfsglobal.com",
//                "Pragma": "no-cache",
//                "Referer": "https://visa.vfsglobal.com/",
//                "Sec-Fetch-Dest": "empty",
//                "Sec-Fetch-Mode": "cors",
//                "Sec-Fetch-Site": "same-site",
//                "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
//                "sec-ch-ua": "\"Chromium\";v=\"118\", \"Google Chrome\";v=\"118\", \"Not=A?Brand\";v=\"99\"",
//                "sec-ch-ua-mobile": "?0",
//                "sec-ch-ua-platform": "macOS",
//                "Content-Type": "application/json;charset=UTF-8",
//            ]
//
//            // Adding headers to the request
//            headers.forEach { header in
//                request.headers.add(name: header.key, value: header.value)
//            }
//
//            request.headers.add(name: "route", value: "\(countryCode)/en/\(missionCode)")
//            // Setting the Content-Type header to application/json
//            request.headers.replaceOrAdd(name: "Content-Type", value: "application/x-www-form-urlencoded")
//
//            guard let password = PasswordEncript.getEncryptedPasswordBase64(password: vfs_password)
//            else {
//                print("Isuuse is in password encript")
//                try await httpClient.shutdown()
//                return
//            }
//
//            let loginCFSolution = LoginCFSolution(url: "https://visa.vfsglobal.com/\(countryCode)/en/\(missionCode)/login")
//            let solution_token = await loginCFSolution.heroAndreykaSolveCaptcha()
//
//            guard
//                let token_is_not_empty = solution_token["token"],
//                let token = token_is_not_empty else {
//                return
//            }
//
//            // Start measuring time
//            let startTime = Date()
//
//            let loginPayload = LoginPayload(
//                username: email_text,
//                password: password,
//                missioncode: missionCode,
//                countrycode: countryCode,
//                captcha_api_key: token
//            )
//
//            // Convert the instance to a ByteBuffer
//            let requestBody = try loginPayload.toByteBuffer()
//            request.body = .bytes(requestBody)
//
//            let currentTime = currentTime()
//            guard let clientsource = PasswordEncript.getEncryptedPasswordBase64(password: currentTime) else {
//                return
//            }
//            request.headers.add(name: "clientsource", value: clientsource)
//            let response = try await httpClient.execute(request, timeout: .seconds(30))
//
//            // Assuming 'request' is of type HTTPClient.Request
//            let headersDictionary = Dictionary(uniqueKeysWithValues: request.headers.map { ($0.name, $0.value) })
//            if let jsonData = try? JSONSerialization.data(withJSONObject: headersDictionary, options: .prettyPrinted),
//               let jsonString = String(data: jsonData, encoding: .utf8) {
//                print("Headers: \(jsonString)")
//            } else {
//                print("Failed to print headers.")
//            }
//
//            if response.status == .ok {
//                // handle response
//
//                let bodyData = try await response.body.collect(upTo: 4096 * 4096)
//                // Convert ByteBuffer to Data
//                let data = Data(buffer: bodyData)
//
//                do {
//                    let loginResponse = try JSONDecoder().decode(LoginResponse.self, from: data)
//                    dump(loginResponse)
//                } catch {
//                    print("Decode error: \(error)")
//                }
//
//                // Calculate the elapsed time
//                let elapsedTime = Date().timeIntervalSince(startTime)
//
//                // Print the elapsed time
//                print("Elapsed time: \(elapsedTime) seconds")
//            } else {
//                print("Response error: \(response)")
//            }
//
//        } catch {
//            // handle error
//        }
//        // it's important to shutdown the httpClient after all requests are done, even if one failed
//        try await httpClient.shutdown()
//
//    }
//}
//
