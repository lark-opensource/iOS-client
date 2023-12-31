//
//  Dependency.swift
//  LarkSDKAssembly
//
//  Created by CharlieSu on 10/8/19.
//

import Foundation
import LarkSDK
import Swinject
import LarkModel
import LarkAppConfig
import LarkMessengerInterface
import LarkOpenFeed
import LarkMessageCore
import LarkContainer
import RxSwift
import LarkSDKInterface
import RustPB
import LarkCore
#if CCMMod
import SpaceInterface
import CCMMod
#endif

final class SDKDependencyImpl: SDKDependency {

    fileprivate let resolver: UserResolver

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    // MARK: RustSendMessageAPIDependency & RustSendThreadAPIDependency
    private lazy var modelService = { return try? resolver.resolve(assert: ModelService.self) }()
    private lazy var feedSyncDispatchService = { return try? resolver.resolve(assert: FeedSyncDispatchService.self) }()

    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus {
        return feedSyncDispatchService?.dynamicNetStatus ?? .excellent
    }

    let imageToFileThresholdMB: Double = 25

    func messageSummerize(_ message: LarkModel.Message) -> String {
        return modelService?.messageSummerize(message) ?? ""
    }

    func isSupportURLType(url: URL) -> (Bool, type: String, token: String) {
        #if CCMMod
        (try? resolver.resolve(assert: DocSDKAPI.self))?.isSupportURLType(url: url) ?? (false, "", "")
        #else
        (false, "", "")
        #endif
    }

    func trackClickMsgSend(_ chat: LarkModel.Chat, _ message: LarkModel.Message, chatFromWhere: String?) {
        IMTracker.Chat.Main.Click.MsgSend(chat, message, chatFromWhere)
    }

    // MARK: DocsCacheDependency
    func calculateCacheSize() -> Observable<Float> {
        #if CCMMod
        return (try? resolver.resolve(assert: DocsUserCacheServiceProtocol.self))?.calculateCacheSize() ?? .just(0)
        #else
        .just(0)
        #endif
    }

    func clearCache() -> Observable<Void> {
        #if CCMMod
        (try? resolver.resolve(assert: DocsUserCacheServiceProtocol.self))?.clearCache() ?? .just(())
        #else
        .just(())
        #endif
    }
}
