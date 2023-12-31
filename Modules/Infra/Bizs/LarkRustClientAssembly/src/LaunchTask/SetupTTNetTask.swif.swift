//
//  SetupTTNetTask.swif.swift
//  LarkBaseService
//
//  Created by 李勇 on 2021/4/12.
//

import Foundation
import BootManager
import LarkTTNetInitializor
import LarkAppConfig
import LarkContainer
import ZeroTrust
import LarkFoundation
import LKCommonsLogging
import LarkSetting
import LarkFeatureGating
import LarkEnv

final class SetupTTNetTask: FlowBootTask, Identifiable {
    static var identify = "SetupTTNetTask"

    private static let logger = Logger.log(SetupTTNetTask.self)
    @InjectedLazy private var appConfig: AppConfiguration
    @RawSetting(key: UserSettingKey.make(userKeyLiteral: "ttnet_tnc_config")) private var tncConfig: [String: Any]?

    override var runOnlyOnce: Bool { return true }

    override func execute(_ context: BootContext) {
        TTNetInitializor.setupTracker(TTNetLogger(log: Self.logger))

        let domainSetting = DomainSettingManager.shared.currentSetting

        // 零信任SDK证书配置
        var certLists: [Data]?
        // cert & private key
        if let security = CertTool.read(with: ZeroTrustConfig.fixedSaveP12Label) {
            certLists = security.certificates.map({ CertTool.data(from: $0) })
        }
        var tncConfigJSON = ""
        if let tncConfig = tncConfig,
           let tncConfigData = try? JSONSerialization.data(withJSONObject: tncConfig, options: []),
           let tncConfigJSONString = String(data: tncConfigData, encoding: .utf8) {
            tncConfigJSON = tncConfigJSONString
        }
        var userAgent = ""
        let config = TTNetInitializor.Configuration(
            userAgent: userAgent,
            deviceID: "",
            session: "",
            tenentID: "",
            uuid: "",
            envType: convert(env: EnvManager.env.type),
            envUnit: EnvManager.env.unit,
            tncConfig: tncConfigJSON,
            tncDomains: domainSetting[.ttnetTNC] ?? [],
            httpDNS: domainSetting[.ttnetHttpDNS] ?? [],
            netlogDomain: domainSetting[.ttnetNetLog] ?? [],
            certificateList: certLists
        )
        TTNetInitializor.initialize(config)
    }
}

func convert(env: Env.TypeEnum) -> TTNetInitializor.EnvType {
    switch env {
    case .release: return .release
    case .staging: return .staging
    case .preRelease: return .preRelease
    @unknown default: return .release
    }
}

private final class TTNetLogger: TTNetInitializorTracker {
    private let log: Log

    init(log: Log) {
        self.log = log
    }

    func track(data: [AnyHashable: Any]?, logType: String) {
        log.info(logType, tag: logType, additionalData: data as? [String: String], error: nil)
    }

    func info(_ message: String, error: Error?, file: String, method: String, line: Int) {
        log.info(message, tag: method, additionalData: nil, error: error)
    }
}
