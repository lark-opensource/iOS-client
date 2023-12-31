//
//  OpenPluginDriveCloudAPIContainer.swift
//  OPPlugin
//
//  Created by 刘焱龙 on 2022/12/28.
//

import Foundation
import ThreadSafeDataStructure
import LarkOpenAPIModel

struct DriveOperation {
    let taskID: String

    var key: String?

    var shouldCancel: Bool = false
    var abortCallback: ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)?

    init(taskID: String) {
        self.taskID = taskID
    }
}

class OpenPluginDriveCloudAPIContainer {
    private var operations: [String: DriveOperation] {
        get { _operations.getImmutableCopy() }
        set { _operations.replaceInnerData(by: newValue) }
    }
    private var _operations: SafeDictionary<String, DriveOperation> = [:] + .semaphore


    func add(operation: DriveOperation) {
        operations[operation.taskID] = operation
    }

    func hasOperation(taskID: String) -> Bool {
        return operations[taskID] != nil
    }

    func update(key: String, forTaskID: String) {
        operations[forTaskID]?.key = key
    }

    func key(_ taskID: String) -> String? {
        return operations[taskID]?.key
    }

    func abort(_ taskID: String, callback: @escaping (OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void) {
        operations[taskID]?.shouldCancel = true
        operations[taskID]?.abortCallback = callback
    }

    func shouldAbort(_ taskID: String) -> Bool {
        guard let op = operations[taskID] else { return false }
        return op.shouldCancel
    }

    func abortCallback(_ taskID: String) -> ((OpenAPIBaseResponse<OpenAPIBaseResult>) -> Void)? {
        return operations[taskID]?.abortCallback
    }

    func remove(_ taskID: String) {
        removeAbortTask(taskID)
        operations.removeValue(forKey: taskID)
    }

    func removeAbortTask(_ taskID: String) {
        operations[taskID]?.shouldCancel = false
        operations[taskID]?.abortCallback = nil
    }

    func removeAll() {
        operations.removeAll()
    }
}
