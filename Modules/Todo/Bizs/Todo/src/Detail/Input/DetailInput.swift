//
//  DetailInput.swift
//  Todo
//
//  Created by 白言韬 on 2021/5/7.
//

import Foundation

enum DetailInput {
    /// 全屏创建
    case create(source: TodoCreateSource, callbacks: TodoCreateCallbacks)
    /// 快速新建展开进入全屏创建
    case quickExpand(
        todo: Rust.Todo,
        subTasks: [Rust.Todo]?,
        relatedTaskLists: [Rust.TaskContainer]?,
        sectionRefResult: [String: Rust.SectionRefResult]?,
        ownedSection: Rust.ContainerSection?,
        source: TodoCreateSource,
        callbacks: TodoCreateCallbacks
    )
    /// 编辑
    case edit(guid: String, source: TodoEditSource, callbacks: TodoEditCallbacks)

    // 来自快捷创建
    var isQiuckCreate: Bool {
        switch self {
        case .quickExpand: return true
        default: return false
        }
    }
}
