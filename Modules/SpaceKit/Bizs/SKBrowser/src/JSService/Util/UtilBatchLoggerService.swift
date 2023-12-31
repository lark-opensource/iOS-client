//
//  UtilBatchLoggerService.swift
//  SKBrowser
//
//  Created by ByteDance on 2022/11/29.
//

import Foundation
import SKCommon
import SKFoundation

/// 接收前端聚合后传递过来的Log
class UtilBatchLoggerService: BaseJSService {
    
    let logQueue = DispatchQueue(label: "com.bytedance.docs.batchlog")
    
}

extension UtilBatchLoggerService: DocsJSServiceHandler {
    
    public var handleServices: [DocsJSService] {
        [.utilBatchLogger]
    }
    
    public func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.utilBatchLogger.rawValue:
            handleLogs(params: params)
        default:
            break
        }
    }
}

private extension UtilBatchLoggerService {
    
    func handleLogs(params: [String: Any]) {
        
        guard let logList = params["logMessages"] as? [[String: Any]] else {
            DocsLogger.info("batch-log data format error")
            return
        }
        
        let webviewId = model?.jsEngine.editorIdentity ?? ""
        
        for logJson in logList {
            autoreleasepool {
                if let ts = logJson["timeStamp"] as? TimeInterval { // 必须有时间戳,单位秒,保留3位小数(ms)
                    let msg = (logJson["msg"] as? String) ?? "" // 日志内容
                    self.logQueue.async {
                        let message = "\(webviewId) js log: \(msg)"
                        DocsLogger.log(level: .info, message: message, time: ts, useCustomTimeStamp: true)
                    }
                }
            }
        }
        DocsLogger.info("batch-log write done, count: \(logList.count)")
    }
}
