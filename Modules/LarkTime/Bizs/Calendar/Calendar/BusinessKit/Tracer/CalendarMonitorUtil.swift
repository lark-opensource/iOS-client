//
//  CalendarMonitorUnit.swift
//  Alamofire
//
//  Created by zhouyuan on 2019/3/11.
//

import UIKit
import Foundation
import CalendarFoundation
import RxSwift
import ThreadSafeDataStructure
import AppReciableSDK
import RxRelay
import LarkContainer
import AppContainer
enum CalendarMonitorKey: String {
    /// 视图加载时间
    case daysViewLoadTime = "days_view_load_time"

    /// 详情页加载时间
    case detailLoadTime = "detail_load_time"
}

extension Foundation.Notification {
    public static let calendarHomeLaunchFinish = Notification(name: Notification.Name(rawValue: "lark.calendar.calendarHomeLaunchFinish"))
}

struct MonitorTask {
    let startTime: CFTimeInterval
    let callback: (CFTimeInterval, [String: Any]) -> Void
    init(startTime: CFTimeInterval,
         callback: @escaping (CFTimeInterval, [String: Any]) -> Void) {
        self.startTime = startTime
        self.callback = callback
    }
}

enum LaunchDetailTimeKey: String {
    case launchLaterApp
    case showGrid
    case getInstance
    case loadSetting
    case renderInstance
    case viewDidLoad
    case initEventVC
    case didAppearGap
    case instanceRenderGap
    case handleInstance
    case getInstanceLayout
}

final class TimeTracer {
    enum TracerExtra: String {
        case firstScreenInstancesLength
        case cachedInstancesLength
    }

    let key: LaunchDetailTimeKey
    private(set) var cost: Double = 0.0
    private(set) var extra: [TracerExtra: Any] = [:]
    private var traced = false
    init(key: LaunchDetailTimeKey) {
        self.key = key
    }

    func start() {
        guard !traced else { return }
        TimerMonitorHelper.shared.start(key: self.key.rawValue) { [weak self] (cost, _) in
            guard let `self` = self else { return }
            self.cost = cost
        }
    }

    func cancel() {
        guard !traced else { return }

        TimerMonitorHelper.shared.cancel(key: self.key.rawValue)
    }

    func end(extra: [TracerExtra: Any] = [:]) {
        guard !traced else { return }

        TimerMonitorHelper.shared.end(key: self.key.rawValue)
        traced = true
        self.extra = extra
    }

    func error() {
        TimerMonitorHelper.shared.error(key: self.key.rawValue)
        traced = false
        self.extra = [:]
    }

    func isTraced() -> Bool {
        return traced
    }
}

final class LaunchTimeTracer {
    /// 记录Lark冷启动后，日历冷启动时间
    let launchLaterApp = TimeTracer(key: .launchLaterApp)
    /// 记录显示网格线时间
    let showGrid = TimeTracer(key: .showGrid)
    /// 记录冷启动getInstance时间
    let getInstance = TimeTracer(key: .getInstance)
    /// 记录setting获取时间
    let loadSetting = TimeTracer(key: .loadSetting)
    /// 记录渲染日程块时间
    let renderInstance = TimeTracer(key: .renderInstance)
    /// 记录初始化VC时间
    let initEventVC = TimeTracer(key: .initEventVC)
    let viewDidLoad = TimeTracer(key: .viewDidLoad)
    /// 记录viewdidload到 didAppear时间。其他主线程任务插入runloop可能导致此时间变长
    let didAppearGap = TimeTracer(key: .didAppearGap)
    /// 记录instance转换为ViewData时间
    let handleInstance = TimeTracer(key: .handleInstance)
    /// 只有日/3日视图有
    let getInstanceLayout = TimeTracer(key: .getInstanceLayout)
    /// viewDidAppear到instance render时间。其他线程抢占可能导致此时间变长
    let instanceRenderGap = TimeTracer(key: .instanceRenderGap)
}

final class TimerMonitorHelper {
    static let shared = TimerMonitorHelper()
    var launchTimeTracer: LaunchTimeTracer?

    private(set) var currentMemory: CGFloat = -1.0
    var tasks: SafeDictionary<String, MonitorTask> = [:] + .readWriteLock

    //记录日历冷启动时内存
    func traceCalendarLaunchMem() {
        self.currentMemory = getCurrentMemoryUsageInBytes()
    }

    //获取内存增量
    func getCalendarLaunchMem() -> Int {
        let result = getCurrentMemoryUsageInBytes() - self.currentMemory
        self.currentMemory = -1.0
        return Int(result) < 0 ? 0 : Int(result) //冷启动lark前2s内存变化较大，可能出现增量为负
    }

    func getFirstScreenInstancesLength() -> Int {
        guard let lauchTimeTracer = TimerMonitorHelper.shared.launchTimeTracer else { return -1 }
        let instanceExtra = lauchTimeTracer.getInstance.extra
        let dataLength = instanceExtra[.firstScreenInstancesLength] as? Int ?? -1
        return dataLength
    }

    func getCachedInstanceLength() -> Int {
        guard let instanceExtra = TimerMonitorHelper.shared.launchTimeTracer?.getInstance.extra else { return -1 }
        return instanceExtra[.cachedInstancesLength] as? Int ?? -1
    }

    func start(key: String,
               callback: @escaping (CFTimeInterval, [String: Any]) -> Void) {
        let startTime = CACurrentMediaTime()
        self.tasks[key] = MonitorTask(startTime: startTime,
                                      callback: callback)
    }

    func cancel(key: String) {
        self.tasks.safeWrite { (tasks) in
            guard let task = tasks[key] else {
                return
            }

            tasks.removeValue(forKey: key)
        }
    }

    func end(key: String, extra: [String: Any] = [:]) {
        self.tasks.safeWrite { (tasks) in
            guard let task = tasks[key] else {
                return
            }

            let cost = round((CACurrentMediaTime() - task.startTime) * 1000)
            //抛弃大于2分钟的数据
            task.callback(cost, extra)
            tasks.removeValue(forKey: key)
        }
    }

    func error(key: String) {
        self.tasks.removeValue(forKey: key)
    }
}

final class CalendarMonitorUtil {
    static var hadTrackPerfCalLaunch: Bool = false //为避免切换视图触发埋点
    static func startTrackHomePageLoad(firstScreenDataReady: BehaviorRelay<Bool>) {
        let mode = CalendarDayViewSwitcher().mode
        ReciableTracer.shared.recTracerStart(scene: Scene.CalDiagram, event: "cal_click_tab", page: getCalRecTracerPage())
        TimerMonitorHelper.shared
            .start(key: CalendarMonitorKey.daysViewLoadTime.rawValue) { (cost, _) in
                ReciableTracer.shared.recTracerEnd(scene: Scene.CalDiagram, event: "cal_click_tab", page: getCalRecTracerPage())
                firstScreenDataReady.accept(true)
                if let launchTimeTracer = TimerMonitorHelper.shared.launchTimeTracer {
                    CalendarTracer.shareInstance.perfCalLaunch(
                        costTime: cost,
                        launchTimeTracer: launchTimeTracer,
                        viewType: CalendarTracer.ViewType(mode: mode))
                }
                // 标记冷启动完成
                HomeScene.coldLaunchState = .end
                CalendarMonitorUtil.hadTrackPerfCalLaunch = true
                TimerMonitorHelper.shared.launchTimeTracer = nil
            }
    }

    static func getCalRecTracerPage() -> String {
        let mode = CalendarDayViewSwitcher().mode
        switch mode {
        case .month:
            return "cal_month_diagram"
        case .threeDay, .week:
            return "cal_three_diagram"
        case .schedule:
            return "cal_list_diagram"
        case .singleDay:
            return "cal_daily_diagram"
        }
    }

    static func cancelTrackHomePageLoad() {
        guard !hadTrackPerfCalLaunch else { return }
        NotificationCenter.default.post(Notification.calendarHomeLaunchFinish)
        TimerMonitorHelper.shared.launchTimeTracer?.renderInstance.cancel()
        TimerMonitorHelper.shared.cancel(key: CalendarMonitorKey.daysViewLoadTime.rawValue)
        hadTrackPerfCalLaunch = true
    }

    static func endTrackHomePageLoad() {
        NotificationCenter.default.post(Notification.calendarHomeLaunchFinish)
        guard !hadTrackPerfCalLaunch else { return }
        TimerMonitorHelper.shared.launchTimeTracer?.renderInstance.end()
        TimerMonitorHelper.shared.end(key: CalendarMonitorKey.daysViewLoadTime.rawValue)
    }

    static func startTrackSdkCallTime(command: String) {
        TimerMonitorHelper.shared.start(key: command) { (cost, _) in
                CalendarTracer.shareInstance.perfCalSdkCall(costTime: cost,
                                                            command: command)
        }
    }

    static func endTrackSdkCallTime(command: String) {
        TimerMonitorHelper.shared.end(key: command)
    }

    static func startTrackGetInstanceTime(querySpan: Int64) {
        TimerMonitorHelper.shared.start(key: "perf_cal_get_ins") { (cost, param) in
            guard let dataLength = param["dataLength"] as? Int else {
                assertionFailureLog()
                return
            }
            CalendarTracer.shareInstance.perfCalGetIns(costTime: cost,
                                                       dataLength: dataLength,
                                                       querySpan: querySpan)
        }
    }

    static func endTrackGetInstanceTime(dataLength: Int) {
        TimerMonitorHelper.shared.end(key: "perf_cal_get_ins",
                                      extra: ["dataLength": dataLength])
    }

    //rsvp event detail
    static func startTrackRsvpEventDetailTime(calEventId: String?, originalTime: Int64, uid: String) {
        TimerMonitorHelper.shared
            .start(key: "rsvp_event_detail") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "rsvp_event",
                                                           extraName: "event_detail",
                                                           calEventId: calEventId,
                                                           originalTime: originalTime,
                                                           uid: uid)
            }

    }

    static func endTrackRsvpEventDetailTime() {
        TimerMonitorHelper.shared.end(key: "rsvp_event_detail")
    }

    //rsvp bot card
    static func startTrackRsvpEventBotCardTime(calEventId: String?, originalTime: Int64, uid: String) {
        TimerMonitorHelper.shared
            .start(key: "rsvp_event_bot_card") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "rsvp_event",
                                                           extraName: "bot_card",
                                                           calEventId: calEventId,
                                                           originalTime: originalTime,
                                                           uid: uid)
            }

    }

    static func endTrackRsvpEventBotCardTime() {
        TimerMonitorHelper.shared.end(key: "rsvp_event_bot_card")
    }
    
    //rsvp rsvp card
    static func startTrackRsvpCardTime(calEventId: String?, originalTime: Int64, uid: String) {
        TimerMonitorHelper.shared
            .start(key: "rsvp_card") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "rsvp_event",
                                                           extraName: "new_card",
                                                           calEventId: calEventId,
                                                           originalTime: originalTime,
                                                           uid: uid)
            }

    }

    static func endTrackRsvpCardTime() {
        TimerMonitorHelper.shared.end(key: "rsvp_card")
    }

    //roomsInBuilding creatEventPage
    static func startTrackViewRoomsInBuildingCreateEventPageTime() {
        TimerMonitorHelper.shared
            .start(key: "view_rooms_in_building_create_event_page") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "view_rooms_in_building",
                                                           extraName: "create_event_page")
            }

    }

    static func endTrackViewRoomsInBuildingCreateEventPageTime() {
        TimerMonitorHelper.shared.end(key: "view_rooms_in_building_create_event_page")
    }
    
    //free busy view in chat
    static func startTrackFreebusyViewInChatTime() {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_in_chat") { (cost, params) in
                guard let calNum = params["calNum"] as? Int else {
                    assertionFailureLog()
                    return
                }
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view",
                                                           extraName: "chat",
                                                           calNum: calNum,
                                                           versionName: FG.freebusyOpt ? "optv1" : "")
            }
    }

    static func endTrackFreebusyViewInChatTime(calNum: Int) {
        TimerMonitorHelper.shared.end(key: "freebusy_view_in_chat",
                                      extra: ["calNum": calNum])
    }


    
    static func endTrackFreebusyViewAttendeeTime(calNum: Int) {
        TimerMonitorHelper.shared.end(key: "freebusy_view_attendee",
                                      extra: ["calNum": calNum])
    }

    static func startTrackFreebusyViewAttendeeTime() {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_attendee") { (cost, params) in
                guard let calNum = params["calNum"] as? Int else {
                    assertionFailureLog()
                    return
                }
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view_attendee",
                                                           extraName: "",
                                                           calNum: calNum)
            }
    }
    
    static func endTrackFreebusyViewInstanceTime(calNum: Int, instanceNum: Int) {
        TimerMonitorHelper.shared.end(key: "freebusy_view_instance",
                                      extra: ["calNum": calNum,
                                              "instanceNum": instanceNum])
    }

    static func startTrackFreebusyViewInstanceTime() {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_instance") { (cost, params) in
                guard let calNum = params["calNum"] as? Int, let instanceNum = params["instanceNum"] as? Int else {
                    assertionFailureLog()
                    return
                }
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view_instance",
                                                           extraName: "",
                                                           calNum: calNum,
                                                           totalInstanceNum: instanceNum)
            }
    }
    
    
    static func endTrackFreebusyViewChatterTime() {
        TimerMonitorHelper.shared.end(key: "freebusy_view_Chatter")
    }

    static func startTrackFreebusyViewChatterTime() {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_Chatter") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view_chatter",
                                                           extraName: "")
            }
    }
    
    //free busy view in append
    static func startTrackFreebusyViewInAppendTime(calNum: Int) {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_in_append") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view",
                                                           extraName: "append",
                                                           calNum: calNum,
                                                           versionName: FG.freebusyOpt ? "optv1" : "")
            }
        
    }

    static func endTrackFreebusyViewInAppendTime() {
        TimerMonitorHelper.shared.end(key: "freebusy_view_in_append")
    }

    //free busy view in profile
    static func startTrackFreebusyViewInProfileTime() {
        TimerMonitorHelper.shared
            .start(key: "freebusy_view_in_profile") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "freebusy_view",
                                                           extraName: "profile",
                                                           calNum: 2,
                                                           versionName: FG.freebusyOpt ? "optv1" : "")
            }
        
    }

    static func endTrackFreebusyViewInProfileTime() {
        TimerMonitorHelper.shared.end(key: "freebusy_view_in_profile")
    }

    static func endTrackSubscribeCalendarTime() {
        TimerMonitorHelper.shared.end(key: "subscribe_calendar")
    }

    // 展开建筑物查看会议室 （日程编辑 + 订阅日历）
    static func startTrackExpandBuildingSectionTime(from: TrackerFromType) {
        TimerMonitorHelper.shared
            .start(key: "view_rooms_in_building") { (cost, _) in
                CalendarTracer.shareInstance.calPerfCommon(costTime: cost,
                                                           sceneType: "view_rooms_in_building",
                                                           extraName: (from == .eventEdit) ? "create_event_page" : "subscribe_calendar")
            }
    }

    static func endTrackExpandBuildingSectionTime() {
        TimerMonitorHelper.shared.end(key: "view_rooms_in_building")
    }

    // 加入日程
    static func startJoinEventTime(extraName: String, calEventID: String, originalTime: Int64, uid: String) {
        TimerMonitorHelper.shared
            .start(key: "join_event") { (cost, param) in
                guard let isSuccess = param["isSuccess"] as? Bool, let errorCode = param["errorCode"] as? String else {
                    assertionFailureLog()
                    return
                }

                CalendarTracer.shareInstance.calEventLatencyDev(costTime: cost,
                                                                click: "join_event",
                                                                isSuccess: isSuccess,
                                                                errorCode: errorCode,
                                                                calEventID: calEventID,
                                                                originalTime: originalTime,
                                                                uid: uid,
                                                                extraName: extraName)
            }
    }

    static func endJoinEventTime( isSuccess: Bool, errorCode: String) {
        TimerMonitorHelper.shared.end(key: "join_event",
                                      extra: ["isSuccess": isSuccess,
                                              "errorCode": errorCode])
    }

    // 退出日程
    static func startExitEventTime(calEventID: String, originalTime: Int64, uid: String) {
        TimerMonitorHelper.shared
            .start(key: "exit_event") { (cost, param) in
                guard let isSuccess = param["isSuccess"] as? Bool, let errorCode = param["errorCode"] as? String else {
                    assertionFailureLog()
                    return
                }

                CalendarTracer.shareInstance.calEventLatencyDev(costTime: cost,
                                                                click: "exit_event",
                                                                isSuccess: isSuccess,
                                                                errorCode: errorCode,
                                                                calEventID: calEventID,
                                                                originalTime: originalTime,
                                                                uid: uid)
            }
    }

    static func endExitEventTime(isSuccess: Bool, errorCode: String) {
        TimerMonitorHelper.shared.end(key: "exit_event",
                                      extra: ["isSuccess": isSuccess,
                                              "errorCode": errorCode])
    }

    // 进入日程详情
    static func startTrackEventDetailView(actionSource: CalendarTracer.ActionSource, calEventId: String, originalTime: Int64, uid: String, viewType: HomeSceneMode? = nil) {
        TimerMonitorHelper.shared
            .start(key: "view_detail_load") { (cost, _) in
                CalendarTracer.shareInstance.detailViewLoadTime(costTime: cost,
                                                                actionSource: actionSource,
                                                                calEventId: calEventId,
                                                                originalTime: originalTime,
                                                                uid: uid,
                                                                viewType: HomeSceneMode.current)
            }
    }

    static func endTrackEventDetailView() {
        TimerMonitorHelper.shared.end(key: "view_detail_load")

    }

    static func startTrackZoomMeetingCreate() {
        TimerMonitorHelper.shared
            .start(key: "zoom_meeting_create") { (cost, _) in
                CalendarTracer.shareInstance.perfZoomMeetingCreate(costTime: cost)
            }
    }

    static func endTrackZoomMeetingCreate() {
        TimerMonitorHelper.shared.end(key: "zoom_meeting_create")
    }

}

extension TimerMonitorHelper {
    /// 获取app当前已使用内存
    func getCurrentMemoryUsageInBytes() -> CGFloat {
        #if GadgetMod
        BDPMemoryMonitor.currentMemoryUsageInBytes()
        #else
        0.0
        #endif
    }
}
