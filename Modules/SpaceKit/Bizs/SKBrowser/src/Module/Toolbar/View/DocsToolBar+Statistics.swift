//
//  DocsToolBar+Statistics.swift
//  SpaceKit
//
//  Created by 边俊林 on 2019/3/20.
//

import Foundation
import SKCommon
import SKFoundation
import SKUIKit

// 埋点逻辑写在这里，不要写进主逻辑中哦
extension DocsToolBar {
    @inline(__always)
    func logSheetToolBarOperation(_ action: String, info: DocsInfo) {
        let params = ["action": action,
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "mode": "default",
                      "module": info.type.name,
                      "source": "sheet_toolbar"]

        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }
    // 移动端展示键盘上方工具栏
    func showToolBarView(info: DocsInfo) {
        guard let publicParams = Self.toolBarPublicParamsWith(info: info) else {
            return
        }
        var event: DocsTracker.EventType
        let params = publicParams
        switch info.type {
        case .mindnote:
            event = SKDisplay.pad ? DocsTracker.EventType.bottomToolbarIPadView : DocsTracker.EventType.bottomToolbarView
        default:
            return
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    // 移动端，除了iPad，键盘上方工具栏中的字体颜色设置
    func docsShowFontColorView(info: DocsInfo) {
        guard let publicParams = Self.toolBarPublicParamsWith(info: info) else {
            return
        }
        var event: DocsTracker.EventType
        let params = publicParams
        switch info.type {
        case .mindnote:
            event = DocsTracker.EventType.bottomToolbarFontColorView
        default:
            return
        }
        DocsTracker.newLog(enumEvent: event, parameters: params)
    }

    public static func toolBarPublicParamsWith(info: DocsInfo) -> [AnyHashable: Any]? {
        var publicParams = [String: String]()
        switch info.inherentType {
        case .mindnote:
            publicParams["file_id"] = (info.type == .wiki) ? (info.wikiInfo?.objToken ?? info.encryptedObjToken) : info.encryptedObjToken
            publicParams["page_token"] = info.encryptedObjToken
            publicParams["file_type"] = "mindnote"
            publicParams["mindnote_mode"] = "outline"
            publicParams["is_block"] = "FALSE"
            publicParams["block_id"] = "null"
            publicParams["app_form"] = (info.isInVideoConference == true) ? "vc" : "null"
            publicParams["module"] = "mindnote"
            publicParams["sub_module"] = "none"
        default:
            break
        }
        return publicParams
    }
}
