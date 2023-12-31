//
//  MinutesAPI.swift
//  MinutesFoundation
//
//  Created by lvdaqian on 2021/1/13.
//

import Foundation
import LKCommonsLogging
import LarkStorage
import LarkEnv

public struct MinutesConfig {
    let platform = "ios"
    let version = "1.0.0"
    let userAgent: String?
    let appID: String
    let deviceID: String
    let session: String
    let locale: String
    var larkVersion: String

    public static let `default` = MinutesConfig()

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
        if EnvManager.env.type == .staging {
            if let boeFeatureEnv = KVPublic.Common.ttenv.value(), boeFeatureEnv.isEmpty == false {
                header["x-tt-env"] = boeFeatureEnv
            }
        }
        return header
    }
}

open class MinutesAPI {

    public static let logger = Logger.log(MinutesAPI.self, category: "Networking")

    public static var config: MinutesConfig {
        return globalAPI.config
    }

    private static var globalAPI: MinutesAPI = MinutesAPI(URL(fileURLWithPath: ""))

    public static var sessionConfiguration: URLSessionConfiguration {
        return globalAPI.sessionConfiguration
    }

    public static func setup(_ api: MinutesAPI) {
        MinutesAPI.globalAPI = api
    }

    public static func clone(_ baseURL: URL? = nil, config: MinutesConfig? = nil) -> MinutesAPI {
        if baseURL == nil, config == nil {
            return globalAPI
        } else {
            return globalAPI.clone(baseURL, config: config)
        }
    }

    public static func buildURL(for objectToken: String, base url: URL? = nil) -> URL {
        let domain = globalAPI.domain
        let isPre = domain.contains("-pre") && domain.replacingOccurrences(of: "-pre", with: "") == url?.host
        if let customURL = url, !isPre {
            return customURL
        }

        return URL(string: "https://\(globalAPI.domain)/minutes/\(objectToken)")!
    }

    public var baseURL: URL
    public var domain: String {
        return baseURL.host ?? ""
    }

    open var config: MinutesConfig {
        return MinutesConfig.default
    }

    open var sessionConfiguration: URLSessionConfiguration {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let timeoutIntervalForRequest: TimeInterval = 15
        sessionConfiguration.timeoutIntervalForRequest = timeoutIntervalForRequest
        var customHeaders = config.commonHeaders()
        customHeaders["Referer"] = baseURL.absoluteString
        sessionConfiguration.httpAdditionalHeaders = customHeaders
        return sessionConfiguration
    }

    public static let workQueue: DispatchQueue = DispatchQueue(label: "MinutesAPI", qos: .background, autoreleaseFrequency: .workItem)

    open func sendRequest<T: Request>(_ request: T, completionHandler: @escaping (Result<T.ResponseType, Error>) -> Void) {
        fatalError("not implement")
    }

    open func upload<T: UploadRequest>(_ request: T, completionHandler: @escaping (Result<T.ResponseType, Error>) -> Void) {
        fatalError("not implement")
    }

    open func clone(_ baseURL: URL? = nil, config: MinutesConfig? = nil) -> MinutesAPI {
        fatalError("not implement")
    }

    public init(_ baseURL: URL) {
        self.baseURL = baseURL
    }
}
