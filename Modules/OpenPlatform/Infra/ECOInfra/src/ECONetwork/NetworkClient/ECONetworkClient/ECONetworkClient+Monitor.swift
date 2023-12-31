//
//  ECONetworkClient+Monitor.swift
//  ECOInfra
//
//  Created by MJXin on 2021/5/27.
//

import Foundation

//MARK: - Monitor
extension ECONetworkClient {
    func monitorRequestStart(task: ECONetworkTask) {
        OPMonitor(name: kEventName_econetwork_request, code: ECONetworkMonitorCode.request_start)
            .tracing(task.trace)
            .addCategoryValue("request_id", task.requestID)
            .addCategoryValue("url", NSString.safeURL(task.requestURL))
            .addCategoryValue(ECONetworkMonitorKey.source, task.context.source)
            .flush()
    }
    
    func monitorRequestEnd(task: ECONetworkTask, isCancel: Bool) {
        let monitor = OPMonitor(name: kEventName_econetwork_request, code: ECONetworkMonitorCode.request_end)
            .tracing(task.trace)
            .addCategoryValue("request_id", task.requestID)
            .addCategoryValue("url", NSString.safeURL(task.requestURL))
            .addCategoryValue(ECONetworkMonitorKey.source, task.context.source)
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
        if let response = task.httpResponse {
            _ = monitor.addCategoryValue("http_code", response.statusCode)
        }
        monitor.flush()
    }
}
