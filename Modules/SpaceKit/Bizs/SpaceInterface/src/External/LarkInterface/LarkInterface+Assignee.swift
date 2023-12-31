//
//  LarkInterface+Assignee.swift
//  SpaceInterface
//
//  Created by zengsenyuan on 2021/11/11.
//  


import Foundation
import EENavigator

/// 展示任务执行者
public struct LarkShowTaskAssigneeBody: PlainBody {
    public static let pattern = "//client/assignee/larkTodo"
    
    public typealias FinishHandler = ([[String: Any]]) -> Void
    
    /// 参见 TodoUserBody
    public let params: [String: Any]
    public var finishHandler: FinishHandler

    public init(params: [String: Any], finishHandler: @escaping FinishHandler) {
        self.params = params
        self.finishHandler = finishHandler
    }
}


public struct LarkSearchAssigneePickerItem {
    public var id: String
    public var name: String
    
    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

/// 所有者选择器
public struct LarkSearchAssigneePickerBody: PlainBody {
    public static let pattern = "//client/assignee/larkPicker"
    /// 选择器标题
    public let title: String
    public var selectedItems: [LarkSearchAssigneePickerItem] = []
    public var didFinishChoosenItems: (([LarkSearchAssigneePickerItem]) -> Void)

    public init(title: String, didFinishChoosenItems: @escaping (([LarkSearchAssigneePickerItem]) -> Void)) {
        self.didFinishChoosenItems = didFinishChoosenItems
        self.title = title
    }
}

/// 打开创建任务页
public struct LarkShowCreateTaskBody: PlainBody {
    public static let pattern = "//client/assignee/showCreate"
    
    public typealias FinishHandler = ([String: Any]) -> Void
    public let params: [String: Any]
    public var finishHandler: FinishHandler

    public init(params: [String: Any], finishHandler: @escaping FinishHandler) {
        self.params = params
        self.finishHandler = finishHandler
    }
}
