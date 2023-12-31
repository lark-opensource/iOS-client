//
//  LarkPushTokenUploadQueue.swift
//  LarkPushTokenUploader
//
//  Created by aslan on 2023/11/2.
//

import Foundation
import ThreadSafeDataStructure

struct PendingUploadUser {
    let userId: String
    let isForeground: Bool

    init(userId: String, isForeground: Bool) {
        self.userId = userId
        self.isForeground = isForeground
    }
}

struct LarkPushTokenUploadQueue {

    private let queue = OperationQueue()
    private let uploadUserList: SafeArray<PendingUploadUser> = [] + .readWriteLock

    init() {
        queue.isSuspended = true
        queue.name = "upload.pushtoken.queue"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .userInteractive
    }

    func appendTask(with user: PendingUploadUser, task: @escaping (_ pendingUser: PendingUploadUser) -> Void) {
        if !self.isExsit(user: user) {
            self.uploadUserList.append(user)
            self.queue.addOperation {
                task(user)
            }
        }
    }

    func isExsit(user: PendingUploadUser) -> Bool {
        if let _ = uploadUserList.first { (item) -> Bool in
                item.userId == user.userId
        } {
            return true
        }
        return false
    }

    func reset() {
        self.frozen()
        self.uploadUserList.removeAll()
        queue.cancelAllOperations()
    }

    func frozen() {
        queue.isSuspended = true
    }

    func resume() {
        queue.isSuspended = false
    }

    func isQueueSuspended() -> Bool {
        queue.isSuspended
    }
}
