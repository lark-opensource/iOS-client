//
//  LDError.swift
//  NewLarkDynamic
//
//  Created by MJXin on 2022/4/27.
//

import Foundation
public enum LDCardError: Error {
    public enum ActionError: Error {
        /// action 找不到或不存在
        case actionInvalid
        /// action 不允许点击
        case actionNotAllow
        /// action 处理中
        case actionProcessing // action 处理中
        /// url 不存在
        case urlError
        /// 非合法的跳转链接
        case openLinkUrlInvalid
        /// 不支持打开 对应的 url
        case openLinkUrlUnsupport
        /// 点击频率太高,限频
        case openLinkLimitInterval
        /// 没有 Triggercode
        case openLinkWithoutTriggercode
        /// 没有 Triggercode 对应的 func
        case openLinkwithoutTriggercodeFunc
        /// 打开链接失败
        case openLinkFail(String?)
        /// 请求响应失败
        case responseFail(Error?)
    }
    
}
