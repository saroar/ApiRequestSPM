import AsyncHTTPClient
import Foundation
import NIOCore
import NIOHTTP1
import Logging

// Refactor the networking into its own struct
public struct NetworkService {

    enum NetworkServiceError: Error {
        case decoderError(String?), invalidPayload, requestFailed
    }

    private let httpClient: HTTPClient
    private let logger = Logger(label: "com.networkService.main")


    // Adjusted initializer
    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    func getIPRequest<T: Decodable>(
        from url: String,
        queryParameters: [String: String]? = nil,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil
    ) async throws -> T {


        var request = HTTPClientRequest(url: url)
        request.method = .GET

        additionalHeaders?.forEach({
            request.headers.add(name: $0.0.key, value: $0.1)
        })

        // Execute the request
        let response: HTTPClientResponse = try await httpClient.execute(request, timeout: .seconds(6))

        let bodyData = try await response.body.collect(upTo: 4096 * 4096)
        // Convert ByteBuffer to Data
        let data = Data(buffer: bodyData)

        do {
            let response = try JSONDecoder().decode(T.self, from: data)
            return response

        } catch {
            throw NetworkServiceError.invalidPayload // Or a more specific error for decoding failure
        }

    }

    func getRequest<T: Decodable>(
        from endpoint: APIEndpoint,
        queryParameters: Encodable? = nil,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil
    ) async throws -> T {

        var urlComponents = URLComponents(string: endpoint.rawValue)!

        if let queryParameters = queryParameters {
            let queryItems = try queryParameters.toQueryItems()
            urlComponents.queryItems = queryItems
        }

        var request = HTTPClientRequest(url: urlComponents.url!.absoluteString)
        request.method = .GET

        additionalHeaders?.forEach({
            request.headers.add(name: $0.0.key, value: $0.1)
        })

        // Execute the request
        let response: HTTPClientResponse = try await httpClient.execute(request, timeout: .seconds(30))

        let bodyData = try await response.body.collect(upTo: 134217728) // 128MB
        // Convert ByteBuffer to Data
        let data = Data(buffer: bodyData)

//        if let rawResponseString = String(data: data, encoding: .utf8) {
//            logger.info("Raw response string: \(rawResponseString)")
//        } else if let rawResponseString = String(data: data, encoding: .isoLatin1) {
//            logger.info("Raw response string with ISO-8859-1: \(rawResponseString)")
//        } else {
//            logger.info("Failed to convert response data to string")
//        }

        do {
            let decoder = JSONDecoder()
            decoder.setDateDecodingStrategy(.multipleFormatters([
                DateFormatter.sharedDateMDYFormatter,
                DateFormatter.sharedDateDMYFormatter,
                DateFormatter.sharedISO8601Formatter,
                DateFormatter.sharedDateMDYHMSFormatter,
                DateFormatter.sharedDateFormatYMDFormatter,
            ]))

            let response = try decoder.decode(T.self, from: data)

            return response

        } catch let error as DecodingError {
            switch error {
            case .dataCorrupted(let context):
                logger.error("Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                logger.error("Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                logger.error("Value '\(type)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            @unknown default:
                logger.error("Unknown decoding error: \(error)")
            }

            throw NetworkServiceError.decoderError(error.localizedDescription)
        } catch {
            logger.error("\(error.localizedDescription)")
            throw NetworkServiceError.decoderError(error.localizedDescription)
        }

    }

    // Generic method to perform POST requests with an Encodable payload
    func postWithBodyStringRequest<T: Encodable, R: Decodable>(
        to endpoint: APIEndpoint,
        payload: T,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil
    ) async throws -> R {

        guard let requestBodyString = payload.toURLEncodedFormData(),
              let bodyData = requestBodyString.data(using: .utf8)
        else {
            throw NetworkServiceError.invalidPayload
        }

        var request = HTTPClientRequest(url: endpoint.fullPath)
        request.method = .POST

        // Add headers from the enum
        HTTPHeaderField.applyDefaultHeaders(
            to: &request,
            withOptionalHeaders: additionalHeaders
        )

        request.body = .bytes(.init(data: bodyData))
        

        let response = try await httpClient.execute(request, timeout: .seconds(30))
        logger.info("ResStatus: \(response.status.code) - \(response.status.reasonPhrase)")

        let resBodyData = try await response.body.collect(upTo: 134217728) // Adjust the size as needed
        let data = Data(buffer: resBodyData)

//        guard let bodyString = resBodyData.getString(at: 0, length: resBodyData.readableBytes) else {
//            throw NetworkServiceError.requestFailed
//        }
//        print("bodyString", bodyString)

        do {
            let decoder = JSONDecoder()
            decoder.setDateDecodingStrategy(.multipleFormatters([
                DateFormatter.sharedDateMDYFormatter,
                DateFormatter.sharedISO8601Formatter,
                DateFormatter.sharedDateMDYHMSFormatter,
                DateFormatter.sharedDateFormatYMDFormatter,
            ]))

            let response = try decoder.decode(R.self, from: data)

            return response

        } catch let error as DecodingError {
            switch error {
            case .dataCorrupted(let context):
                    logger.error("Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                    logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                    logger.error("Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                    logger.error("Value '\(type)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            @unknown default:
                    logger.error("Unknown decoding error: \(error)")
            }

            try await self.httpClient.shutdown()
            throw NetworkServiceError.decoderError(error.localizedDescription)
        } catch {
            logger.error("\(error.localizedDescription)")
            try await self.httpClient.shutdown()
            throw NetworkServiceError.decoderError(error.localizedDescription)
        }

    }

    // Generic method to perform POST requests with an Encodable payload
    func postWithJSONBodyRequest<T: Encodable, R: Decodable>(
        to endpoint: APIEndpoint,
        payload: T,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil,
        headersToRemove: [HTTPHeaderField]? = nil
    ) async throws -> R {

        var request = HTTPClientRequest(url: endpoint.fullPath)
        request.method = .POST

        // Add headers from the enum
        HTTPHeaderField.applyDefaultHeaders(
            to: &request,
            withOptionalHeaders: additionalHeaders
        )

        // Remove specified headers
        if let headersToRemove = headersToRemove {
            for header in headersToRemove {
                request.headers.remove(name: header.key) // Assuming HTTPHeaderField.rawValue gives the string representation
            }
        }

        let bodyBuffer = try payload.toByteBuffer()
        request.body = .bytes(bodyBuffer)

        let response = try await httpClient.execute(request, timeout: .seconds(30))

        let resBodyData = try await response.body.collect(upTo: 134217728) // Adjust the size as needed
        let data = Data(buffer: resBodyData)

//        guard let bodyString = resBodyData.getString(at: 0, length: resBodyData.readableBytes) else {
//            throw NetworkServiceError.requestFailed
//        }
//        self.logger.info("Raw response string:  \(bodyString)")
//
//
//        if let rawResponseString = String(data: data, encoding: .utf8) {
//            logger.info("Raw response string: \(rawResponseString)")
//        } else if let rawResponseString = String(data: data, encoding: .isoLatin1) {
//            logger.info("Raw response string with ISO-8859-1: \(rawResponseString)")
//        } else {
//            logger.info("Failed to convert response data to string")
//        }

        do {
            let decoder = JSONDecoder()
            decoder.setDateDecodingStrategy(.multipleFormatters([
                DateFormatter.sharedDateMDYFormatter,
                DateFormatter.sharedISO8601Formatter,
                DateFormatter.sharedDateMDYHMSFormatter,
                DateFormatter.sharedDateFormatYMDFormatter,
            ]))

            let response = try decoder.decode(R.self, from: data)

            return response

        } catch let error as DecodingError {
            switch error {
            case .dataCorrupted(let context):
                    logger.error("Data corrupted: \(context)")
            case .keyNotFound(let key, let context):
                    logger.error("Key '\(key.stringValue)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .typeMismatch(let type, let context):
                    logger.error("Type '\(type)' mismatch: \(context.debugDescription), codingPath: \(context.codingPath)")
            case .valueNotFound(let type, let context):
                    logger.error("Value '\(type)' not found: \(context.debugDescription), codingPath: \(context.codingPath)")
            @unknown default:
                    logger.error("Unknown decoding error: \(error)")
            }

            try await self.httpClient.shutdown()
            throw NetworkServiceError.decoderError(error.localizedDescription)
        } catch {
            logger.error("\(#line) \(error)")
            try await self.httpClient.shutdown()
            throw NetworkServiceError.decoderError(error.localizedDescription)
        }
    }

    func shutdown() async throws {
        try await self.httpClient.shutdown()
    }

}
