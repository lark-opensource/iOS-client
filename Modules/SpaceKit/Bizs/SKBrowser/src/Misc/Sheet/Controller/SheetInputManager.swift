//
//  SheetInputManager.swift
//  SKBrowser
//
//  Created by lijuyou on 2020/6/2.
//

import Foundation
import SKCommon
import SKFoundation
import SpaceInterface

public final class SheetInputManager {
    private var model: BrowserModelConfig?
    public init(_ model: BrowserModelConfig?) {
        self.model = model
    }

    public func atListView(type: AtViewType) -> AtListView? {
        guard let m = self.model else { return nil }
        guard m.requestAgent.currentUrl?.host != nil,
            let fileType = m.browserInfo.docsInfo?.type,
            let token = m.browserInfo.token else { spaceAssertionFailure(); return nil }
        let chatID = m.browserInfo.chatId
        let atConfig = AtDataSource.Config(chatID: chatID, sourceFileType: fileType, location: type, token: token)
        let dataSource = AtDataSource(config: atConfig)
        return AtListView(dataSource, type: type)
    }

    public func inputView(didChangeInput cellID: String?,
                          segmentArr: [[String: Any]]?,
                          editState: SheetInputView.SheetEditMode,
                          keyboard: SheetInputKeyboardDetails) {

        let params = [ "cellInfo": cellID ?? "",
                       "newValue": segmentArr as Any,
                       "editState": editState.rawValue,
                       "format": keyboard.mainKeyboard.rawValue,
                       "dateType": keyboard.subKeyboard.rawValue] as [String: Any]
        
        model?.jsEngine.callFunction(DocsJSCallBack.sheetOnUpdateEdit, params: params, completion: { (_, error) in

            if let err = error {
                DocsLogger.error("SheetInputView update text error", extraInfo: nil, error: err, component: nil)
            }
        })
    }

    public func doStatisticsForAction(enumEvent: DocsTracker.EventType, extraParameters: [SheetInputView.StatisticParams: SheetInputView.SheetAction]) {
        var params = [String: Any]()
        for (param, action) in extraParameters {
            params[param.rawValue] = action.rawValue
        }
        doStatisticsCore(enumEvent: enumEvent, extraParameters: params)
    }

    public func fileIdForStatistics() -> String? {
        guard let objToken = model?.browserInfo.docsInfo?.objToken else { return nil }
        return DocsTracker.encrypt(id: objToken)
    }

    private func doStatisticsCore(enumEvent: DocsTracker.EventType, extraParameters: [String: Any]) {
        var params = [String: Any]()
        if let objToken = model?.browserInfo.docsInfo?.objToken {
            params["file_id"] = DocsTracker.encrypt(id: objToken)
        }
        params["file_type"] = model?.browserInfo.docsInfo?.type.name
        var isCrossTenant = false
        if let fileOwnerTenantId = model?.browserInfo.docsInfo?.tenantID {
            params["file_tenant_id"] = DocsTracker.encrypt(id: fileOwnerTenantId)
            isCrossTenant = fileOwnerTenantId != User.current.info?.tenantID
        }
        params["file_is_cross_tenant"] = isCrossTenant ? "true" : "false"

        for (param, action) in extraParameters {
            params[param] = action
        }
        DocsTracker.log(enumEvent: enumEvent, parameters: params)
    }
}
