//
//  SKRootTracing.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2021/11/29.
//  


import Foundation

public struct SKRootTracing {
    public var rootId: String
    public var logComponent: String
    public var commonParams: [String: Any]
    public init(rootId: String, logComponent: String, commonParams: [String: Any]) {
        self.rootId = rootId
        self.logComponent = logComponent
        self.commonParams = commonParams
    }
    
    @discardableResult
    public func startChild(spanName: String,
                           parentSpanName: String? = nil,
                           params: [String: Any] = [:],
                           fileName: String = #fileID,
                           funcName: String = #function,
                           funcLine: Int = #line) -> String {
        
        var finalParams = commonParams
        params.forEach {
            finalParams.updateValue($0.value, forKey: $0.key)
        }
        return SKTracing.shared.startChild(spanName: spanName,
                                           parentSpanName: parentSpanName,
                                           rootSpanId: rootId,
                                           params: finalParams,
                                           component: logComponent,
                                           fileName: fileName,
                                           funcName: funcName,
                                           funcLine: funcLine)
    }
    
    public func startChildAndEndAutomatically(spanName: String,
                                              parentSpanName: String? = nil,
                                              spanResult: SpanResult = .normal,
                                              params: [String: Any] = [:],
                                              fileName: String = #fileID,
                                              funcName: String = #function,
                                              funcLine: Int = #line) {
        
        var finalParams = commonParams
        params.forEach {
            finalParams.updateValue($0.value, forKey: $0.key)
        }
        SKTracing.shared.startChildAndEndAutomatically(spanName: spanName,
                                                       parentSpanName: parentSpanName,
                                                       rootSpanId: rootId,
                                                       spanResult: spanResult,
                                                       params: finalParams,
                                                       component: logComponent,
                                                       fileName: fileName,
                                                       funcName: funcName,
                                                       funcLine: funcLine)
    }
    
    public func endSpan(spanName: String,
                        spanResult: SpanResult = .normal,
                        params: [String: Any] = [:],
                        fileName: String = #fileID,
                        funcName: String = #function,
                        funcLine: Int = #line) {
        var finalParams = commonParams
        params.forEach {
            finalParams.updateValue($0.value, forKey: $0.key)
        }
        SKTracing.shared.endSpan(spanName: spanName,
                                 rootSpanId: rootId,
                                 spanResult: spanResult,
                                 params: finalParams,
                                 component: logComponent,
                                 fileName: fileName,
                                 funcName: funcName,
                                 funcLine: funcLine)
    }
    
    public func finish() {
        SKTracing.shared.finishTrace(rootSpanId: rootId)
    }
}

extension SKRootTracing {
    
    /// 单点打 log，自带 componnet 和 traceId
    public func info(_ message: String,
                     extraInfo: [String: Any]? = nil,
                     fileName: String = #fileID,
                     funcName: String = #function,
                     funcLine: Int = #line) {
        var extraInfo = extraInfo ?? [:]
        commonParams.forEach {
            extraInfo.updateValue($0.value, forKey: $0.key)
        }
        DocsLogger.info(message,
                        extraInfo: extraInfo,
                        component: logComponent,
                        traceId: rootId,
                        fileName: fileName,
                        funcName: funcName,
                        funcLine: funcLine)
    }
    
    /// 单点打 log，自带 componnet 和 traceId
    public func error(_ message: String,
                      extraInfo: [String: Any]? = nil,
                      error: Error? = nil,
                      errMsg: String? = nil,
                      fileName: String = #fileID,
                      funcName: String = #function,
                      funcLine: Int = #line) {
        var extraInfo = extraInfo ?? [:]
        commonParams.forEach {
            extraInfo.updateValue($0.value, forKey: $0.key)
        }
        if let errMsg = errMsg {
            extraInfo.updateValue(errMsg, forKey: "errMsg")
        }
        DocsLogger.error(message,
                         extraInfo: extraInfo,
                         error: error,
                         component: logComponent,
                         traceId: rootId,
                         fileName: fileName,
                         funcName: funcName,
                         funcLine: funcLine)
    }
    
}
