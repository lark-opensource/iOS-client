//
//  DialogManagerService.swift
//  LarkDialogManager
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import ThreadSafeDataStructure
import LarkSetting

public struct DialogTask {
    // 弹窗执行的优先级
    public var priority: Int
    // 弹窗展示逻辑
    public var onShow: () -> Void
    
    public init(priority: Int = 0, onShow: @escaping (() -> Void)) {
        self.priority = priority
        self.onShow = onShow
    }
}

public protocol DialogManagerService {
    // 弹窗展示结束，调用dismiss方法告知执行后续弹窗任务
    // 需要和addTask成对使用
    // ‼️：弹窗关闭一定要调用这个方法
    func onDismiss()

    // 添加新的弹窗任务
    func addTask(task: DialogTask)
}

final class DialogManagerImpl: DialogManagerService {
    static var shared: DialogManagerImpl = DialogManagerImpl()

    var isDialogShowing = false
    var taskQueue: SafeArray<DialogTask> = [] + .readWriteLock
    let dialogManagerFG = FeatureGatingManager.shared.featureGatingValue(with: "lark.core.coldstart_dialog")

    private func execute() {
        if let task = taskQueue.first, !isDialogShowing {
            taskQueue.remove(at: 0)
            isDialogShowing = true
            task.onShow()
        }
    }

    public func onDismiss() {
        isDialogShowing = false
        self.execute()
    }

    public func addTask(task: DialogTask) {
        guard dialogManagerFG else {
            task.onShow()
            return
        }
        taskQueue.append(task)
        taskQueue = taskQueue.sorted(by: {$0.priority >= $1.priority})
        execute()
    }
}
