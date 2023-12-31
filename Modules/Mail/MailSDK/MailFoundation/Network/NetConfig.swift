//
//  Configuration.swift
//  DocsSDK
//
//  Created by weidong fu on 28/3/2018.
//

import Foundation

final class MailNetConfig {

    enum Qos: Int {
        case `default` = 0
        case high = 1
        case background = 2
    }

    enum TrafficType: Int {
        case `default` = 0
        case upload = 1
        case mailFetch = 2
        case download = 3
    }

    private static var baseUrl: String = ""
    static var userID: String?
    static weak var authDelegate: NetworkAuthDelegate?
    private static var additionHeader: [String: String] = [:]

    static private func generateNeteworkSession(isWiFi: Bool, forceNoRust: Bool = false) -> NetworkSession {
        let timeout = isWiFi ? MailNetConfig.timeoutConfig.wifiTimeout : MailNetConfig.timeoutConfig.carrierTimeout
        let session = NetworkSession(host: MailNetConfig.baseUrl,
                                     requestHeader: MailNetConfig.additionHeader,
                                     timeoutInterval: timeout,
                                     forceNoRust: forceNoRust)
        session.authDelegate = authDelegate
        return session
    }
    static private var _carrierDefaultSession: NetworkSession?
    static private var carrierDefaultSession: NetworkSession {
        if _carrierDefaultSession == nil {
            _carrierDefaultSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierDefaultSession!
    }

    static private var _wifiDefaultSession: NetworkSession?
    static private var wifiDefaultSession: NetworkSession {
        if _wifiDefaultSession == nil {
            _wifiDefaultSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiDefaultSession!
    }
    static private var _carrierUploadSession: NetworkSession?
    private static var carrierUploadSession: NetworkSession {
        if _carrierUploadSession == nil {
            _carrierUploadSession = generateNeteworkSession(isWiFi: false, forceNoRust: true)
        }
        return _carrierUploadSession!
    }
    static private var _wifiUploadSession: NetworkSession?
    private static var wifiUploadSession: NetworkSession {
        if _wifiUploadSession == nil {
            _wifiUploadSession = generateNeteworkSession(isWiFi: true, forceNoRust: true)
        }
        return _wifiUploadSession!
    }
    static private var _carrierFetchSession: NetworkSession?
    static private var carrierFetchSession: NetworkSession {
        if _carrierFetchSession == nil {
            _carrierFetchSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierFetchSession!
    }
    static private var _wifiFetchSession: NetworkSession?
    static private var wifiFetchSession: NetworkSession {
        if _wifiFetchSession == nil {
            _wifiFetchSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiFetchSession!
    }

    static private var _carrierDownloadSession: NetworkSession?
    static private var carrierDownloadSession: NetworkSession {
        if _carrierDownloadSession == nil {
            _carrierDownloadSession = generateNeteworkSession(isWiFi: false)
        }
        return _carrierDownloadSession!
    }
    static private var _wifiDownloadSession: NetworkSession?
    static private var wifiDownloadSession: NetworkSession {
        if _wifiDownloadSession == nil {
            _wifiDownloadSession = generateNeteworkSession(isWiFi: true)
        }
        return _wifiDownloadSession!
    }

    static var retryCount: UInt = 2

    static func configWith(additionHeader: [String: String]) {
        var headers = additionHeader
        headers.merge(MailHttpHeaders.common) { (current, _) -> String in current }
        MailNetConfig.additionHeader = headers
    }

    static func sessionFor(_ qos: Qos, trafficType: TrafficType = .default) -> NetworkSession {
        switch trafficType {
        case .default: return wifiDefaultSession
        case .upload: return wifiUploadSession
        case .mailFetch: return wifiFetchSession
        case .download: return wifiDownloadSession
        }
    }

    static func cookies() -> [HTTPCookie]? {
        return wifiDefaultSession.cookies()
    }

    static private func sessions() -> [NetworkSession] {
        var array = [NetworkSession]()
        array.addOptional(_wifiDefaultSession)
        array.addOptional(_carrierDefaultSession)
        array.addOptional(_wifiUploadSession)
        array.addOptional(_carrierUploadSession)
        array.addOptional(_wifiFetchSession)
        array.addOptional(_carrierFetchSession)
        return array
    }
}

extension Array where Element == NetworkSession {
    mutating func addOptional(_ session: NetworkSession?) {
        if session != nil {
            append(session!)
        }
    }
}

// 网络的配置都放到这里
extension MailNetConfig {
    // 远程配置
    enum ConfigKey: String {
        case carrierNetworkTimeOut    = "Mail_remoteConfigKeyForCarrierNetworkTimeOut"
        case wifiNetworkTimeOut       = "Mail_remoteConfigKeyForWifiNetworkTimeOut"
    }
    static var timeoutConfig = TimeoutConfig()
    struct TimeoutConfig {
        var wifiTimeout: Double {
            get {
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                let maxTimeOut: Double = 200
                let defaultTimeOut: Double = 15
                if let configTimeOut = kvStore.value(forKey: MailNetConfig.ConfigKey.wifiNetworkTimeOut.rawValue) ?? 0.0,
                    configTimeOut > 0, configTimeOut < maxTimeOut {
                    return configTimeOut
                }
                return defaultTimeOut
            }
            set {
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                kvStore.set(newValue, forKey: MailNetConfig.ConfigKey.wifiNetworkTimeOut.rawValue)
            }
        }
        var carrierTimeout: Double {
            get {
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                let maxTimeOut: Double = 200
                let defaultTimeOut: Double = 30
                if let configTimeOut = kvStore.value(forKey: MailNetConfig.ConfigKey.carrierNetworkTimeOut.rawValue) ?? 0.0,
                    configTimeOut > 0, configTimeOut < maxTimeOut {
                    return configTimeOut
                }
                return defaultTimeOut
            }
            set {
                let kvStore = MailKVStore(space: .global, mSpace: .global)
                kvStore.set(newValue, forKey: MailNetConfig.ConfigKey.carrierNetworkTimeOut.rawValue)
            }
        }
    }
}
