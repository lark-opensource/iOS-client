//
//  AppStartupMonitor.swift
//  LarkCore
//
//  Created by 李晨 on 2019/1/3.
//

import UIKit
import Foundation
import LKCommonsTracker
import LKCommonsLogging
import AppContainer
import ThreadSafeDataStructure

// swiftlint:disable identifier_name
public let AppStartupMonitorService: String = "app_startup_time"
// swiftlint:enable identifier_name

public enum AppStartupMonitorKey: String {
    case startup = "latency"                // app 整体启动时间
    case rustSDK = "init_rust_sdk"          // rust sdk 初始化时间
    case ttnetInitialize = "ttnet_initialize"   // ttnet初始化
    case calendar = "init_calendar_sdk"     // calendar sdk 初始化时间
    case docSDK = "init_docs_sdk"           // docs sdk 初始化时间
    case docTabInit = "init_docs_tab"       // docs Tab 初始化时间
    case docAccountLoad = "docs_account_load"       // docs account loaded 时间s
    case mailSDK = "init_mail_sdk"          // mail sdk 初始化时间
    case microSDK = "init_micro_app_sdk"    // 小程序 sdk 初始化时间
    case byteviewSDK = "init_byteview_sdk"  // 音视频 sdk 初始化时间
    case voipSDK = "init_voip_sdk"          // 加密通话 sdk 初始化时间
    case monitor = "init_monitor_sdk"       // 所有监控平台
    case UA = "init_ua"                     // 设置系统 ua
    case push = "init_push"                 // 初始化通知、push 相关服务
    case shortcut = "load_shortcut"         // 加载首屏 shortcut 数据
    case feed = "load_feed"                 // 加载首屏 feed 数据
    case firstRender = "first_render"       // 绘制第一屏(不等远端数据加载完成)耗时

    case feedContextID = "context_id.load_feed"
    case shortcutContextID = "context_id.load_shortcut"
    case userID = "user_id"

    case initDomain = "init_domain"         // load domain config
    
    case initCallKit = "init_callkit"        // 初始化 CallKit
}

// 只在 account 登录 且 是前台登录的时候才需要上传数据

public final class AppStartupMonitor {

    static let logger = Logger.log(AppStartupMonitor.self, category: "app.startup.monitor")

    public static let shared = AppStartupMonitor()

    public private(set) var hadUploaded: Bool = false  // 是否已经上传了启动数据
    public var isFastLogin: Bool?  // 是否是快速登录
    public var isBackgroundLaunch: Bool? // 不是后台启动
    private var uploadTimeout: Bool = false // 判定本次上传超时 避免快速登录与正常登陆或者切换账号混淆

    public var needUpload: Bool {
        return (isFastLogin ?? false) && !(isBackgroundLaunch ?? true)
    }
    public var watchDogOpen: Bool = false // 开启一个 20s 的 timer 检测最终是否上传了启动数据

    var startupTimeStamp: CFTimeInterval = 0
    var latestEnterForegroundTimeStamp: CFTimeInterval = 0

    private var queue: DispatchQueue = DispatchQueue(label: "app.startup.monitor", qos: .utility)
    private var startupTimeDic: SafeDictionary<AppStartupMonitorKey, String> = [:] + .readWriteLock
    private var startupExtraDic: SafeDictionary<AppStartupMonitorKey, String> = [:] + .readWriteLock
    private var startTimeDic: SafeDictionary<AppStartupMonitorKey, CFTimeInterval> = [:] + .readWriteLock

    // Client Perf需要输出启动时间到日志，部分模块启动在日志模块初始化之前，需要缓存
    private var startTimeStampDic: SafeDictionary<AppStartupMonitorKey, TimeInterval> = [:] + .readWriteLock
    private var endTimeStampDic: SafeDictionary<AppStartupMonitorKey, TimeInterval> = [:] + .readWriteLock

    public func start(key: AppStartupMonitorKey) {
        self.startWatchDogIfNeeded()
        let startTime = AppMonitor.initStartupTimeStamp()

        // Client Perf
        let startTimeStamp = Date().timeIntervalSince1970 * 1_000
        self.startTimeStampDic[key] = startTimeStamp

        if self.uploadTimeout { return }
        if self.startTimeDic[key] != nil { return }
        // 超时之前 上传之后 执行start， 检查代码是否有bug
        if self.hadUploaded {
            assertionFailure()
            return
        }
        self.startTimeDic[key] = startTime
    }

    public func getStartTime(key: AppStartupMonitorKey) -> TimeInterval? {
        return self.startTimeDic[key]
    }

    public func end(key: AppStartupMonitorKey) {
        let endTime = CACurrentMediaTime()

        // Client Perf
        let endTimeStamp = Date().timeIntervalSince1970 * 1_000
        self.endTimeStampDic[key] = endTimeStamp

        if self.uploadTimeout { return }
        if self.startupTimeDic[key] != nil { return }
        // 超时之前 上传之后 执行end， 检查代码是否有bug
        if self.hadUploaded {
            assertionFailure()
            return
        }

        if let startTime = self.startTimeDic[key] {
            self.startupTimeDic[key] = "\((endTime - startTime) * 1_000)"
        } else {
            assertionFailure()
        }

        if key == .startup {
            // 首页出现之后 3s 上报启动时间打点
            self.queue.asyncAfter(deadline: .now() + 3, execute: {
                self.uploadStartupTime()
            })
        }
    }

    public func set(key: AppStartupMonitorKey, value: String) {
        if self.uploadTimeout { return }
        // 超时之前 上传之后 执行set， 检查代码是否有bug
        if self.startupExtraDic[key] != nil { return }

        if self.hadUploaded {
            assertionFailure()
            return
        }

        self.startupExtraDic[key] = value
    }

    private func uploadStartupTime() {
        if !self.needUpload { return }
        if self.hadUploaded { return }

        self.startTimeStampDic.forEach { ClientPerf.shared.startEvent($0.rawValue, time: $1) }
        self.endTimeStampDic.forEach { ClientPerf.shared.endEvent($0.rawValue, time: $1) }

        // TimeLogger 打点输出日志
        TimeLogger.shared.printDebugResult { (start: [String: TimeInterval], end: [String: TimeInterval]) in
            start.forEach { ClientPerf.shared.startEvent($0, time: $1) }
            end.forEach { ClientPerf.shared.endEvent($0, time: $1) }
        }

        if self.uploadTimeout {
            // 上传数据的时候已经超时 请检查是否代码存在错误
            AppStartupMonitor.logger.warn("App startup montior upload after timeout")
        }

        guard let value = self.startupTimeDic[.startup] else {
            assertionFailure() // 上传的时候必须存在启动时间主参数
            return
        }
        let metric = self.startupTimeDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }
        let extra = self.startupExtraDic.reduce([String: String]()) { (result, arg) -> [String: String] in
            let (key, value) = arg
            var result = result
            result[key.rawValue] = value
            return result
        }
        Tracker.post(SlardarEvent(
            name: AppStartupMonitorService,
            metric: metric,
            category: ["value": value],
            extra: extra)
        )
        self.hadUploaded = true
    }

    private func startWatchDogIfNeeded() {
        if self.watchDogOpen { return }
        self.watchDogOpen = true

        self.queue.asyncAfter(deadline: .now() + 20) { [weak self] in
            guard let `self` = self else { return }
            if self.needUpload && !self.hadUploaded {
                AppStartupMonitor.logger.warn("App startup monitor not upload when timeout")
            }
            if self.isFastLogin == nil || self.isBackgroundLaunch == nil {
                AppStartupMonitor.logger.warn("App startup monitor not set params when timeout")
            }

            self.uploadTimeout = true
        }
    }
}
