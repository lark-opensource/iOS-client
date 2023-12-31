//
//  AttachmentUploader.swift
//  Lark
//
//  Created by lichen on 2017/8/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import RxSwift
import RxCocoa
import LKCommonsLogging
import ThreadSafeDataStructure
import LarkStorage

public final class AttachmentUploader {

    public let disposeBag: DisposeBag = DisposeBag()

    public let cache: AttachmentDataStorage

    static let logger = Logger.log(AttachmentUploader.self, category: "Module.Attachment")

    public var name: String
    public let uploadImmediately: Bool

    public var identifer: String = "\(Int(Date().timeIntervalSince1970 * 10_000))\(UInt32.random(in: 0..<256))"
    public var count: Int = 0
    fileprivate func newAttachmentKey() -> String {
        count += 1
        return "\(self.identifer)\(self.count)"
    }

    let operationQueue: OperationQueue

    public init(name: String, queue: OperationQueue = OperationQueue(), uploadImmediately: Bool = true, cache: AttachmentDataStorage) {
        self.name = name
        self.operationQueue = queue
        self.uploadImmediately = uploadImmediately
        self.cache = cache
    }

    deinit {
        AttachmentUploader.logger.debug("attachment uploader : \(self.identifer) deinit")
    }

    public var allTasks: [AttachmentUploadTask] = []
    public var preparedTasks: [AttachmentUploadTask] = []
    public var uploadingTasks: [AttachmentUploadTask] = []
    public var successedTasks: [AttachmentUploadTask] = []
    public var failedTasks: [AttachmentUploadTask] = []
    public var results: [String: String] = [:]

    public func task(key: String) -> AttachmentUploadTask? {
        for task in self.allTasks where task.key == key {
            return task
        }
        return nil
    }

    // Attachemnt Builder
    public func attachemnt(data: Data, type: Attachment.FileType, info: [String: String] = [:]) -> Attachment {
        let key = self.newAttachmentKey()
        self.cache.syncSaveDraftAttachment(domain: self.name, attachmentName: key, attachmentData: data)
        let attachment = Attachment(key: key, type: type, info: info)
        return attachment
    }

    public func path(attachment: Attachment) -> IsoPath {
        return AttachmentDataStorage.draftPath(root: self.cache.root, domain: self.name, attachmentName: attachment.key)
    }

    /// 任务结束callback 保证在主线程回调
    public var defaultCallback: (AttachmentUploadTaskCallback)?
    /// 全部任务结束callback 保证在主线程回调
    public var allFinishedCallback: ((AttachmentUploader) -> Void)? {
        didSet {
            if self.allFinished() {
                self.allFinishedCallback?(self)
            }
        }
    }

    // handler
    fileprivate var handlers: SafeDictionary<Attachment.FileType, AttachmentUploadHandler> = [:] + .readWriteLock
    public func register(type: Attachment.FileType, handler: (AttachmentUploadHandler)?) {
        self.handlers[type] = handler
    }

    /// 当业务方完成上传后需要再调用这个方法从数组中移除
    /// key：attachment的key，result：上传完成后返回的url，data：处理完成的图片，error：上传失败返回的错误
    /// 需要配合customUpload(attachment: Attachment)方法使用
    public func finishCustomUpload(key: String, result: String?, data: Data?, error: Error?) {
        DispatchQueue.main.async {
            synchronized(lock: self) { [weak self] in
                guard let self = self, let task = self.uploadingTasks.first(where: { $0.attachment.key == key }) else {
                    return
                }
                self.uploadingTasks.removeIfNeeded(key: key)
                if error != nil || result == nil {
                    self.failedTasks.append(task)
                } else if let result = result {
                    self.results[key] = result
                    self.successedTasks.append(task)
                }
                self.defaultCallback?(self, key, result, data, error)
                self.checkFinish()
            }
        }
    }

    /// 自定义上传
    /// 如果业务方需要自己上传富文本中的图片就调用此方法
    /// 改方法会将attachment生成task并存储起来
    public func customUpload(attachment: Attachment) {
        synchronized(lock: self) { [weak self] in
            guard let self = self else { return }
            let task = AttachmentUploadTask(attachment: attachment, cancelBlock: nil)
            self.allTasks.append(task)
            self.uploadingTasks.append(task)
        }
    }

    public func upload(attachment: Attachment) -> Bool {
        if self.handlers[attachment.type] == nil {
            AttachmentUploader.logger.error(
                "没有找到对应类型附件的 upload handler",
                additionalData: ["type": "\(attachment.type.rawValue)"]
            )
            return false
        }

        let task = AttachmentUploadTask(attachment: attachment, cancelBlock: nil)
        self.upload(task: task)
        return true
    }

    public func reuploadFailedTask(key: String) {
        if let index = self.failedTasks.firstIndex(where: { (task) -> Bool in
            return task.key == key
        }) {
            let task = self.failedTasks[index]
            self.failedTasks.removeIfNeeded(key: key)
            self.upload(task: task, reupload: true)
        }
    }

    public func reuploadAllFailedTasks() {
        let allFailedTasks = self.failedTasks
        self.failedTasks.removeAllTasks()
        allFailedTasks.forEach { (task) in
            self.upload(task: task, reupload: true)
        }
    }

    public func startUpload() {
        self.uploadAllPreparedTasks()
        self.reuploadAllFailedTasks()
    }

    fileprivate func upload(task: AttachmentUploadTask, reupload: Bool = false) {
        synchronized(lock: self) {
            if !reupload {
                self.allTasks.append(task)
            }
            self.preparedTasks.append(task)
        }

        if self.uploadImmediately {
            self.uploadAllPreparedTasks()
        }
    }

    fileprivate func uploadAllPreparedTasks() {
        synchronized(lock: self) {
            let callback = self.defaultCallback
            for task in self.preparedTasks {
                // 这里是向 OperationQueue 中添加 Operation, 所以不存在死锁的问题
                self.operationQueue.add { [weak self] (completionHandler) in
                    guard let strongSelf = self else {
                        return
                    }

                    let cancelBlock: (@escaping () -> Void) -> Void = { [weak task] (cancel: @escaping () -> Void) in
                        task?.cancelBlock = {
                            cancel()
                            completionHandler()
                        }
                    }

                    let uploadAttachment = { (uploader: AttachmentUploader, key: String, attachment: Attachment) in
                        self?.handlers[attachment.type]?(uploader, key, attachment, { [weak self] (key, url, data, error) in
                            // 保证在主线程回调
                            DispatchQueue.main.async {
                                defer {
                                    completionHandler()
                                }
                                guard let `self` = self,
                                    let task = self.allTasks.task(key: key) else {
                                        return
                                }

                                synchronized(lock: self) {
                                    self.uploadingTasks.removeIfNeeded(key: key)
                                    if error != nil || url == nil {
                                        self.failedTasks.append(task)
                                    } else if let url = url {
                                        self.results[key] = url
                                        self.successedTasks.append(task)
                                    }
                                    callback?(self, key, url, data, error)
                                    self.checkFinish()
                                }
                            }
                        }, cancelBlock)
                    }

                    uploadAttachment(strongSelf, task.key, task.attachment)
                }
                self.uploadingTasks.append(task)
            }
            self.preparedTasks.removeAll()
        }
    }

    fileprivate func checkFinish() {
        if self.allFinished() {
            self.allFinishedCallback?(self)
        }
    }

    public func clearAllTask(excludeKeys: [String] = []) {
        synchronized(lock: self) {
            self.allTasks.removeAllTasks(excludeKeys: excludeKeys)
            self.uploadingTasks.removeAllTasks(excludeKeys: excludeKeys, cancel: true)
            self.preparedTasks.removeAllTasks(excludeKeys: excludeKeys)
            self.successedTasks.removeAllTasks(excludeKeys: excludeKeys)
            self.failedTasks.removeAllTasks(excludeKeys: excludeKeys)
            self.results = self.results.filter({ (key, _) -> Bool in
                return excludeKeys.contains(key)
            })
        }
    }

    public func clearAllNoSuccessedTask() {
        synchronized(lock: self) {
            self.allTasks.removeAllTasks(excludeKeys: self.results.map({ (key, _) -> String in
                return key
            }), cancel: true)
            self.uploadingTasks.removeAllTasks(cancel: true)
            self.preparedTasks.removeAllTasks()
            self.failedTasks.removeAllTasks()
        }
    }

    public func clearTask(key: String) {
        synchronized(lock: self) {
            self.allTasks.removeIfNeeded(key: key)
            self.uploadingTasks.removeIfNeeded(key: key, cancel: true)
            self.preparedTasks.removeIfNeeded(key: key)
            self.successedTasks.removeIfNeeded(key: key)
            self.failedTasks.removeIfNeeded(key: key)
            self.results[key] = nil
        }
    }

    public func append(_ attachment: Attachment, result: String) {
        let task = AttachmentUploadTask(attachment: attachment, cancelBlock: nil)
        synchronized(lock: self) {
            self.allTasks.append(task)
            self.successedTasks.append(task)
            self.results[attachment.key] = result
        }
    }

    public func cleanPostDraftAttachment(excludeKeys: [String] = [], completion: (() -> Void)? = nil) {
        self.cache.syncCleanDraftAttachment(domain: self.name, excludeKeys: excludeKeys)
        completion?()
    }

    public func getDraftImageAttachment(attachmentName: String, callback: @escaping (UIImage?) -> Void) {
        self.cache.getDraftImageAttachment(domain: self.name, attachmentName: attachmentName, callback: callback)
    }

    public func getDraftAttachment(attachmentName: String, callback: @escaping (Data?) -> Void) {
        self.cache.getDraftAttachment(domain: self.name, attachmentName: attachmentName, callback: callback)
    }
}

extension AttachmentUploader {
    public func allFinished() -> Bool {
        return self.uploadingTasks.isEmpty && self.preparedTasks.isEmpty
    }

    public func uploadSuccessed(key: String) -> Bool {
        return self.successedTasks.contains(where: { (task) -> Bool in
            return task.key == key
        })
    }

    public func uploadFailed(key: String) -> Bool {
        return self.failedTasks.contains(where: { (task) -> Bool in
            return task.key == key
        })
    }

    public func isUploading(key: String) -> Bool {
        return self.uploadingTasks.contains(where: { (task) -> Bool in
            return task.key == key
        })
    }
}
func synchronized(lock: AnyObject, closure: () -> Void) {
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}
