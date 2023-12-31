//
//  SKFilePath+Ext.swift
//  SKCommon
//
//  Created by huangzhikai on 2022/11/23.
//

import SKFoundation
import CommonCrypto
import LarkDocsIcon

// 迁移 FileOperator+Ext 文件下的目录声明
extension SKFilePath {

    // workspace 跨业务 library 目录
    public static var workspaceLibraryDir: SKFilePath {
        //let path = (libraryDir ?? homeDir).appendingPathComponent("DocsSDK/workspace")
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("workspace")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var driveLibraryDir: SKFilePath {
        //let path = (libraryDir ?? homeDir).appendingPathComponent("DocsSDK/drive")
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("drive")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var spaceLibraryDir: SKFilePath {
//        let path = (libraryDir ?? homeDir).appendingPathComponent("DocsSDK/space")
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("space")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var spaceCacheDir: SKFilePath {
//        let path = (cachesDir ?? homeDir).appendingPathComponent("DocsSDK/space")
        let path = SKFilePath.globalSandboxWithCache.appendingRelativePath("space")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var driveCacheDir: SKFilePath {
//        let path = (cachesDir ?? homeDir).appendingPathComponent("drive")
        let path: SKFilePath = SKFilePath.globalSandboxWithCache.appendingRelativePath("drive")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var driveVideoCacheDir: SKFilePath {
//        let path = (cachesDir ?? homeDir).appendingPathComponent("drive/video")
        let path = SKFilePath.globalSandboxWithCache.appendingRelativePath("drive/video")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var docsImageCacheDir: SKFilePath {
//        let path = (libraryDir ?? homeDir).appendingPathComponent("DocsSDK/docs/image")
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/image")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var docsUploadCacheDir: SKFilePath {
//        let path = (libraryDir ?? homeDir).appendingPathComponent("DocsSDK/docs/upload")
        let path = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("docs/upload")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var currentUserIdStr: String {
        return User.current.info?.userID ?? "unknown"
    }

//    public static let docsSDKDir = FileOperator.getSubDirFromLibraryDir("DocsSDK")

//    public static let legacyCacheDir = FileOperator.getSubDirFromLibraryDir("DocsSDK").appendingPathComponent("NewCache")

    public static let legacyCacheDir = SKFilePath.globalSandboxWithLibrary.appendingRelativePath("NewCache")

    public static var newCacheDir: SKFilePath {
        //DocsSDK/\(currentUserIdStr)/NewCache
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var clientVarCacheDir: SKFilePath {
//        return FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/NewCache/ClientVars")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache/ClientVars")
        path.createDirectoryIfNeeded()
        return path

    }

    public static var microInsertImageDir: SKFilePath {
//        return FileOperator.getSubDirFromTmpDir("DocsSDK/\(currentUserIdStr)/microInsertPicture")
        let path = SKFilePath.userSandboxWithTemporary(currentUserIdStr).appendingRelativePath("microInsertPicture")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var metaSqlitePath: SKFilePath {
//        let root = FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/NewCache/ClientVars")
//        return root.appendingPathComponent("meta.sqlite")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache/ClientVars")
        path.createDirectoryIfNeeded()
        return path.appendingRelativePath("meta.sqlite")
    }

    public static var metaSqlCipherPath: SKFilePath {
//        let root = FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/NewCache/ClientVars")
//        return root.appendingPathComponent("metaCipher.sqlite")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache/ClientVars")
        path.createDirectoryIfNeeded()
        return path.appendingRelativePath("metaCipher.sqlite")

    }

    public static var pictureCacheRootDir: SKFilePath {
//        return FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/NewCache/Pictures")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache/Pictures")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var syncPictureCacheRootDir: SKFilePath {
//        return FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/NewCache/syncPictures")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("NewCache/syncPictures")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var bitableCacheDir: SKFilePath {
//        return FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/BitableCache/Anchor")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("BitableCache/Anchor")
        path.createDirectoryIfNeeded()
        return path
    }

    // bitable 附件上传缓存
    public static var bitableUploadAttachCacheDir: SKFilePath {
//        let root = FileOperator.getSubDirFromLibraryDir("DocsSDK/\(currentUserIdStr)/BitableCache/uploadAttachInfo")
//        return root.appendingPathComponent("attachInfo.sqlite")
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr).appendingRelativePath("BitableCache/uploadAttachInfo")
        path.createDirectoryIfNeeded()
        return path.appendingRelativePath("attachInfo.sqlite")
    }

    public static var wikiUserDir: SKFilePath {
//        return getSubDirFromLibraryDir("DocsSDK/wiki/").appendingPathComponent("\(User.current.info?.userID ?? "default_user")_\(User.current.info?.tenantID ?? "default_tenant")")

        let path = SKFilePath.globalSandboxWithLibrary
            .appendingRelativePath("wiki/\(User.current.info?.userID ?? "default_user")_\(User.current.info?.tenantID ?? "default_tenant")")
        path.createDirectoryIfNeeded()
        return path
    }

    public static var preloadPermissionCachePath: SKFilePath {
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr)
            .appendingRelativePath("NewCache")
            .appendingRelativePath("preloadDocs")
        path.createDirectoryIfNeeded()
        return path.appendingRelativePath("preloadPermission")
    }
    
    public static var preloadTaskSavePath: SKFilePath {
        let path = SKFilePath.userSandboxWithLibrary(currentUserIdStr)
            .appendingRelativePath("NewCache")
            .appendingRelativePath("preloadDocs")
        path.createDirectoryIfNeeded()
        return path.appendingRelativePath("preloadTask")
    }
    
    // MARK: - migrated by ZYC
    public static func getFileNamePrefix(name: String) -> String {
        if name.last == "." {
            return name
        }
        guard let fileExtension = getFileExtension(from: name) else {
            return name
        }
        if let index = name.range(of: ".\(fileExtension)", options: .backwards)?.lowerBound {
            let fileName = String(name[..<index])
            return fileName
        } else {
            return name
        }
    }

    public static func getFileExtension(from path: String, needCheckAdditionExtension: Bool = true, needTrim: Bool = true) -> String? {
        //下沉到DocsIconInfo里面
        return DocsIconInfo.getFileExtension(from: path, needCheckAdditionExtension: needCheckAdditionExtension, needTrim: needTrim)
    }
    
    public static func createFileName(name: String, ext: String) -> String {
        if ext.isEmpty {
            return name
        } else {
            return "\(name).\(ext)"
        }
    }
    
    /// 计算文件的md5值
    ///
    /// - Parameter url: 文件的url linke
    /// - Returns: md5 16进制串
    public static func md5(at path: URL) -> String? {
        let bufferSize = 1024 * 1024
        do {
            let file = try FileHandle(forReadingFrom: path)     // lint:disable:this lark_storage_check
            defer {
                file.closeFile()
            }
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes({ (ptr: UnsafeRawBufferPointer) in
                        _ = CC_MD5_Update(&context, ptr.baseAddress, numericCast(data.count))
                    })
                    return true
                } else {
                    return false
                }
            }) { }
            var digest = Data(count: Int(CC_MD5_DIGEST_LENGTH))
            digest.withUnsafeMutableBytes({ (ptr: UnsafeMutableRawBufferPointer) in
                let int8Ptr = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
                _ = CC_MD5_Final(int8Ptr, &context)
            })
            return digest.map { String(format: "%02hhx", $0) }.joined()
        } catch {
            return nil
        }
    }
}

private extension SKFilePath {
   static var homeDir: String {
       return NSHomeDirectory()     // lint:disable:this lark_storage_migrate_check
   }
   static var cachesDir: String? {
       return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first    // lint:disable:this lark_storage_migrate_check
   }
}

