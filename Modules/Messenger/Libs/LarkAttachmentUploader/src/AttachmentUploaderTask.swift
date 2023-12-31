//
//  AttachmentUploaderTask.swift
//  Lark
//
//  Created by lichen on 2017/8/27.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkStorage

public typealias AttachmentUploadTaskCallback = (_ upolder: AttachmentUploader, _ key: String, _ url: String?, _ data: Data?, _ error: Error?) -> Void
public typealias AttachmentUploadCallback = (_ key: String, _ url: String?, _ data: Data?, _ error: Error?) -> Void
public typealias AttachmentUploadHandler = (_ uploader: AttachmentUploader, _ key: String, _ attachment: Attachment,
    _ callback: @escaping AttachmentUploadCallback, _ cancelBlock: (@escaping () -> Void) -> Void) -> Void

public extension AttachmentUploadTask {
    enum CacheArchiverKey: String {
        case key, type, info
    }

    typealias Resource = AttachmentUploadTask.Cache

    final class Cache {
        public let key: String
        public let type: Attachment.FileType
        public let info: [String: String]

        public init(key: String, type: Attachment.FileType, info: [String: String]) {
            self.key = key
            self.type = type
            self.info = info
        }

        public func jsonString() -> String {
            var dataDic: [String: Any] = [:]
            dataDic[CacheArchiverKey.key.rawValue] = self.key
            dataDic[CacheArchiverKey.type.rawValue] = self.type.rawValue
            dataDic[CacheArchiverKey.info.rawValue] = self.info
            guard let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []) else {
                return ""
            }
            return String(data: data, encoding: .utf8) ?? ""
        }

        public static func generate(jsonString: String) -> Resource? {
            guard let data = jsonString.data(using: .utf8),
                let dataDic = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any],
                let key = dataDic[CacheArchiverKey.key.rawValue] as? String,
                let typeStr = dataDic[CacheArchiverKey.type.rawValue] as? String,
                let type = Attachment.FileType(rawValue: typeStr),
                let info = dataDic[CacheArchiverKey.info.rawValue] as? [String: String] else {
                    return nil
            }
            return AttachmentUploadTask.Cache(key: key, type: type, info: info)
        }
    }
}

public final class AttachmentUploadTask: Equatable {
    public var attachment: Attachment
    public var cancelBlock: (() -> Void)?

    public init(
        attachment: Attachment,
        cancelBlock: (() -> Void)? = nil
    ) {
        self.attachment = attachment
        self.cancelBlock = cancelBlock
    }

    public init(cache: AttachmentUploadTask.Cache,
         cancelBlock: (() -> Void)? = nil) {
        self.attachment = Attachment(key: cache.key, type: cache.type, info: cache.info)
        self.cancelBlock = cancelBlock
    }

    public var key: String {
        return self.attachment.key
    }

    public static func == (_ lhs: AttachmentUploadTask, rhs: AttachmentUploadTask) -> Bool {
        return lhs.key == rhs.key
    }

    public func cache() -> AttachmentUploadTask.Cache {
        return AttachmentUploadTask.Cache(key: self.key, type: attachment.type, info: attachment.info)
    }

    public func isInvalid(in root: IsoPath, domain: String) -> Bool {
        return !AttachmentDataStorage.draftExists(root: root, domain: domain, attachmentName: self.key)
    }
}

extension Array where Element == AttachmentUploadTask {
    public mutating func removeIfNeeded(key: String, cancel: Bool = false) {
        if let index = self.firstIndex(where: { (task) -> Bool in
            return task.key == key
        }) {
            if cancel {
                self[index].cancelBlock?()
            }
            self.remove(at: index)
        }
    }

    public mutating func removeAllTasks(excludeKeys: [String] = [], cancel: Bool = false) {
        if cancel {
            self.forEach { (task) in
                if !excludeKeys.contains(task.key) {
                    task.cancelBlock?()
                }
            }
        }

        if excludeKeys.isEmpty {
            self.removeAll()
        } else {
            var excludeTasks: [AttachmentUploadTask] = []
            excludeKeys.forEach({ (key) in
                if let index = self.firstIndex(where: { (task) -> Bool in
                    return key == task.key
                }) {
                    excludeTasks.append(self[index])
                }
            })
            self.removeAll()
            self += excludeTasks
        }
    }

    public func task(key: String) -> AttachmentUploadTask? {
        if let index = self.firstIndex(where: { (task) -> Bool in
            return task.key == key
        }) {
            return self[index]
        }
        return nil
    }
}
