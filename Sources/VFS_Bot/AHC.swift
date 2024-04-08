import AsyncHTTPClient
import NIO
import NIOSSL
import Foundation


func bla() async throws {

    let countryCode = "uzb"
    let missionCode = "ltp"

    var route: String {
        return "\(countryCode)/en/\(missionCode)"
    }

    var pageurl: String {
        "https://visa.vfsglobal.com/\(route)/login"
    }

    let url = "https://lift-api.vfsglobal.com/user/login"

    var cf_solution: LoginCFSolution { .init(url: pageurl, proxy: "") }

    let solution_token = try await cf_solution.heroAndreykaSolveCaptcha()

    guard
        let token = solution_token?.token
    else {
        print("Token is empty")
        return
    }
    

    let emailText = "max54herreraz89@outlook.com"
    let vfsPassword = "44$Mp$sP!"

//    guard let encriptedPassword = PasswordEncript.getEncryptedPasswordBase64(password: vfsPassword) else {
//        return
//    }

    let startTime = Date()
    
    do {

        let proxyUrl = "http://customer-uzb_ltp-cc-lt-sessid-0970248605-sesstime-30:vibtazkUgva8behpod@pr.oxylabs.io:7777"
        // "http://andrey:test@94.228.196.119:5000"
        // "http://customer-uzb_ltp-cc-lt-sessid-0970248605-sesstime-30:vibtazkUgva8behpod@pr.oxylabs.io:7777"
        guard let proxyData = ProxyData(from: proxyUrl)
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

        configuration.httpVersion = .http1Only

        let httpClient = HTTPClient(
            eventLoopGroupProvider: .singleton,
            configuration: configuration
        )

        // Prepare your request body as Data
        let lp = LoginPayload(username: emailText, password: vfsPassword, missioncode: missionCode, countrycode: countryCode, captcha_api_key: token)
        let data = lp.convertToFormData!

        let byteBuffer = ByteBuffer(data: data) // making byte bufer
        let body: HTTPClientRequest.Body = .bytes(byteBuffer) // making body

        // Construct the request
        var request = HTTPClientRequest(url: url)
        request.method = .POST
        request.body = body // .bytes(.init(data: pp))


        // Add headers from the enum
        HTTPHeaderField.applyDefaultHeaders(
            to: &request,
            withOptionalHeaders: [
                (.route, route),
                (.contentType, "application/x-www-form-urlencoded"),
            ]
        )


        let response = try await httpClient.execute(request, timeout: .seconds(30))

        print("res:", response)
        if response.status == .ok {
            // handle response

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
            print("- /user/login Elapsed time: \(elapsedTime) seconds")
        } else {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("Elapsed time: \(elapsedTime) seconds")
            print("Response error: \(response)")
        }


        // Remember to shut down the client when it's no longer needed to free up resources
        do {
            try await httpClient.shutdown()
        } catch {
            print("Failed to shut down HTTPClient: \(error)")
        }

    }

    catch {
        print("Errors", error)
    }
}

//curl 'https://lift-api.vfsglobal.com/user/login' \
//  -H 'accept: application/json, text/plain, */*' \
//  -H 'accept-language: en-GB,en-US;q=0.9,en;q=0.8' \
//  -H 'cache-control: no-cache' \
//  -H 'clientsource: A0QTcidMO7qpU413IWRSqd/C/I5yYzK3DDNtkpXpnqEQbIkcZr4Rmrd/jPIMaUkXz4BAN9rp7ugMQW+axTmnss6UGveshNtiUwrexsY/0loSjEIkoHqaipCMRwrvqkkRMHhquC3lUEefWu0LM8OdaBPOfcgwgLkl1T3Fptn+lSM=' \
//  -H 'content-type: application/x-www-form-urlencoded' \
//  -H 'origin: https://visa.vfsglobal.com' \
//  -H 'pragma: no-cache' \
//  -H 'referer: https://visa.vfsglobal.com/' \
//  -H 'route: usa/en/prt' \
//  -H 'sec-ch-ua: "Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"' \
//  -H 'sec-ch-ua-mobile: ?0' \
//  -H 'sec-ch-ua-platform: "macOS"' \
//  -H 'sec-fetch-dest: empty' \
//  -H 'sec-fetch-mode: cors' \
//  -H 'sec-fetch-site: same-site' \
//  -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36' \
//  --data-raw 'username=DIANE16SCRUGGSQLZ@OUTLOOK.COM&password=lN7/gP8Eyo62jcfEtiQo3bjSJYZODY/Ux/2d9ekBJokm3SkxOUyIMbYfl4OGfoqlzgV5nXp6n0ZgYcXACtjHbT/I2vh2vhLKU94Xp6kHfZDv0hVcS4BX8zSX7W44ZNJwbq5RY4ccz7N5xGoEBfzb5hCcb9YSq9gB4EjCEGs31mA=&missioncode=prt&countrycode=usa&captcha_version=cloudflare-v1&captcha_api_key=0.fq33vM4677RPaHv2DNMgQW0LYxE6sPQWE4Yxv15uIjO_ZQmK8r_XtB3PL_DNT_O3syT3U1lAGx3qqB-8govO-i6ktMyvPBaC94ElfrpehpCYoWrvxxSL0V02DfwaAXwGPvwl26YGb2HzJyXN1vq98RJEuwsLf6ldGnaKefxOLdmfPId4G74wZjRDwLiOyc6prVeZEnHGmlTArjYgrQRT4v8zQbLVhDfA9t9UsXCi_tGl7c3X7eVCttULyrasMHsOK-GTHwMCkW1hpFLuX228pKioJrVP9ibAnt2uJzUprMdH3ijQjKLwxfS7HJB8jOKy42GlxJsWqtI-eR7bC1Az50REZZE5JxzHdESPmt1z4O99lx4qqKNnortmRpUiAhWFfV7_3BEtUkslcnKsC3FHl14nn-_z2JU806KZfNzO3LlEsZkhqZXPmeeEIurPeRcmkJpP20zkr2pQaBSJVocmWA.Fx3wXGikOxZixHnkylv1Rw.803c44d26fad9d5c4ebf2148769f4c590a532348ed1f7ca6ee3c501d915dfb15'
