//
//  AttachmentUploader+Cache.swift
//  LarkUIKit
//
//  Created by lichen on 2018/5/29.
//  Copyright © 2018年 liuwanlin. All rights reserved.
//

import Foundation

extension AttachmentUploader {
    public var draft: AttachmentUploader.Draft {
        get {
            return AttachmentUploader.Draft(uploader: self)
        }
        set {
            self.clearAllTask()
            synchronized(lock: self) {
                self.identifer = newValue.identifer
                self.count = newValue.count
                self.results.removeAll()
                newValue.results.forEach { (key, value) in
                    self.results[key] = value
                }

                let successedCache = newValue.successedTasks
                let failedCache = newValue.failedTasks
                var allTasks: [AttachmentUploadTask] = []
                var preparedTasks: [AttachmentUploadTask] = []
                var successedTasks: [AttachmentUploadTask] = []
                var failedTasks: [AttachmentUploadTask] = []

                newValue.allTasks.forEach({ (cacheString) in
                    if let task = self.uploadTaskFromCache(cacheString: cacheString) {
                        allTasks.append(task)
                        if successedCache.contains(task.key) {
                            successedTasks.append(task)
                        } else if failedCache.contains(task.key) {
                            failedTasks.append(task)
                        } else {
                            preparedTasks.append(task)
                        }
                    } else {
                        AttachmentUploader.logger.warn("attachmnet 附件缓存被清除")
                    }
                })

                self.allTasks = allTasks
                self.preparedTasks = preparedTasks
                self.successedTasks = successedTasks
                self.failedTasks = failedTasks
            }
        }
    }

    private func uploadTaskFromCache(cacheString: String) -> AttachmentUploadTask? {
        guard let cache = AttachmentUploadTask.Cache.generate(jsonString: cacheString) else {
            return nil
        }
        let task = AttachmentUploadTask(cache: cache)
        if task.isInvalid(in: self.cache.root, domain: self.name) {
            return nil
        }
        return task
    }

    public enum DraftArchiverKey: String {
        case identifer, count, allTasks, successedTasks, failedTasks, results
    }

    /**
     NOTE: allTasks 为 task cache 数组，successedTasks/failedTasks/results 为 task key 数组
     */
    public final class Draft {
        public let identifer: String
        public let count: Int
        public let allTasks: [String]
        public let successedTasks: [String]
        public var failedTasks: [String]
        public let results: [String: String]

        public init(uploader: AttachmentUploader) {
            self.identifer = uploader.identifer
            self.count = uploader.count
            self.allTasks = uploader.allTasks.map({ (task) -> String in
                return task.cache().jsonString()
            })
            self.successedTasks = uploader.successedTasks.map({ (task) -> String in
                return task.key
            })
            self.failedTasks = uploader.failedTasks.map({ (task) -> String in
                return task.key
            })
            self.results = uploader.results
        }

        public convenience init?(json: String) {
            guard let data = json.data(using: .utf8) else {
                return nil
            }
            self.init(data)
        }

        public init?(_ data: Data) {
            guard let dic = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                let identifer = dic[DraftArchiverKey.identifer.rawValue] as? String,
                let countStr = dic[DraftArchiverKey.count.rawValue] as? String,
                let count = Int(countStr),
                let allTasks = dic[DraftArchiverKey.allTasks.rawValue] as? [String],
                let successedTasks = dic[DraftArchiverKey.successedTasks.rawValue] as? [String],
                let failedTasks = dic[DraftArchiverKey.failedTasks.rawValue] as? [String],
                let results = dic[DraftArchiverKey.results.rawValue] as? [String: String] else {
                    return nil
            }
            self.identifer = identifer
            self.count = count
            self.allTasks = allTasks
            self.successedTasks = successedTasks
            self.failedTasks = failedTasks
            self.results = results
            checkTask()
        }

        public func archiverDic() -> [String: Any] {
            var dic: [String: Any] = [:]
            dic[DraftArchiverKey.identifer.rawValue] = self.identifer
            dic[DraftArchiverKey.count.rawValue] = "\(self.count)"
            dic[DraftArchiverKey.allTasks.rawValue] = self.allTasks
            dic[DraftArchiverKey.successedTasks.rawValue] = self.successedTasks
            dic[DraftArchiverKey.failedTasks.rawValue] = self.failedTasks
            dic[DraftArchiverKey.results.rawValue] = self.results
            return dic
        }

        public func atchiverData() -> Data? {
            return try? JSONSerialization.data(withJSONObject: self.archiverDic(), options: .prettyPrinted)
        }

        public func atchiverString() -> String? {
            if let data = self.atchiverData() {
                return String(data: data, encoding: .utf8)
            }
            return nil
        }

        func checkTask() {
            // 筛选出在allTask中，但没有在result的task
            let noResultTasks = allTasks.filter { results[$0] == nil }
            AttachmentUploader.logger.info("check no result tasks \(noResultTasks.count)")
            // 如果没有则返回
            if noResultTasks.isEmpty { return }
            // 如果有这样的task，去重后，添加进failedTask中
            failedTasks.append(contentsOf: noResultTasks.filter { !failedTasks.contains($0) })
        }
    }
}
