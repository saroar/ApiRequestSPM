
import NIOHTTP1
import Foundation
import AsyncHTTPClient

public enum HTTPHeaderField: CaseIterable {
    case host
    case authority
    case authorize
    case clientSource
    case accept
    case acceptLanguage
    case cacheControl
    case connection
    case dnt
    case origin
    case pragma
    case referer
    case secFetchDest
    case secFetchMode
    case secFetchSite
    case userAgent
    case secCHUA
    case secCHUAMobile
    case secCHUAPlatform
    case contentType
    case route
    case acceptEncoding
    case secGpc

    public var key: String {
        switch self {
            case .host: return "Host"
            case .authority: return "authority"
            case .authorize: return "authorize"
            case .accept: return "Accept"
            case .acceptLanguage: return "Accept-Language"
            case .cacheControl: return "Cache-Control"
            case .connection: return "Connection"
            case .dnt: return "DNT"
            case .origin: return "Origin"
            case .pragma: return "Pragma"
            case .referer: return "Referer"
            case .secFetchDest: return "Sec-Fetch-Dest"
            case .secFetchMode: return "Sec-Fetch-Mode"
            case .secFetchSite: return "Sec-Fetch-Site"
            case .userAgent: return "User-Agent"
            case .secCHUA: return "sec-ch-ua"
            case .secCHUAMobile: return "sec-ch-ua-mobile"
            case .secCHUAPlatform: return "sec-ch-ua-platform"
            case .contentType: return "Content-Type"
            case .route: return "route"
            case .acceptEncoding: return "Accept-Encoding"
            case .secGpc: return "sec-gpc"
            case .clientSource: return "cientSource"
        }
    }
//    Accept-Language: en-GB,en;q=0.9

    public var value: String {
        switch self {
            case .host, .authority: return "lift-api.vfsglobal.com"
            case .authorize: return ""
            case .accept: return "application/json, text/plain, */*"
            case .acceptLanguage: return "en-GB,en-US;q=0.9,en;q=0.8"
            case .cacheControl, .pragma: return "no-cache"
            case .connection: return "keep-alive"
            case .dnt: return "1"
            case .origin: return "https://visa.vfsglobal.com"
            case .referer: return "https://visa.vfsglobal.com/"
            case .secFetchDest: return "empty"
            case .secFetchMode: return "cors"
            case .secFetchSite: return "same-site"
            case .userAgent: return "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            case .secCHUA: return "\"Chromium\";v=\"118\", \"Google Chrome\";v=\"118\", \"Not=A?Brand\";v=\"99\""
            case .secCHUAMobile: return "?0"
            case .secCHUAPlatform: return "\"macOS\""
            case .contentType: return "application/json;charset=UTF-8"
            case .route: return "uzb/en/ltp"
            case .acceptEncoding: return "gzip, deflate"
            case .secGpc: return "1"
            case .clientSource: return "clientSource"
        }
    }


    static func applyVFSHeaders(withOptionalHeaders optionalHeaders: [(HTTPHeaderField, String)]? = nil) -> HTTPHeaders {
        var headers = HTTPHeaders()

        // Default headers
        headers.add(name: HTTPHeaderField.host.key, value: HTTPHeaderField.host.value)
        headers.add(name: HTTPHeaderField.authority.key, value: HTTPHeaderField.authority.value)
        headers.add(name: HTTPHeaderField.accept.key, value: HTTPHeaderField.accept.value)
        headers.add(name: HTTPHeaderField.acceptLanguage.key, value: HTTPHeaderField.acceptLanguage.value)
        headers.add(name: HTTPHeaderField.cacheControl.key, value: HTTPHeaderField.cacheControl.value)
        headers.add(name: HTTPHeaderField.connection.key, value: HTTPHeaderField.connection.value)
        headers.add(name: HTTPHeaderField.dnt.key, value: HTTPHeaderField.dnt.value)
        headers.add(name: HTTPHeaderField.origin.key, value: HTTPHeaderField.origin.value)
        headers.add(name: HTTPHeaderField.pragma.key, value: HTTPHeaderField.pragma.value)
        headers.add(name: HTTPHeaderField.referer.key, value: HTTPHeaderField.referer.value)
        headers.add(name: HTTPHeaderField.secFetchDest.key, value: HTTPHeaderField.secFetchDest.value)
        headers.add(name: HTTPHeaderField.secFetchMode.key, value: HTTPHeaderField.secFetchMode.value)
        headers.add(name: HTTPHeaderField.secFetchSite.key, value: HTTPHeaderField.secFetchSite.value)
        headers.add(name: HTTPHeaderField.userAgent.key, value: HTTPHeaderField.userAgent.value)
        headers.add(name: HTTPHeaderField.secCHUA.key, value: HTTPHeaderField.secCHUA.value)
        headers.add(name: HTTPHeaderField.secCHUAMobile.key, value: HTTPHeaderField.secCHUAMobile.value)
        headers.add(name: HTTPHeaderField.secCHUAPlatform.key, value: HTTPHeaderField.secCHUAPlatform.value)
        headers.add(name: HTTPHeaderField.acceptEncoding.key, value: HTTPHeaderField.acceptEncoding.value)

        // Optional headers
        optionalHeaders?.forEach { headerField, value in
            headers.replaceOrAdd(name: headerField.key, value: value)
        }

        return headers
    }
}
