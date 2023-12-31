//
//  Extension+HTTP.swift
//  LarkExtensionServices
//
//  Created by yaoqihao on 2022/6/20.
//

import UIKit
import Foundation
import LarkHTTP
import LarkStorageCore

public final class ExtensionLogger {
    static public let logger = LogFactory.createLogger(label: "Extension.ExtensionLogger")
}

public extension HTTP {
    private static let store = KVStores.Extension.globalShared()

    private static var trackDict: [String: Any]? {
        get {
            store.dictionary(forKey: KVKeys.Extension.HTTP.trackDict)
        }
        set {
            store.setDictionary(newValue ?? [:], forKey: KVKeys.Extension.HTTP.trackDict)
        }
    }

    @KVConfig(key: KVKeys.Extension.HTTP.trackTime, store: store)
    private static var trackTime: TimeInterval?

    @KVConfig(key: KVKeys.Extension.HTTP.trackError, store: store)
    private static var trackError: Bool?

    open class var currentUserId: String? {
        return ExtensionAccountService.currentAccountID
    }

    /**
    Class method to run a POST request that handles the URLRequest and parameter encoding for you.
    */
    @discardableResult open class func POSTForLark(data: Data? = nil, userId: String? = HTTP.currentUserId, requestSerializer: HTTPSerializeProtocol = HTTPParameterSerializer(), completionHandler: ((Response) -> Void)? = nil) -> HTTP? {
        ExtensionLogger.logger.info("POST For Lark")
        guard let userId else {
            ExtensionLogger.logger.error("Current User Id Is Empty")
            let resp = Response()
            resp.error = HTTPOptError.invalidRequest
            completionHandler?(resp)
            return nil
        }
        guard let currentAccountSession = ExtensionAccountService.getUserSession(userId) else {
            let category: [String: Any] = ["error": true, "error_type": "session"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_HTTP",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            ExtensionLogger.logger.error("Account Session Is Empty: \(userId)")
            let resp = Response()
            resp.error = HTTPOptError.invalidRequest
            completionHandler?(resp)
            return nil
        }
        guard let gateway = AppConfig.getGateway(userId),
              let gatewayUrl = URL(string: gateway) else {
            let category: [String: Any] = ["error": true, "error_type": "url"]
            ExtensionTracker.shared.trackSlardarEvent(key: "APNs_HTTP",
                                                      metric: [:],
                                                      category: category,
                                                      params: [:])
            ExtensionLogger.logger.error("Get URL Error")
            let resp = Response()
            resp.error = HTTPOptError.invalidRequest
            completionHandler?(resp)
            return nil
        }

        ExtensionTracker.shared.trackSlardarEvent(key: "APNs_HTTP",
                                                  metric: [:],
                                                  category: ["error": false],
                                                  params: [:])

        let deviceId = ExtensionAccountService.getUserDeviceId(userId) ?? ""
        let headers = HTTP.getLarkHeader(deviceId: deviceId, session: currentAccountSession)
        let xRequestID = headers?["X-Request-ID"]
        let ttEnv = headers?["x-tt-env"]
        ExtensionLogger.logger.info("Get Headers X-Request-ID=\(xRequestID), x-tt-env=\(ttEnv)")

        return Run(gatewayUrl.absoluteString, method: .POST, parameters: data, headers: headers, requestSerializer: requestSerializer, completionHandler: completionHandler)
    }

    /**
    Class method to run a POST request that handles the URLRequest and parameter encoding for you.
    */
    @discardableResult
    open class func trackForLark(event: String,
                                 parameters: [String: Any]? = nil,
                                 userId: String? = HTTP.currentUserId,
                                 completionHandler: ((Response) -> Void)? = nil) -> HTTP? {
        guard let userId else {
            ExtensionLogger.logger.error("[track receive notification] Current User Id Is Empty")
            return nil
        }

        guard let applog = AppConfig.getApplogURL(userId) else {
            ExtensionLogger.logger.error("[track receive notification] app log url is nil")
            return nil
        }

        let url = applog + "?aid=\(AppConfig.appID ?? "")"

        var plaform = ""
        if UIDevice.current.model.contains("iPhone") {
            plaform = "iphone"
        } else if UIDevice.current.model.contains("iPad") {
            plaform = "ipad"
        } else {
            plaform = "ios"
        }

        let headers: [String: String] = ["X-Request-ID": String.randomStr(len: 40),
                                         "Content-Type": "application/json",
                                         "X-AppID": AppConfig.appID ?? "",
                                         "User-Agent": ExtensionAccountService.currentUserAgent ?? ""]

        let date = Date()
        let formatString = "yyyy-MM-dd HH:mm:ss"
        let format = DateFormatter()
        format.dateFormat = formatString
        let logTime = format.string(from: date)

        let timeInterval = Int(date.timeIntervalSince1970)
        let timeIntervalms = Int(date.timeIntervalSince1970 * 1000)

        let userDao = ExtensionAccountService.getUserDao(userId)
        let uniqueId = userDao?.encryptedUserId ?? ""

        let eventV3: [String: Any] = [
            "params": parameters ?? [:],
            "ab_sdk_version": "",
            "user_unique_id": userDao?.encryptedUserId ?? "",
            "event": event,
            "session_id": UUID().uuidString,
            "nt": 4,
            "datetime": logTime,
            "local_time_ms": timeIntervalms
        ]

        #if DEBUG
        let package = "group.com.bytedance.ee.lark.yzj"
        #else
        let package = AppConfig.AppGroupName
        #endif

        let headerDic: [String: Any] = [
            "device_id": ExtensionAccountService.getUserDeviceId(userId) ?? "",
            "platform": "ios",
            "app_name": AppConfig.appName ?? "",
            "ab_sdk_version": "",
            "user_agent": ExtensionAccountService.currentUserAgent ?? "",
            "device_platform": plaform,
            "install_id": ExtensionAccountService.getUserInstallId(userId) ?? "",
            "user_unique_id": uniqueId,
            "os": "iOS",
            "aid": AppConfig.appID ?? "",
            "app_full_version": ExtensionAccountService.currentAPPVersion ?? "",
            "package": package
        ]

        var startTime = Date().timeIntervalSince1970
        if let time = HTTP.trackTime {
            startTime = time
        } else {
            HTTP.trackTime = startTime
        }

        let interval: Double = AppConfig.teaUploadDiffTimeInterval
        let number: Int = AppConfig.teaUploadDiffNumber

        if interval == -1, number <= 0 {
            return nil
        }
    
        var dict: [String: Any] = [:]

        if let defaultDict = HTTP.trackDict {
            dict = defaultDict
        } else {
            HTTP.trackDict = dict
        }

        let now = Date().timeIntervalSince1970

        var shouldPost = false
        if let user = dict[uniqueId] as? [String: Any] {
            let isError = HTTP.trackError ?? false
            if now - startTime >= interval / 1_000 {
                shouldPost = true
            } else if user["count"] as? Int ?? 0 >= number - 1, !isError {
                shouldPost = true
            }
        }

        guard let user = dict[uniqueId] as? [String: Any], shouldPost else {
            HTTP.setValue(uid: uniqueId, headerDic: headerDic, event: eventV3)
            return nil
        }

        var events: [[String: Any]] = [eventV3]

        if let defaultEvents = user["events"] as? [[String: Any]] {
            events.append(contentsOf: defaultEvents)
        }

        let param: [String: Any] = [
            "event_v3": events,
            "magic_tag": "ss_app_log",
            "header": headerDic,
            "local_time": timeInterval
        ]

        HTTP.trackTime = now

        return POST(url,
                    parameters: param,
                    headers: headers,
                    requestSerializer: JSONParameterSerializer()) { response in
            if response.error != nil {
                HTTP.trackError = true
                completionHandler?(response)
                return
            }

            HTTP.trackError = false

            var newEvents: [[String: Any]] = []
            if let defaultDict = HTTP.trackDict,
               let user = defaultDict[uniqueId] as? [String: Any],
                let defaultEvents = user["events"] as? [[String: Any]] {
                for defaultEvent in defaultEvents {
                    if let sessionID = defaultEvent["session_id"] as? String, !events.contains(where: {
                        $0["session_id"] as? String == sessionID
                    }) {
                        newEvents.append(defaultEvent)
                    }
                }
            }

            dict[uniqueId] = [:]
            HTTP.trackDict = dict

            for newEvent in newEvents {
                HTTP.setValue(uid: uniqueId, headerDic: headerDic, event: newEvent)
            }
            completionHandler?(response)
        }
    }

    private class func setValue(uid: String, headerDic: [String: Any], event: [String: Any]) {
        var dict: [String: Any] = [:]
        var userDict: [String: Any] = [:]

        if let defaultDict = HTTP.trackDict,
            let user = defaultDict[uid] as? [String: Any] {
            dict = defaultDict
            userDict = user
        }

        userDict["header"] = headerDic

        var events: [[String: Any]] = []
        if let defaultEvents = userDict["events"] as? [[String: Any]] {
            events = defaultEvents
        }

        events.append(event)
        /// 避免积累过多event 但是不会导致http请求超时
        events = Array(events.suffix(30))

        userDict["events"] = events
        userDict["count"] = events.count

        dict[uid] = userDict
        HTTP.trackDict = dict
    }

    private class func getLarkHeader(deviceId: String, session: String) -> [String:String]? {
        var plaform = ""
        if UIDevice.current.model.contains("iPhone") {
            plaform = "iphone"
        } else if UIDevice.current.model.contains("iPad") {
            plaform = "ipad"
        } else {
            plaform = "ios"
        }

        //case release = 1
        //case staging = 2
        //case preRelease = 3
        var ttEnv = ""
        if let envType = AppConfig.envType, envType != 1, let xTTEnv = AppConfig.xTTEnv {
            ttEnv = xTTEnv
        }
        let httpHeader: [String: String] = ["X-Request-ID": String.randomStr(len: 40),
                                            "Cookie": "session=\(session)",
                                            "Content-Type": "application/x-protobuf",
                                            "X-AppID": AppConfig.appID ?? "",
                                            "User-Agent": ExtensionAccountService.currentUserAgent ?? "",
                                            "aid": AppConfig.appID ?? "",
                                            "app_name": AppConfig.appName ?? "",
                                            "region": Locale.current.regionCode ?? "CN",
                                            "device_id": deviceId,
                                            "x-tt-env": ttEnv,
                                            "device_platform": plaform]
        return httpHeader
    }
}

/// 生成指定长度的随机字符串，用于cid和req_id
public extension String {
    public static let randomStrCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    public static func randomStr(len: Int) -> String {
        var ranStr = ""
        for _ in 0..<len {
            let index = Int(arc4random_uniform(UInt32(randomStrCharacters.count)))
            ranStr.append(randomStrCharacters[randomStrCharacters.index(randomStrCharacters.startIndex,
                                                                        offsetBy: index)])
        }
        return ranStr
    }
}
