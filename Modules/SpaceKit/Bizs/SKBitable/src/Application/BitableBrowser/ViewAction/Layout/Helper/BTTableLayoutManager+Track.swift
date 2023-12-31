//
//  BTTableLayoutManager+Track.swift
//  SKBitable
//
//  Created by zhysan on 2023/2/13.
//

import SKFoundation
import SKCommon
import SKBrowser

extension BTTableLayoutSettings.ViewType {
    
    /// 埋点使用：mobile_grid_type
    static let trackKey = "mobile_grid_type"
    
    /// 埋点使用：传统表格 mobile_grid_layout；卡片样式 mobile_card_layout
    var trackValue: String {
        switch self {
        case .classic:
            return "mobile_grid_layout"
        case .card:
            return "mobile_card_layout"
        }
    }
}

extension BTTableLayoutManager {
    
    // MARK: - public
    
    func trackSettingsPanelShow() {
        let baseData = BTBaseData(baseId: context.baseId, tableId: context.tableId, viewId: context.viewId)
        var params = BTEventParamsGenerator.createCommonParams(by: service?.hostDocInfo, baseData: baseData)
        params[BTTableLayoutSettings.ViewType.trackKey] = settings.gridViewLayoutType.trackValue
        if settings.gridViewLayoutType == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
            params.merge(other: CardViewConstant.commonParams)
        }
        DocsTracker.newLog(enumEvent: .bitableMobileGridFormatView, parameters: params)
    }
    
    func trackSettingsCoverPanelShow(attachmentFieldNumber: Int) {
        let baseData = BTBaseData(baseId: context.baseId, tableId: context.tableId, viewId: context.viewId)
        var params: [String: Any] = BTEventParamsGenerator.createCommonParams(by: service?.docsInfo, baseData: baseData)
        params["subject_num"] = attachmentFieldNumber
        if settings.gridViewLayoutType == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
            params.merge(other: CardViewConstant.commonParams)
        }
        DocsTracker.newLog(enumEvent: .bitableMobileCardCoverView, parameters: params)
    }
    
    func trackSettingsPanelClose(cardSettings: BTCardLayoutSettings) {
        let baseData = BTBaseData(baseId: context.baseId, tableId: context.tableId, viewId: context.viewId)
        var params: [String: Any] = BTEventParamsGenerator.createCommonParams(by: service?.hostDocInfo, baseData: baseData)
        params["click"] = "save"
        params["from_mobile_grid_type"] = initialSettings.gridViewLayoutType.trackValue
        params["to_mobile_grid_type"] = settings.gridViewLayoutType.trackValue
        if settings.gridViewLayoutType == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
            params.merge(other: CardViewConstant.commonParams)
        }
        params["column_num"] = cardSettings.column?.columnType.rawValue
        params["title_field_type"] = cardSettings.titleAndCover?.titleField.compositeType.uiType.fieldTrackName
        params["summary_field_type"] = cardSettings.titleAndCover?.subTitleField?.compositeType.uiType.fieldTrackName
        params["visible_field_num"] = cardSettings.display.fields.count
        params["invisivle_field_num"] = cardSettings.more.fields.count
        params["field_visble_situation"] = cardSettings.display.fields.map({
            ["field_type": $0.compositeType.uiType.fieldTrackName,
             "is_visible": $0.isHidden ? "false" : "true",
             "field_id": $0.id
            ]
        }).toJSONString() ?? ""
        params["is_cover_open"] = cardSettings.titleAndCover?.coverField != nil ? 1 : 0
        DocsTracker.newLog(enumEvent: .bitableMobileGridFormatClick, parameters: params)
    }
}

extension BTEventParamsGenerator {
    /// ⚠️ 慎用：使用前需要确认前端已通过 biz.bitable.updateTableInfo 将相关信息传递到客户端
    static func createCommonParamsByGlobalInfo(docsInfo: DocsInfo?) -> [String: String] {
        guard let baseId = docsInfo?.token, let view = BTGlobalTableInfo.currentViewInfoForBase(baseId) else {
            if let docsInfo = docsInfo {
                return DocsParametersUtil.createCommonParams(by: docsInfo)
            }
            return [:]
        }
        let baseData = BTBaseData(baseId: view.baseId, tableId: view.tableId, viewId: view.viewId)
        var params = createCommonParams(by: docsInfo, baseData: baseData)
        params[BTTableLayoutSettings.ViewType.trackKey] = view.gridViewLayoutType?.trackValue
        if view.gridViewLayoutType == .card, UserScopeNoChangeFG.XM.nativeCardViewEnable {
            params.merge(other: CardViewConstant.commonParams)
        }
        return params
    }
}
