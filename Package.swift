// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "VFS_Bot",
    platforms: [
        .macOS(.v13)  // Updated to a valid version number
    ],
    products: [
        .library(
            name: "VFS_Bot",
            targets: [
                "VFS_Bot",
                "CXXLibrary"
            ]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.38.0"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "VFS_Bot",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                "CXXLibrary"
            ],
            path: "Sources/VFS_Bot"
        ),
        .target(
            name: "CXXLibrary",
            dependencies: [],
            path: "Sources/CXXLibrary",
            sources: ["RSACrypto.cpp"],
            publicHeadersPath: "Include",
            cxxSettings: [
                .headerSearchPath("Include"),
                .headerSearchPath("Include/OpenSSL"),  // Assuming this contains custom or necessary configuration
                .unsafeFlags(["-I/opt/homebrew/opt/openssl@3/include"], .when(platforms: [.macOS]))  // Corrected path
            ],
            linkerSettings: [
                .linkedLibrary("ssl"),
                .linkedLibrary("crypto"),
                .unsafeFlags(["-L/opt/homebrew/opt/openssl@3/lib"], .when(platforms: [.macOS]))  // Corrected path
            ]
        ),
        .testTarget(
            name: "VFS_BotTests",
            dependencies: ["VFS_Bot"]),
    ]
)



//import PackageDescription
//
//let package = Package(
//    name: "VFS_Bot",
//    platforms: [
//        .macOS(.v13)
//    ],
//    products: [
//        // Products define the executables and libraries a package produces, making them visible to other packages.
//        .executable(name: "VFS_Bot2", targets: ["VFS_Bot2"]),
//    ],
//    dependencies: [
//        .package(url: "https://github.com/apple/swift-nio.git", from: "2.38.0"),
//        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
//        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
//        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.2")
//    ],
//    targets: [
//        .executableTarget(
//            name: "VFS_Bot2",
//            dependencies: [
//                .product(name: "Logging", package: "swift-log"),
//                .product(name: "NIOCore", package: "swift-nio"),
//                .product(name: "AsyncHTTPClient", package: "async-http-client"),
//                .product(name: "CryptoSwift", package: "CryptoSwift")
//            ]
//        )
//    ]
//)
