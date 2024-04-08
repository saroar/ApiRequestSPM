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
