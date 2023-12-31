//
//  UtilMoreService+Track.swift
//  SpaceKit
//
//  Created by lijuyou on 2022/1/26.
//  


import Foundation
import SKFoundation
import SKCommon
import SKBrowser
import SpaceInterface

extension UtilMoreService {
    func logSheetFindSwitch(isPrevious: Bool) {
        guard let info = hostDocsInfo, info.type == .sheet else { return }
        let opItem: String = isPrevious ? "last button" : "next button"
        let params = ["action": "find_item",
                      "op_item": opItem,
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": "default",
                      "module": info.type.name]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }

    func logSheetShowFind() {
        guard let info = hostDocsInfo, info.type == .sheet else { return }
        let params = ["action": "find",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": "default",
                      "module": info.type.name]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }
}

struct DocsSearchTracker {
    
    static let supportDocsTypes: [DocsType] = [.docX] //目前只有docx走这套上报
    
    enum Event {
        //显示搜索面板
        case showSearchPanel
        //点击完成查找
        case finishFind
        //点击切换查找结果
        case scrollResult(isPrev: Bool)
        
        var trackParams: (DocsTracker.EventType, [String: Any]) {
            switch self {
            case .showSearchPanel:
                return (.docFindReplacePanelView, [:])
            case .finishFind:
                return (.docFindReplacePanelClick, ["click": "click_finish_find",
                                                    "target": "none"])
            case let .scrollResult(isPrev):
                let actionStr = isPrev ? "previous" : "next"
                return (.docFindReplacePanelClick, ["click": "click_scroll_result",
                                                    "sub_click": actionStr,
                                                    "target": "none"])
            }
        }
    }
    
    static func report(event: Event, docsInfo: DocsInfo?) {
        guard let docsInfo = docsInfo, supportDocsTypes.contains(docsInfo.type) else {
            return
        }
        let token = (docsInfo.wikiInfo?.objToken ?? docsInfo.objToken) ?? ""
        var parameters = event.trackParams.1
        // ccm全局公参
        var commonParams = DocsParametersUtil.createCommonParams(by: docsInfo)
        parameters.merge(other: commonParams)
        DocsTracker.newLog(event: event.trackParams.0.rawValue, parameters: parameters)
    }
}
