//
//  PreloadStatistics.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/10.
//
// 处理模板预加载的上报

import SKFoundation
import SpaceInterface

public final class PreloadStatistics {
    var currentPreloadInfo = [String: PreloadInfo]()

    public static let shared = PreloadStatistics()

    public func startRecordPreload(_ editorIdentifier: String) {
//        spaceAssert(currentPreloadInfo[editorIdentifier] == nil, "has started prelod for \(editorIdentifier)")
        var preloadInfo = PreloadInfo()
        preloadInfo.startTime = Date().timeIntervalSince1970

        currentPreloadInfo[editorIdentifier] = preloadInfo
    }

    public func endRecordPreload(_ editorIdentifer: String,
                                 hasLoadSomeThing: Bool,
                                 statisticsStage: String,
                                 hasComplete: Bool) {
        guard hasLoadSomeThing else {
            currentPreloadInfo[editorIdentifer] = nil
            return
        }
        guard let info = currentPreloadInfo[editorIdentifer],
        let startTime = info.startTime else {
            spaceAssertionFailure("preload info is empty")
            return
        }
        let currentTime = Date().timeIntervalSince1970
        let costTime = (currentTime - startTime) * 1000
        let fileType = statisticsStage 
        let ordinal = info.preloadTypes.firstIndex(of: fileType) ?? -1
        let allParames: [String: Any] = ["cost_time_app_launch_to_jsready": (currentTime - DocsPerformance.initTime),
                                         "cost_time": costTime,
                                         "file_type": fileType,
                                         "docs_preload_stage": statisticsStage as Any,
                                         "ordinal": ordinal]
        DocsTracker.log(enumEvent: .preLoadTemplate, parameters: allParames)
    }
    
    public func updatePreloadTypes(_ editorIdentifer: String, types: [String]) {
        if var info = currentPreloadInfo[editorIdentifer] {
            info.preloadTypes = types
            currentPreloadInfo[editorIdentifer] = info
        }
    }
    
    public func getPreloadTypes(_ editorIdentifer: String) -> [String] {
        if var info = currentPreloadInfo[editorIdentifer] {
            return info.preloadTypes
        }
        return []
    }
    
    public func clear(_ editorIdentifer: String) {
        currentPreloadInfo[editorIdentifer] = nil
    }
}

extension PreloadStatistics {
    struct PreloadInfo {
        var startTime: CFAbsoluteTime!
        var preloadTypes = [String]()
    }
}
