import XCTest
@testable import VFS_Bot

final class VFS_BotTests: XCTestCase {
    func testExample() async throws {

//        try await setupAndStart()
        try await main_run(country: .USA, missionCode: .PORTUGAL)

    }
}
