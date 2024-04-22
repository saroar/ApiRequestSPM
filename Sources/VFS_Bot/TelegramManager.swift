import Foundation
import Logging
import NIO

public struct TelegramManager {

    enum TMError: Error {
        case cantFindTelegramID
    }

    private let networkService: NetworkService
    private let botToken: String
    private let logger: Logger

    private var iso_to_chat_id = [
        "def": "-1001955986822",  // Default chat ID
        "ind": "-1002006211947",
        "uzb": "-1002017389400",
        "kaz": "-1002103748437",
        "tjk": "-1002103748437",
        // Add other mappings as needed
    ]

    public init(
        networkService: NetworkService
    ) {
        self.networkService = networkService
        self.botToken = "6268203001:AAFuSe5hk_0GGesecQznF3OLDPMJpdoXGrQ"
        self.logger = Logger(label: "com.telegram.main")
    }

    // Method to send messages
    func sendMessage(countryCode: CountryCode, text: String) async throws {
        let chatId = iso_to_chat_id[countryCode.rawValue] ?? iso_to_chat_id["def"]!

        do {

            let tsmPayload = TelegramSendMessage(chat_id: chatId, text: text)

             logger.info("\(tsmPayload.toJSONString())")

            let requestJSONBodyToByteBuffer = try tsmPayload.toByteBuffer()

            let _: EmptyResponse = try await networkService.request(
                endpoint: .telegram(botToken: self.botToken, method: .sendMessage),
                method: .POST,
                headers: [HTTPHeaderField.contentType.key: "application/json"],
                body: requestJSONBodyToByteBuffer
            )

            self.logger.info("Send msg to telegram channel \(countryCode.rawValue): \(text)")
            try await self.networkService.shutdown()

        } catch {
            logger.info("Failed to send message: \(error)")
            try await self.networkService.shutdown()
            throw error
        }
    }
}


struct TelegramManagerClient {
    var sendMessage: @Sendable (CountryCode, String) async throws -> Void
    var sendDocument: @Sendable (CountryCode, URL) async throws -> Void // _, path
}

extension TelegramManagerClient {

    public static func live(
        networkService: NetworkService
    ) -> Self {
        let logger: Logger = .init(label: "com.telegram.main")

        let iso_to_chat_id = [
            "def": "-1001955986822",  // Default chat ID
            "ind": "-1002006211947",
            "uzb": "-1002017389400",
            "kaz": "-1002103748437",
            "tjk": "-1002103748437",
            // Add other mappings as needed
        ]

        let botToken = "6268203001:AAFuSe5hk_0GGesecQznF3OLDPMJpdoXGrQ"

        return Self(
            sendMessage: { countryCode, message in
                let chatId = iso_to_chat_id[countryCode.rawValue] ?? iso_to_chat_id["def"]!

                do {

                    let tsmPayload = TelegramSendMessage(chat_id: chatId, text: message)

//                     logger.info("\(tsmPayload.toJSONString())")

                    let _: EmptyResponse = try await networkService.request(
                        endpoint: .telegram(botToken: botToken, method: .sendMessage),
                        method: .POST,
                        headers: [HTTPHeaderField.contentType.key: "application/json"],
                        queryParameters: tsmPayload
                    )

                    // Response: {"ok":true,"result":{"message_id":354,"sender_chat":{"id":-1002017389400,"title":"Uzb VFS","type":"channel"},"chat":{"id":-1002017389400,"title":"Uzb VFS","type":"channel"},"date":1713734042,"text":"Hello there"}}
                    logger.info("Send msg to telegram channel \(countryCode.rawValue): \(message)")

                } catch {
                    logger.info("Failed to send message: \(error)")
                    throw error
                }
            },

                sendDocument: { countryCode, fileURL in

                    let chatId = iso_to_chat_id[countryCode.rawValue] ?? iso_to_chat_id["def"]!

                    do {

                        let boundary = "Boundary-\(UUID().uuidString)"
                        var body = ByteBuffer()

                        // Read file data
                        let fileData = try Data(contentsOf: fileURL)
                        let filename = fileURL.lastPathComponent

                        // Append chat_id part
                        body.writeString("--\(boundary)\r\n")
                        body.writeString("Content-Disposition: form-data; name=\"chat_id\"\r\n\r\n")
                        body.writeString("\(chatId)\r\n")

                        // Append document part
                        body.writeString("--\(boundary)\r\n")
                        body.writeString("Content-Disposition: form-data; name=\"document\"; filename=\"\(filename)\"\r\n")
                        body.writeString("Content-Type: application/octet-stream\r\n\r\n")
                        body.writeBytes(fileData)
                        body.writeString("\r\n--\(boundary)--\r\n")

                        let _: EmptyResponse = try await networkService.request(
                            endpoint: .telegram(botToken: botToken, method: .sendDocument),
                            method: .POST,
                            headers: [HTTPHeaderField.contentType.key: "multipart/form-data; boundary=\(boundary)"],
                            body: body
                        )

                        logger.info("Send msg to telegram channel \(countryCode.rawValue): \(fileURL)")

                    } catch {
                        logger.info("Failed to send message: \(error)")
                        throw error
                    }
                }
        )
    }
}

struct MessagePayload: Encodable {
    let chatId: String
    let text: String
}

struct EmptyResponse: Decodable {}

struct TelegramSendMessage: Codable {
    let chat_id: String
    let text: String
}


struct TelegramSendDocument: Codable {
    let chat_id: String
    let document: URL // its file path
    var caption: String? = nil
}
