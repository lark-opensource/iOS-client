//
//  ContextKeys.swift
//  EENavigator
//
//  Created by liuwanlin on 2018/9/11.
//

import Foundation

public struct ContextKeys {
    /// Key for matched groups of custom url matcher
    public static let matchedGroups = "_kMatchedGroups"
    /// Key for matched path parameters of default url matcher
    public static let matchedParameters = "_kMatchedParameters"
    /// Key for matched or not
    public static let matched = "_kMatched"
    /// Key for matched or not
    public static let matchedPattern = "_kMatchedPattern"
    /// Key for request body
    public static let body = "_kBody"

    /// Key for redirect callback
    static let acyncRedirect = "_kAnsyncRedirect"
    /// Key for redirect times
    static let redirectTimes = "_kRedirectTimes"

    // Only for Navigator
    public static let naviParams = "_kNaviParams"

    // key for openType
    public static let openType = "_kOpenType"
    // key for from entity, Type is NavigatorFromWrapper
    public static let from = "_kFrom"

    // 需要保证redirect时也保留的环境context字段。暂时根据lark使用场景写死,
    // 注意和Navigator+User里定义的一致性
    static let inheritKeys = ["_kUserID", "__callerResolver"]

    /// 检查 push 的安全性，如果被 push 的页面已经在 NavigationController 栈中了，
    /// 就执行 pop 操作
    public static let checkPushSafety = "_kCheckPushSafety"
}
