
import NIOSSL
import Foundation
import NIOHTTP1
import AsyncHTTPClient

enum CaptchaSolutionStatus: String, Decodable {
    case SOLVED, WORK, UNSOLVED
}


struct TaskTokenResponse: Decodable {
    let taskid: String
    let status: CaptchaSolutionStatus?
    let token: String?
}

struct TaskCap: Encodable {
    let sitekey: String
    let url: String
    let userkey: String
}


struct LoginCFSolutionClient {
    enum LoginCFSError: Error {
        case someErrors
    }

    var heroAndreykaSolveCaptcha: @Sendable () async throws -> TaskTokenResponse?

}

import Logging

extension LoginCFSolutionClient {

    public static func live(
        urlString: String,
        proxy: String?
    ) -> Self {

        let env = ProcessInfo.processInfo.environment
        guard 
            let SITE_KEY = env["SITE_KEY"],
            let USER_KEY = env["USER_KEY"]
        else {
            fatalError("SITE_KEY is Missiing!")
        }

        let CAPTCHA_SERVER = "http://solver.visabot.pro"  // Replace with your server URL
        let logger = Logger(label: "com.cfSolution.main")

        let task = TaskCap(sitekey: SITE_KEY, url: urlString, userkey: USER_KEY)

        // Start measuring time
        let startTime = Date()

        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)

        @Sendable
        func getSolvedTask(
            ttResponse: TaskTokenResponse,
            start: Date
        ) async throws -> TaskTokenResponse? {

            while true {

                do {
                    try await Task.sleep(for: .seconds(5)) // 5 seconds

                    var request = HTTPClientRequest(url: "\(CAPTCHA_SERVER)/gettask/\(ttResponse.taskid)")
                    request.method = .GET
                    request.headers.add(name: "Content-Type", value: "application/json")

                    let response = try await httpClient.execute(request, timeout: .seconds(30))
                    if response.status == .ok{
                        let bodyData = try await response.body.collect(upTo: 1024 * 1024)
                        let data = Data(buffer: bodyData)

                        let ttRes = try JSONDecoder().decode(TaskTokenResponse.self, from: data)
    //                    dump(ttRes)

                        switch ttRes.status {
                            case .SOLVED:
                                let elapsedTime = Date().timeIntervalSince(start)
                                logger.info("Captcha solver -/- Was solved in \(elapsedTime) seconds")
                                try await httpClient.shutdown()
                                return ttRes
                            case .WORK where Date().timeIntervalSince(start) > 60, .UNSOLVED:
                                continue
                            default:
                                try await httpClient.shutdown()
                                return nil
                        }
                    } else {
                        logger.info("Response issue: \(response)")
                        try await httpClient.shutdown()
                    }

                } catch {
                    logger.error("\(#function) Errors: \(error)")
                    try await httpClient.shutdown()
                }
            }

        }

        return Self(

            heroAndreykaSolveCaptcha: {

                do {
                    var request = HTTPClientRequest(url: "\(CAPTCHA_SERVER)/newtask")
                    request.method = .POST
                    request.headers.add(name: "Content-Type", value: "application/json")

                    let bodyBuffer = try task.toByteBuffer()
                    request.body = .bytes(bodyBuffer)

                    let response = try await httpClient.execute(request, timeout: .seconds(30))
                    logger.info("ResStatus: \(response.status.code) - \(response.status.reasonPhrase)")
                    if response.status == .ok {

                        let bodyData = try await response.body.collect(upTo: 1024 * 1024)
                        let data = Data(buffer: bodyData)

                        let ttRes = try JSONDecoder().decode(TaskTokenResponse.self, from: data)
                        // dump(ttRes)

                        if ttRes.status == nil {
                            return try await getSolvedTask(ttResponse: ttRes, start: startTime)
                        }

                        switch ttRes.status {
                            case .SOLVED:
                                try await httpClient.shutdown()

                                let elapsedTime = Date().timeIntervalSince(startTime)
                                logger.info("Captcha solver -/- Was solved in \(elapsedTime) seconds")

        //                        dump(ttRes)
                                return ttRes
                            default:
                                return try await getSolvedTask(ttResponse: ttRes, start: startTime)
                        }


                    }

                } catch {
                    // handle error
                    try await httpClient.shutdown()
                    logger.error("\(#function) Error: \(error)")
                }

                try await httpClient.shutdown()
                return nil
            }
        )

    }
}
