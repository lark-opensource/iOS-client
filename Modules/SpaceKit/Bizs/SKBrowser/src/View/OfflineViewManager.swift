//
//  OfflineViewManager.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/3/29.
//  

import Foundation
import SKCommon
import SKUIKit
import SKFoundation
import SpaceInterface

extension NetInterruptTipView: SapceEditorTipShowAble {

}

class OfflineViewManager {
    private var _offlineTipView: SapceEditorTipShowAble?
    var offlineTipView: SapceEditorTipShowAble {
        if _offlineTipView == nil {
            _offlineTipView = NetInterruptTipView.defaultView()
        }
        return _offlineTipView!
    }

    func updateOfflineTips(with type: DocsType, isOfflineCreate: Bool) {
        var tipsType: TipType = .docOfflineOpen
        switch type {
        case .bitable: tipsType = .bitableOffline
        case .sheet: tipsType = .sheetOffline
        case .mindnote: tipsType = .mindnoteOffline
        case .docX, .doc, .wiki: tipsType = isOfflineCreate ? .docOfflineCreate : .docOfflineOpen
        case .slides: tipsType = .slideOffline
        default:
            spaceAssertionFailure("需要定义提示语")
        }
        offlineTipView.setTip(tipsType)
    }
}
