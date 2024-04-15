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
}
