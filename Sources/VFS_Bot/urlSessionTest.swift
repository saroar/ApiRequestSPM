import Foundation

func currentTime() -> String {
    let formatter = DateFormatter()
    // Keep 'Z' in the format string, but understand it's purely literal here, not indicating UTC.
    formatter.dateFormat = "GA;yyyy-MM-dd'T'HH:mm:ss'Z'"
    // Omit setting the formatter's timeZone to use the device's local time zone.
    let currentDate = Date()
    let currentTime = formatter.string(from: currentDate)
    return currentTime
}

struct URLSESSIONn {

    enum NetworkServiceError: Error {
        case invalidPayload, requestFailed
    }


    func login() async throws {

        let startTime = Date()
        print("login start ...")

        let emailText =  "ZETWUJONAX@OUTLOOK.COM"
        let vfsPassword =  "Z2?woMs8"
        let proxy = ""

        let countryCode = "uzb"
        let missionCode = "ltp"

        var route: String {
            return "\(countryCode)/en/\(missionCode)"
        }

        var pageurl: String {
            "https://visa.vfsglobal.com/\(route)/login"
        }


        var cf_solution: LoginCFSolution { .init(url: pageurl, proxy: proxy) }
        let solution_token = try await cf_solution.heroAndreykaSolveCaptcha()

        guard
            let token = solution_token?.token
        else {
            print("Token is empty")
            return
        }


        let lp = LoginPayload(username: emailText, password: vfsPassword, missioncode: "ltp", countrycode: "uzb", captcha_api_key: token)
        let data = lp.convertToFormData!

        let login = URL(string: "https://lift-api.vfsglobal.com/user/login")!
        let headers = [
            "accept": "application/json, text/plain, */*",
            "accept-language": "en-GB,en-US;q=0.9,en;q=0.8",
            "cache-control": "no-cache",
            "content-type": "application/x-www-form-urlencoded; charset=utf-8",
            "origin": "https://visa.vfsglobal.com",
            "pragma": "no-cache",
            "referer": "https://visa.vfsglobal.com/",
            "route": "uzb/en/ltp",
            "sec-ch-ua": "\"Google Chrome\";v=\"123\", \"Not:A-Brand\";v=\"8\", \"Chromium\";v=\"123\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        ]

        print("headers", headers)
        var request = URLRequest(url: login)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = data as Data

        print("Before URLSession")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            // Process the response data here
            let str = String(data: data, encoding: .utf8)
            print("str", str ?? "")
            print("response", response)

            let elapsedTime = Date().timeIntervalSince(startTime)
            print("Elapsed time login: \(elapsedTime) seconds")
        } catch {
            print("error", error)
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("Elapsed time login: \(elapsedTime) seconds")
        }
    }

    func application() async throws {
        let startTimea = Date()
        let jsonData = [
            "countryCode": "uzb",
            "missionCode": "ltp",
            "loginUser": "jennifer26ouelletteqog@outlook.com",
            "languageCode": "en-US"
        ] as [String : Any]
        let dataa = try! JSONSerialization.data(withJSONObject: jsonData, options: [])

        let url_app = URL(string: "https://lift-api.vfsglobal.com/appointment/application")!
        let headersa = [
            "accept": "application/json, text/plain, */*",
            "accept-language": "en-GB,en-US;q=0.9,en;q=0.8",
            "authorize": "EAAAAPvH7ECF7MY5AxeS+objGf7dY25QYNZXd0sGdIizGu3IJy2ii8vhm+HDlZrF3c2ra2VHGzxN38pY9dxP6+9R5cWrri+USCGgaVi9ZBjwNFKCXnPJq5tYKsM1emma4Iwp872JJ8qATEr+rfWhgHJkX9wdfo75sktJ8vKZHcvO+Ad06RWi94+d2NfsIG+D8KnGcitICY0Xt+ZeMIwm99UBb72XplSXwSXFDCGv4aeBCX21CJHvTAPpp+Aou83iuPpDe9/0n1UBd0ojc5kHSGTg6B6oF/PYZ6X+m0KQ4X18+cmCD7ouSMCyZCuLCfeop1c3KOxy5gAbVf14dtVDoStYCRfoXOrByLaMAbI1tql0x3xb7TB1Mj5u9Z8aA0GlI6wZCmdTpeT5wF19i3gLUmYkoEr5hi2ieSbm/Az1dcx6ieioqYtWF7p4Ybj+A3Np7v/He9YYerLU2j1SVo+RTzSf0tOz3Py7lZefIlezPJtzoeiZGFDZe34l6vn4t8KVf5dYnyhgRuq/ro2jPdOJpQMkdrtsSHm8nE+XP6NaYvg/4aRWNc8odLG8fWKLOpjD+kieuRH1vnHqfOhskjwvGoyRkGY=",
            "cache-control": "no-cache",
            "content-type": "application/json;charset=UTF-8",
            "origin": "https://visa.vfsglobal.com",
            "pragma": "no-cache",
            "referer": "https://visa.vfsglobal.com/",
            "route": "uzb/en/ltp",
            "sec-ch-ua": "\"Google Chrome\";v=\"123\", \"Not:A-Brand\";v=\"8\", \"Chromium\";v=\"123\"",
            "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": "\"macOS\"",
            "sec-fetch-dest": "empty",
            "sec-fetch-mode": "cors",
            "sec-fetch-site": "same-site",
            "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
        ]

        var request2 = URLRequest(url: url_app)
        request2.httpMethod = "POST"
        request2.allHTTPHeaderFields = headersa
        request2.httpBody = dataa as Data

        let task2 = URLSession.shared.dataTask(with: request2) { (data, response, error) in
            if let error = error {
                print(error)
            } else if let data = data {
                let str = String(data: data, encoding: .utf8)
                print(str ?? "")
            }
        }

        task2.resume()
        let elapsedTime2 = Date().timeIntervalSince(startTimea)
        print("Elapsed time applications: \(elapsedTime2) seconds")
    }
}




