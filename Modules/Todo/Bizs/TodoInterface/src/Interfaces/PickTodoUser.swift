//
//  PickTodoUser.swift
//  TodoInterface
//
//  Created by wangwanxin on 2021/11/8.
//

import EENavigator

public struct TodoUserBody: PlainBody {
    public static let pattern = "//client/docx/pickTodo"
    // 为了方便ccm同学透传，这里使用key，而非结构体
    public var param: [String: Any] = [:]
    public var callback: (([[String: Any]]) -> Void)?
    public init() { }

    // userIds: [[id: "", name: "", completedMilliTime: 0]], editable: bool
    public static let userIds = "userIds"
    public static let users = "users"
    public static let enableMultiAssignee = "enableMultiAssignee"
    public static let editable = "editable"

    // [id: "", name: "", completedMilliTime: 0]
    public static let id = "id"
    public static let name = "name"
    public static let completedMilliTime = "completedMilliTime"

}

public struct CreateTaskFromDocBody: PlainBody {
    public static let pattern = "//client/task/createFromDoc"

    public typealias Callback = (([String: Any]) -> Void)

    public let param: [String: Any]
    public let callback: Callback

    public init(param: [String: Any], callback: @escaping Callback) {
        self.param = param
        self.callback = callback
    }
}

extension CreateTaskFromDocBody {

    // 为了读取数据
    public static let TaskKey = "todo"
    public static let SectionKey = "taskListSections"
    public static let CallbackKey = "data"

}
