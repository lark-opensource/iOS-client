//
//  MessageActionDataPreloader.swift
//  LarkOpenPlatform
//
//  Created by houjihu on 2021/3/4.
//

import LarkMessageBase
import Swinject
import LKCommonsLogging
import LarkOPInterface
import LarkContainer

/// 进入会话时，根据有无缓存和缓存过期时间按需提前拉取加号菜单应用数据
/// 再打开加号面板时只使用缓存数据，避免加号菜单应用闪现问题
class MessageActionDataPreloader: PageService {
    private static let logger = Logger.oplog(MessageActionDataPreloader.self, category: MessageActionPlusMenuDefines.messageActionLogCategory)

    let resolver: UserResolver
    let dataProvider: MoreAppListDataProvider
    let scene: BizScene = .addMenu
    init(resolver: UserResolver) {
        self.resolver = resolver
        ///小程序的信息跟语言相关，切换语言需要重新拉取
        let locale = OpenPlatformAPI.curLanguage()
        dataProvider = MoreAppListDataProvider(
            resolver: resolver,
            locale: locale,
            scene: scene
        )
    }

    /// 对应首屏消息渲染完成之后(目前只有普通会话页面支持这个时机回调)
    func afterFirstScreenMessagesRender() {
        var noCacheCode: OPMonitorCodeBase
        var hadCacheCode: OPMonitorCodeBase
        switch scene {
        case .addMenu:
            noCacheCode = EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.cache_expire_in_chat
            hadCacheCode =  EPMClientOpenPlatformMessageactionPlusmenuAppPlusMenuCode.cache_exist_in_chat
        case .msgAction:
            noCacheCode = EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.cache_expire_in_chat
            hadCacheCode =  EPMClientOpenPlatformMessageactionPlusmenuAppMsgActionCode.cache_exist_in_chat
        }
        let noCache = OPMonitor(noCacheCode)
        let hadCache = OPMonitor(hadCacheCode)
        dataProvider.updateRemoteExternalItemListIfNeed(forceUpdate: false) { shouldUpdate in
            if shouldUpdate {
                noCache.flush()
            } else {
                hadCache.flush()
            }
        } updateCallback: { (error, model) in
            guard error == nil else {
                Self.logger.error("update plus menu data list failed with error: \(error?.localizedDescription ?? "")")
                return
            }
            Self.logger.info("update plus menu data list success")
        }
    }
}
