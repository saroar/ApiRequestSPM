import AsyncHTTPClient
import Foundation
import NIOCore
import NIOHTTP1

// Refactor the networking into its own struct
struct NetworkService {

    enum NetworkServiceError: Error {
        case invalidPayload, requestFailed
    }

    private let httpClient: HTTPClient

    // Adjusted initializer
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    // Generic method to perform POST requests with an Encodable payload
    mutating func postWithBodyStringRequest<T: Encodable>(
        to endpoint: APIEndpoint,
        payload: T,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil
    ) async throws -> HTTPClientResponse {

        print("Payload", payload)
        guard let requestBodyString = payload.toURLEncodedFormData(),
              let data = requestBodyString.data(using: .utf8)
        else {
            print("Payload missing")
            throw NetworkServiceError.invalidPayload
        }

        var request = HTTPClientRequest(url: endpoint.fullPath)
        request.method = .POST

        // Add headers from the enum
        HTTPHeaderField.applyDefaultHeaders(
            to: &request,
            withOptionalHeaders: additionalHeaders
        )


        request.body = .bytes(.init(data: data))

        return try await httpClient.execute(request, timeout: .seconds(30))
    }

    // Generic method to perform POST requests with an Encodable payload
    mutating func postWithJSONBodyRequest<T: Encodable>(
        to endpoint: APIEndpoint,
        payload: T,
        additionalHeaders: [(HTTPHeaderField, String)]? = nil,
        headersToRemove: [HTTPHeaderField]? = nil
    ) async throws -> HTTPClientResponse {

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

        return try await httpClient.execute(request, timeout: .seconds(30))
    }


    func shutdown() async throws {
        try await self.httpClient.shutdown()
    }

}
