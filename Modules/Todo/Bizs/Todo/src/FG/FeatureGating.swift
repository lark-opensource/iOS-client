//
//  FeatureGating.swift
//  Todo
//
//  Created by wangwanxin on 2021/6/17.
//

import LarkSetting
import LarkContainer

/// Todo Feature Gating
enum FeatureGatingKey: String, CaseIterable {
    /// 任务中心是否支持搜索 version：>4.4.999
    case search = "todo.center.search"

    /// url 中台 v4.6
    case urlPreview = "todo.urlpreview.on"

    /// 支持举报；长期保留，作为功能开关
    case report = "lark.todo.report"

    /// 任务中心了解更多
    case helper = "todo.help.center"

    // 甘特图
    case gantt = "todo.task_gantt_view"
    /// 用户态
    case userScope = "ios.container.scope.user.todo"

    /// 分组排序
    case reorderSection = "todo.center.section_drag"

    // 任务ID
    case entityNum = "task.input.entity_num"

    /// 自定义字段
    case customFields = "todo.task_custom_fields"

    /// 开始时间
    case startTime = "todo.start.time"

    /// 我负责的&进行中
    case settingRed = "todo.red_bot_owned_unfinish"

    /// 多执行者
    case multiAssignee = "todo.bring_back_multi_assignee"

    /// 文本字段
    case textField =  "todo.task_text_field"

    /// 管理任务清单
    case organizableTaskList = "todo.organizable_task_list"
    
    /// 历史记录
    case history = "todo.history.record"
}

extension FeatureGatingKey {
    #if DEBUG
    #if InTodoDemo

    var debugBoolValue: Bool { true }

    #endif
    #endif

    static var isDebugMode = false
}

struct FeatureGating {
    let userResolver: UserResolver

    init(resolver: UserResolver) {
        self.userResolver = resolver
    }

    func boolValue(for key: FeatureGatingKey) -> Bool {
        #if DEBUG
        #if InTodoDemo
        return key.debugBoolValue
        #endif
        #endif
        let aKey = FeatureGatingManager.Key(stringLiteral: key.rawValue)
        return userResolver.fg.staticFeatureGatingValue(with: aKey)
    }

    ///  严格与rust启动时一致
    static func boolValue(for key: FeatureGatingKey) -> Bool {
        #if DEBUG
        #if InTodoDemo
        return key.debugBoolValue
        #endif
        #endif
        let aKey = FeatureGatingManager.Key(stringLiteral: key.rawValue)
        return FeatureGatingManager.shared.featureGatingValue(with: aKey)
    }
}
