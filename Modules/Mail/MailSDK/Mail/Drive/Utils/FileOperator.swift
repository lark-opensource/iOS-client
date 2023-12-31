//
//  FileOperator.swift
//  DocsSDK
//
//  Created by Duan Ao on 2019/1/9.
//

import Foundation
import LarkStorage

final class FileOperator {

    private(set) var path: IsoPath
    private var mSpace: MSpace = .global
    private var mailBiz: MailBiz = .normal
    private(set) var type: RootPathType.Normal = .document
    private var reportTea: Bool = true
    private(set) var subPath: String = ""

    /// 工厂方法
    init(space: Space, mSpace: MSpace, mailBiz: MailBiz, type: RootPathType.Normal, subPath: String = "", reportTea: Bool = true) {
        self.mSpace = mSpace
        self.mailBiz = mailBiz
        self.type = type
        self.subPath = subPath
        self.reportTea = reportTea
        self.path = FileOperator.contructIsoPath(space, self.mSpace, self.mailBiz, self.type, self.subPath)
    }

    init(space: Space, mSpace: MSpace, type: RootPathType.Normal, subPath: String = "", reportTea: Bool = true) {
        self.mSpace = mSpace
        self.type = type
        self.subPath = subPath
        self.reportTea = reportTea
        self.path = FileOperator.contructIsoPath(space, self.mSpace, self.mailBiz, self.type, self.subPath)
    }

    private static func contructIsoPath(_ space: Space, _ mSpace: MSpace, _ mailBiz: MailBiz, _ type: RootPathType.Normal, _ subPath: String = "") -> IsoPath {
        let domain = Domains.Business.mail.child(mSpace.isolationId).child(mailBiz.isolationId)
        let rootPath = IsoPath.in(space: space, domain: domain).build(type)
        let path = rootPath + subPath
        if !path.exists {
            try? path.createDirectoryIfNeeded()
        }
        return path
    }
}

// MARK: MailSDK 使用
extension FileOperator {

    static func getFileOperator(_ path: String, type: RootPathType.Normal, userID: String?) -> FileOperator {
        var mspace: MSpace
        if let accountID = Store.settingData.getCachedCurrentAccount()?.mailAccountID {
            mspace = MSpace.account(id: accountID)
        } else {
            mailAssertionFailure("[mail_storage] getFileOperator when mailAccountID is nil, please check")
            mspace = MSpace.global
        }
        var space: Space
        if let userID = userID {
            space = .user(id: userID)
        } else {
            space = .global
        }
        return FileOperator.init(space: space, mSpace: mspace, type: type, subPath: path)
    }

    static func getAttachmentLibraryDir(userID: String?) -> FileOperator {
        return FileOperator.getFileOperator("MailSDK/Attachment", type: .library, userID: userID)
    }

    static func getAttachmentCacheDir(userID: String?) -> FileOperator {
        return FileOperator.getFileOperator("attachment", type: .cache, userID: userID)
    }

    static func getAttachmentCacheDirURL(_ appendString: String = "", userID: String?) -> URL {
        return (FileOperator.getAttachmentCacheDir(userID: userID).path + appendString).url
    }

    static func getReadMailIamgeCacheDir(userID: String?) -> FileOperator {
        return FileOperator.getFileOperator("readmail/image", type: .cache, userID: userID)
    }

    static func getReadMailIamgeCacheDirURL(userID: String?) -> URL {
        return FileOperator.getReadMailIamgeCacheDir(userID: userID).path.url
    }

    static func makeImageUploadingPath(with uuid: String, userID: String?, isGif: Bool = false) -> IsoPath {
        let uploadingPath = "attachment_upload_caches/uploading"
        let type = isGif ? "gif" : "jpeg"
        return FileOperator.getAttachmentLibraryDir(userID: userID).path + uploadingPath + "\(uuid).\(type)"
    }
}

// MARK: - Create

extension FileOperator {
    class func createUploadDirectory(userID: String?) {
        let fileOp = FileOperator.getAttachmentLibraryDir(userID: userID)
        let path = fileOp.path + "attachment_upload_caches/uploading"
        try? path.createDirectoryIfNeeded()
    }

    @discardableResult
    class func createFile(at path: IsoPath, contents: Data? = nil, overwrite: Bool = true, attributes: [FileAttributeKey: Any]? = nil, userID: String?) -> Bool {
        if !path.deletingLastPathComponent.exists {
            createUploadDirectory(userID: userID)
        }
        if !overwrite && path.exists {
            return true
        }
        do {
            try path.createFile(with: contents, attributes: attributes)
            return true
        } catch {
            MailLogger.error("Failed to create file: \(error)")
            return false
        }
    }

    @discardableResult
    class func copyItem(at sourcePath: AbsPath, to targetPath: IsoPath, overwrite: Bool = true) -> Bool {
        guard sourcePath.exists  else {
            assertionFailure("Source path is not exist.")
            return false
        }

        do {
            try targetPath.createDirectoryIfNeeded(withIntermediateDirectories: true)
            if overwrite, targetPath.exists {
                try targetPath.removeItem()
            }
            try targetPath.copyItem(from: sourcePath)
            return true
        } catch {
            MailLogger.log(level: .debug, message: error.localizedDescription)
            return false
        }
    }
}

// MARK: - Check

extension FileOperator {

    class func isExist(at path: String) -> Bool {
        return !path.isEmpty && AbsPath(path).exists
    }

    class func directory(at path: String) -> String {
        return (path as NSString).deletingLastPathComponent
    }
}
