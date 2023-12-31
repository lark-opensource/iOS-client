//
//  SheetToolManagerService+analysis.swift
//  SpaceKit
//
//  Created by Webster on 2019/8/29.
//

import Foundation
import SKCommon
import SKFoundation

extension SheetToolManagerService {
    func logFabToolkitSwitchToKeyboard() {
        guard let info = model?.browserInfo.docsInfo else { return }
        let params = ["action": "open_keyboard",
                      "source": "sheet_m_fab",
                      "fab_tpe": "cell_fab",
                      "eventType": "click",
                      "file_id": DocsTracker.encrypt(id: info.objToken),
                      "file_type": info.type.name,
                      "module": "sheet"]
        DocsTracker.log(enumEvent: DocsTracker.EventType.sheetOperation, parameters: params)
    }

    func logAdjustSheetToolkitFloatModel(floatModel: SheetToolkitFloatModel, fromToolkit: Bool) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var params: [String: String] = [:]
        params["action"] = "panel_height"
        params["file_id"] = DocsTracker.encrypt(id: info.objToken)
        params["file_type"] = "sheet"
        params["mode"] = "default"
        params["module"] = "sheet"
        params["source"] = fromToolkit ? "sheet_toolbar" : "sheet_m_fab"
        params["eventType"] = "click"
        params["opt_item"] = floatModel.logText
        params["fab_type"] = rangeType?.rawValue.lowercased() ?? "cell"
        DocsTracker.log(enumEvent: .sheetOperation, parameters: params)
    }

    func logPressFilterSearchButton(fromToolkit: Bool) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var params: [String: String] = [:]
        params["action"] = "filter_search"
        params["file_id"] = DocsTracker.encrypt(id: info.objToken)
        params["file_type"] = "sheet"
        params["mode"] = "default"
        params["module"] = "sheet"
        params["source"] = fromToolkit ? "sheet_toolbar" : "sheet_m_fab"
        params["eventType"] = "click"
        params["fab_type"] = rangeType?.rawValue.lowercased() ?? "cell"
        DocsTracker.log(enumEvent: .sheetOperation, parameters: params)
    }

    func logStartFilterSearch(fromToolkit: Bool) {
        guard let info = model?.browserInfo.docsInfo else { return }
        var params: [String: String] = [:]
        params["action"] = "filter_search_confirm"
        params["file_id"] = DocsTracker.encrypt(id: info.objToken)
        params["file_type"] = "sheet"
        params["mode"] = "default"
        params["module"] = "sheet"
        params["source"] = fromToolkit ? "sheet_toolbar" : "sheet_m_fab"
        params["eventType"] = "click"
        params["fab_type"] = rangeType?.rawValue.lowercased() ?? "cell"
        DocsTracker.log(enumEvent: .sheetOperation, parameters: params)
    }
}
