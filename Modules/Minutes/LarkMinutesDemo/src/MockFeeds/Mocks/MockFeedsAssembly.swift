//
//  MockFeedsAssembly.swift
//  LarkMessengerDemoMockFeeds
//
//  Created by bytedance on 2020/5/15.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import Swinject
import LarkSDKInterface
import RustPB
import LarkFoundation
import LarkAppConfig
import LarkAccountInterface
import LarkReleaseConfig
import LarkLocalizations
import LarkRustClient

class MockFeedsAssembly: Assembly {
    // copied from AccountAssembly.swift ...
    static private var _counter: Int64 = 0
    static var counter: Int64 {
        OSAtomicIncrement64(&_counter)
    }

    func assemble(container: Container) {
        // copy的AccountAssembly.swift 里面的注册 - 有所改动，下面有标记
        container.register(RustService.self) { (r, userId: String?) -> RustService in
            let appConfig = r.resolve(AppConfiguration.self)!
            var preloadConfig = RustPB.Basic_V1_InitSDKRequest.PreloadConfig()
            preloadConfig.preloadChatChatterCount = Int32(r.resolve(RustConfigurationService.self)!
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
            domainInitConfig.kaInitConfigPath = Bundle.main.bundleURL.appendingPathComponent("KA.bundle").path

            var config = RustClientConfiguration(
                identifier: "LarkRustClient(\(Self.counter))",
                storagePath: appConfig.documentPath,
                version: LarkFoundation.Utils.appVersion,
                userAgent: LarkFoundation.Utils.userAgent,
                envV2: appConfig.env.transformToEnvV2(),
                appId: ReleaseConfig.appId,
                localeIdentifier: LanguageManager.currentLanguage.localeIdentifier,
                clientLogStoragePath: appConfig.clientLogPath,
                dataSynchronismStrategy: .subscribe,
                userId: userId,
                domainInitConfig: domainInitConfig,
                frontierConfig: frontierConfig
            )
            config.preloadConfig = preloadConfig

            // 有所改动
            let commands: [Basic_V1_Command] = [.pushShortcuts,
                                               .pushInboxCards,
                                               .pushLoadFeedCardsStatus,
                                               .pushFeedCursor]
            // 这里依赖LarkRustClient => subspec Mock(仅debug下提供)，可以提供mock push handlers调用
            return MockInterceptionRustClient(configuration: config, commands: commands)
        }

        // 替换掉FeedAPI，要接手Feeds相关的操作
        container.register(FeedAPI.self) { r in
            let pushOb = r.pushCenter.observable(for: PushWebSocketStatus.self)

            var feedAPIName = "", maxFeedsLimit = 0, maxShortcutsLimit = 0

            // 如果只有一个参数，即executable name本身，则失败，需要传入MockFeedAPI class name才能执行这个target
            if ProcessInfo.processInfo.arguments.count == 1 {
                // MANUAL LAUNCH ONLY - 方便调试某个test case
                feedAPIName = "InboxPushFeedPreviewMockFeedAPI"
                maxFeedsLimit = 250
                maxShortcutsLimit = 10
            } else {
                assert(ProcessInfo.processInfo.arguments.count == 4)

                // 这里是固定的顺序
                feedAPIName = ProcessInfo.processInfo.arguments[1]
                maxFeedsLimit = Int(ProcessInfo.processInfo.arguments[2]) ?? 0
                maxShortcutsLimit = Int(ProcessInfo.processInfo.arguments[3]) ?? 0
            }

            // 这里要留意下，假设Bundle name没有包含空格，如果有空格，还要多加一步" " -> "_"的逻辑
            let namespace = Bundle.main.infoDictionary!["CFBundleExecutable"] as? String

            guard let feedAPIClass = NSClassFromString("\(namespace ?? "LarkMessengerDemoMockFeeds").\(feedAPIName)")
                as? MockFeedAPI.Type else {
                fatalError("Wrong MockFeedAPI class name. Try another one. - \(#file)")
            }

            let feedAPIInst = feedAPIClass.init(webSocketStatusPushOb: pushOb,
                maxFeedsLimit: maxFeedsLimit,
                maxShortcutsLimit: maxShortcutsLimit)
            return feedAPIInst
        }.inObjectScope(.user)
    }
}
