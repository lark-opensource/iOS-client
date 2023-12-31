//
//  LarkMeegoNetClientHelper.swift
//  MeegoMod
//
//  Created by ByteDance on 2022/7/28.
//

import Foundation
import LarkFoundation
import LarkContainer
import LarkAccountInterface
import LarkEnv
import LarkReleaseConfig
import LarkLocalizations
import LarkMeego
import LarkSetting
import LarkMeegoNetClient
import LarkMeegoLogger

enum MeegoDefaultBaseURL {
    static let scheme = "https://"
    static let meego = "meego"
    static let project = "project"
    static let primaryDomain = "cn"
    static let secondaryDomain = "feishu"
    static let dot = "."
}

final class LarkMeegoNetClientHelper {
    private let passportService: PassportService
    private let passportUserService: PassportUserService

    init(userResolver: UserResolver) throws {
        passportService = try userResolver.resolve(assert: PassportService.self)
        passportUserService = try userResolver.resolve(assert: PassportUserService.self)
    }

    func createNetConfig() -> MeegoNetClientConfig {
        #if ALPHA
        let ttEnv = canDebug ? MeegoEnv.get(.ttEnv) : ""
        #else
        let ttEnv = ""
        #endif
        let config = MeegoNetClientConfig(deviceID: passportService.deviceID,
                                          appVersion: LarkFoundation.Utils.appVersion,
                                          locale: LanguageManager.locale.languageCode ?? "zh",   // 需传入"zh"、"en"，后端目前不认"zh-CN"、"en-US"
                                          appID: ReleaseConfig.appIdForAligned,
                                          appHost: "lark",
                                          userAgent: LarkFoundation.Utils.userAgent,
                                          ttEnv: ttEnv,
                                          isFeishuPackage: ReleaseConfig.isFeishu,
                                          isFeishuBrand: passportService.isFeishuBrand,
                                          tenantBrand: passportUserService.userTenantBrand.rawValue,
                                          isBoe: canDebug ? EnvManager.env.isStaging : false,
                                          isPPE: isPPE)
        return config
    }

    func getMeegoBaseURL() -> URL {
        // 动态域名，用户态，切租户时需刷新。
        // https://cloud-boe.bytedance.net/appSettings-v2/detail/config/121646/detail/whitelist-detail/116474

        var hostStr: String = {
            // 内部租户
            if passportUserService.userTenant.tenantID == "1" {
                return DomainSettingManager.shared.currentSetting["mg_meego"]?.first ?? meegoDefaultDomain
            } else {
                // 外部租户
                return DomainSettingManager.shared.currentSetting["mg_project"]?.first ?? projectDefaultDomain
            }
        }()

        MeegoLogger.info("getMeegoBaseURL with \(hostStr).")
        guard let baseURL = URL(string: (MeegoDefaultBaseURL.scheme + hostStr)) else {
            MeegoLogger.error("init baseURL fail with \(hostStr).")
            return URL(fileURLWithPath: "")
        }
        return baseURL
    }

    private var isPPE: Bool {
        #if ALPHA
        if canDebug && MeegoEnv.get(.usePPE) == "1" || MeegoEnv.get(.usePPE) == "true" {
            return true
        }
        return false
        #else
        return false
        #endif
    }

    private var canDebug: Bool = {
        #if DEBUG || ALPHA
        return true
        #else
        let suffix = Utils.appVersion.lf.matchingStrings(regex: "[a-zA-Z]+(\\d+)?").first?.first
        return suffix != nil
        #endif
    }()
}

private extension LarkMeegoNetClientHelper {
    // swiftlint:disable line_length
    var meegoDefaultDomain: String {
        get {
            return "\(MeegoDefaultBaseURL.meego)\(MeegoDefaultBaseURL.dot)\(MeegoDefaultBaseURL.secondaryDomain)\(MeegoDefaultBaseURL.dot)\(MeegoDefaultBaseURL.primaryDomain)"
        }
    }

    var projectDefaultDomain: String {
        get {
            return "\(MeegoDefaultBaseURL.project)\(MeegoDefaultBaseURL.dot)\(MeegoDefaultBaseURL.secondaryDomain)\(MeegoDefaultBaseURL.dot)\(MeegoDefaultBaseURL.primaryDomain)"
        }
    }
    // swiftlint:enable line_length
}
