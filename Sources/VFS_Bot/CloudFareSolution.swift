
import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient

enum CaptchaSolutionStatus: String, Decodable {
    case SOLVED, WORK, UNSOLVED
}


struct TaskTokenResponse: Decodable {
    let taskid: String
    let status: CaptchaSolutionStatus
    let token: String?
}

struct TaskCap: Encodable {
    let sitekey: String
    let url: String
    let userkey: String
}


class LoginCFSolution {
    var CAPTCHA_SERVER = "http://solver.visabot.pro"  // Replace with your server URL
    var CHECKINTERVAL = 5  // Time in seconds to wait between checks
    var SOLVETIMEOUT = 120  // Time in seconds before giving up on solving

    var SITE_KEY = "0x4AAAAAAACYaM3U_Dz-4DN1"
    var TWO_CAPTCHA_API_KEY = "46a156067a1b78a020e659c459c12cdd"


    let url: URL
    //    self.task = {
    //        "sitekey": SITE_KEY,
    //        "url": self.url,
    //        "userkey": "a6a8b491e2bc4d588b8051e41329ccaf",
    //    }

    var task: TaskCap
    var proxy: String? // Assuming you want to use proxy as a string

    init(url: String, proxy: String? = nil) {
        guard let url = URL(string: url) else {
            fatalError("Invalid URL")
        }
        self.url = url
        self.task = TaskCap(sitekey: SITE_KEY, url: url.absoluteString, userkey: "a6a8b491e2bc4d588b8051e41329ccaf")
        self.proxy = proxy
    }

    private func httpConfig() -> HTTPClient {

        var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
        tlsConfiguration.certificateVerification = .none

        var configuration = HTTPClient.Configuration(
            tlsConfiguration: tlsConfiguration
        )
        configuration.httpVersion = .http1Only

        if
            let proxy = self.proxy,
            let proxyData = ProxyData(from: proxy)
        {
            configuration.proxy = .server(
                host: proxyData.host,
                port: proxyData.port,
                authorization: .basic(
                    username: proxyData.username,
                    password: proxyData.password
                )
            )
        }


        // Initialize HTTP client with proxy configuration
        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton, configuration: configuration)
        return httpClient
    }

    private func getSolvedTask(ttResponse: TaskTokenResponse, start: Date) async throws -> TaskTokenResponse? {
        let httpClient = self.httpConfig()

        guard let token = ttResponse.token else {
            print("\(#function) Token is nil!")
            return nil
        }

        while true {
            try? await Task.sleep(for: .seconds(5)) // 5 seconds
            do {
                var request = HTTPClientRequest(url: "\(CAPTCHA_SERVER)/gettask/\(token)")
                request.method = .POST
                request.headers.add(name: "Content-Type", value: "application/json")

                let response = try await httpClient.execute(request, timeout: .seconds(30))
                if response.status == .ok{
                    let bodyData = try await response.body.collect(upTo: 1024 * 1024)
                    let data = Data(buffer: bodyData)

                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Raw JSON string: \(jsonString)")
                    }

                    let ttRes = try JSONDecoder().decode(TaskTokenResponse.self, from: data)
                    dump(ttRes)

                    switch ttRes.status {
                        case .SOLVED:
                            let elapsedTime = Date().timeIntervalSince(start)
                            print("Captcha solver -/- Was solved in \(elapsedTime) seconds")
                            try await httpClient.shutdown()
                            return ttRes
                        case .WORK where Date().timeIntervalSince(start) > 60, .UNSOLVED:
                            continue
                        default:
                            try await httpClient.shutdown()
                            return nil
                    }
                } else {
                    print("Response issue: \(response)")
                }

            } catch {
                print("getSolvedTask Errors: \(error)")
            }
        }

    }

    func heroAndreykaSolveCaptcha() async throws -> TaskTokenResponse? {

        // Start measuring time
        let startTime = Date()
        let httpClient = self.httpConfig()

        do {
            var request = HTTPClientRequest(url: "\(CAPTCHA_SERVER)/newtask")
            request.method = .POST
            request.headers.add(name: "Content-Type", value: "application/json")

            let bodyBuffer = try self.task.toByteBuffer()
            request.body = .bytes(bodyBuffer)

            let response = try await httpClient.execute(request, timeout: .seconds(30))
            if response.status == .ok{

                let bodyData = try await response.body.collect(upTo: 1024 * 1024)
                let data = Data(buffer: bodyData)
 
                let ttRes = try JSONDecoder().decode(TaskTokenResponse.self, from: data)
                // dump(ttRes)

                switch ttRes.status {
                    case .SOLVED:
                        try await httpClient.shutdown()

                        let elapsedTime = Date().timeIntervalSince(startTime)
                        print("Captcha solver -/- Was solved in \(elapsedTime) seconds")

//                        dump(ttRes)
                        return ttRes
                    default:
                        return try await self.getSolvedTask(ttResponse: ttRes, start: startTime)
                }


            } else {
                print("Received non-OK status: \(response.status)")
            }

        } catch {
            // handle error
            print("Error: \(error)")
        }

        try await httpClient.shutdown()
        return nil
    }

}

//if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//   let status = responseDict["status"] as? String {
//    let taskid = responseDict["taskid"] as? String
//    let token = responseDict["token"] as? String
//
//    switch status {
//        case "SOLVED":
//            // Log: "Captcha solver -/- Was solved in \(Date().timeIntervalSince(start)) seconds"
//            return TaskToken(taskid: taskid, token: token)
//        case "WORK" where Date().timeIntervalSince(start) > 60, "UNSOLVED":
//            return TaskToken(taskid: taskid, token: token)
//        default:
//            break
//    }
//}
