
import Foundation

struct PasswordEncrypt {

    /// Encrypts a string using RSA and encodes the result in Base64.
    /// - Parameter password: The password string to encrypt.
    /// - Returns: The Base64 encoded encrypted password, or nil if an error occurs.
    static func getEncryptedPasswordBase64(password: String) -> String? {
        let publicKeyPEM = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCpigN3/5Ti/WJk51pbPQdpCe96TPVoeMAk/cUlAPpYh8zGpr6zssbM11Je1SoQTiuipxIL+c0oGXti8vLzln3yfS+N56wuSh0Hyt1Z+waSx6IDFlfzImEtq8m1osS32B83HRiFZbeKB8QIRJhZil1pJSzMsg0Y0QmDyv1yR4FzIQIDAQAB"

        func publicKey(from pemEncoded: String) -> SecKey? {

            // Decode the base64 string to data.
            guard let data = Data(base64Encoded: publicKeyPEM) else { return nil }

            // Define the attributes for importing the key.
            let options: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeySizeInBits as String: 2048
            ]

            // Create a SecKey from the data.
            var error: Unmanaged<CFError>?
            guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error) else {
                print("Error creating SecKey from data: \(error!.takeRetainedValue() as Error)")
                return nil
            }

            return key
        }

        guard let publicKey = publicKey(from: publicKeyPEM),
              let data = password.data(using: .utf8) else {
            return nil
        }

        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1

        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, algorithm),
              let cipherText = SecKeyCreateEncryptedData(publicKey, algorithm, data as CFData, nil) else {
            return nil
        }

        let pp = (cipherText as Data).base64EncodedString()

        return pp
    }

}

//import CryptoSwift
//
//struct PasswordEncrypt {
//    static func getEncryptedPasswordBase64(password: String) -> String? {
//        let publicKeyPEM = """
//        -----BEGIN PUBLIC KEY-----
//        MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCpigN3/5Ti/WJk51pbPQdpCe96
//        TPVoeMAk/cUlAPpYh8zGpr6zssbM11Je1SoQTiuipxIL+c0oGXti8vLzln3yfS+N
//        56wuSh0Hyt1Z+waSx6IDFlfzImEtq8m1osS32B83HRiFZbeKB8QIRJhZil1pJSzM
//        sg0Y0QmDyv1yR4FzIQIDAQAB
//        -----END PUBLIC KEY-----
//        """
//
//        let pemStripped = publicKeyPEM
//            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
//            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
//            .replacingOccurrences(of: "\r\n", with: "")
//            .replacingOccurrences(of: "\n", with: "")
//            .trimmingCharacters(in: .whitespaces)
//
//        // Decode the base64 string to data.
//        guard let data = Data(base64Encoded: pemStripped) else { return nil }
//
//
//        //        let data = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
//
//
//        let messageToDecrypt = Data(base64Encoded: fixture.messages[password]!.encryptedMessage["algid:encrypt:RSA:PKCS1"]!)!.bytes
//
//
//        return nil
//
//    }
//}
