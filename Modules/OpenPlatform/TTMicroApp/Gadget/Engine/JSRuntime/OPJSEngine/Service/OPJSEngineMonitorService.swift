//
//  OPJSEngineMonitorService.swift
//  TTMicroApp
//
//  Created by yi on 2021/12/29.
//
// 提供给OPJSEngine的monitor service

import Foundation
import OPJSEngine
final class OPJSEngineMonitorService: NSObject, OPJSEngineMonitorProtocol {
    public func bindTracing(monitor: OPMonitor, uniqueID: OPAppUniqueID) {
        let tracing = BDPTracingManager.sharedInstance().getTracingBy(uniqueID)
        monitor.setUniqueID(uniqueID).tracing(tracing)
    }
}
