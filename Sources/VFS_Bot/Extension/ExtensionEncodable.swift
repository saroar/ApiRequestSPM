import Foundation
import NIOCore
import NIOFoundationCompat

//extension Encodable {
//    /// Converts an `Encodable` instance to a `ByteBuffer`.
//    /// - Parameters:
//    ///   - allocator: The `ByteBufferAllocator` used to allocate the `ByteBuffer`.
//    /// - Returns: A `ByteBuffer` containing the JSON-encoded representation of the instance.
//    /// - Throws: An error if the instance could not be encoded.
//    public func toByteBuffer(allocator: ByteBufferAllocator = ByteBufferAllocator()) throws -> ByteBuffer {
//        let jsonData = try JSONEncoder().encode(self)
//        var buffer = allocator.buffer(capacity: jsonData.count)
//        buffer.writeBytes(jsonData)
//        return buffer
//    }
//}


extension Encodable {
    func toQueryItems() throws -> [URLQueryItem] {
        let encoder = JSONEncoder() // You can use any encoder that conforms to Encoder
        let data = try encoder.encode(self)

        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [], debugDescription: "Failed to convert to dictionary"))
        }

        return dictionary.map { URLQueryItem(name: $0.key, value: String(describing: $0.value)) }
    }

    func prettyPrinted() -> String {
        let encoder = JSONEncoder()
        encoder.setDateEncodingStrategy(.multipleFormatters([
            DateFormatter.sharedDateMDYFormatter,
            DateFormatter.sharedDateDMYFormatter,
            DateFormatter.iso8601FormatterWithoutMilliseconds,
            DateFormatter.iso8601FormatterWithMilliseconds,
            DateFormatter.sharedDateMDYHMSFormatter,
            DateFormatter.sharedDateFormatYMDFormatter,
        ]))

//        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(self)
            if let jsonString = String(data: data, encoding: .utf8) {
                return jsonString
            } else {
                return "Failed to convert JSON data to string."
            }
        } catch {
            return "Failed to encode to JSON: \(error)"
        }
    }
}
