//
//  ECONetworkRustClient+Monitor.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/8.
//

import Foundation

extension ECONetworkRustClient {
    func monitorRequestStart(task: ECONetworkRustTask) {
        OPMonitor(name: kEventName_econetwork_request, code: ECONetworkMonitorCode.request_start)
            .tracing(task.trace)
            .addCategoryValue("request_id", task.requestID)
            .addCategoryValue("url", NSString.safeURL(task.requestURL))
            .addCategoryValue(ECONetworkMonitorKey.source, task.context.source)
            .flush()
    }
    
    func monitorRequestEnd(task: ECONetworkRustTask, isCancel: Bool) {
        let header = task.response?.allHeaderFields
        let monitor = OPMonitor(name: kEventName_econetwork_request, code: ECONetworkMonitorCode.request_end)
            .tracing(task.trace)
            .addCategoryValue("request_id", task.requestID)
            .addCategoryValue("url", NSString.safeURL(task.requestURL))
            .addCategoryValue(ECONetworkMonitorKey.source, task.context.source)
            .addCategoryValue(ECONetworkMonitorKey.logId, header?["x-tt-logid"])
        if let metrics = task.metrics {
            _ = monitor.addMap(metrics.toDictionary())
        }
        if isCancel {
            _ = monitor.setResultTypeCancel()
        } else {
            if let error = task.error {
                _ = monitor.setResultTypeFail().setError(error)
            } else {
                _ = monitor.setResultTypeSuccess()
            }
        }
        if let response = task.response {
            _ = monitor.addCategoryValue("http_code", response.statusCode)
        }
        monitor.flush()
    }
}
