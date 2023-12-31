//
//  BTStatisticNativeRenderHandle.swift
//  SKBitable
//
//  Created by zoujie on 2023/12/4.
//  


import Foundation

final class BTStatisticNativeRenderHandle: BTStatisticReportHandle {
    func handle(reportItem: BTBaseStatisticReportItem) {
        guard let traceId = reportItem.extra?["traceId"] as? String else {
            return
        }
        
        let point = BTStatisticNormalPoint(name: reportItem.event ?? "ccm_bitable_mobile_view_lifecycle", extra: reportItem.extra)
        BTStatisticManager.shared?.addNormalPoint(traceId: traceId, point: point)
    }
}
