//
//  TodoAppLink.swift
//  TodoInterface
//
//  Created by wangwanxin on 2022/12/1.
//

import Foundation

public struct TodoAppLink {
    // 切 Tab 打开任务中心
    public static let Open = "/client/todo/open"
    // 创建任务
    public static let Create = "/client/todo/create"
    // 查看列表
    public static let View = "/client/todo/view"
    // 查看任务清单
    public static let TaskList = "/client/todo/task_list"
    // 打开详情页
    public static let Detail = "/client/todo/detail"
    // 标题
    public static let CreateQuerySummary = "summary"
    // 截止时间
    public static let CreateQueryDueTime = "dueTime"
    // 埋点事件
    public static let EventName = "trackEventName"

}
