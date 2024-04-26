import Logging
import NIOHTTP1
import AsyncHTTPClient

//@main
//struct VFS_Bot2 {
//    static func main(country: CountryCode, missionCode: CountryCode) async throws -> Void {
//        logger.info("Start main")
////        let result = try await setupAndStart()
//
//        let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
//
//        let networkService = NetworkService(httpClient: httpClient)
//        let result = try await BotManager(
//            networkService: networkService, 
//            caQuery: .init(countryCode: country, missionCode: missionCode)
//        )
//        .run()
//
//        logger.info("End main \(result)")
//
//        return result
//    }
//}

func main_run(country: CountryCode, missionCode: CountryCode) async throws -> Void {
    print("Start main")

    let httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    let networkService = NetworkService(httpClient: httpClient)
    let result = try await BotManager(
        requestSleepSec: 180,
        nanoseconds: 800_000_000, // 1_000_000_000 1 sec
        caQuery: .init(countryCode: country, missionCode: missionCode),
        networkService: networkService,
        telegramManager: .init(networkService: networkService)
    )
    .run()

    print("End main \(result)")

    return result
}
