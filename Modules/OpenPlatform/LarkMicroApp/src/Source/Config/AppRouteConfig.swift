//
//  AppRouteConfig.swift
//  LarkMicroApp
//
//  Created by yinyuan on 2019/4/9.
//

import Foundation
import EEMicroAppSDK
import SwiftyJSON
import LKCommonsLogging

let gadgetRouteLog = Logger.log(MicroAppRouteConfigManager.self)

struct MicroAppRouteConfig {
    let schemes: [String]?
    let hosts: [String]?
    let paths: [String]?
    let appid: String?
    let fullMatchForPath: Bool

    init(config: [String: Any]) {
        self.schemes = config["schemes"] as? [String]
        self.hosts = config["hosts"] as? [String]
        self.paths = config["paths"] as? [String]
        self.appid = config["appid"] as? String
        self.fullMatchForPath = config["fullMatchForPath"] as? Bool ?? false
    }

    init() {
        self.init(config: [:])
    }

    /// 针对头条圈的特化逻辑
    func isMalaita() -> Bool {
        guard let appid = appid else {
            return false
        }
        return (appid == "tt06bd70009997ab3e")
    }
}

final class MicroAppRouteConfigManager {
    private static let miniPathKey = "miniPath"

    /// 最低级别的配置，在线上配置获取失败时作为备份使用
    private static let DefaultAppRouteConfigList: [[String: Any]] =
        [
            [
                "appid": "tt06bd70009997ab3e",
                "hosts": [
                    "ee.bytedance.net"
                ],
                "paths": [
                    "/malaita",
                    "/malaita/",
                    "/malaita/pc",
                    "/malaita/pc/"
                ],
                "schemes": [
                    "http",
                    "https"
                ],
                "fullMatchForPath": true
            ],
            [
                "appid": "cli_9cf62f5b0b3c1101",
                "hosts": [
                    "people.bytedance.net"
                ],
                "paths": [
                    "/recruitment/my/offer_approval/detail/"
                ],
                "schemes": [
                    "https"
                ]
            ]
        ]

    static func isMatchConfig(url: URL) -> Bool {
        return matchedConfig(url: url) != nil
    }

    private static func matchedConfig(url: URL) -> MicroAppRouteConfig? {

        let configList = appRouteConfigList()

        for configData in configList {
            guard let configData = configData as? [String: Any] else {
                continue
            }
            let config = MicroAppRouteConfig(config: configData)

            guard config.appid != nil else { continue }

            if let schemes = config.schemes {
                guard let scheme = url.scheme, schemes.contains(scheme) else {
                    continue
                }
            }

            if let hosts = config.hosts {
                guard let host = url.host, hosts.contains(host) else {
                    continue
                }
            }

            if let paths = config.paths, !paths.contains(where: { config.fullMatchForPath ? $0 == url.path : url.path.contains($0) }) {
                continue
            }

            return config
        }

        return nil
    }

    private static func appRouteConfigList() -> [Any] {

        var appRouteConfigList: [Any]?

        // 优先取配置中心最新线上配置
        if let config = EERoute.shared().onlineConfig() {
            appRouteConfigList = config.appRouteConfigList()
        }

        // 如果取不到，取 DefaultAppRouteConfigList 的代码配置
        if appRouteConfigList == nil {
            appRouteConfigList = MicroAppRouteConfigManager.DefaultAppRouteConfigList
        }

        if let appRouteConfigList = appRouteConfigList {
            return appRouteConfigList
        }

        return []
    }

    public static func convertHttpToSSLocal(_ url: URL) -> URL? {
        guard let appRouteConfig = MicroAppRouteConfigManager.matchedConfig(url: url),
            let appid = appRouteConfig.appid else {
                return nil
        }

        let sslocalModel = SSLocalModel()
        sslocalModel.type = .open
        sslocalModel.app_id = appid

        let queryParameters = url.queryParameters
        if queryParameters.keys.contains(miniPathKey),
            let startPageValue = queryParameters[miniPathKey] {
            sslocalModel.start_page = startPageValue
        } else if appRouteConfig.isMalaita() {
            // 头条圈的特化逻辑: url参数包含 open_item=[feedID], 通过miniPath: "pages/feedinfo/root?feedID=[feedID]" 打开头条圈小程序; 如果url中不带miniPath, 则默认miniPath="pages/home/root"
            var charSet = CharacterSet.alphanumerics
            charSet.insert(charactersIn: "-_.!~*'()")

            let feedIDKey = "open_item"
            if queryParameters.keys.contains(feedIDKey),
                let feedIDValue = queryParameters[feedIDKey] {
                sslocalModel.start_page = "pages/feedinfo/root?feedID=\(feedIDValue)"
            } else if let miniRefererEncoded = url.absoluteString.addingPercentEncoding(withAllowedCharacters: charSet) {
                sslocalModel.start_page = "pages/home/root?miniReferer=\(miniRefererEncoded)"
            }
        }

        let refererJson = JSON([
            "extraData": [
                "refererLink": url.absoluteString
            ]
        ])
        if let refererInfo = refererJson.rawString() {
            sslocalModel.refererInfo = refererInfo
        } else {
            gadgetRouteLog.warn("parse referer josn failed, add refererInfo failed")
        }

        return sslocalModel.generateURL()
    }
}
