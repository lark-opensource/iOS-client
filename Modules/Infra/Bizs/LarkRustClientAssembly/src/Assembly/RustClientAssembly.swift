//
//  RustClientAssembly.swift
//  LarkRustClient
//
//  Created by Yiming Qu on 2021/2/2.
//

import UIKit
import Foundation
import Swinject
import RustPB
import LarkReleaseConfig
import ZeroTrust
import LarkRustClient
import LarkAccountInterface
import LarkFoundation
import LarkLocalizations
import LarkDebugExtensionPoint
import BootManager
import LarkEnv
import LarkTTNetInitializor
import LarkAssembler
import LarkContainer
import LarkSetting
import LarkStorage
import LKCommonsTracker

public protocol LarkRustService {
    func trackDataFilter(event: String, params: [String: Any], onSuccess: @escaping (([String: Any]) -> Void))
    func getConfigSettings(onSuccess: @escaping (([String: String]) -> Void))
    func notifyNetworkStatus()
}

public final class RustClientAssembly: LarkAssemblyInterface {

    public init() {}

    static private var _counter: Int64 = 0
    static var counter: Int64 {
        OSAtomicIncrement64(&_counter)
    }

    public func registContainer(container: Container) { // swiftlint:disable:this all
        let user = container.inObjectScope(.user(type: .both, lifetime: .user))
        let userGraph = container.inObjectScope(.user(type: .both, lifetime: .graph))
        let global = container.inObjectScope(.container)
        /// 获取userscope的RustService，需要做容错处理..
        /// 考虑到兼容模式可能导致user串，并且目前LarkRustClient可能被重复userID reset替换实例，
        /// 所以不缓存，只做验证
        let rustServiceMaker = { (r: UserResolver) -> RustService in // swiftlint:disable:this all
            // NOTE: 串用户的情况可以通过error抛错拦截记录
            let rustClient = try r.resolve(assert: LarkRustClient.self)
            if r.compatibleMode {
                return rustClient.unwrapped
            }
            // 即时是用的当前resolver，其userID也可能不一致（LarkRustClient先更新）。
            // 另外placeholder也一定不相等.., placeholder场景应该使用global RustService
            return try rustClient.safeUnwrapped(userID: r.userID)
        }
        userGraph.register(RustService.self, factory: rustServiceMaker)
        userGraph.register(RustService.self, name: "user", factory: rustServiceMaker)
        /// 这一个是始终存活的全局RustService，且会保证在Rust初始化函数后运行
        global.register(GlobalRustService.self) { (_) in
            return Self.makeRustClient(resolver: container, userId: nil, name: "global")
        }.userSafe()

        container.register(LarkRustService.self) { (r) -> LarkRustService in // swiftlint:disable:this all
            return try r.resolve(assert: LarkRustClient.self) // Global
        }.userSafe()

        global.register(RustConfigurationService.self) { (_) in
            return RustConfiguration()
        }.userSafe()

        global.register(RustImplProtocol.self) { (_) in
            return RustClientLauncherDelegate()
        }

        global.register(PassportRustClientDependency.self) { (_) in
            return RustClientLauncherDelegate()
        }

        global.register(LarkRustClient.self) { (_) -> LarkRustClient in
            let v = LarkRustClient(
                localeIdentifier: LanguageManager.currentLanguage.localeIdentifier,
                rustServiceProvider: { Self.makeRustClient(resolver: container, userId: $0, name: Self.counter.description) }
            )
            SimpleRustClient.hook = v
            return v
        }.userSafe()

        container.register(LarkContainerManagerInterface.self) { _ in LarkContainerManager.shared }.userSafe()
        container.register(RustClientDependency.self) { _ in DefaultRustClientDependency() as RustClientDependency }

        // 先放到这里集成，PushCenter基本是和rust一起用的，单独建Pod比较麻烦
        user.register(SubscriptionCenter.self) { _ in
            return SubscriptionCenter()
        }
        user.register(PushNotificationCenter.self) { resolver in
            let scope = ScopedPushNotificationCenter()
            scope.userID = resolver.userID
            scope.allowGlobalReceiver = resolver.foreground
            return scope
        }
    }
    static func makeRustClient(resolver r: Resolver, userId: String?, name: String) -> RustClient {
        let identifier = "LarkRustClient(\(name))"
        let rustClient = RustClient(
            identifier: identifier,
            userID: userId)

        var config: RustClientConfiguration {
            // lazy load RustClientConfiguration
            func makeEnvV2(_ env: LarkEnv.Env, brand: String, geo: String) -> Basic_V1_InitSDKRequest.EnvV2 {
                var rustEnv = Basic_V1_InitSDKRequest.EnvV2()
                rustEnv.unit = env.unit
                rustEnv.type = env.type.transform()
                rustEnv.brand = brand
                rustEnv.geo = geo
                return rustEnv
            }

            var preloadConfig = RustPB.Basic_V1_InitSDKRequest.PreloadConfig()
            preloadConfig.preloadChatChatterCount = Int32(try! r.resolve(assert: RustConfigurationService.self)
                .preloadGroupPreviewChatterCount)

            var domainInitConfig = DomainInitConfig()
            domainInitConfig.channel = ReleaseConfig.releaseChannel
            domainInitConfig.isCustomizedKa = ReleaseConfig.isPrivateKA

            var frontierConfig: RustPB.Basic_V1_InitSDKRequest.FrontierConfig?
            if !ReleaseConfig.frontierServerId.isEmpty {
                frontierConfig = RustPB.Basic_V1_InitSDKRequest.FrontierConfig()
                frontierConfig?.fpid = ReleaseConfig.frontierProductId
                frontierConfig?.serviceID = ReleaseConfig.frontierServerId
                frontierConfig?.aid = ReleaseConfig.frontierAppId
                frontierConfig?.appKey = ReleaseConfig.frontierAppKey
            }

            // equal to ConfigManager.swift func createRequest(): kaInitConfigPath
            domainInitConfig.kaInitConfigPath = Bundle.main.bundlePath

            // 零信任SDK证书配置
            var certConfig: RustClientConfiguration.CertConfig?
            if let hosts = ZeroTrustConfig.fixedSupportHost, // hosts
               let security = CertTool.read(with: ZeroTrustConfig.fixedSaveP12Label), // cert & private key
               let cert = security.certificates.first, // cert
               let keyData = CertTool.data(from: security.key) // private key to data
            {
                certConfig = (hosts, CertTool.data(from: cert), keyData)
            }

            let brand = try! r.resolve(assert: PassportService.self).tenantBrand.rawValue
            let geo = try! r.resolve(assert: PassportUserService.self).userGeo
            let env = EnvManager.env

            #if canImport(AWEAnywhereArena)
            // lint:disable:next lark_storage_check
            let isAnywhereDoorEnable = UserDefaults.standard.bool(forKey: AnyWhereDoorItem.itemKey)
            if isAnywhereDoorEnable {
                LarkFoundation.Utils.additionalUAString += " LarkEnv/\(env.type.rawValue)_\(env.unit)"
            }
            #else
            let isAnywhereDoorEnable = false
            #endif

            var settingsQuery: [String: String] = [:]
            if let alchemyProjectID = Bundle.main.infoDictionary?["ALCHEMY_PROJECT_ID"] as? String,
               !alchemyProjectID.isEmpty {
                settingsQuery["alchemy_project_id"] = alchemyProjectID
            }

            if let deviceScore = KVPublic.Common.deviceScore.value(), deviceScore > 0 {
                settingsQuery["deviceBenchmarkScore"] = String(deviceScore)
            }
            
            var devicePerfLevel: String? = nil
            let deviceClassify = try? SettingManager.shared.setting(with: UserSettingKey.make(userKeyLiteral: "get_device_classify"))
            if let deviceType = deviceClassify?["mobileClassify"] as? String {
                devicePerfLevel = deviceType
            }

            let hitFeedABTest = KVPublic.FG.enableFetchFeed.value()

            var config = RustClientConfiguration(
                identifier: identifier,
                storagePath: AbsPath.document.url,
                version: LarkFoundation.Utils.appVersion,
                osVersion: UIDevice.current.systemVersion,
                userAgent: LarkFoundation.Utils.userAgent,
                envV2: makeEnvV2(env, brand: brand, geo: geo),
                appId: ReleaseConfig.appId,
                localeIdentifier: LanguageManager.currentLanguage.localeIdentifier,
                clientLogStoragePath: AbsPath.clientLogRootPath.absoluteString,
                dataSynchronismStrategy: .subscribe,
                deviceModel: LarkFoundation.Utils.machineType,
                userId: userId,
                domainInitConfig: domainInitConfig,
                appChannel: ReleaseConfig.pushChannel,
                frontierConfig: frontierConfig,
                certConfig: certConfig,
                domainConfigPath: Bundle.main.bundlePath,
                basicMode: KVPublic.Core.minimumMode.value(),
                preReleaseStressTag: PassportDebugEnv.stressTag,
                preReleaseFdValue: PassportDebugEnv.preReleaseFd.components(separatedBy: ":"),
                preReleaseMockTag: PassportDebugEnv.mockTag,
                xttEnv: PassportDebugEnv.xttEnv,
                boeFd: PassportDebugEnv.BOEFd.components(separatedBy: ":"),
                isAnywhereDoorEnable: isAnywhereDoorEnable,
                settingsQuery: settingsQuery,
                devicePerfLevel: devicePerfLevel
            )
            config.preloadConfig = preloadConfig
            config.fetchFeedABTest = hitFeedABTest
            return config
        }
        rustClient.rustInit(configuration: { config })
        return rustClient
    }

    private func assembleLauncherDelegate(container: Container) {
        LauncherDelegateRegistery.register(factory: LauncherDelegateFactory {
            return RustClientLauncherDelegate()
        }, priority: .high)
    }

    public func registLaunch(container: Container) {
        NewBootManager.register(PreloadLaunchTask.self)
        NewBootManager.register(SetupRustTask.self)
        NewBootManager.register(SetupTTNetTask.self)
        NewBootManager.register(SetNetworkStatusTask.self)
        #if canImport(AWEAnywhereArena)
        NewBootManager.register(AnywhereDoorTask.self)
        #endif
    }

    public func registLauncherDelegate(container: Container) {
        (LauncherDelegateFactory {
            return RustClientLauncherDelegate()
        }, LauncherDelegateRegisteryPriority.high)
    }

    public func registDebugItem(container: Container) {
        ({ ClearCookitItem() }, SectionType.basicInfo)
        ({ BoeProxyItem() }, SectionType.basicInfo)
        ({ CAStoreItem() }, SectionType.basicInfo)
        #if canImport(AWEAnywhereArena)
        ({ AnyWhereDoorItem() }, SectionType.basicInfo)
        #endif
    }

    public func registPushHandler(container: Container) {
        getRegistPush(container: container)
    }

    private func getRegistPush(container: Container) -> [Basic_V1_Command: RustPushHandlerFactory] {
        let factories: [Basic_V1_Command: RustPushHandlerFactory] = [
            .pushFrontierStatus: {
                PushFrontierStatusHandler()
            }
        ]
        return factories
    }
}
