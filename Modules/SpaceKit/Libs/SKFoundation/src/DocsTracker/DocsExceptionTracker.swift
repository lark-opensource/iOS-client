//
//  DocsExceptionTracker.swift
//  SKFoundation
//
//  Created by huayufan on 2022/9/8.
//  

import Foundation
import Heimdallr

///  自定义异常上报
public final class DocsExceptionTracker {
    public enum ExceptionType: String {
        case cookie = "docs_cookie"
    }
}

extension DocsExceptionTracker {
    
    /// 记录一条自定义异常事件并且上报所有线程的调用栈，指定当前线程作为关键线程
    /// - Parameters:
    /// - type 异常类型，不可为空
    /// - skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
    /// - customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
    /// - filters 自定义的筛选项，可在平台列表页中筛选
    /// - callback: 日志是否记录成功的回调
    public static func trackException(_ type: DocsExceptionTracker.ExceptionType,
                                      skippedDepth: UInt = 0,
                                      customParams: [String: Any]? = nil,
                                      filters: [String: Any]? = nil) {
        HMDUserExceptionTracker.shared().trackAllThreadsLogExceptionType(type.rawValue, skippedDepth: skippedDepth, customParams: customParams, filters: filters, callback: { error in
            guard let error = error else { return }
            /// errcode的定义:
            /// 1: user exception模块没有开启工作
            /// 2: 类型缺失
            /// 3: 超出客户端限流，1min内同一种类型的自定义异常不可以超过1条
            /// 4: 写入数据库失败
            /// 5: 参数缺失
            /// 6: hitting blockList
            /// 7: 日志生成失败
            DocsLogger.error("trace thread error", error: error, component: LogComponents.docsException)
        })
    }
}
