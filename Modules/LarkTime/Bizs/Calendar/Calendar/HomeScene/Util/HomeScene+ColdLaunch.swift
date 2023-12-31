//
//  HomeScene+ColdLaunch.swift
//  Calendar
//
//  Created by 张威 on 2020/11/4.
//

import UIKit
import Foundation
import LarkSetting
import CTFoundation
import LKCommonsLogging
import LKCommonsTracker
import ThreadSafeDataStructure

// MARK: ColdLaunch Context

extension HomeScene {

    /// 冷启动 context
    struct ColdLaunchContext {
        // 冷启动展示的区域范围
        var dayRange: JulianDayRange
        var timeZone: TimeZone
        var viewSetting: EventViewSetting
        var loggerModel: CaVCLoggerModel
    }
    
    enum ColdLaunchState {
        case none
        case start
        case end
    }
    // 冷启动的状态
    static var coldLaunchState: ColdLaunchState = .none

    static private(set) var coldLaunchContext: ColdLaunchContext?

    static func setColdLaunchContext(
        with sceneMode: SceneMode,
        timeZone: TimeZone,
        viewSetting: EventViewSetting,
        settingService: LarkSetting.SettingService?,
        loggerModel: CaVCLoggerModel
    ) {
        let today = JulianDayUtil.julianDay(from: Date(), in: timeZone)

        let dayRange: JulianDayRange
        switch HomeSceneMode.current {
        case .day(let dayCate):
            dayRange = today..<today + dayCate.daysPerScene
        case .month:
            // FIXME: 月视图的冷启动范围，不能简单定义为一个月
            dayRange = JulianDayUtil.julianDayRange(inSameMonthAs: today)
        case .list:
            let isLowDevice = ViewPageDowngradeTaskManager.getIsLowDevice(settingService: settingService)
            // 冷启动优化fg开启并且是低端机，只拉取3天的数据
            let count = isLowDevice ? 3 : 14
            dayRange = today..<today + count
        }
        coldLaunchContext = .init(dayRange: dayRange, timeZone: timeZone, viewSetting: viewSetting, loggerModel: loggerModel)
    }

}

// MARK: ColdLaunch Tracker

extension HomeScene {

    static private(set) var coldLaunchTracker: ColdLaunchTracker?

    static func setupColdLaunchTracker() {
        switch HomeScene.SceneMode.current {
        case .day, .list:
            coldLaunchTracker = ColdLaunchTracker(sceneMode: HomeScene.SceneMode.current)
        default:
            return
        }
    }

    static func clearColdLaunchTracker() {
        coldLaunchTracker = nil
    }

    /// 冷启动子阶段
    enum ColdLaunchStage: String {
        /// Prepare Setting
        case prepareSetting = "prepare_setting"

        /// Prepare Instance

        /// 加载 instance（不区分数据来源是 rust 还是 snapshot）
        case prepareInstance = "prepare_instance"
        /// 从 snapshot 加载 instance
        case prepareInstanceFromSnapshot = "prepare_instance_from_snapshot"
        /// 从 rust 加载 instance
        case prepareInstanceFromRust = "prepare_instance_from_rust"

        /// Request Instance

        /// 请求 allDay instance
        case requestAllDayInstance = "request_all_day_instance"
        /// 请求 nonAllDay layotued instance（包括 instance + layout）
        case requestNonAllDayLayoutedInstance = "request_non_all_day_layouted_instance"
        /// 请求 nonAllDay instance
        case requestNonAllDayInstance = "request_non_all_day_instance"
        /// 请求 nonAllDay instance 的 layout
        case requestNonAllDayInstanceLayout = "request_non_all_day_instance_layout"
        /// 请求 listScene instance
        case requestListSceneInstance = "request_list_scene_instance"

        /// Make ViewData

        /// 准备列表视图 viewData
        case makeListViewData = "make_list_view_data"
        /// 准备月视图 viewData
        case makeMonthViewData = "make_month_view_data"
        /// 准备日全天日程 viewData
        case makeAllDayViewData = "make_all_day_view_data"
        /// 准备日非全天日程 viewData
        case makeNonAllDayViewData = "make_non_all_day_view_data"

        fileprivate var metricKey: String { "stage_\(rawValue)_cost" }
    }

    /// 冷启动关键节点
    enum ColdLaunchPoint: String, CaseIterable, Equatable {
        /// Prepare
        case prepareSetting = "prepare_setting"
        case prepareInstance = "prepare_instance"

        /// 主视图（容器）相关重要 point

        /// 初始化 homeScene vc
        case initHomeScene = "init_home_scene"
        /// homeScene viewDidLoad
        case homeSceneDidLoad = "home_scene_did_load"
        /// homeScene viewDidAppear
        case homeSceneDidAppear = "home_scene_did_appear"

        /// 日视图相关重要 point

        /// 初始化 dayScnee
        case initDayScene = "init_day_scene"
        /// dayScnee didLoad
        case daySceneDidLoad = "day_scene_did_load"
        /// dayScnee didAppear
        case daySceneDidAppear = "day_scene_did_appear"
        /// dayScene 请求 viewData
        case dayScenePrepareViewData = "day_scene_prepare_view_data"
        /// dayScene viewData 数据准备好了
        case daySceneViewDataReady = "day_scene_view_data_ready"

        /// 列表视图相关重要 point

        /// 初始化 listScene
        case initListScene = "init_list_scene"
        /// listScene didLoad
        case listSceneDidLoad = "list_scene_did_load"
        /// listScene 请求 viewData
        case listScenePrepareViewData = "list_scene_prepare_view_data"
        /// listScene viewata 数据准备好了
        case listSceneViewDataReady = "list_scene_view_date_ready"

        fileprivate var metricKey: String { "point_\(rawValue)_latency" }

        static func == (lhs: Self, rhs: Self) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }
    }

    enum ColdLaunchCustomMetricKey: String {
        // instance 的数量
        case instanceCount = "instance_count"
        // 非全天日程的数量
        case nonAllDayInstanceCount = "non_all_day_instance_count"
        // 全天日程的数量
        case allDayInstanceCount = "all_day_instance_count"
    }

    /// Category，用于过滤
    enum ColdLaunchCategory: String, CaseIterable {
        /// 视图类型
        case sceneMode = "scene_mode"
        /// 异步渲染
        case asyncDraw = "async_draw"
        /// instance 来源
        case instanceSource = "instance_source"
        /// 冷启动结果
        case result = "result"

        static func categoryValue(for sceneMode: SceneMode) -> String {
            switch sceneMode {
            case .day(let cate): return "day_\(cate.daysPerScene)"
            case .month: return "month"
            case .list: return "list"
            }
        }

        static func categoryValue(for result: ColdLaunchResult) -> String {
            switch result {
            case .succeed: return "succeed"
            case .failedForError: return "failed_for_error"
            case .failedForTimeout: return "failed_for_timeout"
            }
        }

        static let asyncDrawValues = (true: "true", false: "false")
        static let instanceSourceValues = (fromRust: "from_rust", fromSnapshot: "from_snapshot")
    }

    /// 冷启动结果
    enum ColdLaunchResult {
        case succeed
        case failedForError
        case failedForTimeout
    }

    /// 冷启动埋点
    final class ColdLaunchTracker {

        static let slardarEventName = "cal_home_scene_launch_detail"

        typealias Extra = [String: String]

        private var metric: SafeDictionary<String, Any> = [:] + .readWriteLock
        private var category: SafeDictionary<ColdLaunchCategory, Any> = [:] + .readWriteLock
        private var extra: SafeDictionary<String, String> = [:] + .readWriteLock
        private var startTime: CFTimeInterval = -0.001

        let sceneMode: SceneMode
        init(sceneMode: SceneMode) {
            self.sceneMode = sceneMode
        }

        func start() {
            startTime = CACurrentMediaTime()
        }

        func finish(_ result: ColdLaunchResult) {
            // 标记冷启动完成
            HomeScene.coldLaunchState = .end
            let cost = (CACurrentMediaTime() - startTime) * 1000
            metric["total_cost"] = cost
            setValue(ColdLaunchCategory.categoryValue(for: result), forCategory: .result)
            flush()

            // 完成冷启动上报，释放 tracker
            DispatchQueue.global().async {
                HomeScene.clearColdLaunchTracker()
            }
        }

        func insertPoint(_ point: ColdLaunchPoint) {
            assert(startTime > 0)
            metric[point.metricKey] = (CACurrentMediaTime() - startTime) * 1000
        }

        func addStage(_ stage: ColdLaunchStage, with cost: CFTimeInterval) {
            metric[stage.metricKey] = cost * 1000
        }

        func setValue(_ value: Any, forMetricKey metricKey: ColdLaunchCustomMetricKey) {
            metric[metricKey.rawValue] = value
        }

        func setValue(_ value: Any, forCategory cate: ColdLaunchCategory) {
            category[cate] = value
        }

        private func flush() {
            setValue(ColdLaunchCategory.categoryValue(for: sceneMode), forCategory: .sceneMode)

            var eventMetrix = self.metric.getImmutableCopy()
            for point in ColdLaunchPoint.allCases where eventMetrix[point.metricKey] == nil {
                // 以 -1 作为无效值
                eventMetrix[point.metricKey] = CFTimeInterval(-1)
            }

            let category = self.category.getImmutableCopy()
            var eventCategory = [String: Any]()
            for c in ColdLaunchCategory.allCases {
                eventCategory[c.rawValue] = category[c] ?? "undefined"
            }

            let viewType = CalendarTracer.ViewType(mode: CalendarDayViewSwitcher().mode)
            let costTime = floor(Double(eventMetrix["total_cost"] as? CFTimeInterval ?? 0))
            CalendarTracer.shared.perfCalLaunch(costTime: costTime, launchTimeTracer: nil, viewType: viewType)
            Tracker.post(SlardarEvent(
                name: Self.slardarEventName,
                metric: eventMetrix,
                category: eventCategory,
                extra: extra.getImmutableCopy()
            ))
        }

    }

}
