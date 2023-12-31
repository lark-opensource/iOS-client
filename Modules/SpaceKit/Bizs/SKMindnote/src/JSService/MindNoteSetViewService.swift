//
//  MindNoteSetViewService.swift
//  SpaceKit
//
//  Created by chengqifan on 2019/9/4.
//  

import Foundation
import SKCommon

enum MindnotViewType: String {
    case outline = "OUTLINE"
    case mindmap = "MINDMAP"
}

final class MindNoteSetViewService: BaseJSService {
    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension MindNoteSetViewService: DocsJSServiceHandler {
    var handleServices: [DocsJSService] {
        return [.mindnoteSetView]
    }

    func handle(params: [String: Any], serviceName: String) {
        guard let type = params["viewType"] as? String else { return }
        switch type {
        case MindnotViewType.mindmap.rawValue:
            model?.browserInfo.docsInfo?.mindnoteInfo = MindnoteInfo(isMindMapType: true)
        default:
            model?.browserInfo.docsInfo?.mindnoteInfo = MindnoteInfo(isMindMapType: false)
        }
    }
}
