//
//  QuickAction+Extension.swift
//  LarkAIInfra
//
//  Created by Hayden on 4/9/2023.
//

import RustPB
import ServerPB

/// QuickAction 的扩展方法
public extension AIQuickActionModel {

    /// 确认快捷指令是否需要用户输入后才能执行
    /// - NOTE:
    ///  1. 所有参数都不需要用户确认 --> 点击后快捷指令不上输入框，直接执行
    ///  2. 部分参数需要用户确认 --> 点击后上输入框，只有需要确认的快捷指令会在输入框上看到。
    var needUserInput: Bool {
        // 没有参数，可直接执行
        if paramList.isEmpty { return false }
        // 所有参数都不需用户确认，可直接执行
        if paramList.allSatisfy({ !$0.needConfirm }) { return false }
        // 其他情况，需要用户输入
        return true
    }

    var needUserInputParamNames: [String] {
        guard needUserInput else { return [] }
        return paramList.filter { $0.needConfirm }.map { $0.name }
    }

    /// 快捷指令中所有不需要确认的参数，以及其默认值
    /// - NOTE: 这类参数不需用户输入，静默发送，发送后也不上屏
    var unconfirmableParams: [String: String] {
        var params: [String: String] = [:]
        for paramDetail in paramList where !paramDetail.needConfirm {
            if paramDetail.hasDefault && !paramDetail.default.isEmpty {
                params[paramDetail.name] = paramDetail.default
            }

        }
        return params
    }

    /// 所有的参数列表，预先填充好默认值
    /// - NOTE: 目前的现状是：即使用户不填参数，依然要带上，否则快捷指令平台就不会回复。虽然我认为极为不合理，但是只能服从多数。
    var allParamsMap: [String: String] {
        var params: [String: String] = [:]
        for paramDetail in paramList {
            params[paramDetail.name] = paramDetail.hasDefault ? paramDetail.default : ""
        }
        return params
    }

    /// 快捷指令在输入框展示的名称
    /// - NOTE: 如果没有 displayName，展示 description；如果没有 description，展示 name
    var realDisplayName: String {
        if hasDisplayName { return displayName }
        return name
    }

    /// 从 `extraMap` 中筛选出的透传参数，发送快捷指令时放入 `aiInfoContext.chatContext` 中
    /// - NOTE: 参数 key 由服务端指定，客户端不感知内容
    var serverRecallMap: [String: String] {
        // 目前只有召回源参数，以后有新的参数在这里添加
        let recallKeys: Set<String> = ["_SYSTEM_QUERY_METADATA"]
        return extraMap.filter { element in
            recallKeys.contains(element.key)
        }
    }
}

/// QuickAction 参数的扩展方法
public extension AIQuickActionParamModel {

    /// 快捷指令参数在输入框展示的名称
    /// - NOTE: 如果没有 displayName，展示 description；如果没有 description，展示 name
    var realDisplayName: String {
        if hasDisplayName { return displayName }
        return name
    }

    /// 快捷指令参数是否有默认值（去掉空字符）
    var hasDefaultContent: Bool {
        hasDefault && !self.default.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Im_V1_Param: AIQuickActionParamModel {}
extension Im_V1_QuickAction: AIQuickActionModel {
    public var typeIsPromptTask: Bool { actionType == .promptTask }
    public var typeIsAPI: Bool { actionType == .api }
    public var typeIsQuery: Bool { actionType == .query }
    public var paramList: [AIQuickActionParamModel] {
        paramDetails.compactMap { $0 as AIQuickActionParamModel }
    }
}

extension ServerPB_Office_ai_Param: AIQuickActionParamModel {}
extension ServerPB_Office_ai_QuickAction: AIQuickActionModel {
    public var typeIsPromptTask: Bool { actionType == .promptTask }
    public var typeIsAPI: Bool { actionType == .api }
    public var typeIsQuery: Bool { actionType == .query }
    public var paramList: [AIQuickActionParamModel] {
        paramDetails.compactMap { $0 as AIQuickActionParamModel }
    }
}
