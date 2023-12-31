//
//  ECONetworkRustClient+TaskClient.swift
//  ECOInfra
//
//  Created by ByteDance on 2023/10/7.
//

import Foundation

//MARK: - URLSessionDelegate
extension ECONetworkRustClient: ECONetworkRustTaskClient {
    
    func taskResuming(task: ECONetworkRustTask) {
        tasksSemaphore.wait()
        // 外界重复调用属于正常现象
        guard task.state == .suspended else {
            tasksSemaphore.signal()
            return
        }
        Self.logger.info(
            "TaskControl - taskResuming",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? ""
            ]
        )
        // 准备 Response 的数据接收器
        if let error = task.responseDataHandler.ready() {
            // 数据接收对象准备失败, 失败直接结束任务
            Self.logger.error("taskID: \(task.taskIdentifier) task resume error \(error)")
            task.error = error
            tasksSemaphore.signal()
            task.complete()
        } else {
            // 数据接收对象构造成功, 开始请求
            inner_requestingTasks[task.taskIdentifier] = task
            task.state = .running
            task.internalTask.resume()
            tasksSemaphore.signal()
            // 埋请求开始点
            monitorRequestStart(task: task)
        }
    }
    
    func taskPausing(task: ECONetworkRustTask) {
        tasksSemaphore.wait(); defer { tasksSemaphore.signal() }
        // 外界重复调用属于正常现象
        guard task.state == .running else { return }
        Self.logger.info(
            "TaskControl - taskPausing",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
            ]
        )
        task.state = .suspended
        task.internalTask.suspend()
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
    }
    
    func taskCanceling(task: ECONetworkRustTask) {
        tasksSemaphore.wait(); defer { tasksSemaphore.signal()}
        // 外界重复调用属于正常现象
        guard task.state == .suspended || task.state == .running else { return }
        task.state = .canceling
        task.internalTask.cancel()
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
        Self.logger.info(
            "TaskControl - taskCanceling",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
                "prevState": task.state.description()
            ]
        )
    }
    
    func taskCompleting(task: ECONetworkRustTask) {
        tasksSemaphore.wait()
        // 外界重复调用属于正常现象
        guard task.state != .completed else {
            Self.logger.error("taskID: \(task.taskIdentifier) complted")
            assertionFailure("taskID: \(task.taskIdentifier) complted")
            tasksSemaphore.signal()
            return
        }
        Self.logger.info(
            "TaskControl - taskCompleting",
            additionalData: [
                "clientID": identifier,
                "taskID": String(task.taskIdentifier),
                "traceID": task.trace?.traceId ?? "",
                "requestID": task.requestID ?? "",
                "requestURL": NSString.safeURL(task.requestURL) ?? "",
                "error": task.error?.localizedDescription ?? "",
                "prevState": task.state.description()
            ]
        )
        inner_requestingTasks.removeValue(forKey: task.taskIdentifier)
        task.state = .completed
        tasksSemaphore.signal()
        
        // 执行回调
        task.completionHandler?(
            task.context,
            task.error == nil ? task.responseDataHandler.product() :  nil,
            task.response,
            task.error
        )
        // 埋请求结束点
        monitorRequestEnd(task: task, isCancel: false)
        if task.shouldCleanTempFile, let error = task.responseDataHandler.clean() {
            Self.logger.error("taskID: \(identifier) task clean temp file error:\(error)")
        }    }
    
}
