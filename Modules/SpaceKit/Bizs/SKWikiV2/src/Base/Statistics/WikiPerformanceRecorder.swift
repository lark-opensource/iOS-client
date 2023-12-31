//
//  WikiPerformanceRecorder.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/11/13.
//

import Foundation
import SKCommon
import SKFoundation

class WikiPerformanceRecorder {
    enum Stage: String {
        case total
    }

    enum ReportKey: String {
        case stage           = "stage"
        case resultKey       = "result_key"
        case costTime        = "cost_time"
        case resultCode      = "result_code"
        case openType        = "open_type"
        case source          = "source"
        case fileId          = "file_id"
        case action
        case isSingleTree    = "is_single_tree"
        case hasPermission   = "has_perm"
    }

    enum SourceType: String {
        case fullScreen
        case panel
    }

    enum OpenType: String {
        case cache
        case network
    }

    enum ResultKey: String {
        case success
        case fail
    }

    enum Action: String {
        case openTree
        case expandNode
        case add
        case remove
        case move
    }

    /// 各种时刻
    private var costTime: Dictionary = [String: Date]()
    /// key为stage 字典为对应的参数数据
    private var uploadParameters: Dictionary = [String: [String: Any]]()

    static let shared = WikiPerformanceRecorder()
    private init() {}

    struct RecordContext {
        let event: DocsTracker.EventType
        let stage: Stage
        let wikiToken: String
        let source: SourceType
        let openType: OpenType
        let action: Action
    }

    func wikiPerformanceRecordBegin(context: RecordContext) {
        let event = context.event
        let stage = context.stage
        let wikiToken = context.wikiToken
        let source = context.source
        let openType = context.openType
        let action = context.action
        let key = event.rawValue + stage.rawValue + wikiToken
        costTime[key] = Date()
        let tmpParamers: [String: Any] = [ReportKey.fileId.rawValue: DocsTracker.encrypt(id: wikiToken),
                                          ReportKey.source.rawValue: source.rawValue,
                                          ReportKey.openType.rawValue: openType.rawValue,
                                          ReportKey.action.rawValue: action.rawValue]
        uploadParameters[key] = tmpParamers
        #if DEBUG || BETA
        DocsLogger.info("wikitree performance start: \(stage))")
        #else
        #endif
    }

    func wikiPerformanceRecordEnd(event: DocsTracker.EventType,
                                  stage: Stage,
                                  wikiToken: String,
                                  resultKey: ResultKey,
                                  resultCode: String) {
        let key = event.rawValue + stage.rawValue + wikiToken
        guard let previousTime = self.costTime[key] else {
            DocsLogger.info("wikitree performance end misskey")
            return
        }
        let costTime = round(Date().timeIntervalSince(previousTime) * 1000)
        var allParames: [String: Any] = [ReportKey.costTime.rawValue: costTime,
                                         ReportKey.resultKey.rawValue: resultKey.rawValue,
                                         ReportKey.resultCode.rawValue: resultCode]
        if stage != .total {
            allParames.merge(other: [ReportKey.stage.rawValue: stage.rawValue])
        }
        allParames.merge(other: uploadParameters[key])

        DocsLogger.debug("wikitree performance end: \(stage) \(costTime)")

        DocsTracker.log(enumEvent: event, parameters: allParames)
        self.uploadParameters[key] = nil
        self.costTime[key] = nil
    }

    func clearAllData() {
        costTime = [String: Date]()
        uploadParameters = [String: [String: Any]]()
    }
}
