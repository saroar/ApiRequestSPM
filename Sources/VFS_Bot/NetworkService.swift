import AsyncHTTPClient
import Foundation
import NIOCore
import NIOHTTP1
import Logging


public class NetworkService {

    enum NetworkServiceError: Error {
        case decodingError(String), invalidPayload, requestFailed, urlBuildFailed
    }

    private let httpClient: HTTPClient
    private let logger: Logger

    public init(httpClient: HTTPClient) {
        self.httpClient = httpClient
        self.logger = Logger(label: "com.networkService.main")
    }

    deinit {
        do {
            try self.httpClient.syncShutdown()
        } catch {
            logger.error("deint sd issue \(error)")
        }
    }

    public func request<T: Decodable>(
        endpoint: APIEndpoint,
        method: HTTPMethod,
        headers: HTTPHeaders,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil,
        queryParameters: Encodable? = nil,
        body: ByteBuffer? = nil,
        timeout: TimeAmount = .seconds(30),
        maxSize: Int = 134217728,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async throws -> T {
        logger.info("Request called from \(function) at line \(line)")

        guard var urlComponents = URLComponents(string: endpoint.fullPath) else {
            logger.error("Failed to urlComponents URL with provided components.")
            throw NetworkServiceError.urlBuildFailed
        }

        if let queryParameters = queryParameters {
            do {
                let queryItems = try queryParameters.toQueryItems()
                urlComponents.queryItems = queryItems

            } catch {
                logger.error("Failed to encode query parameters: \(error)")
                throw NetworkServiceError.urlBuildFailed
            }
        }

        // Final URL from URLComponents
        guard let finalURL = urlComponents.url else {
            logger.error("Failed to build final URL with provided components.")
            throw NetworkServiceError.urlBuildFailed
        }

        var request = HTTPClientRequest(url: finalURL.absoluteString)
        request.method = method
        request.headers = headers

        additionalHeaders?.forEach({
            request.headers.add(name: $0.0.key, value: $0.1)
        })

        if let body = body {
            request.body = .bytes(body)
        }

        let response = try await httpClient.execute(request, timeout: timeout)
        let bodyData = try await response.body.collect(upTo: maxSize)
        let data = Data(buffer: bodyData)


//        if let rawResponseString = String(data: data, encoding: .utf8) {
//            logger.info("Raw response string: \(rawResponseString)")
//        } else if let rawResponseString = String(data: data, encoding: .isoLatin1) {
//            logger.info("Raw response string with ISO-8859-1: \(rawResponseString)")
//        } else {
//            logger.info("Failed to convert response data to string")
//        }
        
        let route = request.headers[HTTPHeaderField.route.key].last ?? ""
        logger.info("URL: \(endpoint.path) Res Status: \(response.status.code) - \(response.status.reasonPhrase) -> Route: \(route)")

        do {
            let decoder = JSONDecoder()
            decoder.setDateDecodingStrategy(.multipleFormatters([
                DateFormatter.sharedDateMDYFormatter,
                DateFormatter.sharedDateDMYFormatter,
                DateFormatter.iso8601FormatterWithoutMilliseconds,
                DateFormatter.iso8601FormatterWithMilliseconds,
                DateFormatter.sharedDateMDYHMSFormatter,
                DateFormatter.sharedDateFormatYMDFormatter,
            ]))

            let decodedResponse = try decoder.decode(T.self, from: data)
            return decodedResponse

        } catch let error as DecodingError {
            if let rawResponseString = String(data: data, encoding: .utf8) {
                logger.info("Raw response string: \(rawResponseString)")
            } else if let rawResponseString = String(data: data, encoding: .isoLatin1) {
                logger.info("Raw response string with ISO-8859-1: \(rawResponseString)")
            } else {
                logger.info("Failed to convert response data to string")
            }

            self.logDecodingError(error)
            throw NetworkServiceError.decodingError(error.localizedDescription)
        }  catch {
            logger.error("Error: \(error.localizedDescription) \(file) from \(endpoint.path)")
            throw NetworkServiceError.decodingError(error.localizedDescription)
        }
    }

    private func createHeaders(_ additionalHeaders: [(HTTPHeaderField, String)]?) -> HTTPHeaders {
        var headers = HTTPHeaders()
        additionalHeaders?.forEach { headers.add(name: $0.0.key, value: $0.1) }
        return headers
    }

    func shutdown() async throws {
        try await httpClient.shutdown()
    }
}


extension NetworkService {
    private func logDecodingError(_ error: DecodingError) {
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
    }
}
