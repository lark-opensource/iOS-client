//
//  RustClient.swift
//  LarkRustClient
//
//  Created by SolaWing on 2019/9/25.
//

import UIKit
import Foundation
import RustPB
import RustSDK
import SwiftProtobuf
import RxSwift
import EEAtomic
import Security
import LarkStorage

private enum InitSDKRet: Int, CustomStringConvertible {
    case normal = 0
    case error = 1
    case inputError = 2
    case outputError = 3
    case storageError = 4

    public var description: String {
        switch self {
        case .normal:
            return "rustSDK init success"
        case .error:
            return "rustSDK init error nomal"
        case .inputError:
            return "rustSDK init error inputError"
        case .outputError:
            return "rustSDK init error outputError"
        case .storageError:
            return "rustSDK init error storageError"
        }
    }
}

/// 扩展异步初始化，command转换等
public final class RustClient: SimpleRustClient {
    static var rustInitialized = AtomicOnce()
    public static var rustInitCost: TimeInterval = 0
    public convenience init(configuration: RustClientConfiguration) {
        self.init(identifier: configuration.identifier, userID: configuration.userId)
        rustInit(configuration: { configuration })
    }

    public func rustInit(configuration: @escaping () -> RustClientConfiguration) {
        self.sendQueue.async(flags: .barrier) {
            /// https://bytedance.feishu.cn/docs/doccnD8owIHQlf42hkZ9HJYKrue#
            /// 确认3个有可能产生变动的参数都没问题，可以之后运行时修改。现在只初始化一次。
            RustClient.rustInitialized.once {
                SimpleRustClient.logger.info("RustClient SDK start init...")
                let timeStart = CACurrentMediaTime()
                let configuration = configuration()
                self.sdkPreInit(configuration: configuration)
                self._setConfiguration(configuration: configuration)
                RustClient.rustInitCost = (CACurrentMediaTime() - timeStart) * 1_000
            }
        }
    }

    private func getAppKey() -> [UInt8]? {
        let oldServiceKey = "com.lark.appKeyForSDKPreInit"
        let serviceKey = oldServiceKey + ".new"
        // Fix https://meego.feishu.cn/larksuite/issue/detail/7968114
        let getQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: serviceKey,
                                       kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                                       kSecReturnData as String: true]
        var value: CFTypeRef?
        SecItemCopyMatching(getQuery as CFDictionary, &value)
        if let data = value as? Data, let key = String(data: data, encoding: .utf8)?.utf8 {
            // 返回keyChain中存储
            SimpleRustClient.logger.info("getAppKey find key in keyChain with AfterFirstUnlock")
            return Array(key)
        }
        SimpleRustClient.logger.info("getAppKey keyChain not find key with AfterFirstUnlock")
        if let key = getAppKeyOld(serviceKey: oldServiceKey) {
            if save2Keychain(serviceKey: serviceKey, Data(key)) {
                return key
            }
            return nil
        }
        let key = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        if let keyData = key.data(using: .utf8), save2Keychain(serviceKey: serviceKey, keyData) {
            return Array(key.utf8)
        }
        return nil
    }

    private func save2Keychain(serviceKey: String, _ key: Data) -> Bool {
        let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecValueData as String: key,
                                       kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                                       kSecAttrService as String: serviceKey]
        let result = SecItemAdd(addquery as CFDictionary, nil)
        if result == errSecSuccess {
            SimpleRustClient.logger.info("getAppKey keyChain save success with AfterFirstUnlock")
            return true
        }
        SimpleRustClient.logger.error("getAppKey keyChain save fail \(result) with AfterFirstUnlock")
        return false
    }

    private func getAppKeyOld(serviceKey: String) -> [UInt8]? {
        let getQuery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                       kSecAttrService as String: serviceKey,
                                       kSecReturnData as String: true]
        var value: CFTypeRef?
        SecItemCopyMatching(getQuery as CFDictionary, &value)
        if let data = value as? Data, let key = String(data: data, encoding: .utf8)?.utf8 {
            // 返回keyChain中存储
            SimpleRustClient.logger.info("getAppKey find key in keyChain")
            return Array(key)
        }
        SimpleRustClient.logger.info("getAppKey keyChain not find key")
        return nil
    }

    private func sdkPreInit(configuration: RustClientConfiguration) {
        let storagePath = configuration.storagePath.path.utf8
        guard let key = self.getAppKey() else {
            SimpleRustClient.logger.error("sdkPreInit key get failed")
            return
        }
        SimpleRustClient.logger.info("sdkPreInit lark_sdk_pre_init key \(key.first) **** \(key.last)")
        let result = lark_sdk_pre_init(Array(storagePath),
                                       storagePath.count,
                                       key,
                                       key.count)
        SimpleRustClient.logger.info("sdkPreInit lark_sdk_pre_init result\(result)")
    }

    private func _setConfiguration(configuration: RustClientConfiguration) {
        do {
            var request = InitSDKRequest()
            request.proxyConfig = .init()
            #if DEBUG || ALPHA
            request.proxyConfig.proxyType = .automatic
            #else
            request.proxyConfig.proxyType = .none
            #endif
            request.version = configuration.version
            request.osVersion = configuration.osVersion
            request.userAgent = configuration.userAgent
            request.storagePath = configuration.storagePath.path
            request.env = .online // 3.27.0起，无用字段
            request.envV2 = configuration.envV2
            request.processType = InitSDKRequest.ProcessType(rawValue: configuration.processType.rawValue) ?? .main
            request.localeIdentifier = configuration.localeIdentifier
            request.clientLogStoragePath = configuration.clientLogStoragePath
            request.dataSynchronismStrategy = configuration.dataSynchronismStrategy
            request.deviceModel = configuration.deviceModel
            request.pathPrefix = NSHomeDirectory() // lint:disable:this lark_storage_check
            request.enableThread = true
            request.useDeprecatedPushMsg = false
            request.deprecatedConfig.useDeprecatedUserLst = false
            request.mainThreadID = configuration.mainThreadInt64
            request.localTimezone = TimeZone.current.identifier
            request.initConfigPath = configuration.domainConfigPath
            request.basicMode = configuration.basicMode
            request.isAnydoorEnable = configuration.isAnywhereDoorEnable
            request.appChannel = configuration.appChannel
            if let classify = configuration.devicePerfLevel {
                if classify == "mobile_classify_high" {
                    request.devicePerfLevel = .deviceHigh
                }
                if classify == "mobile_classify_mid" {
                    request.devicePerfLevel = .deviceMiddle
                }
                if classify == "mobile_classify_low" {
                    request.devicePerfLevel = .deviceLow
                }
            } else {
                request.devicePerfLevel = .deviceUnknown
            }
            var clientAbExperiment = Basic_V1_InitSDKRequest.ClientABExperiment()
            clientAbExperiment.enableDelayLoadMoreFeeds = configuration.fetchFeedABTest
            request.clientAbExperiment = clientAbExperiment

            // 环境相关配置
            if !configuration.preReleaseStressTag.isEmpty {
                request.stressTestTag = configuration.preReleaseStressTag
            }
            if configuration.preReleaseFdValue.count == 2 {
                request.preRpcPersistDyecpFdKey = configuration.preReleaseFdValue[0]
                request.preRpcPersistDyecpFdValue = configuration.preReleaseFdValue[1]
            }
            if !configuration.preReleaseMockTag.isEmpty {
                request.preRpcPersistMockTagValue = configuration.preReleaseMockTag
            }
            if configuration.boeFd.count == 2 {
                request.boeRpcPersistDyecpFd.key = configuration.boeFd[0]
                request.boeRpcPersistDyecpFd.value = configuration.boeFd[1]
            }
            if !configuration.xttEnv.isEmpty {
                request.xTtEnv = configuration.xttEnv
            }

            if !configuration.settingsQuery.isEmpty {
                request.settingsQueries = configuration.settingsQuery
            }

            if let channel = Bundle.main.infoDictionary?["RELEASE_CHANNEL"] as? String,
               channel.lowercased().hasSuffix("oversea") {
                request.packageID = .lark
            } else {
                request.packageID = .feishu
            }
            if let userId = configuration.userId {
                request.userID = userId
            }
            if let frontierConfig = configuration.frontierConfig {
                request.frontierConfig = frontierConfig
            }
            request.appID = configuration.appId
            if let preloadConfig = configuration.preloadConfig {
                request.preloadConfig = preloadConfig
            }

            request.kaInitConfig = configuration.domainInitConfig

            request.tags = [UIDevice.current.userInterfaceIdiom == .pad ? "iPad_onRustSDK" : "iPhone_onRustSDK"]

            var logSetting = Basic_V1_InitSDKRequest.LogSetting()
            let secretKey = LarkStorage.KVPublic.Setting.rustLogSecretKey.value()
            logSetting.key = secretKey["encoded_public_key"] ?? ""
            logSetting.keyID = secretKey["key_id"] ?? ""
            request.logSetting = logSetting

            // 零信任网络配置
            configClientCert(with: &request, configuration: configuration)

            let result = try RustManager.shared.initialize(config: request)

            if result != 0 {
                let ret = InitSDKRet(rawValue: result)
                SimpleRustClient.logger.error(
                    "RustClient init failure errorCode = \(result) + \(ret?.description ?? "no description")")
                if result == 4 {
                    exit(0)
                }
            }
            assert(result == 0, "RustClient init failure.")
        } catch {
            SimpleRustClient.logger.error("RustSDK启动失败", error: error)
        }
    }

    public var serializeHook: ((SwiftProtobuf.Message) -> SwiftProtobuf.Message?)?
    override func serialize(request: SwiftProtobuf.Message, context: SimpleRustClient.RequestContext) throws -> Data {
        if let serializeHook {
            let request = serializeHook(request) ?? request
            return try super.serialize(request: request, context: context)
        }
        return try super.serialize(request: request, context: context)
    }
    /// 零信任网络，客户端证书等配置
    @inline(__always)
    private func configClientCert(with request: inout InitSDKRequest, configuration: RustClientConfiguration) {
        if let config = configuration.certConfig {
            var cert = ClientCert()
            cert.cert = config.cert
            cert.hosts = config.hosts
            cert.privkey = config.privateKey
            request.clientCert = cert
        } else {
            Self.logger.error(
                "RustClient: ZeroTrust config not exist when init SDK.")
        }
    }

    // MARK: sendQueue API
    // all message through sendQueue should call following method!
    override public func sync(_ request: RequestPacket) -> ResponsePacket<Void> {
        mainGuard(request: request)
        return super.sync(request)
    }

    override public func sync<R>(_ request: RequestPacket) -> ResponsePacket<R> where R: Message {
        mainGuard(request: request)
        return super.sync(request)
    }

    func mainGuard(request: RequestPacket) {
        if !request.allowOnMainThread && Thread.isMainThread {
            let message = "\(request) should not sync message on main thread!"
            #if !DisableAssertMain
            assertionFailure(message)
            #endif
            SimpleRustClient.logger.error(message)
        }
    }
}
