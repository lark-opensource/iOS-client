// longweiwei

import Foundation
import CryptoSwift
import LarkFoundation
import Homeric

public final class MailTracker {

    public static let shared = MailTracker()

    fileprivate static let costTimeLock = NSLock()
    fileprivate static let memoryDiffLock = NSLock()

    fileprivate static let serialQueue = DispatchQueue(label: "MailSDK.Tracker.Queue",
                                                       attributes: .init(rawValue: 0))

    public class func log(event eventName: String, params: [String: Any]?) {
        // 区分三方客户端和saas
        var finalParams = params
        if eventName != Homeric.EMAIL_MAILSDK_LAUNCH_DURATION { // 自动屏蔽
            finalParams?.updateValue(Store.settingData.getMailAccountType(), forKey: "mail_account_type")
        }
        // 最终调用到LarkMail去执行上报操作
        // 增加模拟器过滤
        if LarkFoundation.Utils.isSimulator {
            print("MailTracker: log \(eventName) with params: \(String(describing: finalParams ?? [:]))")
            //MailTracker.reportToAppReciableSDK(key: eventName, param: params)
            return
        }
        #if DEBUG
        MailLogger.debug(eventName, extraInfo: params, error: nil, component: nil)
        #else
        serialQueue.async {
            ProviderManager.default.trackProvider?.handleMailTrackEvent(eventName, params: finalParams)
        }
        #endif
    }

    /// 终止耗时打点，不上报
    class func abortRecordTimeConsuming(event eventName: String) {
        serialQueue.async {
            MailLogger.info("MailTracker: abort \(eventName)")
            guard timeEvents[eventName] != nil else { return }
            timeEvents[eventName] = nil
        }
    }

    class func addTimeConsuming(subEvents: [String], inEvent eventName: String, startAndEndTime: (Int, Int)? = nil) {
        let startTime = getCurrentTime()
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            guard var mainEvent = timeEvents[eventName] else { return }
            for sub in subEvents {
                if let startAndEnd = startAndEndTime {
                    mainEvent.subEvents[sub] = startAndEnd
                } else {
                    mainEvent.subEvents[sub] = (startTime, nil)
                }
                let costTime: String
                if let startAndEnd = startAndEndTime {
                    costTime = "\(startAndEnd.1 - startAndEnd.0)"
                } else {
                    costTime = "nil"
                }
                MailLogger.info("MailTracker: \(eventName) -> \(sub) addTime, start:\(startAndEndTime?.0 ?? startTime) end: \(startAndEndTime?.1 ?? 0), costTime: \(costTime)")
            }
            timeEvents[mainEvent.eventName] = mainEvent
        }
    }

    class func endTimeConsuming(subEvents: [String], inEvent eventName: String) {
        let endTime = getCurrentTime()
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            guard var mainEvent = timeEvents[eventName] else {
                print("Event \(eventName) has subevents ended before event created \(subEvents)")
                return
            }
            for (subEventName, var subEventStartAndEnd) in mainEvent.subEvents where subEvents.contains(subEventName) {
                subEventStartAndEnd.eventEndTime = endTime
                let costTime = endTime - subEventStartAndEnd.eventBeginTime
                MailLogger.info("MailTracker: \(eventName) -> \(subEventName) end, start:\(subEventStartAndEnd.eventBeginTime) end: \(endTime), cost_time: \(costTime)")
                mainEvent.subEvents[subEventName] = subEventStartAndEnd
            }
            timeEvents[eventName] = mainEvent
        }
    }

    class func updateParams(event eventName: String, params: [String: Any]) {
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            guard var mainEvent = timeEvents[eventName] else { return }
            var newParams = mainEvent.params ?? params
            newParams.merge(other: params)
            mainEvent.params = newParams

            timeEvents[eventName] = mainEvent
        }
    }

    /// 重新开始计时，更新已开始打点的currentTime
    class func restartRecordTimeConsuming(event eventName: String) {
        let beginTime = getCurrentTime()
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            if var event = timeEvents[eventName] {
                event.eventBeginTime = beginTime
                timeEvents[eventName] = event

                let subEventsString = event.subEvents.keys.reduce("", { $0 + "|\($1)" })
                MailLogger.info("MailTracker: \(eventName) restart to beginTime: \(beginTime), withSubEvents: \(subEventsString)")
            }
        }
    }

    /// 耗时埋点记录开始
    class func startRecordTimeConsuming(event eventName: String, subEvents: [String]? = nil, params: [String: Any]?, currentTime: Int? = nil) {
        let beginTime = getCurrentTime()
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            let event = MailTrackerTimeEvent(event: eventName, beginTime: currentTime ?? beginTime, subEvents: subEvents, params: params)
            timeEvents[event.eventName] = event
            let subEventsStr = subEvents?.reduce("", { return $0 + "|\($1)" }) ?? ""
            MailLogger.info("MailTracker: \(eventName) start with subs \(subEventsStr), begin: \(beginTime)")
        }
    }

    /// 耗时埋点记录结束
    class func endRecordTimeConsuming(event eventName: String, params: [String: Any]?, currentTime: Int? = nil, useNewKey: Bool = false) {
        serialQueue.async {
            costTimeLock.lock()
            defer { costTimeLock.unlock() }

            guard var event = timeEvents[eventName] else { return }
            let allParams = event.end(useNewKey: useNewKey)
            MailTracker.log(event: event.eventName, params: allParams)
            timeEvents[event.eventName] = nil
            MailLogger.info("MailTracker: \(eventName) end, params \(allParams)")
        }
    }

    /// 内存快照记录开始
    class func startRecordMemory(event eventName: String, params: [String: Any]?) {
        serialQueue.async {
            memoryDiffLock.lock()
            defer { memoryDiffLock.unlock() }

            memoryValue[eventName] = MailPerformanceUtil.usedMemoryInMB()
            uploadParameters[eventName] = params
        }
    }

    /// 内存快照记录结束
    class func endRecordMemory(event eventName: String, params: [String: Any]?) {
        serialQueue.async {
            memoryDiffLock.lock()
            defer { memoryDiffLock.unlock() }

            guard let lastMemory = self.memoryValue[eventName] else { return }
            let memoryDifference = MailPerformanceUtil.usedMemoryInMB() - lastMemory

            var allParames: [String: Any] = ["memory_difference": memoryDifference]
            if let uploadParameter = self.uploadParameters[eventName] {
                allParames.merge(other: uploadParameter)
            }
            allParames.merge(other: params)
            MailTracker.log(event: eventName, params: allParames)
            MailLogger.info("memory event: \(eventName) end, params \(allParames)")
            self.memoryValue[eventName] = nil
        }
    }

    // 以后接管账号切换的时候可能需要用上
    static func setupUserID(_ userID: String) {
//        let uuid = MailUserIDEncryptoKit.encryptoId(userID)
//        TTTracker.sharedInstance().setCurrentUserUniqueID(uuid)
//        print("\(uuid)")
    }
}

extension MailTracker {
    private static var timeEvents = [String: MailTrackerTimeEvent]()
    private static var memoryValue: Dictionary = [String: Float]()
    private static var uploadParameters = [String: [String: Any]]()

    /// timeIntervalSince1970 in ms
    class func getCurrentTime() -> Int {
        return Int(1000 * Date().timeIntervalSince1970)
    }
}

extension MailTracker {
    // Params
    /// Int
    static let MESSAGE_COUNT = "mail_message_count"
    /// String
    static let THREAD_ID = "mail_thread_id"
    /// Int
    static let THREAD_BODY_LENGTH = "mail_thread_body_length"
    /// Int
    static let HAS_BIG_MESSAGE = "has_big_message"
    /// Int
    static let TIME_COST_GET_RUST_DATA = "get_rust_data_cost_time"
    /// Int
    static let TIME_COST_PARSE_HTML = "parse_html_cost_time"
    /// Int
    static let TIME_COST_RENDER_PAGE = "render_page_cost_time"
    /// Int
    static let GET_RUST_DATA_FROM_NET = "get_rust_data_from_net"
    /// int
    static let INIT_WEBVIEW_COST_TIME = "init_webview_cost_time"
    /// int
    static let FROM_NOTIFICATION = "from_notification"
    /// string
    static let OPTIMIZE_FEAT = "optimize_feat"
    /// int
    static let IS_READ = "is_read"
    /// int
    static let FROM_READ_MORE = "from_read_more"
}

struct MailTrackerTimeEvent {
    let eventName: String
    var eventBeginTime: Int

    var params: [String: Any]?
    var subEvents: [String: (eventBeginTime: Int, eventEndTime: Int?)]
    var eventEndTime: Int?

    init(event: String, beginTime: Int, subEvents: [String]?, params: [String: Any]?) {
        self.eventName = event
        self.eventBeginTime = beginTime
        self.params = params
        var subs = [String: (eventBeginTime: Int, eventEndTime: Int?)]()
        for subEventName in subEvents ?? [] {
            subs[subEventName] = (beginTime, nil)
        }
        self.subEvents = subs
    }

    /// 停止计时并返回打点参数
    mutating func end(useNewKey: Bool) -> [String: Any] {
        let costTimeKey = useNewKey ? "time_cost_ms" : "mail_cost_time"
        var allParames: [String: Any] = [costTimeKey: getCostTime()]
        allParames.merge(other: params)
        allParames.merge(other: getSubEventsCostTime())
        allParames.merge(other: params)
        return allParames
    }

    private mutating func getCostTime() -> Int {
        let end: Int
        if let eventEndTime = eventEndTime {
            end = eventEndTime
        } else {
            end = MailTracker.getCurrentTime()
            eventEndTime = end
        }
        return end - eventBeginTime
    }

    func getSubEventsCostTime() -> [String: Int] {
        var costTimes = [String: Int]()
        for (subEventName, sub) in subEvents {
            let end: Int
            if let endTime = sub.eventEndTime {
                end = endTime
            } else {
                end = eventEndTime ?? MailTracker.getCurrentTime()
            }
            costTimes[subEventName] = end - sub.eventBeginTime
            MailLogger.info("MailTracker: \(eventName) -> \(subEventName) end, endTime: \(end), begin: \(sub.eventBeginTime), cost_time: \(end - sub.eventBeginTime)")
        }
        return costTimes
    }
}
