//
//  AppReciableSDK.swift
//  AppReciableSDK
//
//  Created by qihongye on 2020/7/30.
//

import Foundation
import LKCommonsTracker
import EEAtomic
import ThreadSafeDataStructure

/// Configuration for AppReciableSDK
public struct Configuration {
    /// startup time
    public let startupTimestamp: CFTimeInterval

    /// init for Configuration
    /// - Parameter startup: startup time, default CACurrentMediaTime()
    public init(startup: CFTimeInterval = CACurrentMediaTime()) {
        self.startupTimestamp = startup
    }
}

protocol ExtraEvent {
    var endTimestamp: CFTimeInterval { get }
    var extra: Extra? { get }
}

enum EventKey: String {
    case loadingKey = "appreciable_loading_time"
    case errorKey = "appreciable_error"
}

/// TimeCost参数
public struct TimeCostParams: CustomDebugStringConvertible {
    /// Biz
    public let biz: Biz
    /// Scene
    public let scene: Scene
    /// EventName
    public let event: ReciableEventable
    /// unit: ms. 毫秒为单位
    public let cost: Int
    /// 结束时间点,用于打印日志
    public var timestamp: TimeInterval?
    /// Acrtive ViewController name
    public let page: String?
    /// Extra info
    public let extra: Extra?
    /// 是否在后台
    public var isInBackground: Bool?
    /// init
    public init(biz: Biz, scene: Scene, eventable: ReciableEventable,
                cost: Int, page: String?, extra: Extra? = nil) {
        self.biz = biz
        self.scene = scene
        self.event = eventable
        self.cost = cost
        self.page = page
        self.extra = extra
    }

    /// convenience init
    public init(biz: Biz, scene: Scene, event: Event,
                cost: Int, page: String?, extra: Extra? = nil) {
        self.init(biz: biz, scene: scene, eventable: event, cost: cost, page: page, extra: extra)
    }

    func category(netStatus: Int, isInBackground: Bool) -> [String: Any] {
        var category: [String: Any] = [
            "biz": biz.rawValue,
            "scene": scene.rawValue,
            "need_net": extra?.isNeedNet ?? false,
            "net_status": netStatus,
            "is_in_background": isInBackground,
            "version": extra?.extra?["version"] ?? 1
        ]
        if let page = page {
            category["page"] = page
        }
        return category
    }

    func metric() -> [String: Any] {
        var map: [String: Any] = [
            "latency": cost,
            "event": event.eventKey
        ]
        if let detail = extra?.latencyDetail {
            map["latency_detail"] = detail
        }
        return map
    }

    public var debugDescription: String {
        let headerLabels: [String?] = [
            AppReciableSDK.LogID.latency.rawValue, event.eventKey, biz.debugDescription, scene.debugDescription, page
        ]
        let header = headerLabels.compactMap { $0 }.joined(separator: ":")
        return "[\(header)]=>[latency=\(cost)]"
            + "[is_in_background=\(isInBackground ?? false)]\(extra?.debugDescription ?? "")"
    }
}

/// ErrorParams
public struct ErrorParams: CustomDebugStringConvertible {
    /// Biz
    public let biz: Biz
    /// Scene
    public let scene: Scene
    /// Event
    public let event: ReciableEventable?
    /// ErrorType
    public let errorType: ErrorType
    /// ErrorLevel
    public let errorLevel: ErrorLevel
    /// ErrorCode
    public let errorCode: Int
    /// EventName
    public let userAction: String?
    /// Acrtive ViewController name
    public let page: String?
    /// Error message
    public let errorMessage: String?
    /// Extra info
    public let extra: Extra?
    /// 透传SDK侧的LarkError结构体里的status字段
    public let errorStatus: Int
    /// 结束时间点,用于打印日志
    public var timestamp: TimeInterval?

    /// init
    public init(biz: Biz, scene: Scene, eventable: ReciableEventable? = nil,
                errorType: ErrorType, errorLevel: ErrorLevel,
                errorCode: Int = 0, errorStatus: Int = 0, userAction: String?, page: String?,
                errorMessage: String?, extra: Extra? = nil) {
        self.biz = biz
        self.scene = scene
        self.event = eventable
        self.errorType = errorType
        self.errorLevel = errorLevel
        self.errorCode = errorCode
        self.userAction = userAction
        self.page = page
        self.errorMessage = errorMessage
        self.extra = extra
        self.errorStatus = errorStatus
    }

    /// convenience init
    public init(biz: Biz, scene: Scene, event: Event? = nil,
                errorType: ErrorType, errorLevel: ErrorLevel,
                errorCode: Int = 0, errorStatus: Int = 0, userAction: String?, page: String?,
                errorMessage: String?, extra: Extra? = nil) {
        self.init(biz: biz,
                  scene: scene,
                  eventable: event,
                  errorType: errorType,
                  errorLevel: errorLevel,
                  errorCode: errorCode,
                  errorStatus: errorStatus,
                  userAction: userAction,
                  page: page,
                  errorMessage: errorMessage,
                  extra: extra)
    }

    func metric() -> [String: Any] {
        var metric: [String: Any] = [
            "level": errorLevel.rawValue,
            "error_code": errorCode,
            "error_status": errorStatus
        ]
        if let event = event {
            metric["event"] = event.eventKey
        }
        if let errorMessage = errorMessage {
            metric["error_message"] = errorMessage
        }
        if let userAction = userAction {
            metric["user_action"] = userAction
        }
        return metric
    }

    func category(netStatus: Int, isInBackground: Bool) -> [String: Any] {
        var category: [String: Any] = [
            "biz": biz.rawValue,
            "scene": scene.rawValue,
            "error_type": errorType.rawValue,
            "need_net": extra?.isNeedNet ?? false,
            "is_in_background": isInBackground,
            "net_status": netStatus,
            "version": extra?.extra?["version"] ?? 1
        ]
        if let page = page {
            category["page"] = page
        }
        return category
    }

    public var debugDescription: String {
        let headerLabels: [String?] = [
            AppReciableSDK.LogID.error.rawValue, event?.eventKey, biz.debugDescription,
            scene.debugDescription, "\(errorCode)", errorLevel.debugDescription, errorType.debugDescription
        ]
        let header = headerLabels.compactMap({ $0 }).joined(separator: ":")
        return "[\(header)]=>[errorMessage=\(errorMessage ?? "")][\(extra?.debugDescription ?? "")]"
    }
}

/// Extra
public struct Extra: CustomDebugStringConvertible {
    /// Is need net
    public var isNeedNet: Bool
    /// Latency detail
    public var latencyDetail: [String: Any]?
    /// metric
    public var metric: [String: Any]?
    /// category
    public var category: [String: Any]?
    /// extra.extra
    public var extra: [String: Any]?

    /// Extra initialize
    /// - Parameters:
    ///   - isNeedNet: Is need net
    ///   - latencyDetail: Latency detail
    ///   - metric: Metric
    ///   - category: Category
    public init(
        isNeedNet: Bool = false,
        latencyDetail: [String: Any]? = nil,
        metric: [String: Any]? = nil,
        category: [String: Any]? = nil,
        extra: [String: Any]? = nil) {
        self.isNeedNet = isNeedNet
        self.latencyDetail = latencyDetail
        self.metric = metric
        self.category = category
        self.extra = extra
    }

    public var debugDescription: String {
        let bodyLabels: [String: String?] = [
            "need_net": isNeedNet.description,
            "latency_detail": debugDesc(latencyDetail),
            "extra.metric": debugDesc(metric),
            "extra.category": debugDesc(category),
            "extra.extra": debugDesc(extra)
        ]
        return bodyLabels.compactMap { (k, v) -> String? in
            guard let v = v else {
                return nil
            }
            return "[\(k)=\(v)]"
        }.joined()
    }

    @inline(__always)
    func debugDesc(_ map: [String: Any]?) -> String? {
        if let map = map {
            return "[\(map.compactMap({ "\($0.key)=\($0.value)" }).joined(separator: ","))]"
        }
        return nil
    }
}

public final class DisposedKey: Hashable, CustomDebugStringConvertible {
    let key: String
    let appReciableRef: AppReciableSDK

    init(key: String, _ appReciableRef: AppReciableSDK) {
        self.key = key
        self.appReciableRef = appReciableRef
    }

    deinit {
        appReciableRef.eventsMap.removeValue(forKey: key)
    }

    public var debugDescription: String {
        return key
    }

    public func hash(into hasher: inout Hasher) {
        key.hash(into: &hasher)
    }

    public static func == (lhs: DisposedKey, rhs: DisposedKey) -> Bool {
        return lhs.key == rhs.key
    }

    public static func == (lhs: DisposedKey, rhs: String) -> Bool {
        return lhs.key == rhs
    }

    public static func == (lhs: String, rhs: DisposedKey) -> Bool {
        return lhs == rhs.key
    }
}

/// AppReciableSDKPrinter
public protocol AppReciableSDKPrinter {
    /// info
    /// - Parameters:
    ///   - logID: logID
    ///   - message: log message
    ///   - timestamp: the timestamp corresponding to the log
    func info(logID: String, _ message: String, _ timestamp: TimeInterval?)

    /// error
    /// - Parameters:
    ///   - logID: logID
    ///   - message: error message
    ///   - timestamp: the timestamp corresponding to the log
    func error(logID: String, _ message: String, _ timestamp: TimeInterval?)
}

public extension AppReciableSDKPrinter {
    func info(logID: String, _ message: String) {
        info(logID: logID, message, nil)
    }
    func error(logID: String, _ message: String) {
        error(logID: logID, message, nil)
    }
}

/// https://bytedance.feishu.cn/wiki/wikcnAPLiePd7qjpAlCrkgLmG9g#
public final class AppReciableSDK {
    enum LogID: String {
        case latency = "appreciable_log:latency"
        case error = "appreciable_log:error"
    }

    struct LoadingTimeEvent: ExtraEvent, CustomDebugStringConvertible {
        let startTimestamp: CFTimeInterval
        var endTimestamp: CFTimeInterval
        var hasPause: Bool = false
        var pauseTimestamp: CFTimeInterval = 0
        var pauseTime: CFTimeInterval = 0
        let biz: Biz
        let scene: Scene
        let event: String
        let page: String?
        let userAction: String?
        var extra: Extra?
        var isInBackground: Bool = false

        func latency() -> Int {
            return Int(((endTimestamp - startTimestamp) - pauseTime) * 1_000)
        }

        func metric() -> [String: Any] {
            var map: [String: Any] = [
                "latency": latency(),
                "event": event
            ]
            if let latencyDetail = extra?.latencyDetail {
                map["latency_detail"] = latencyDetail
            }
            return map
        }

        func category(netStatus: Int) -> [String: Any] {
            var category: [String: Any] = [
                "biz": biz.rawValue,
                "scene": scene.rawValue,
                "need_net": extra?.isNeedNet ?? false,
                "net_status": netStatus,
                "is_in_background": isInBackground,
                "version": extra?.extra?["version"] ?? 1
            ]
            if let page = page {
                category["page"] = page
            }
            return category
        }

        mutating func pause() -> Bool {
            if hasPause {
                return false
            }
            hasPause = true
            pauseTimestamp = CACurrentMediaTime()
            return true
        }

        mutating func `continue`() -> Bool {
            if !hasPause {
                return false
            }
            hasPause = false
            pauseTime += CACurrentMediaTime() - pauseTimestamp
            return true
        }

        mutating func mergeExtra(_ extra: Extra?) {
            guard let extra = extra else {
                return
            }
            guard var originExtra = self.extra else {
                self.extra = extra
                return
            }
            originExtra.isNeedNet = extra.isNeedNet
            if let latencyDetail = extra.latencyDetail {
                var origin = originExtra.latencyDetail ?? [:]
                for (k, v) in latencyDetail {
                    origin[k] = v
                }
                originExtra.latencyDetail = origin
            }
            if let metric = extra.metric {
                var originMetric = originExtra.metric ?? [:]
                for (k, v) in metric {
                    originMetric[k] = v
                }
                originExtra.metric = originMetric
            }
            if let category = extra.category {
                var originCategory = originExtra.category ?? [:]
                for (k, v) in category {
                    originCategory[k] = v
                }
                originExtra.category = originCategory
            }
            if let extra = extra.extra {
                var originExtraExtra = originExtra.extra ?? [:]
                for (k, v) in extra {
                    originExtraExtra[k] = v
                }
                originExtra.extra = originExtraExtra
            }
            self.extra = originExtra
        }

        var debugDescription: String {
            let headerLabels: [String?] = [
                LogID.latency.rawValue, event, biz.debugDescription, scene.debugDescription, page
            ]
            let header = headerLabels.compactMap { $0 }.joined(separator: ":")
            return "[\(header)]=>[latency=\(latency())]"
                + "[is_in_background=\(isInBackground)]\(extra?.debugDescription ?? "")"
        }
    }

    /// shared
    public static let shared = AppReciableSDK()

    private var latestEnterForegroundTime: AtomicInt64Cell
    private let startupToken = AtomicOnce()
    private let printerToken = AtomicOnce()
    private var configuration: Configuration
    private var counter: Int32 = 0
    private var printer: AppReciableSDKPrinter?
    private var isCurrentInBackground: Bool = false

    struct NetStatusItem {
        let timestamp: CFTimeInterval
        let netStatus: Int

        init(timestamp: CFTimeInterval = CACurrentMediaTime(), netStatus: Int) {
            self.timestamp = timestamp
            self.netStatus = netStatus
        }
    }
    private var netStatusRecords: AtomicObject<LimitQueue<NetStatusItem>>
    private var maxNetStausValue: Int = .max

    var eventsMap = SafeDictionary<String, LoadingTimeEvent>([:], synchronization: .readWriteLock)

    /// init
    /// - Parameter configuration: Configuration
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
        latestEnterForegroundTime = AtomicInt64Cell(Int64(configuration.startupTimestamp * 1_000))
        netStatusRecords = AtomicObject(LimitQueue(capacity: 100))
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    /// setNetStatus
    /// - Parameter status: Net work status
    public func setNetStatus(_ status: Int) {
        netStatusRecords.value.push(NetStatusItem(netStatus: status))
    }

    public func setMaxNetStatus(_ status: Int) {
        maxNetStausValue = status
    }

    /// setStartupTimeStamp
    /// - Parameter time: startup timestamp
    public func setStartupTimeStamp(_ time: CFTimeInterval) {
        startupToken.once {
            configuration = Configuration(startup: time)
            latestEnterForegroundTime.value = Int64(time * 1_000)
        }
    }

    /// setupPrinter
    /// - Parameter printer: AppReciableSDKPrinter
    public func setupPrinter(_ printer: AppReciableSDKPrinter) {
        printerToken.once {
            self.printer = printer
        }
    }

    /// setEnterForegroundTimeStamp
    /// - Parameter msTime: CACurrentMediaTime()
    public func setEnterForegroundTimeStamp(msTime: CFTimeInterval) {
        latestEnterForegroundTime.value = Int64(msTime)
    }

    /// error
    /// - Parameter params: ErrorParams
    public func error(params: ErrorParams) {
        #if !DEBUG
        Tracker.post(SlardarEvent(
            name: EventKey.errorKey.rawValue,
            metric: params.metric(),
            category: params.category(
                netStatus: netStatusRecords.value.last?.netStatus ?? 0,
                isInBackground: isCurrentInBackground
            ),
            extra: getExtra(params)
        ))
        if let event = params.event {
            let eventKey = "appr_error_\(event.eventKey)"
            self.trackerToTea(eventKey: eventKey, metric: params.metric(), category: params.category(
                netStatus: netStatusRecords.value.last?.netStatus ?? 0,
                isInBackground: isCurrentInBackground
            ), extraEvent: params)
        }
        #endif
        printer?.error(logID: LogID.error.rawValue, params.debugDescription, params.timestamp)
    }

    /// start event
    /// - Parameters:
    ///   - biz: Biz
    ///   - scene: Scene
    ///   - event: eventName
    ///   - page: Which ViewController. 当前事件发生在哪个页面
    ///   - extra: more infomation that user passed. 更多的信息
    /// - Returns: Key
    public func start(biz: Biz,
                      scene: Scene,
                      eventable: ReciableEventable,
                      page: String?,
                      userAction: String? = nil,
                      extra: Extra? = nil) -> DisposedKey {
        let msTimestamp = CACurrentMediaTime()
        let key = "\(String(format: "%0.f", msTimestamp))\(uuint())"
        eventsMap[key] = LoadingTimeEvent(
            startTimestamp: msTimestamp,
            endTimestamp: msTimestamp,
            pauseTime: 0,
            biz: biz,
            scene: scene,
            event: eventable.eventKey,
            page: page,
            userAction: userAction,
            extra: extra
        )

        return DisposedKey(key: key, self)
    }

    /// same as  "start(biz: Biz, scene: Scene, event: Event, page: String?)"
    public func start(biz: Biz,
                      scene: Scene,
                      event: Event,
                      page: String?,
                      userAction: String? = nil,
                      extra: Extra? = nil) -> DisposedKey {
        return self.start(biz: biz, scene: scene, eventable: event, page: page, userAction: userAction, extra: extra)
    }

    /// start event
    /// - Parameters:
    ///   - biz: Biz
    ///   - scene: Scene
    ///   - event: eventName
    ///   - page: Which ViewController. 当前事件发生在哪个页面
    ///   - extra: more infomation that user passed. 更多的信息
    /// - Returns: Key
    @available(*, deprecated, message: "Please use start(biz: Biz, scene: Scene, event: Event, page: String?)")
    public func start(biz: Biz,
                      scene: Scene,
                      event: String,
                      page: String?,
                      userAction: String? = nil,
                      extra: [String: Any]? = nil) -> DisposedKey {
        let msTimestamp = CACurrentMediaTime()
        let key = "\(String(format: "%0.f", msTimestamp))\(uuint())"
        eventsMap[key] = LoadingTimeEvent(
            startTimestamp: msTimestamp,
            endTimestamp: msTimestamp,
            pauseTime: 0,
            biz: biz,
            scene: scene,
            event: event,
            page: page,
            userAction: userAction,
            extra: Extra(isNeedNet: false, latencyDetail: nil, metric: extra, category: nil)
        )

        return DisposedKey(key: key, self)
    }

    /// pause
    /// - Parameters:
    ///   - key: start() return value.
    ///   - extra: more infomation that user passed. 更多的信息
    public func pause(key: DisposedKey, extra: Extra? = nil) {
        if !eventsMap.keys.contains(key.key) {
            return
        }
        eventsMap.safeWrite(for: key.key) { (event) in
            if event?.pause() == true {
                event?.mergeExtra(extra)
            }
        }
    }

    /// continue
    /// - Parameters:
    ///   - key: start() return value.
    ///   - extra: more infomation that user passed. 更多的信息
    public func `continue`(key: DisposedKey, extra: Extra? = nil) {
        if !eventsMap.keys.contains(key.key) {
            return
        }
        eventsMap.safeWrite(for: key.key) { (event) in
            if event?.continue() == true {
                event?.mergeExtra(extra)
            }
        }
    }

    /// end
    /// - Parameters:
    ///   - key: start() return value.
    ///   - extra: more infomation that user passed. 更多的信息
    public func end(key: DisposedKey, extra: Extra? = nil) {
        guard let event = endAndReturnEvent(key: key.key, extra: extra) else {
            assertionFailure("End without start!")
            return
        }

        if event.isInBackground {
            printer?.info(
                logID: LogID.latency.rawValue,
                "\(event.event), In background, does not post event!"
            )
        }

        #if !DEBUG
        Tracker.post(SlardarEvent(
            name: EventKey.loadingKey.rawValue,
            metric: event.metric(),
            category: event.category(netStatus: getActualNetStatus(
                    start: event.startTimestamp,
                    end: event.endTimestamp
                )
            ),
            extra: getExtra(event)
        ))

        //往T埋点
        let eventKey = "appr_time_\(event.event)"
        self.trackerToTea(eventKey: eventKey, metric: event.metric(), category: event.category(netStatus: getActualNetStatus(
            start: event.startTimestamp,
            end: event.endTimestamp
        )
    ), extraEvent: event)
        #endif
        printer?.info(logID: LogID.latency.rawValue, event.debugDescription)
    }

    //往可感知Tea打点
    private func trackerToTea(eventKey: String, metric: [String: Any], category: [String: Any], extraEvent: ExtraEvent) {
        var params: [String: Any] = [:]
        var extra: [String: Any] = [:]
        extra["since_latest_startup"] = "\(Int((extraEvent.endTimestamp - configuration.startupTimestamp) * 1_000))"
        let sinceLatestEnterForegroundTime = Int64(extraEvent.endTimestamp * 1_000) - latestEnterForegroundTime.value
        extra["since_latest_enter_foreground"] = "\(sinceLatestEnterForegroundTime)"
        params.merge(extra, uniquingKeysWith: { (first, _) in first })

        var extraMetirc = extraEvent.extra?.metric
        var extraCategory = extraEvent.extra?.category
        var extraExtra = extraEvent.extra?.extra
        if let extraMetirc = extraMetirc as? [String: Any] {
            params.merge(extraMetirc, uniquingKeysWith: { (first, _) in first })
        }
        if let extraCategory = extraCategory as? [String: Any] {
            params.merge(extraCategory, uniquingKeysWith: { (first, _) in first })
        }
        if let extraExtra = extraExtra as? [String: Any] {
            params.merge(extraExtra, uniquingKeysWith: { (first, _) in first })
        }
        if let latencyDetail = metric["latency_detail"] as? [String: Any] {
            params.merge(latencyDetail, uniquingKeysWith: { (first, _) in first })
        }
        params.merge(metric, uniquingKeysWith: { (first, _) in first })
        params.merge(category, uniquingKeysWith: { (first, _) in first })
        Tracker.post(TeaEvent(eventKey, params: params))
    }

    /// timeCost
    /// - Parameter params: TimeCostParams
    public func timeCost(params: TimeCostParams) {
        let end = CACurrentMediaTime()
        let start = end - CFTimeInterval(params.cost / 1_000)
        let enterBackgroundTime = CFTimeInterval(latestEnterForegroundTime.value / 1_000)
        let isInBackground = isCurrentInBackground ||
            (start < enterBackgroundTime && end > enterBackgroundTime)
        if isInBackground {
            printer?.info(
                logID: LogID.latency.rawValue,
                "\(params.event.eventKey), In background, does not post event!"
            )
        }
        var params = params
        params.isInBackground = isInBackground
        printer?.info(logID: LogID.latency.rawValue, params.debugDescription, params.timestamp)
        #if !DEBUG
        Tracker.post(SlardarEvent(
            name: EventKey.loadingKey.rawValue,
            metric: params.metric(),
            category: params.category(
                netStatus: getActualNetStatus(start: start, end: end),
                isInBackground: isInBackground
            ),
            extra: getExtra(params))
        )
        let eventKey = "appr_time_\(params.event.eventKey)"
        self.trackerToTea(eventKey: eventKey, metric: params.metric(), category: params.category(
            netStatus: getActualNetStatus(start: start, end: end),
            isInBackground: isInBackground
        ), extraEvent: params)
        #endif
    }

    @inline(__always)
    func uuint() -> Int32 {
        return OSAtomicIncrement32(&counter) & Int32.max
    }

    @inline(__always)
    func getExtra(_ extraEvent: ExtraEvent) -> [String: Any] {
        var extra: [String: Any] = [:]
        extra["since_latest_startup"] = "\(Int((extraEvent.endTimestamp - configuration.startupTimestamp) * 1_000))"
        let sinceLatestEnterForegroundTime = Int64(extraEvent.endTimestamp * 1_000) - latestEnterForegroundTime.value
        extra["since_latest_enter_foreground"] = "\(sinceLatestEnterForegroundTime)"
        if let metric = extraEvent.extra?.metric {
            extra["metric"] = metric
        }
        if let category = extraEvent.extra?.category {
            extra["category"] = category
        }
        if let extraExtra = extraEvent.extra?.extra {
            extra["extra"] = extraExtra
        }
        return extra
    }

    @inline(__always)
    func endAndReturnEvent(key: String, extra: Extra?) -> LoadingTimeEvent? {
        guard var event = eventsMap.removeValue(forKey: key) else {
            return nil
        }
        event.mergeExtra(extra)
        event.endTimestamp = CACurrentMediaTime()
        return event
    }

    @objc
    private func applicationWillEnterForeground() {
        isCurrentInBackground = false
        setEnterForegroundTimeStamp(msTime: CACurrentMediaTime() * 1_000)
        eventsMap.safeWrite { (map) in
            for (k, _) in map {
                map[k]?.isInBackground = true
            }
        }
    }

    @objc
    private func applicationDidEnterBackground() {
        isCurrentInBackground = true
    }

    public func getActualNetStatus(start: CFTimeInterval, end: CFTimeInterval) -> Int {
        var netStatus = 0
        var netStatusHasChanged = false
        netStatusRecords.value.forEach { (item) in
            if item.timestamp >= start && item.timestamp <= end {
                netStatusHasChanged = true
                netStatus = max(item.netStatus, netStatus)
            }
            if netStatus >= maxNetStausValue {
                return false
            }
            return true
        }
        if netStatusHasChanged {
            return netStatus
        }
        // 如果上报埋点的时候，确实还没传入netStatus，则上报0
        return netStatusRecords.value.last?.netStatus ?? 0
    }

    public func isInBackground(start: CFTimeInterval, end: CFTimeInterval) -> Bool {
        let enterBackgroundTime = CFTimeInterval(latestEnterForegroundTime.value / 1_000)
        return (isCurrentInBackground || (start < enterBackgroundTime && end > enterBackgroundTime))
    }

    func appendNetStatusRecord(_ record: NetStatusItem) {
        netStatusRecords.value.push(record)
    }
}

extension TimeCostParams: ExtraEvent {
    var endTimestamp: CFTimeInterval {
        return CACurrentMediaTime()
    }
}

extension ErrorParams: ExtraEvent {
    var endTimestamp: CFTimeInterval {
        return CACurrentMediaTime()
    }
}
