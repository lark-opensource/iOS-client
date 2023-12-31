//
//  NativeSyncPriorityManager.swift
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/11/7.
//

import Foundation

/// 同一runloop内执行任务管理类
/// 解决问题：因为源代码逻辑中存在某些逻辑执行时wekkit中部分状态未准备好，所以打算将任务统一到一处执行。
/// 为了统一在runloop的最终时机，也就是UIScrollView 的 dealloc时，将任务队列中的任务依次执行
final class NativeSyncPriorityManager {
    static let shared = NativeSyncPriorityManager()
    
    /// 任务映射表
    private var taskMap: [String: Bool] = [:]
    /// 任务队列
    private var tasks: [() -> String?] = []
    private var needExecute = false
    
    /// 向任务队列中添加任务。
    /// 如果是第一次添加任务，除了将任务添加到任务队列以外，还要将清理任务队列以及任务映射表的任务交给下一个runloop执行
    /// 如果是第一次以后添加任务，则只需要将任务添加到任务队列
    func addTask(execute work: @escaping () -> String?) {
        if !needExecute {
            needExecute = true
            DispatchQueue.main.async {
                // 执行任务
                self.executeTask()
            }
        }
        tasks.append(work)
    }
    
    /// 如果任务队列中有任务，则将所有任务依次执行完，并且修改任务映射表
    /// 如果任务对列中没有任务，则直接返回
    func executeAllTaskIfNeeded() {
        guard !tasks.isEmpty else {
            return
        }
        var condition = true
        while(condition) {
            if let task = tasks.popLast() {
                if let renderId = task() { // 执行完且存在
                    taskMap[renderId] = true
                }
            } else {
                condition = false
            }
        }
    }
    
    /// 判断renderID对应的任务是否执行完毕
    func isContainsTask(renderId: String) -> Bool? {
        return taskMap[renderId]
    }
    
    /// 依次执行所有任务，并清空任务队列以及任务映射表
    private func executeTask() {
        needExecute = false
        
        tasks.forEach { task in
            let _ = task()
        }
    
        tasks.removeAll()
        taskMap.removeAll()
    }
}
