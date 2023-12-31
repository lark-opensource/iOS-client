//
//  ExtensionTracker.swift
//  LarkExtensionServices
//
//  Created by 王元洵 on 2021/3/30.
//

import UIKit
import Foundation
import LarkStorageCore

/// extension埋点实现
///
/// 该类为全局单例，不会发送网络请求上报埋点，而是会将埋点存入share container中
/// 使用方可以使用其公共接口`trackTeaEvent`和`trackSlardarEvent`分别上报TEA和Slardar埋点
///
///     ExtensionTracker.shared.trackTeaEvent(key: "aaaa", params: ["bbb": "ccc"])
///     ExtensionTracker.shared.trackSlardarEvent(key: "aaaa",
///                                               params: ["bbb":"ccc"],
///                                               metric: ["bbb":"ccc"],
///                                               category: ["bbb":"ccc"]
/// 埋点会在Lark启动任务中被异步上报
public final class ExtensionTracker {
    private lazy var cache: [[String: Any]] = {
        store.array(forKey: extensionEventListKey) as? [[String: Any]] ?? []
    }()
    private let queue = DispatchQueue(label: "lark.extenisons.tracker")
    private var extensionEventListKey: String { KVKeys.Extension.trackerEvent }
    private let store = KVStores.Extension.globalShared()

    /// 为了测试需要，设置成internal
    var maxTracks = 20

    /// 全局单例
    public static let shared = ExtensionTracker()

    private init() {
        registerAppStateChangeNotification()
    }

    /// pop events for posting
    public func popEventsForPosting() -> [[String: Any]]? {
        guard
            let events = store.array(forKey: extensionEventListKey) as? [[String: Any]]
        else {
            return nil
        }

        store.setArray([], forKey: extensionEventListKey)
        return events
    }

    /// 记录一个TEA平台的埋点
    ///
    /// - Parameters:
    ///   - key: 埋点的key
    ///   - params: 埋点的参数
    public func trackTeaEvent(key: String, params: [String: Any], md5AllowList: [AnyHashable]? = nil) {
        guard AppConfig.logEnable else { return }
        var event = [
            "uuid": UUID().uuidString,
            "type": "TEA",
            "key": key,
            "params": params
        ] as [String: Any]
        if let md5AllowList {
            event["md5AllowList"] = md5AllowList
        }
        insertCache(event: event)
    }

    /// 记录一个TEA平台的埋点
    ///
    /// - Parameters:
    ///   - key: 埋点的key
    ///   - metric: 平台所需的metric信息
    ///   - category: 平台所需的category信息
    ///   - params: 埋点的参数
    public func trackSlardarEvent(key: String,
                                  metric: [String: Any],
                                  category: [String: Any],
                                  params: [String: Any]) {
        guard AppConfig.logEnable else { return }
        let event = [
            "uuid": UUID().uuidString,
            "type": "Slardar",
            "key": key,
            "params": params,
            "metric": metric,
            "category": category
        ] as [String: Any]
        insertCache(event: event)
    }

    private func insertCache(event: [String: Any]) {
        self.queue.async { [weak self] in
            guard let self = self else { return }
            self.cache.append(event)

            if self.cache.count > self.maxTracks {
                self.writeCacheDataToStore()
            }
        }
    }

    private func writeCacheDataToStore() {
        guard !cache.isEmpty else { return }

        var currentEvents = store.array(forKey: extensionEventListKey) as? [[String: Any]] ?? []
        // 由于 cache 初次访问都会从 UserDefault 中读取，而多个 AppExtension 进程会保有多个 cache 实例，
        // 因此这里直接将 UserDefault 中的 event 和 cache 合并会产生重复 event，需要进行去重操作。
        let allEvents = mergeCurrentEvents(currentEvents, with: cache)
        cache.removeAll()
        store.setArray(allEvents, forKey: extensionEventListKey)
    }

    /// 根据 events 的 uuid 去重
    private func mergeCurrentEvents(_ savedEvents: [[String: Any]], with cacheEvents: [[String: Any]]) -> [[String: Any]] {
        var allEvents = savedEvents + cacheEvents
        var addedEvents: Set<String> = []

        return allEvents.compactMap { event in
            guard let uuid = event["uuid"] as? String else { return nil }
            guard !addedEvents.contains(uuid) else { return nil }
            addedEvents.insert(uuid)
            return event
        }
    }

    private func registerAppStateChangeNotification() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(
                                                applicationEnterBackgroundOrTerminate(notification:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(
                                                applicationEnterBackgroundOrTerminate(notification:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: nil)
    }

    @objc
    private func applicationEnterBackgroundOrTerminate(notification: NSNotification) {
        self.queue.async { [weak self] in
            guard let self = self else { return }

            self.writeCacheDataToStore()
        }
    }
}
