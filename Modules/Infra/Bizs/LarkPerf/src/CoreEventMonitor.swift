//
//  CoreEventMonitor.swift
//  LarkPerf
//
//  Created by qihongye on 2020/6/24.
//

import UIKit
import Foundation
import ThreadSafeDataStructure
import AppReciableSDK

/// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#
public struct CoreEventMonitor {
    // swiftlint:disable identifier_name
    enum Key: String {
        case at_list_load_time
        case user_profile_load_time
        case user_image_empty_cost
        case switch_tab_cost
        case main_tab_loading_time
        case feed_load_more_time

        var logID: String {
            return "eesa_\(rawValue)"
        }
    }
    // swiftlint:enable identifier_name

    /// Since ImageView in screen to Image render finish.
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#V9G7Xm
    public static var ImageEmptyCost = ImageEmptyCostMonitor()
    /// Since user tap tab icon to TabViewController's first screen data render finish
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#aznNZ2
    public static var SwithTabCost = SwitchTabMonitor()
    /// Since user call up AtViewController to AtViewContoller's data render finish.
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#JnGWZx
    public static var AtListLoadCost = AtListLoadCostMonitor()
    /// https://bytedance.feishu.cn/docs/doccn3xnGWF3rKSx5RaBrl9uGkc#fEyxBv
    public static var MainTabLoadingCost = MainTabLoadingMonitor()

    @inline(__always)
    static func didEnterBackground() {
        ImageEmptyCost.cancel()
        SwithTabCost.cancel()
        AtListLoadCost.cancel()
        MainTabLoadingCost.cancel()
        SwithTabCost.cancel()
        ColdStartup.clear()
    }
}

/// ImageEmptyCostMonitor
public struct ImageEmptyCostMonitor {
    public enum Scene: Int8 {
        case unknown = -1
        case avatar = 0
        case profile = 1
        case imageMessage = 2
        case gifMessage = 3
        case videoMessage = 4
    }

    public enum BizScene: Int8 {
        case unknown = -1
        case feed = 0
        case chat = 1
        case search = 2
        case pin = 3
        case favor = 4
        case profile = 5
    }

    struct Info {
        let timestamp: CFTimeInterval
        let scene: Scene
        let bizScene: BizScene
    }

    private var map = SafeDictionary<String, Info>([:], synchronization: .readWriteLock)

    /// start
    /// - Parameters:
    ///   - identifier: image key
    ///   - bizeScene: BizScene
    ///   - scene: Scene
    public func start(_ identifier: String, bizeScene: BizScene, scene: Scene = .unknown) {
        map[identifier] = Info(timestamp: CACurrentMediaTime(), scene: scene, bizScene: bizeScene)
    }

    /// end
    /// - Parameters:
    ///   - identifier: image key
    ///   - scene: Scene
    public func end(_ identifier: String, scene: Scene = .unknown) {
        guard let start = map.removeValue(forKey: identifier) else {
            return
        }
        let latency = (CACurrentMediaTime() - start.timestamp) * 1_000
        let key = CoreEventMonitor.Key.user_image_empty_cost
        let category: ClientPerf.Category = [
            "scene": scene == .unknown ? start.scene.rawValue : scene.rawValue,
            "biz_scene": start.bizScene.rawValue
        ]
        ClientPerf.shared.singleSlardarEvent(service: key.rawValue, cost: latency, logid: key.logID, category: category)
    }

    /// cancel event
    public func cancel(_ identifier: String? = nil) {
        guard let id = identifier else {
            map.removeAll()
            return
        }
        map.removeValue(forKey: id)
    }
}

/// SwitchTabMonitor
public struct SwitchTabMonitor {
    struct Info {
        var timestamp: CFTimeInterval
        var toTab: String
        var isInitialize: Bool
    }

    /// Unit type ms
    public struct Params {
        public var initVCCost: CFTimeInterval = 0
        public var viewDidLoadCost: CFTimeInterval = 0
        public var viewDidAppearCost: CFTimeInterval = 0
        public var firstScreenDataReadyCost: CFTimeInterval = 0
        //可感知key，用于埋点。
        public var disposeKey: DisposedKey?
        public init() { }
    }

    private var info: Info?
    private var startID: CFTimeInterval?
    private var endID: CFTimeInterval?

    /// start
    /// - Parameters:
    ///   - tab: Tab
    /// Note: make sure call in main thread
    public mutating func start(tabKey: String, isInitialize: Bool) {
        let timeStamp = CACurrentMediaTime()
        if startID == nil {
            endID = timeStamp
        }
        startID = timeStamp
        info = Info(timestamp: timeStamp, toTab: tabKey, isInitialize: isInitialize)
    }

    /// end
    /// - Parameters:
    ///   - params: Params
    /// Note: make sure call in main thread
    public mutating func end(params: Params) {
        guard let info = info, startID == endID else {
            startID = nil
            return
        }
        startID = nil
        self.info = nil
        let end = CACurrentMediaTime()
        let key = CoreEventMonitor.Key.switch_tab_cost
        ClientPerf.shared.singleSlardarEvent(
            service: key.rawValue,
            cost: (end - info.timestamp) * 1_000,
            logid: key.logID,
            metric: [
                "init_vc": params.initVCCost,
                "view_did_appear": params.viewDidAppearCost,
                "view_did_load": params.viewDidLoadCost,
                "first_screen_data_ready": params.firstScreenDataReadyCost
            ],
            category: [
                "to_tab_key": info.toTab,
                "is_initialize": info.isInitialize
            ]
        )
    }

    /// cancel event
    public mutating func cancel() {
        startID = nil
        endID = nil
    }
}

/// AtListLoadCostMonitor
public struct AtListLoadCostMonitor {
    private var startTimestamp: CFTimeInterval?
    private var endTimestamp: CFTimeInterval?

    /// start
    /// Note: make sure call in main thread
    public mutating func start() {
        let timestamp = CACurrentMediaTime()
        if startTimestamp == nil {
            endTimestamp = timestamp
        }
        startTimestamp = timestamp
    }

    /// end
    /// Note: make sure call in main thread
    public mutating func end() {
        guard let start = startTimestamp, start == endTimestamp else {
            startTimestamp = nil
            return
        }
        startTimestamp = nil
        let end = CACurrentMediaTime()
        let key = CoreEventMonitor.Key.at_list_load_time
        ClientPerf.shared.singleSlardarEvent(service: key.rawValue, cost: (end - start) * 1_000, logid: key.logID)
    }

    /// cancel event
    public mutating func cancel() {
        startTimestamp = nil
        endTimestamp = nil
    }
}

/// main_tab_loading_time
public struct MainTabLoadingMonitor {
    private var startTime: CFTimeInterval?
    private var isStartup = true

    /// start
    /// Note: make sure call in main thread
    public mutating func start() {
        self.startTime = CACurrentMediaTime()
    }

    /// cancel
    /// Note: make sure call in main thread
    public mutating func cancel() {
        self.startTime = nil
    }

    /// end
    /// Note: make sure call in main thread
    public mutating func end() {
        defer {
            isStartup = false
            self.startTime = nil
        }
        guard
            let start = self.startTime,
            AppStartupMonitor.shared.isBackgroundLaunch != true,
            AppStartupMonitor.shared.isFastLogin == true
            else { return }
        let end = CACurrentMediaTime()
        let key = CoreEventMonitor.Key.main_tab_loading_time
        ClientPerf.shared.singleSlardarEvent(
            service: key.rawValue,
            cost: (end - start) * 1_000,
            logid: key.logID,
            category: ["is_startup": isStartup]
        )
    }
}
