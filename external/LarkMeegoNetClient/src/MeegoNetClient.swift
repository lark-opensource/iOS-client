//
//  MeegoNetClient.swift
//  LarkMeegoPush
//
//  Created by ByteDance on 2022/7/20.
//

import Foundation
import LarkMeegoLogger

public struct MeegoNetClientConfig {
    public let isFeishuPackage: Bool
    public let isFeishuBrand: Bool
    public let tenantBrand: String

    let platform = "ios"
    let deviceID: String
    let appVersion: String
    let locale: String

    let appID: String
    let appHost: String
    let userAgent: String?

    public let isBoe: Bool
    public let isPPE: Bool
    let ttEnv: String?

    // swiftlint:disable line_length
    public static let `default` = MeegoNetClientConfig(deviceID: "", appVersion: "", locale: "", appID: "", appHost: "", userAgent: "", ttEnv: "", isFeishuPackage: true, isFeishuBrand: true, tenantBrand: "", isBoe: false, isPPE: false)
    // swiftlint:enable line_length

    public init(deviceID: String,
                appVersion: String,
                locale: String,
                appID: String,
                appHost: String,
                userAgent: String?,
                ttEnv: String?,
                isFeishuPackage: Bool,
                isFeishuBrand: Bool,
                tenantBrand: String,
                isBoe: Bool = false,
                isPPE: Bool = false) {
        self.deviceID = deviceID
        self.appVersion = appVersion
        self.locale = locale
        self.appID = appID
        self.appHost = appHost
        self.userAgent = userAgent
        self.ttEnv = ttEnv
        self.isFeishuPackage = isFeishuPackage
        self.isFeishuBrand = isFeishuBrand
        self.tenantBrand = tenantBrand
        self.isBoe = isBoe
        self.isPPE = isPPE
    }

    /// Meego Network HeaderField 约定
    /// https://bytedance.feishu.cn/wiki/wikcnx1Pw86Bm51qNFCTCllnI0e
    public func commonHeaders() -> [String: String] {
        var header: [String: String] = [:]
        header["Content-Type"] = "application/json"

        header[MeegoHeaderKeys.platform] = platform  // 接口明确必填
        header[MeegoHeaderKeys.deviceId] = deviceID  // 接口明确必填
        header[MeegoHeaderKeys.appVersion] = appVersion    // 接口明确必填
        header[MeegoHeaderKeys.locale] = locale  // 接口明确必填 - BFF网关依赖 
        header[MeegoHeaderKeys.contentLanguage] = locale  // 适配接口明确必填 - LGW网关依赖 

        header[MeegoHeaderKeys.appId] = appID
        header[MeegoHeaderKeys.appHost] = appHost    // 接口明确必填
        header[MeegoHeaderKeys.userAgent] = userAgent

        header[MeegoHeaderKeys.clientPipe] = isBoe ? "dev" : "release"

        // BOE环境标设置
        if isBoe && !(ttEnv?.isEmpty ?? true) {
            header[MeegoHeaderKeys.ttEnv] = ttEnv
        }

        // PPE环境标设置
        if !isBoe && isPPE {
            header[MeegoHeaderKeys.ttUsePPE] = "1"
            if !(ttEnv?.isEmpty ?? true) {
                header[MeegoHeaderKeys.ttEnv] = ttEnv
            }
        }
        return header
    }
}

open class MeegoNetClient {
    public let baseURL: URL

    public var domain: String {
        return baseURL.host ?? ""
    }

    open var config: MeegoNetClientConfig {
        return MeegoNetClientConfig.default
    }

    open func sendRequest<T: Request>(_ request: T, completionHandler: @escaping (Result<T.ResponseType, APIError>) -> Void) {
        let msg = "MeegoNetClient sendRequest func do not implement."
        assertionFailure(msg)
        MeegoLogger.error(msg)
    }

    public init(_ baseURL: URL) {
        self.baseURL = baseURL
    }
}
