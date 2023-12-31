//
//  BTActionQueueManager.swift
//  SKBitable
//
//  Created by zoujie on 2022/10/14.
//

import SKFoundation

final class BTTaskQueueManager {
    private var taskQueue: [BTActionTask] = []
    private(set) var currentActionTask: BTActionTask?
    
    var taskExecuteBlock: ((BTActionTask) -> Void)?
    
    /// 添加任务到队列中，任务按顺序执行
    /// - Parameter task: 任务
    func addTask(task: BTActionTask) {
        DocsLogger.btInfo("[BTTaskQueueManager] addTask:\(task.description) completed")
        let currentTask = task
        currentTask.setCompleted {
            DocsLogger.btInfo("[BTTaskQueueManager] \(task.description) completed")
            self.executeNextTask()
        }
        taskQueue.append(currentTask)
        
        if currentActionTask == nil {
            executeNextTask()
        }
    }
    
    /// 执行任务
    private func executeNextTask() {
        currentActionTask = taskQueue.first
        if !taskQueue.isEmpty {
            taskQueue.removeFirst()
        }

        if let task = currentActionTask {
            DocsLogger.btInfo("[BTTaskQueueManager] execute \(task.description)")
            taskExecuteBlock?(task)
        }
    }
    
    /// 重置数据
    func reset() {
        DocsLogger.btInfo("[BTTaskQueueManager] reset")
        taskQueue.removeAll()
        currentActionTask = nil
        taskExecuteBlock = nil
    }
}
