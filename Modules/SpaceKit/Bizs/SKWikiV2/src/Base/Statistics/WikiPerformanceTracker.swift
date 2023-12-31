//
//  WikiPerformanceTracker.swift
//  SKWikiV2
//
//  Created by majie.7 on 2022/12/28.
//

import Foundation
import SKCommon
import SKFoundation


extension WikiPerformanceTracker {
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
    
    enum ReportKey: String {
        case stage       = "stage"
        case resultCode  = "result_code"
        case errorCode   = "fail_code"
        case costTime    = "cost_time"
        case listType    = "list_type"
        case sceneType   = "scene_type"
        case dataSize    = "data_size"
    }
}

public final class WikiPerformanceTracker {
    public static let shared = WikiPerformanceTracker()
    
    private init() {}
    
    private var stageStartTimes: [Stage: Date] = [:]
    // 以下属性用于 openFinish 上报的加载是否成功判断
    // 记录 open finish 时 load DB 是否失败，失败需要提供失败原因
    private var dbFailureReason: String?
    // 记录 open finish 时 load server 是否失败，失败需要原因
    private var serverFailureReason: String?
    private var succeedDataSource: SceneType?
    // 是否正在统计 openFinish
    private var openInProgress: Bool = false
    
    public func begin(stage: Stage) {
        guard stageStartTimes[stage] == nil else {
            spaceAssertionFailure("re-begin stage: \(stage)")
            return
        }
        stageStartTimes[stage] = Date()
        DocsLogger.info("wiki.tracker.perform --- report stage begin for \(stage)")
    }

    public func end(stage: Stage, succeed: Bool, dataSize: Int) {
        guard let startDate = stageStartTimes[stage] else {
            return
        }
        let costTime = round(Date().timeIntervalSince(startDate) * 1000)
        let allParames: [ReportKey: Any] = [
            .stage: stage.rawValue,
            .listType: "wiki_home",
            .costTime: costTime,
            .dataSize: dataSize,
            .resultCode: succeed ? "0" : "1"
        ]
        DocsLogger.info("wiki.tracker.perform --- report stage end for \(stage), time: \(costTime)")
        DocsTracker.log(enumEvent: .spaceOpenStage, parameters: allParames.mapKeyWithRawValue())
        stageStartTimes[stage] = nil
    }
    
    // Tab Init 开始计算 start, 会重置所有状态
    public func reportStartLoading() {
        openInProgress = true
        dbFailureReason = nil
        serverFailureReason = nil
        succeedDataSource = nil
        stageStartTimes = [:]
        DocsLogger.info("wiki.tracker.perform --- start loading")
        DocsTracker.startRecordTimeConsuming(eventType: .spaceOpenFinish,
                                             parameters: nil)
    }

    // Model 层需要调用
    func reportLoadingFailed(dataSource: SceneType, reason: String) {
        guard openInProgress else { return }
        DocsLogger.info("wiki.tracker.perform --- report loading failed", extraInfo: ["source": dataSource, "reason": reason])
        switch dataSource {
        case .fromDBCache:
            dbFailureReason = reason
        case .fromNetwork:
            serverFailureReason = reason
        }
    }

    // Model 层需要调用，第一个 succeed 的 source 会被上报
    func reportLoadingSucceed(dataSource: SceneType) {
        guard openInProgress else { return }
        DocsLogger.info("wiki.tracker.perform --- report loading succeed", extraInfo: ["source": dataSource])
        // 第一个成功的 DataSource 有效
        if succeedDataSource == nil {
            succeedDataSource = dataSource
        }
    }

    // UI 最终展示内容时需要调用 finish，根据 Model 层的成功状态决定最终上报内容
    func reportOpenFinish() {
        guard openInProgress else { return }
        openInProgress = false
        var params: [ReportKey: Any] = [
            .listType: "wiki_home"
        ]
        if let dbReason = dbFailureReason,
           let serverReason = serverFailureReason {
            params[.resultCode] = "1"
            // DB server 都失败报 server 失败
            params[.sceneType] = SceneType.fromNetwork.rawValue
            params[.errorCode] = "DB: \(dbReason); Server: \(serverReason)"
            DocsLogger.info("wiki.tracker.perform --- report open finish, both DB and Server Failed")
        } else if let succeedSceneType = succeedDataSource {
            params[.resultCode] = "0"
            // 报第一个成功的 source
            params[.sceneType] = succeedSceneType.rawValue
            DocsLogger.info("wiki.tracker.perform --- report open finish, succeed by \(succeedSceneType)")
        } else {
            spaceAssertionFailure("None of these situlations match, one of DB and server must succeed, or both DB and server must failed")
            return
        }
        DocsTracker.endRecordTimeConsuming(eventType: .spaceOpenFinish, parameters: params.mapKeyWithRawValue())
    }
}
