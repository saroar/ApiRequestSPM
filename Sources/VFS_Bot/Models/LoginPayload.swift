
import Foundation

struct LoginPayload: Codable {
    let username: String
    let password: String
    let missioncode: String
    let countrycode: String
    var captcha_version: String = "cloudflare-v1"
    var captcha_api_key: String

    var encriptedPassword: String? {
        guard let password = PasswordEncrypt.getEncryptedPasswordBase64C(password: self.password)
        else {
            print("Isuuse is in password encript")
            return nil
        }

        return password
    }

    var convertToUTF8Data: Data? {
        let encoder = JSONEncoder()
//        encoder.outputFormatting = .prettyPrinted // optional pretty printing of JSON data
        do {
            let jsonData = try encoder.encode(self)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString.data(using: .utf8)
            } else {
                print("Failed to convert JSON data to UTF-8 data")
                return nil
            }
        } catch {
            print("Error encoding LoginPayload: \(error)")
            return nil
        }
    }

    var convertToFormData: Data? {
        guard let encriptedPassword = encriptedPassword else {
            return nil
        }

        let formData = "username=\(username)&password=\(encriptedPassword)&missioncode=\(missioncode)&countrycode=\(countrycode)&captcha_version=\(captcha_version)&captcha_api_key=\(captcha_api_key)"
        return formData.data(using: .utf8)
    }
}

extension LoginPayload: URLEncodedFormConvertible {
    func toURLEncodedFormData() -> String {
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "username", value: username),
            URLQueryItem(name: "password", value: encriptedPassword),
            URLQueryItem(name: "missioncode", value: missioncode),
            URLQueryItem(name: "countrycode", value: countrycode),
            URLQueryItem(name: "captcha_version", value: captcha_version),
            URLQueryItem(name: "captcha_api_key", value: captcha_api_key)
        ]
        // Flatten the components to a single string, replacing `+` with `%20` to properly encode spaces
        // as per application/x-www-form-urlencoded standard.
        return components.url?.query?.replacingOccurrences(of: "+", with: "%20") ?? ""
    }
}
