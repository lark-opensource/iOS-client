//
//  AppLogIntegrator.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/3/30.
//

import Foundation
import LarkAppLog
import LarkReleaseConfig
import LarkAccountInterface
import LarkEnv
import LKCommonsLogging

struct AppLogIntegrator {

    static let logger = Logger.plog(AppLogIntegrator.self, category: "AppLogIntegrator")

    static func setupAppLog() {
        let config = getConfigs()
        if PassportStore.shared.universalDeviceServiceUpgraded {
            LarkAppLog.shared.setDeviceIDUnitUpgraded(true)
        } else {
            //设置没有切换到统一did
            LarkAppLog.shared.setDeviceIDUnitUpgraded(false)
            //设置不需要自动替换did
            LarkAppLog.shared.setDeviceIDNeedAutoUprade(false)
        }
        LarkAppLog.shared.setupURLConfig(config)
        Self.cacheDeviceIDUnitAndHost()
    }

    static func updateAppLog() {
        let config = getConfigs()
        LarkAppLog.shared.updateURLConfig(config)
        if PassportStore.shared.universalDeviceServiceUpgraded {
            LarkAppLog.shared.setDeviceIDUnitUpgraded(true)
        } else {
            //设置没有切换到统一did
            LarkAppLog.shared.setDeviceIDUnitUpgraded(false)
            //设置不需要自动替换did
            LarkAppLog.shared.setDeviceIDNeedAutoUprade(false)
        }
        Self.cacheDeviceIDUnitAndHost()
    }
    
    static func updateAppLogForUniDid(with host: String) {
        //如果是Lark，在获取设备id时需要设置 自增did更新的标识
        if ReleaseConfig.isLark {
            LarkAppLog.shared.setDeviceIDNeedAutoUprade(true)
        }
        if PassportStore.shared.universalDeviceServiceUpgraded {
            LarkAppLog.shared.setDeviceIDUnitUpgraded(true)
        } else {
            //设置没有切换到统一did
            LarkAppLog.shared.setDeviceIDUnitUpgraded(false)
        }
        let config = getConfigs(host: host)
        LarkAppLog.shared.updateURLConfig(config)
    }

    // 和传递给 App Log 侧的逻辑保持一致
    static func fetchCurrentDeviceIDHost() -> String {
        if ReleaseConfig.isPrivateKA {
            if let first = Self.config(from: .ttDeviceUri, remote: .ttApplog, append: "service/2/device_register", isKAOnly: true).first,
               let host = URL(string: first)?.host {
                return host
            } else {
                Self.logger.error(
                    "Fetch current device ID failed, KA condition",
                    additionalData: ["value": Self.config(from: .ttDeviceUri, remote: .ttApplog, append: "service/2/device_register", isKAOnly: true).first ?? ""
                    ])
                return ""
            }
        }

        if let value = Self.remoteSetting(for: .ttApplog, append: nil).first {
            return value
        } else {
            Self.logger.error(
                "Fetch current device ID failed, SaaS condition",
                additionalData: ["value": Self.remoteSetting(for: .ttApplog, append: nil).first ?? ""
                ])
            return ""
        }
    }

    private static func getConfigs() -> LarkAppLog.URLConfig {
        /*
         teaEndpoints 只读 FeatureSwitch，后续有 pullGeneralSettings 更新
         ttActiveUri、ttDeviceUri 仅针对KA
         commonHost 仅针对SaaS
         */
        .init(
            ttActiveURL: Self.config(
                from: .ttActiveUri,
                remote: .ttApplog,
                append: "service/2/app_alert_check",
                isKAOnly: true),
            ttDeviceURL: Self.config(
                from: .ttDeviceUri,
                remote: .ttApplog,
                append: "service/2/device_register",
                isKAOnly: true),
            commonHost: Self.remoteSetting(for: .ttApplog, append: nil)
        )
    }

    /// 读取域名配置
    /// - Parameters:
    ///   - fsKey: KA Feature Switch Config Key
    ///   - key: Remote domain key
    ///   - path: url path
    ///   - isKAOnly: The current value is only for KA.
    /// - Returns: 返回对应相应的配置
    private static func config(
        from fsKey: LarkAccount.FeatureConfigKey,
        remote key: LarkAccountInterface.DomainAliasKey,
        append path: String? = nil,
        isKAOnly: Bool = false
    ) -> [String] {

        // KA 优先使用FeatureSwitch
        if ReleaseConfig.isPrivateKA {
            let preference = PassportConf.shared.featureSwitch.config(for: fsKey)
            return preference.isEmpty ? remoteSetting(for: key, append: path) : preference
        } else {
            return isKAOnly ? [] : remoteSetting(for: key, append: path)
        }
    }

    // Read remote setting || 读取远程配置
    private static func remoteSetting(for key: LarkAccountInterface.DomainAliasKey, append path: String?) -> [String] {
        // TODO： 支持获取hosts列表
        let hosts: [String]
        if let domain = PassportConf.shared.serverInfoProvider.getDomain(key).value {
            hosts = [domain]
        } else {
            hosts = []
        }


        #if DEBUG || BETA || ALPHA
        // BOE 环境下海外设备服务使用 http 才能正确拿到 DeviceID
        // 这个问题短期看不会修复，这里只能做 hard code 替换
        let larkBOEHost = "toblog.itobsnssdk.com.boe-gateway"

        guard let path = path else {
            let fixedHosts: [String] = hosts.compactMap {
                let prefix = $0.contains(larkBOEHost) ? "http://" : ""
                return URL(string: "\(prefix)\($0)")?
                    .absoluteString
            }
            return fixedHosts
        }

        let newHosts: [String] = hosts.compactMap {
            let prefix = $0.contains(larkBOEHost) ? "http" : "https"
            return URL(string: "\(prefix)://\($0)")?
                .appendingPathComponent(path)
                .absoluteString
        }
        return newHosts

        #else

        guard let path = path else { return hosts }

        return hosts.compactMap {
            URL(string: "https://\($0)")?
                .appendingPathComponent(path)
                .absoluteString
        }

        #endif
    }

    private static func cacheDeviceIDUnitAndHost() {
        guard let host = Self.getDeviceIDURLString() else {
            Self.logger.error("cacheDeviceIDUnitAndHost did not get any hosts")
            return
        }
        let unit = SwitchEnvironmentManager.shared.env.unit
        let deviceService = PassportDeviceServiceWrapper.shared
        deviceService.cacheDeviceIDUnit(unit, with: host)
    }

    private static func getDeviceIDURLString() -> String? {
        return Self.remoteSetting(for: .ttApplog, append: nil).first
    }
}

extension AppLogIntegrator {

    static func updateAppLog(unit: String, host: String) {
        let config = getConfigs(host: host)
        LarkAppLog.shared.updateURLConfig(config)
        Self.cacheDeviceIDUnitAndHost(unit: unit, host: host)
    }

    private static func cacheDeviceIDUnitAndHost(unit: String, host: String) {
        PassportDeviceServiceWrapper.shared.cacheDeviceIDUnit(unit, with: host)
    }

    private static func getConfigs(host: String) -> LarkAppLog.URLConfig {
        /*
         teaEndpoints 只读 FeatureSwitch，后续有 pullGeneralSettings 更新
         ttActiveUri、ttDeviceUri 仅针对KA
         commonHost 仅针对SaaS
         */
        .init(
            ttActiveURL: Self.config(
                from: .ttActiveUri,
                host: host,
                append: "service/2/app_alert_check",
                isKAOnly: true),
            ttDeviceURL: Self.config(
                from: .ttDeviceUri,
                host: host,
                append: "service/2/device_register",
                isKAOnly: true),
            commonHost: [host]
        )
    }

    private static func config(
        from fsKey: LarkAccount.FeatureConfigKey,
        host: String,
        append path: String? = nil,
        isKAOnly: Bool = false
    ) -> [String] {

        // KA 优先使用FeatureSwitch
        if ReleaseConfig.isPrivateKA {
            let preference = PassportConf.shared.featureSwitch.config(for: fsKey)
            return preference.isEmpty ? convertApplogUrl(for: host, append: path) : preference
        } else {
            return isKAOnly ? [] : convertApplogUrl(for: host, append: path)
        }
    }

    // Read remote setting || 读取远程配置
    private static func convertApplogUrl(for host: String, append path: String?) -> [String] {
        // TODO： 支持获取hosts列表
        let hosts: [String] = [host]

        #if DEBUG || BETA || ALPHA
        // BOE 环境下海外设备服务使用 http 才能正确拿到 DeviceID
        // 这个问题短期看不会修复，这里只能做 hard code 替换
        let larkBOEHost = "toblog.itobsnssdk.com.boe-gateway"

        guard let path = path else {
            let fixedHosts: [String] = hosts.compactMap {
                let prefix = $0.contains(larkBOEHost) ? "http://" : ""
                return URL(string: "\(prefix)\($0)")?
                    .absoluteString
            }
            return fixedHosts
        }

        let newHosts: [String] = hosts.compactMap {
            let prefix = $0.contains(larkBOEHost) ? "http" : "https"
            return URL(string: "\(prefix)://\($0)")?
                .appendingPathComponent(path)
                .absoluteString
        }
        return newHosts

        #else

        guard let path = path else { return hosts }

        return hosts.compactMap {
            URL(string: "https://\($0)")?
                .appendingPathComponent(path)
                .absoluteString
        }

        #endif
    }
}
