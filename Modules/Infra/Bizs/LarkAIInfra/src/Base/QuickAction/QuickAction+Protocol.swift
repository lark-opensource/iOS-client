//
//  QuickAction+Protocol.swift
//  LarkAIInfra
//
//  Created by Hayden on 4/9/2023.
//

import Foundation

// TODO: @wanghaidong 这个扩展应该做到最底层模块，统一所有业务方的 QuickAction 模型

public protocol AIQuickActionModel {

    var id: String { get }
    var hasID: Bool { get }

    var name: String { get }
    var hasName: Bool { get }

    var description_p: String { get }
    var hasDescription_p: Bool { get }

    /// 国际化的快捷指令名称 （按钮上显示）
    var displayName: String { get }
    var hasDisplayName: Bool { get }

    var extraMap: Dictionary<String,String> { get }
    /// 由于协议实现原因，`paramDetails` 在协议中改名 `paramList`
    var paramList: [AIQuickActionParamModel] { get }

    // 由于协议不能定义枚举 case，所以快捷指令类型改为 Bool 类型变量判断

    /// 快捷指令的类型（case `prompTask`）
    var typeIsPromptTask: Bool { get }
    /// 快捷指令的类型（case `api`）
    var typeIsAPI: Bool { get }
    /// 快捷指令的类型（case `query`）
    var typeIsQuery: Bool { get }
}

public protocol AIQuickActionParamModel {

    var id: String { get }
    var hasID: Bool { get }

    /// 参数Key
    var name: String { get }
    var hasName: Bool { get }

    var isOptional: Bool { get }
    var hasIsOptional: Bool { get }

    /// 参数占位的默认值
    var `default`: String { get }
    var hasDefault: Bool { get }

    /// 是否进入输入框
    var needConfirm: Bool { get }
    var hasNeedConfirm: Bool { get }

    var description_p: String { get }
    var hasDescription_p: Bool { get }

    /// 输入框的参数名后面的占位名
    var placeHolder: String { get }
    var hasPlaceHolder: Bool { get }

    /// 需要上输入框的参数名
    var displayName: String { get }
    var hasDisplayName: Bool { get }
}
