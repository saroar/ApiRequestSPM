
import Foundation
import CXXLibrary

struct PasswordEncrypt {

    static func getEncryptedPasswordBase64C(password: String) -> String? {
        let publicKeyPEM = """
        -----BEGIN PUBLIC KEY-----
        MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCpigN3/5Ti/WJk51pbPQdpCe96
        TPVoeMAk/cUlAPpYh8zGpr6zssbM11Je1SoQTiuipxIL+c0oGXti8vLzln3yfS+N
        56wuSh0Hyt1Z+waSx6IDFlfzImEtq8m1osS32B83HRiFZbeKB8QIRJhZil1pJSzM
        sg0Y0QmDyv1yR4FzIQIDAQAB
        -----END PUBLIC KEY-----
        """

        guard let data = password.data(using: .utf8) else {
            return nil
        }

        // Encrypt the password
        if let encryptedData = encryptWithRSA(data: data, publicKey: publicKeyPEM) {
            // Convert the encrypted data to a Base64 encoded string
            return encryptedData.base64EncodedString()
        } else {
            // Handle error or return nil if encryption fails
            return nil
        }
    }


    static func encryptWithRSA(data: Data, publicKey: String) -> Data? {
        return data.withUnsafeBytes { rawBufferPointer -> Data? in
            let bufferPointer = rawBufferPointer.bindMemory(to: UInt8.self)
            if let baseAddress = bufferPointer.baseAddress {
                var outLen = Int32(0)
                if let encrypted = rsaEncrypt(baseAddress, bufferPointer.count, publicKey, &outLen), outLen > 0 {
                    return Data(bytesNoCopy: encrypted, count: Int(outLen), deallocator: .free)
                }
            }
            return nil
        }
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
