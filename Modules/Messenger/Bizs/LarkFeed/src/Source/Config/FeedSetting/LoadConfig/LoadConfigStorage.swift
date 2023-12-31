//
//  LoadConfigStorage.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/18.
//

import Foundation
import RunloopTools
import RxSwift
import RustPB
import LKCommonsLogging
import LarkStorage
import LarkSetting
import LarkContainer

final class LoadConfigStorage {
    private static var store = KVStores.Feed.global()
    private static let settingKey = UserSettingKey.make(userKeyLiteral: "messenger_feed_load_count")
    private static let storageKey = KVKey<LoadSetting?>(settingKey.stringValue)

    /// 需放在BaseVC里，且不同租户Config相同，故置为单例
    static let shared = LoadConfigStorage()

    lazy var settings: LoadSetting? = {
        guard let setting = Self.store[Self.storageKey] else { return nil }
        FeedContext.log.info("feedlog/setting/loadConfig. decode success: \(setting.description)")
        return setting
    }()

    lazy var refresh: Int = {
        guard let config = settings else { return LoadConfigInitial.refresh }
        return config.safe_refresh
    }()

    lazy var loadMore: Int = {
        guard let config = settings else { return LoadConfigInitial.loadMore }
        return config.safe_loadmore
    }()

    lazy var buffer: Int = {
        guard let config = settings else { return LoadConfigInitial.buffer }
        return config.safe_buffer
    }()

    func pull(_ client: LoadConfigDependency) {
        RunloopDispatcher.shared.addTask(priority: .low) {
            self.pull()
        }.waitCPUFree()
    }

    private func pull() {
        // FIXME: 不同用户的settings都是相同的？
        guard let setting = FeedSetting(Container.shared.getCurrentUserResolver()).deserialize(key: LoadConfigStorage.settingKey, entity: LoadSetting.self) // foregroundUser
                as? LoadSetting else { return }
        FeedContext.log.info("feedlog/setting/loadConfig. pull success: \(setting)")
        Self.store[Self.storageKey] = setting
    }
}
