//
//  SpacePerformanceTracker.swift
//  SpaceKit
//
//  Created by guoqp on 2020/5/20.
//
// https://bytedance.feishu.cn/docs/doccnG3uHrMgEVAi5heWu2m0Ikh#

import Foundation
import SKCommon
import SKFoundation
import LarkContainer

extension SpacePerformanceTracker {

    typealias FilterOption = SpaceFilterHelper.FilterOption
    typealias SortType = SpaceSortHelper.SortType

    public enum Stage: String {
        ///初始化控制器
        case createVC        = "init"
        ///从网络加载
        case loadFromNetwork = "load_from_network"
        ///从db加载
        case loadFromDB      = "load_db_data"
    }

    enum SceneType: String {
        ///DB缓存存在
        case fromDBCache = "0"
        ///从网络获取数据
        case fromNetwork = "1"
    }

    typealias DisplayMode = SpaceListDisplayMode

    /// 上报到后台时的字段
    enum ReportKey: String {
        case stage       = "stage"
        case resultCode  = "result_code"
        case errorCode   = "fail_code"
        case costTime    = "cost_time"
        case listType    = "list_type"
        case filterType  = "filter_type1"
        case sortType    = "sort_type"
        case viewMode    = "view_mode"
        case sceneType   = "scene_type"
        case dataSize    = "data_size"
        // 表示新旧首页
        case spaceVersion = "space_version"
        // 表示新旧首页所选tab
        case selectTab   = "select_tab"
    }
}

private extension SpacePerformanceTracker.DisplayMode {
    var performanceStatValue: Int {
        switch self {
        case .grid:
            return 1
        case .list:
            return 0
        }
    }
}

public extension CCMExtension where Base == UserResolver {
    var spacePerformanceTracker: SpacePerformanceTracker? {
        if let instance = try? base.resolve(assert: SpacePerformanceTracker.self) {
            return instance
        }
        DocsLogger.error("space.performance.tracker --can not resolver tracker")
        spaceAssertionFailure("space.performance.tracker --can not resolver tracker")
        return nil
    }
}

public enum SpacePerformanceReportScene: Equatable {
    case recent         // 最近列表
    case homeContents   // 目录
    
    var selectTabValue: String {
        switch self {
        case .recent:
            return "recent"
        case .homeContents:
            return "content"
        }
    }
}

/// 统计 Space 首页   quickacess 和 recent 的 打开性能
public final class SpacePerformanceTracker {
    public static let shared = SpacePerformanceTracker()
    public init() { }

    private var stageStartTimes: [Stage: Date] = [:]

    // 以下属性用于 openFinish 上报的加载是否成功判断
    // 记录 open finish 时 load DB 是否失败，失败需要提供失败原因
    private var dbFailureReason: String?
    // 记录 open finish 时 load server 是否失败，失败需要原因
    private var serverFailureReason: String?
    private var succeedDataSource: SceneType?
    // 是否正在统计 openFinish
    private var openInProgress: Bool = false
    // 当前需要上报的页面，防止多页面上报串数据
    private var reportScene: SpacePerformanceReportScene?

    public func begin(stage: Stage, scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        guard reportScene == scene else { return }
        guard stageStartTimes[stage] == nil else {
            spaceAssertionFailure("re-begin stage: \(stage)")
            return
        }
        stageStartTimes[stage] = Date()
        DocsLogger.info("space.tracker.perform --- report stage begin for \(stage)")
    }

    public func end(stage: Stage, succeed: Bool, dataSize: Int, scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        guard reportScene == scene else { return }
        guard let startDate = stageStartTimes[stage] else {
            return
        }
        let costTime = round(Date().timeIntervalSince(startDate) * 1000)
        let allParames: [ReportKey: Any] = [
            .stage: stage.rawValue,
            .listType: "recent",
            .costTime: costTime,
            .dataSize: dataSize,
            .resultCode: succeed ? "0" : "1",
            .selectTab: scene.selectTabValue,
            .spaceVersion: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? "new_format" : "original"
        ]
        DocsLogger.info("space.tracker.perform --- report stage end for \(stage)")
        DocsTracker.log(enumEvent: .spaceOpenStage, parameters: allParames.mapKeyWithRawValue())
        stageStartTimes[stage] = nil
    }

    // Tab Init 开始计算 start, 会重置所有状态
    // 所有上报前必须调用该方法
    public func reportStartLoading(scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        openInProgress = true
        dbFailureReason = nil
        serverFailureReason = nil
        succeedDataSource = nil
        stageStartTimes = [:]
        reportScene = scene
        DocsLogger.info("space.tracker.perform --- start loading")
        DocsTracker.startRecordTimeConsuming(eventType: .spaceOpenFinish,
                                             parameters: nil)
    }

    // Model 层需要调用
    func reportLoadingFailed(dataSource: SceneType, reason: String, scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        // 非同页面的上报忽略掉
        guard reportScene == scene else { return }
        guard openInProgress else { return }
        DocsLogger.info("space.tracker.perform --- report loading failed", extraInfo: ["source": dataSource, "reason": reason])
        switch dataSource {
        case .fromDBCache:
            dbFailureReason = reason
        case .fromNetwork:
            serverFailureReason = reason
        }
    }

    // Model 层需要调用，第一个 succeed 的 source 会被上报
    func reportLoadingSucceed(dataSource: SceneType, scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        guard reportScene == scene else { return }
        guard openInProgress else { return }
        DocsLogger.info("space.tracker.perform --- report loading succeed", extraInfo: ["source": dataSource])
        // 第一个成功的 DataSource 有效
        if succeedDataSource == nil {
            succeedDataSource = dataSource
        }
    }

    // UI 最终展示内容时需要调用 finish，根据 Model 层的成功状态决定最终上报内容
    func reportOpenFinish(filterOption: FilterOption, sortType: SortType, displayMode: DisplayMode, scene: SpacePerformanceReportScene) {
        spaceAssertMainThread()
        guard reportScene == scene else { return }
        guard openInProgress else { return }
        openInProgress = false
        var params: [ReportKey: Any]
        switch scene {
        case .recent:
            params = [
                .filterType: filterOption.reportName,
                .sortType: sortType.reportName,
                .viewMode: displayMode.performanceStatValue,
                .listType: "recent",
                .spaceVersion: UserScopeNoChangeFG.WWJ.newSpaceTabEnable ? "new_format" : "original"
            ]
        case .homeContents:
            params = [
                .listType: "recent",
                .spaceVersion: "new_format"
            ]
        }
        params[.selectTab] = scene.selectTabValue
        
        if let dbReason = dbFailureReason,
           let serverReason = serverFailureReason {
            params[.resultCode] = "1"
            // DB server 都失败报 server 失败
            params[.sceneType] = SceneType.fromNetwork.rawValue
            params[.errorCode] = "DB: \(dbReason); Server: \(serverReason)"
            DocsLogger.info("space.tracker.perform --- report open finish, both DB and Server Failed")
        } else if let succeedSceneType = succeedDataSource {
            params[.resultCode] = "0"
            // 报第一个成功的 source
            params[.sceneType] = succeedSceneType.rawValue
            DocsLogger.info("space.tracker.perform --- report open finish, succeed by \(succeedSceneType)")
        } else {
            assertionFailure("None of these situlations match, one of DB and server must succeed, or both DB and server must failed")
            return
        }
        DocsTracker.endRecordTimeConsuming(eventType: .spaceOpenFinish, parameters: params.mapKeyWithRawValue())
    }
}
