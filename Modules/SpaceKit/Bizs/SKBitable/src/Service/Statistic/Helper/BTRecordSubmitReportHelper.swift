//
//  BTRecordSubmitReportHelper.swift
//  SKBitable
//
//  Created by yinyuan on 2023/11/24.
//

import Foundation
import SKBrowser

final class BTRecordSubmitReportHelper {
    private static var timestamp: Int {
        return Int(Date().timeIntervalSince1970 * 1000)
    }
    
    private static var currentTraceId: String?
    private static var submitBeginTime: Date?
    private static var submitSuccessTime: Int?
    
    private static func reportBaseAddRecord(stage: BTStatisticMainStageName, extra: [String: Any]? = nil, timestamp: Int? = nil) {
        guard let traceId = currentTraceId else {
            return
        }
        let point = BTStatisticNormalPoint(name: stage.rawValue, timestamp: timestamp ?? Self.timestamp, extra: extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
    
    static func reportBaseAddRecordSubmitStart(cardVC: BTController) {
        guard let shared = BTStatisticManager.shared else {
            return
        }
        
        let traceId = shared.createNormalTrace(parentTrace: cardVC.openFileTraceId)
        currentTraceId = traceId
        submitBeginTime = Date()
        
        let consumer = BTRecordSubmitConsumer()
        shared.addNormalConsumer(traceId: traceId, consumer: consumer)
        
        // 添加公共参数
        shared.addTraceExtra(
            traceId: traceId,
            extra: [
                BTStatisticConstant.openType: BTStatisticOpenFileType.base_add.rawValue,
                BTStatisticConstant.fileId: (cardVC.delegate?.cardGetBrowserController() as? BrowserViewController)?.docsInfo?.encryptedObjToken ?? "",
                BTStatisticConstant.fieldCount: cardVC.viewModel.tableMeta.fields.count
            ]
        )
        
        reportBaseAddRecord(stage: .BASE_ADD_RECORD_SUBMIT_START)
    }
    
    static func reportBaseAddRecordSubmitSuccess(submitSuccessTime: Int?) {
        Self.submitSuccessTime = submitSuccessTime
        
        var extra: [String: Any] = [:]
        if let submitBeginTime = submitBeginTime {
            extra[BTStatisticConstant.costTime] = Int(Date().timeIntervalSince(submitBeginTime) * 1000)
        }
        reportBaseAddRecord(stage: .BASE_ADD_RECORD_SUBMIT_SUCCESS, timestamp: submitSuccessTime)
    }
    
    static func reportBaseAddRecordSubmitFail(code: Int? = nil, msg: String? = nil) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.code] = code
        extra[BTStatisticConstant.msg] = msg
        if let submitBeginTime = submitBeginTime {
            extra[BTStatisticConstant.costTime] = Int(Date().timeIntervalSince(submitBeginTime) * 1000)
        }
        reportBaseAddRecord(stage: .BASE_ADD_RECORD_SUBMIT_FAIL, extra: extra)
        
        // 结束
        currentTraceId = nil
    }
    
    static func reportBaseAddRecordApplyEnd(result: String) {
        var extra: [String: Any] = [:]
        extra[BTStatisticConstant.result] = result
        if let submitSuccessTime = submitSuccessTime {
            extra[BTStatisticConstant.costTime] = Int(Date().timeIntervalSince1970 * 1000) - submitSuccessTime
        }
        reportBaseAddRecord(stage: .BASE_ADD_RECORD_APPLY_END, extra: extra)
        
        // 结束
        currentTraceId = nil
    }
}
