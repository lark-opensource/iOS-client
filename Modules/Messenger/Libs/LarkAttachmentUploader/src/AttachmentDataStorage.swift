//
//  AttachmentDataStorage.swift
//  Lark
//
//  Created by lichen on 2017/8/29.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import ByteWebImage
import LKCommonsLogging
import LarkStorage

public final class AttachmentDataStorage {
    static let logger = Logger.log(AttachmentDataStorage.self, category: "AttachmentDataStorage")

    fileprivate let ioQueue: DispatchQueue

    public var root: IsoPath
    public init(root: IsoPath) {
        let ioQueueName = "com.lark.draft.attachment.queue"
        ioQueue = DispatchQueue(label: ioQueueName)
        self.root = root
    }

    public func cleanDraftAttachment(domain: String, attachmentName: String? = nil,
                                     excludeKeys: [String] = [], completion: (() -> Void)? = nil) {
        self.ioQueue.async {
            self.syncCleanDraftAttachment(domain: domain, attachmentName: attachmentName, excludeKeys: excludeKeys)
            completion?()
        }
    }

    public func syncCleanDraftAttachment(domain: String, attachmentName: String? = nil, excludeKeys: [String] = []) {
        AttachmentDataStorage.checkSavePath(root: self.root, domain: domain)
        var domainDraftPath = AttachmentDataStorage.draftPath(root: self.root, domain: domain)
        if let attachmentName = attachmentName {
            domainDraftPath = AttachmentDataStorage.draftPath(root: self.root, domain: domain, attachmentName: attachmentName)
        }
        do {
            let path = domainDraftPath
            if path.exists {
                if !path.isDirectory || excludeKeys.isEmpty {
                    try path.removeItem()
                } else {
                    let newExcludeKeys = excludeKeys.map { (path + $0).absoluteString }
                    try path.eachChildren { (content) in
                        if !newExcludeKeys.contains(content.absoluteString) {
                            try content.removeItem()
                        }
                    }
                }
            }
        } catch {
            AttachmentDataStorage.logger.error(
                "清除 domain 缓存失败",
                additionalData: ["root": root.absoluteString, "domain": domain],
                error: error
            )
        }
    }

    public func saveDraftAttachment(domain: String, attachmentName: String, attachmentData: Data, completion: (() -> Void)? = nil) {
        self.ioQueue.async {
            self.syncSaveDraftAttachment(domain: domain, attachmentName: attachmentName, attachmentData: attachmentData)
            completion?()
        }
    }

    public func saveDraftAttachment(domain: String, attachmentName: String, attachmentImage: UIImage, completion: (() -> Void)? = nil) {
        self.ioQueue.async {
            self.syncSaveDraftAttachment(domain: domain, attachmentName: attachmentName, attachmentImage: attachmentImage)
            completion?()
        }
    }

    public func syncSaveDraftAttachment(domain: String, attachmentName: String, attachmentImage: UIImage) {
        if let imageData = attachmentImage.pngData() {
            self.syncSaveDraftAttachment(domain: domain, attachmentName: attachmentName, attachmentData: imageData)
        } else {
            AttachmentDataStorage.logger.error("无法转化 image to Data")
        }
    }

    public func syncSaveDraftAttachment(domain: String, attachmentName: String, attachmentData: Data) {
        AttachmentDataStorage.checkSavePath(root: self.root, domain: domain)
        let attachmentPath = AttachmentDataStorage.draftPath(root: self.root, domain: domain, attachmentName: attachmentName)
        do {
            try attachmentPath.createFile(with: attachmentData)
        } catch {
            AttachmentDataStorage.logger.error("保存草稿附件失败", additionalData: ["path": attachmentPath.absoluteString])
        }
    }

    public func getDraftAttachment(domain: String, attachmentName: String, callback: @escaping (Data?) -> Void) {
        self.ioQueue.async {
            let data = self.syncGetDraftAttachment(domain: domain, attachmentName: attachmentName)
            DispatchQueue.main.async {
                callback(data)
            }
        }
    }

    public func syncGetDraftAttachment(domain: String, attachmentName: String) -> Data? {
        let draftAttachmentPath = AttachmentDataStorage.draftPath(root: self.root, domain: domain, attachmentName: attachmentName)
        return try? Data.read(from: draftAttachmentPath)
    }

    public func getDraftImageAttachment(domain: String, attachmentName: String, callback: @escaping (UIImage?) -> Void) {
        self.ioQueue.async {
            let image = self.syncGetDraftImageAttachment(domain: domain, attachmentName: attachmentName)
            DispatchQueue.main.async {
                callback(image)
            }
        }
    }

    public func syncGetDraftImageAttachment(domain: String, attachmentName: String) -> UIImage? {
        let data = self.syncGetDraftAttachment(domain: domain, attachmentName: attachmentName)
        var image: UIImage?
        if let data = data {
            image = try? ByteImage(data)
        }
        return image
    }
}

// MARK: - Path
extension AttachmentDataStorage {
    public static func draftPath(root: IsoPath, domain: String) -> IsoPath {
        return root.appendingRelativePath(domain)
    }

    public static func moveDraftPath(root: IsoPath, fromDomain: String, toDomain: String) {
        let fromPath = root + fromDomain
        guard fromPath.exists else { return }

        do {
            let toPath = root + toDomain
            try fromPath.moveItem(to: toPath)
        } catch let err {
            AttachmentDataStorage.logger.error("moveDraftPath 移动图片失败: \(err) fromDomain \(fromDomain) toDomain \(toDomain)")
        }
    }

    public static func draftPath(root: IsoPath, domain: String, attachmentName: String) -> IsoPath {
        return self.draftPath(root: root, domain: domain).appendingRelativePath(attachmentName)
    }

    public static func draftExists(root: IsoPath, domain: String, attachmentName: String) -> Bool {
        return AttachmentDataStorage.draftPath(root: root, domain: domain, attachmentName: attachmentName).exists
    }

    fileprivate static func checkSavePath(root: IsoPath, domain: String) {
        do {
            try root.createDirectoryIfNeeded()
            let domainDraftPath = AttachmentDataStorage.draftPath(root: root, domain: domain)
            try domainDraftPath.createDirectoryIfNeeded()
        } catch {
            AttachmentDataStorage.logger.error(
                "初始化草稿 domain 路径失败",
                additionalData: ["root": root.absoluteString, "domain": domain],
                error: error
            )
        }
    }
}
