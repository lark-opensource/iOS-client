//
//  BTViewModel+Tracker.swift
//  SpaceKit
//
//  Created by 吴珂 on 2020/7/15.
//  埋点


import Foundation
import SKCommon
import SKBrowser
import SKFoundation

enum BTFailedType: String {
    case metaFailed = "native_parse_table_meta_failed"
    case dataFailed = "native_parse_table_data_failed"
    case recordsEmpty = "native_fetch_table_data_records_empty"
}

/// 打开卡片性能埋点 参考：https://bytedance.feishu.cn/docs/doccnF6EgKJ0Oto1y2bH4Qv92Ae
final class OpenCardTracker {
    var userClickTime: TimeInterval = 0  //点击卡片
    var nativeReceiveShowCardActionTime: TimeInterval = 0  //下发showCard指令
    var nativeRequestTableMetaTime: TimeInterval = 0  //发送getTableMeta请求
    var webReceiveTableMetaRequestTime: TimeInterval = 0  //前端收到getTableMeta请求
    var nativeReceiveTableMetaTime: TimeInterval = 0  //收到meta数据
    var nativeRequestTableDataTime: TimeInterval = 0  //发送getTableData请求
    var webReceiveTableDataRequestTime: TimeInterval = 0  //前端收到getTableData请求
    var nativeReceiveTableDataTime: TimeInterval = 0  //收到data数据
    var nativeShowCardTime: TimeInterval = 0  //弹出卡片
    var isCollectingData = false
    var transactionId: String = ""
    var recordId: String = ""

    enum TrackTimeType {
        case userClickTime
        case nativeReceiveShowCardActionTime
        case nativeRequestTableMetaTime
        case webReceiveTableMetaRequestTime
        case nativeReceiveTableMetaTime
        case nativeRequestTableDataTime
        case webReceiveTableDataRequestTime
        case nativeReceiveTableDataTime
        case nativeShowCardTime
    }
    
    func trackTimestamp(timestamp: TimeInterval = Date().timeIntervalSince1970 * 1000,
                        type: TrackTimeType) {
        if isCollectingData {
            let floorTimestamp = floor(timestamp)
            switch type {
            case .userClickTime:
                userClickTime = floorTimestamp
            case .nativeReceiveShowCardActionTime:
                nativeReceiveShowCardActionTime = floorTimestamp
            case .nativeRequestTableMetaTime:
                nativeRequestTableMetaTime = floorTimestamp
            case .webReceiveTableMetaRequestTime:
                webReceiveTableMetaRequestTime = floorTimestamp
            case .nativeReceiveTableMetaTime:
                nativeReceiveTableMetaTime = floorTimestamp
            case .nativeRequestTableDataTime:
                nativeRequestTableDataTime = floorTimestamp
            case .webReceiveTableDataRequestTime:
                webReceiveTableDataRequestTime = floorTimestamp
            case .nativeReceiveTableDataTime:
                nativeReceiveTableDataTime = floorTimestamp
            case .nativeShowCardTime:
                nativeShowCardTime = floorTimestamp
            }
        }
    }
}

extension BTPayloadModel: BTEventBaseDataType {}

extension BTViewModel {
    var modeTrackInfo: [String: String] {
        if mode.isIndRecord {
            return [
                "source": "share_record",
                "share_type": "record",
                "file_type": "bitable_share",
            ]
        } else {
            return [:]
        }
    }
    
    // ccm 新埋点
    func getCommonTrackParams() -> [String: Any] {
        var params = DocsParametersUtil.createCommonParams(by: bizData.hostDocInfo)
        var businessParams = BTEventParamsGenerator.createCommonParams(
            by: bizData.hostDocInfo,
            baseData: actionParams.data
        )
        params.merge(other: businessParams)
        params["view_type"] = tableModel.viewType
        params.merge(other: modeTrackInfo)
        return params
    }

    func trackCardViewEvent() {
        var isHiddenFieldsDisclosed: Bool?
        if let currentRecordModel = tableModel.getRecordModel(id: currentRecordID),
           let fieldModel = currentRecordModel.getFieldModel(id: BTFieldExtendedType.hiddenFieldsDisclosure.mockFieldID) {
            isHiddenFieldsDisclosed = fieldModel.isHiddenFieldsDisclosed
        }
        var trackParams = getCommonTrackParams()
        if let isHiddenFieldsDisclosed = isHiddenFieldsDisclosed {
            trackParams["is_field_hidden"] = isHiddenFieldsDisclosed ? "open" : "close"
        } else {
            trackParams["is_field_hidden"] = "none"
        }
        if mode.isStage {
            trackParams["sub_type"] = "stage"
            trackParams["source"] = "stage"
            trackParams["card_type"] = "card"
            trackParams["tab_type"] = "stage"
        }
        DocsTracker.newLog(enumEvent: .bitableCardView, parameters: trackParams)
    }

    // 即将废弃的旧埋点
    private func oldTrackParams() -> [String: Any] {
        var params = getCommonTrackParams()
        let businessParams = [
            "bitable_view_type": tableModel.viewType,
            "bitable_editor_type": "card"
        ]
        params.merge(other: businessParams)
        return params
    }
    
    //埋点上报
    func makeTrack(type: BTFieldType, trackInfo: BTTrackInfo) {
        var params = oldTrackParams()
        
        params["bitable_field_type"] = String(type.rawValue)
        if let didSearch = trackInfo.didSearch {
            params["bitable_edit_search"] = didSearch ? "true" : "false"
        }
    
        if let didClickDone = trackInfo.didClickDone {
            params["click_done_btn"] = didClickDone ? "true" : "false"
        }
        
        if let isEditPanelOpen = trackInfo.isEditPanelOpen {
            params["is_edit_panel_open"] = isEditPanelOpen ? "true" : "false"
        }
        
        if let itemChangeType = trackInfo.itemChangeType {
            params["cell_item_change"] = String(itemChangeType.rawValue)
        }
        
        if let userDeleteItemSource = trackInfo.userDeleteItemSource {
            params["delete_item_source"] = userDeleteItemSource.rawValue
        }
        DocsTracker.log(enumEvent: .bitableRecordEdit, parameters: params)
    }

    func trackBitableEvent(eventType: String, params: [String: Any]) {
        guard let event = DocsTracker.EventType(rawValue: eventType) else { return }
        var parameters = getCommonTrackParams()
        parameters.merge(other: params)
        DocsTracker.newLog(enumEvent: event, parameters: parameters)
    }
    
    // 收到showCard指令开始track
    func startTrackOpenCardEvent() {
        if case .link = mode { return }
        openCardTracker = OpenCardTracker()
        openCardTracker?.isCollectingData = true
        openCardTracker?.transactionId = actionParams.transactionId
        openCardTracker?.recordId = actionParams.data.recordId
        openCardTracker?.trackTimestamp(timestamp: actionParams.timestamp, type: .userClickTime)
        openCardTracker?.trackTimestamp(type: .nativeReceiveShowCardActionTime)
    }
    
    // 弹窗卡片开始上报
    func endAndReportOpenCardEvent() {
        let maxInterval = 100000.0
        if let openCardTracker = openCardTracker, openCardTracker.isCollectingData == true {
            let showCardTriggerTime = openCardTracker.nativeReceiveShowCardActionTime - openCardTracker.userClickTime
            let tableMetaRequestTime = openCardTracker.webReceiveTableMetaRequestTime - openCardTracker.nativeRequestTableMetaTime
            let tableMetaDispatchTime = openCardTracker.nativeReceiveTableMetaTime - openCardTracker.webReceiveTableMetaRequestTime
            let tableDataRequestTime = openCardTracker.webReceiveTableDataRequestTime - openCardTracker.nativeRequestTableDataTime
            let tableDataDispatchTime = openCardTracker.nativeReceiveTableDataTime - openCardTracker.webReceiveTableDataRequestTime
            let cardRenderTime = openCardTracker.nativeShowCardTime - openCardTracker.nativeReceiveTableDataTime
            let totalTime = openCardTracker.nativeShowCardTime - openCardTracker.userClickTime
            
            guard showCardTriggerTime < maxInterval, showCardTriggerTime >= 0.0,
                tableMetaRequestTime < maxInterval, tableMetaRequestTime >= 0.0,
                tableMetaDispatchTime < maxInterval, tableMetaDispatchTime >= 0.0,
                tableDataRequestTime < maxInterval, tableDataRequestTime >= 0.0,
                tableDataDispatchTime < maxInterval, tableDataDispatchTime >= 0.0,
                cardRenderTime < maxInterval, cardRenderTime >= 0.0,
                totalTime < maxInterval, totalTime > 0 else {
                    return
            }
            
            var params = oldTrackParams()
            params["record_id"] = openCardTracker.recordId
            params["transaction_id"] = openCardTracker.transactionId
            params["view_type"] = tableModel.viewType
            params["show_card_trigger_time"] = Int(showCardTriggerTime)
            params["table_meta_request_time"] = Int(tableMetaRequestTime)
            params["table_meta_dispatch_time"] = Int(tableMetaDispatchTime)
            params["table_data_request_time"] = Int(tableDataRequestTime)
            params["table_data_dispatch_time"] = Int(tableDataDispatchTime)
            params["card_render_time"] = Int(cardRenderTime)
            params["total_time"] = Int(totalTime)
            let cardOptimized = UserScopeNoChangeFG.XM.ccmBitableCardOptimized
            let cardOpenLoading = UserScopeNoChangeFG.XM.cardOpenLoadingEnable
            if cardOptimized && cardOpenLoading {
                // 同时
                params["optimized_version"] = 3.0
            } else if cardOptimized {
                // 只有卡片打开优化
                params["optimized_version"] = 1.0
            } else if cardOpenLoading {
                // 只有流程变更
                params["optimized_version"] = 2.0
            }
            
            DocsTracker.log(enumEvent: .bitablePerformanceOpenCard, parameters: params)
            DocsLogger.btInfo("[LifeCycle] bitable open card finished \(params)")
        }
        openCardTracker?.isCollectingData = false
    }
    
    func trackFetchDataFailedEvent(errorMsg: String, failedType: BTFailedType) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return  }
            var params = self.getCommonTrackParams()
            params["error_msg"] = errorMsg
            params["fail_type"] = failedType.rawValue
            params["platform"] = "native"
            DocsTracker.log(enumEvent: .bitablePerformanceFail, parameters: params)
        }
    }
}
