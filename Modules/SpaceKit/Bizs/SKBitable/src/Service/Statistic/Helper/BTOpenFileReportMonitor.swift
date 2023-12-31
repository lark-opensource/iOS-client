//
//  BTOpenFileReportMonitor.swift
//  SKBrowser
//
//  Created by 刘焱龙 on 2023/8/28.
//

import Foundation
import SKCommon
import SKFoundation
import RustPB
import SKResource
import LarkReleaseConfig
import UniverseDesignIcon
import SpaceInterface

private extension BitableBrowserViewController {
    
    func getStatisticOpenFileType() -> BTStatisticOpenFileType {
        if isIndRecord {
            return .share_record
        } else if isAddRecord {
            return .base_add
        } else {
            return .main
        }
    }
}

extension FileConfig {
    private static let openBaseTraceId = "OPEN_BASE_TRACE_ID"

    func getOpenFileTraceId() -> String? {
        return extraInfos?[FileConfig.openBaseTraceId]
    }

    mutating func update(openBaseTraceId: String) {
        guard extraInfos?[FileConfig.openBaseTraceId] == nil else {
            return
        }
        if extraInfos == nil {
            extraInfos = [:]
        }
        extraInfos?[FileConfig.openBaseTraceId] = openBaseTraceId
    }
}

final class BTOpenFileReportMonitor {
    private static var timestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }

    static func handleOpenBrowserView(vc: BitableBrowserViewController, fileConfig: FileConfig) {
        guard let shared = BTStatisticManager.shared else {
            return
        }
        guard let url = vc.editor.currentURL else {
            return
        }

        let traceId = shared.createNormalTrace(parentTrace: nil)
        vc.fileConfig?.update(openBaseTraceId: traceId)

        let consumer = BTOpenFileConsumer(type: vc.getStatisticOpenFileType())
        shared.addNormalConsumer(traceId: traceId, consumer: consumer)

        let from = url.queryParameters["from"] ?? ""
        let subFrom = url.queryParameters["subFrom"] ?? ""

        let openType = vc.getStatisticOpenFileType()

        shared.addTraceExtra(
            traceId: traceId,
            extra: [
                "from": from,
                "subFrom": subFrom,
                BTStatisticConstant.openType: openType.rawValue,
                BTStatisticConstant.fileId: vc.docsInfo?.encryptedObjToken ?? ""
            ]
        )

        BTOpenFileReportMonitor.reportOpenStart(vc: vc)
    }

    private static func reportOpenStart(vc: BitableBrowserViewController) {
        guard let shared = BTStatisticManager.shared else {
            return
        }

        let startTimeStr = vc.fileConfig?.extraInfos?["start_time"] as? String
        let startCreateUIStr = vc.fileConfig?.extraInfos?["create_ui_start_time"] as? String
        let endCreateUIStr = vc.fileConfig?.extraInfos?["create_ui_end_time"] as? String

        var startTime = timestamp
        if let startTimeStr = startTimeStr, let startTimeInt = Int(startTimeStr) {
            startTime = startTimeInt
        }

        let traceId: String
        // Doc in base 场景，已有 traceId
        if let currentTraceId = vc.fileConfig?.getOpenFileTraceId() {
            traceId = currentTraceId
        } else {
            traceId = shared.createNormalTrace(parentTrace: nil)
            vc.fileConfig?.update(openBaseTraceId: traceId)
            let consumer = BTOpenFileConsumer(type: vc.getStatisticOpenFileType())
            shared.addNormalConsumer(traceId: traceId, consumer: consumer)
        }
        shared.addTraceExtra(traceId: traceId, extra: ["time_from_native": startTimeStr != nil ? 1 : 0])
        shared.addNormalPoint(
            traceId: traceId,
            point: BTStatisticNormalPoint(name:  BTStatisticMainStageName.OPEN_FILE_START.rawValue, type: .init_point, timestamp: startTime)
        )

        if let startTimeStr = startCreateUIStr, let startTimeInt = Int(startTimeStr) {
            reportStartCreateUI(traceId: traceId, timestamp: startTimeInt)
        }
        if let endTimeStr = endCreateUIStr, let endTimeInt = Int(endTimeStr) {
            reportStopCreateUI(traceId: traceId, timestamp: endTimeInt)
        }
    }

    static func reportOpenFail(traceId: String, timestamp: Int, extra: [String: Any]? = nil) {
        if let extra = extra {
            BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: extra)
        }
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_FAIL.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenCancel(
        traceId: String,
        extra: [String: Any]? = nil,
        engine: BrowserJSEngine? = nil,
        isRecord: Bool = false,
        forceFetchCostData: Bool = false) {
        if forceFetchCostData, let engine = engine {
            let timestamp = timestamp
            Self.reportFetchSDKLoadCost(engine: engine, traceId: traceId, isRecord: isRecord) {
                let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue, timestamp: timestamp, extra: extra)
                BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
            }
            return
        }
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_CANCEL.rawValue, timestamp: timestamp, extra: extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenFasterTTV(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenFasterTTU(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportSdkFirstPaint(traceId: String, timestamp: Int, extra: [String: Any]) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_SDK_FIRST_PAINT.rawValue, timestamp: timestamp, extra: extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStartRender(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_START_RENDER.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStopRender(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_END_RENDER.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStartCreateUI(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_CREATE_UI_START.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStopCreateUI(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_CREATE_UI_END.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStartPreload(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TEMPLATE_PRELOAD_START.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportStopPreload(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TEMPLATE_PRELOAD_END.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportEvent(event: String?, traceId: String, timestamp: Int? = nil, extra: [String: Any]? = nil) {
        guard let event = event else { return }
        let point = BTStatisticNormalPoint(name: event, timestamp: timestamp ?? Self.timestamp, extra: extra ?? [:])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportFetchSDKLoadCost(engine: BrowserJSEngine, traceId: String?, isRecord: Bool, completion: (() -> ())? = nil) {
        guard UserScopeNoChangeFG.LYL.enableStatisticTrace else {
            completion?()
            return
        }
        guard let traceId = traceId else {
            return
        }
        if BTStatisticManager.shared?.enable(key: BTStatisticSettingKey.disable_native_fetch_sdk_cost.rawValue) == true {
            completion?()
            return
        }
        if BTStatisticManager.shared?.isTraceEnd(traceId: traceId) == true {
            completion?()
            return
        }
        engine.callFunction(
            DocsJSCallBack.getFileLoadPerformanceCost,
            params: ["type": isRecord ? 1 : 0],
            completion: { (data, error) in
                if let error = error {
                    DocsLogger.btError("[BTOpenFileReportMonitor] getFileLoadPerformanceCost fail \(error.localizedDescription)")
                    completion?()
                    return
                }
                guard var sdkCost = (data as? [String: Any])?[BTStatisticConstant.sdkCost] as? [String: Any] else {
                    completion?()
                    return
                }
                sdkCost = sdkCost.filter { $0.value is Int }
                BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [
                    BTStatisticConstant.isFromNativePull: true
                ])

                Self.reportSDKLoadCost(traceId: traceId, extra: [BTStatisticConstant.sdkCost: sdkCost])

                completion?()
            })
    }

    static func reportSDKLoadCost(traceId: String, extra: [String: Any]?) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.BITABLE_SDK_LOAD_COST.rawValue, timestamp: timestamp, extra: extra ?? [:], isUnique: false)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    // docs in base

    static func reportOpenDocInBaseTTV(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenDocInBaseTTU(traceId: String, timestamp: Int) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportSwitchViewOrBlock(traceId: String, extra: [String: Any]? = nil) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.POINT_VIEW_OR_BLOCK_SWITCH.rawValue, timestamp: timestamp, extra: extra ?? [:])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    // form

    static func reportOpenFormTTV(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenFormTTU(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenFormFail(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_FAIL.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    // share record

    static func reportOpenShareRecordTTV(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [BTStatisticConstant.openType: BTStatisticOpenFileType.share_record.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenShareRecordTTU(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [BTStatisticConstant.openType: BTStatisticOpenFileType.share_record.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    static func reportOpenShareRecordFail(traceId: String) {
        let point = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [BTStatisticConstant.openType: BTStatisticOpenFileType.share_record.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }

    // dash_board

    /// 仪表盘没有 local ssr，ttv 等于 ttu
    static func reportDashBoardTTU(traceId: String, timestamp: Int?, extra: [String: Any]?) {
        let ttvPoint = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTV.rawValue, timestamp: timestamp ?? Self.timestamp, extra: extra ?? [:])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: ttvPoint)

        let ttuPoint = BTStatisticNormalPoint(name: BTStatisticMainStageName.OPEN_FILE_TTU.rawValue, timestamp: timestamp ?? Self.timestamp, extra: extra ?? [:])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: ttuPoint)
    }
}

// Base Add Record
extension BTOpenFileReportMonitor {
    
    private static func reportBaseAddRecord(traceId: String, stage: BTStatisticMainStageName, extra: [String: Any]? = nil, timestamp: Int? = nil) {
        let point = BTStatisticNormalPoint(name: stage.rawValue, timestamp: timestamp ?? Self.timestamp, extra: extra)
        BTStatisticManager.shared?.addTraceExtra(traceId: traceId, extra: [BTStatisticConstant.openType: BTStatisticOpenFileType.base_add.rawValue])
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportBaseAddRecordMetaStart(traceId: String, retryCount: Int?) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.retryCount] = retryCount
        reportBaseAddRecord(traceId: traceId, stage: .BASE_ADD_RECORD_META_START, extra: extra)
    }
    
    static func reportBaseAddRecordMetaSuccess(traceId: String, costTime: Int?, dataSize: Int?, retryCount: Int?, code: Int? = nil, msg: String? = nil) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.retryCount] = retryCount
        extra[BTStatisticConstant.code] = code
        extra[BTStatisticConstant.msg] = msg
        extra[BTStatisticConstant.dataSize] = dataSize
        extra[BTStatisticConstant.costTime] = costTime
        reportBaseAddRecord(traceId: traceId, stage: .BASE_ADD_RECORD_META_SUCCESS, extra: extra)
    }
    
    static func reportBaseAddRecordMetaFail(traceId: String, costTime: Int?, retryCount: Int?, code: Int? = nil, msg: String? = nil) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.retryCount] = retryCount
        extra[BTStatisticConstant.code] = code
        extra[BTStatisticConstant.msg] = msg
        extra[BTStatisticConstant.costTime] = costTime
        reportBaseAddRecord(traceId: traceId, stage: .BASE_ADD_RECORD_META_FAIL, extra: extra)
    }
    
    static func reportBaseAddRecordGetMeta(traceId: String) {
        reportBaseAddRecord(traceId: traceId, stage: .BASE_ADD_RECORD_GET_META)
    }
    
    static func reportBaseAddRecordReturnMeta(traceId: String) {
        reportBaseAddRecord(traceId: traceId, stage: .BASE_ADD_RECORD_RETURN_META)
    }
    
    static func reportOpenBaseAddRecordTTV(traceId: String, fieldCount: Int?) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.fieldCount] = fieldCount
        reportBaseAddRecord(traceId: traceId, stage: .OPEN_FILE_TTV)
    }
    
    static func reportOpenBaseAddRecordTTU(traceId: String, fieldCount: Int?) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.fieldCount] = fieldCount
        reportBaseAddRecord(traceId: traceId, stage: .OPEN_FILE_TTU)
    }
    
    static func reportOpenBaseAddRecordFail(traceId: String, retryCount: Int?, code: Int? = nil, msg: String? = nil) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.retryCount] = retryCount
        extra[BTStatisticConstant.code] = code
        extra[BTStatisticConstant.msg] = msg
        reportBaseAddRecord(traceId: traceId, stage: .OPEN_FILE_FAIL, extra: extra)
    }
}
