//
//  LiveAPI.swift
//  LarkLive
//
//  Created by panzaofeng on 2021/10/29.
//

import Foundation
import LKCommonsLogging

public struct LiveConfig {
    let platform = "ios"
    let version = "1.0.0"
    let userAgent: String?
    let appID: String
    let deviceID: String
    let session: String
    let locale: String
    var larkVersion: String

    public static let `default` = LiveConfig()

    public init(appID: String = "",
                deviceID: String = "",
                session: String = "",
                locale: String = "zh_cn",
                userAgent: String? = nil,
                larkVersion: String = "") {
        self.appID = appID
        self.deviceID = deviceID
        self.session = session
        self.locale = locale
        self.userAgent = userAgent
        self.larkVersion = larkVersion

    }

    public func commonHeaders() -> [String: String] {
        var header: [String: String] = [:]
        header["User-Agent"] = userAgent
        header["Cookie"] = "session=\(session)"
        header["platform"] = platform
        header["app-id"] = appID
        header["device-id"] = deviceID
        header["m-version"] = version
        header["m-locale"] = locale
        header["lark-version"] = larkVersion
        return header
    }
}

open class LiveAPI {

    public static let logger = LKCommonsLogging.Logger.log(LiveAPI.self, category: "Networking")

    public static var config: LiveConfig {
        return globalAPI.config
    }

    public static var globalAPI: LiveAPI = LiveAPI(URL(fileURLWithPath: ""))

    public static var sessionConfiguration: URLSessionConfiguration {
        return globalAPI.sessionConfiguration
    }

    public static func setup(_ api: LiveAPI) {
        LiveAPI.globalAPI = api
    }

    public let baseURL: URL
    public var domain: String? {
        return baseURL.host
    }

    open var config: LiveConfig {
        return LiveConfig.default
    }

    open var sessionConfiguration: URLSessionConfiguration {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        sessionConfiguration.timeoutIntervalForRequest = 15
        var customHeaders = config.commonHeaders()
        customHeaders["Referer"] = baseURL.absoluteString
        sessionConfiguration.httpAdditionalHeaders = customHeaders
        return sessionConfiguration
    }

    public static let workQueue: DispatchQueue = DispatchQueue(label: "LarkLiveAPI", qos: .background, autoreleaseFrequency: .workItem)

    open func sendRequest<T: LarkLiveRequest>(_ request: T, useTTNet: Bool = true, completionHandler: @escaping (Result<T.ResponseType, Error>) -> Void) {
        fatalError("not implement")
    }
    
    open func sendRequest(_ urlString: String, method: RequestMethod, params: [String: Any], headers: [String: String], useTTNet: Bool = true, completionHandler: @escaping ((Data) -> Void), failureHandler: @escaping ((Error) -> Void)) {
        fatalError("not implement")
    }

    public init(_ baseURL: URL) {
        self.baseURL = baseURL
    }
}
