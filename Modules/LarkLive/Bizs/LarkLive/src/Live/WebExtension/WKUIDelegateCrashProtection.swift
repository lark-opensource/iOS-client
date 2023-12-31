//
//  WKUIDelegateCrashProtection.swift
//  ByteView
//
//  Created by tuwenbo on 2021/4/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import LKCommonsLogging

/// https://bytedance.feishu.cn/docs/doccnSeCUCcBXHgvOZckXWEByve
/// WKUIDelegate 各 UI 方法 回调崩溃保护器，针对window.alert等方法，弹出alert时被异常关闭alert导致无回调进一步导致崩溃，进行防护，请保证主线程调用
final class WKUIDelegateCrashProtection<CompletionHandlerParamsType> {

    private let logger = Logger.live

    /// WKUIDelegate 方法中的回调
    private let completionHandler: (CompletionHandlerParamsType) -> Void

    /// 标注是否已经调用 completionHandler
    private var hasCalledCompletionHandler = false

    /// 回调参数默认值
    private let defaultCompletionHandlerParamsValue: CompletionHandlerParamsType

    /// 初始化 WKUIDelegate 各 UI 方法 回调崩溃保护器
    /// - Parameters:
    ///   - completionHandler: 回调
    ///   - defaultCompletionHandlerParamsValue: 回调参数默认值
    init(_ completionHandler: @escaping (CompletionHandlerParamsType) -> Void, defaultCompletionHandlerParamsValue: CompletionHandlerParamsType) {
        self.completionHandler = completionHandler
        self.defaultCompletionHandlerParamsValue = defaultCompletionHandlerParamsValue
    }

    /// 调用回调
    /// - Parameter completionHandlerParamsValue: 回调参数
    func callCompletionHandler(completionHandlerParamsValue: CompletionHandlerParamsType) {
        //  保证只调用一次回调
        if hasCalledCompletionHandler {
            return
        }
        hasCalledCompletionHandler = true
        completionHandler(completionHandlerParamsValue)
    }

    /// 如果被异常销毁，deinit保障一定回调一次
    deinit {
        //  如果确定异常销毁，补充日志和assert
        if !hasCalledCompletionHandler {
            let msg = "UIAlertController for WKUIDelegate has been dismissed illegally, please check wrong code"
            logger.error(msg)
            assertionFailure(msg)
        }
        callCompletionHandler(completionHandlerParamsValue: defaultCompletionHandlerParamsValue)
    }
}

/// 针对 () -> Void 提供便利方法
extension WKUIDelegateCrashProtection where CompletionHandlerParamsType == Void {
    convenience init(_ completionHandler: @escaping (CompletionHandlerParamsType) -> Void) {
        self.init(completionHandler, defaultCompletionHandlerParamsValue: ())
    }

    func callCompletionHandler() {
        callCompletionHandler(completionHandlerParamsValue:())
    }
}
