//
//  FileSystem+TTFileIO.swift
//  TTMicroApp
//
//  Created by Meng on 2021/10/25.
//

import Foundation
import ECOInfra
import LarkCache
//import OPSDK

/// ttfile 文件系统
///
/// - Note: 包括 ttfile://user 与 ttfile://temp
class LcoalTTFileSystemIO: FileSystemIO {
    // FIXME: 兼容逻辑，将来逐步迁移掉 localfFileManager
    private struct FileBase {
        let filePath: String
        let localFileManager: BDPLocalFileManagerProtocol
    }

    private func isSameTTFile(src: FileObject, dest: FileObject) -> Bool {
        return src.url.scheme == BDP_TTFILE_SCHEME
            && dest.url.scheme == BDP_TTFILE_SCHEME
            && (src.url.host == APP_TEMP_DIR_NAME || src.url.host == APP_USER_DIR_NAME)
            && (dest.url.host == APP_TEMP_DIR_NAME || dest.url.host == APP_USER_DIR_NAME)
    }

    private func resolveFileBase(for file: FileObject, context: FileSystem.Context) throws -> FileBase {
        /// resolve storage module
        let module = BDPModuleManager(of: context.uniqueId.appType)
            .resolveModule(with: BDPStorageModuleProtocol.self)
        guard let storageModule = module as? BDPStorageModuleProtocol else {
            throw FileSystemError.biz(.resolveStorageModuleFailed(context))
        }

        /// resolve local file manager
        let localFileManager = storageModule.sharedLocalFileManager()

        // resovle fileInfo
        let fileInfoObjc = localFileManager.universalFileInfo(
            withRelativePath: file.rawValue, uniqueID: context.uniqueId, useFileScheme: false
        )
        guard let info = OPUnsafeObject(fileInfoObjc) else {
            throw FileSystemError.biz(.resolveLocalFileInfoFailed(file, context))
        }

        /// resolve file path
        guard let filePath = info.path else {
            throw FileSystemError.biz(.resolveFilePathFailed(file, context))
        }
        return FileBase(filePath: filePath, localFileManager: localFileManager)
    }

    func canRead(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let base = try resolveFileBase(for: file, context: context)
        return base.localFileManager.hasAccessRights(forPath: base.filePath, on: context.uniqueId)
    }

    func canWrite(_ file: FileObject, isRemove: Bool, context: FileSystem.Context) throws -> Bool {
        /// temp 目录有删除权限
        if isRemove && file.isInTempDir {
            return true
        }

        let base = try resolveFileBase(for: file, context: context)
        return base.localFileManager.hasWriteRights(forPath: base.filePath, on: context.uniqueId)
    }

    /// 判断写入文件大小，这里默认认为 src 与 dest 都是本文件系统。
    func isWriteFileOverSizeLimit(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        assert(isSameTTFile(src: srcFile, dest: destFile), "src(\(srcFile.rawValue)) and dest(\(destFile.rawValue)) must same ttfile scheme and host path")
        let srcBase = try resolveFileBase(for: srcFile, context: context)
        let destBase = try resolveFileBase(for: destFile, context: context)
        let sandboxPathObjc = destBase.localFileManager.appSandboxPath(with: context.uniqueId)
        guard let sandboxPath = OPUnsafeObject(sandboxPathObjc) else {
            throw FileSystemError.biz(.resolveSandboxPathFailed(context))
        }
        let sandboxSize = LSFileSystem.fileSize(path: sandboxPath)
        let fileSize = LSFileSystem.fileSize(path: srcBase.filePath)

        let (totalSize, overflow) = sandboxSize.addingReportingOverflow(fileSize)
        if overflow {
            throw FileSystemError.biz(.calculateSizeOverflow(srcFile, destFile, UInt64(fileSize), context))
        }

        return totalSize > BDP_MAX_MICRO_APP_FILE_SIZE
    }

    func isWriteDataOverSizeLimit(from dataSize: Int64, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        let destBase = try resolveFileBase(for: destFile, context: context)
        let sandboxPathObjc = destBase.localFileManager.appSandboxPath(with: context.uniqueId)
        guard let sandboxPath = OPUnsafeObject(sandboxPathObjc) else {
            throw FileSystemError.biz(.resolveSandboxPathFailed(context))
        }
        
        let sandboxSize = LSFileSystem.fileSize(path: sandboxPath)
        let (totalSize, overflow) = sandboxSize.addingReportingOverflow(dataSize)
        if overflow {
            throw FileSystemError.biz(.calculateSizeOverflow(nil, destFile, UInt64(dataSize), context))
        }
        return totalSize > BDP_MAX_MICRO_APP_FILE_SIZE
    }

    func fileExists(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let fileInternal = try resolveFileBase(for: file, context: context)
        return LSFileSystem.fileExists(filePath: fileInternal.filePath)
    }

    func isDirectory(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let base = try resolveFileBase(for: file, context: context)
        return LSFileSystem.isDirectory(filePath: base.filePath)
    }

    func getDirectoryContents(_ file: FileObject, context: FileSystem.Context) throws -> [String] {
        let base = try resolveFileBase(for: file, context: context)
        do {
            return try LSFileSystem.contentsOfDirectory(dirPath: base.filePath)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func readFileContents(_ file: FileObject, position: Int64, length: Int64, context: FileSystem.Context) throws -> Data {
        // 如果 length 为 0，直接返回空数据
        if length == 0 {
            return Data()
        }
        let base = try resolveFileBase(for: file, context: context)
        let filePath = try FSCrypto.oldApiDecryptFile(with: base.filePath, context: context)
        let pos = UInt64(truncatingIfNeeded: position)
        let len = Int(truncatingIfNeeded: length)

        do {
            let fileHandle = try LSFileSystem.main.fileReadingHandle(filePath: filePath)
            if #available(iOS 13.4, *) {
                try fileHandle.seek(toOffset: pos)
                let readData = try fileHandle.read(upToCount: len)
                try fileHandle.close()
                if let resultData = readData {
                    return resultData
                } else {
                    throw FileSystemError.biz(.fileHandleReadDataFailed(file, context))
                }
            } else {
                fileHandle.seek(toFileOffset: pos)
                let data = fileHandle.readData(ofLength: len)
                fileHandle.closeFile()
                return data
            }
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func readFileContents(_ file: FileObject, context: FileSystem.Context) throws -> Data {
        let base = try resolveFileBase(for: file, context: context)
        let filePath = try FSCrypto.oldApiDecryptFile(with: base.filePath, context: context)
        do {
            return try LSFileSystem.main.readData(from: filePath)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func writeFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.write(data: data, to: base.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }
    
    func appendFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            let fileHandle = try LSFileSystem.main.fileWritingHandleV2(filePath: base.filePath, append: true, useEncrypt: encryptEnable)
            try _ = fileHandle.seekToEnd()
            try fileHandle.write(contentsOf: data)
            try fileHandle.close()
        } catch {
            throw FileSystemError.system(error)
        }
    }
    
    func getFileInfo(_ file: FileObject, autoDecrypt: Bool, context: FileSystem.Context) throws -> [FileAttributeKey : Any] {
        if FileSystemUtils.getFileSizeDisable() {
            return try getFileInfoOld(file, autoDecrypt: autoDecrypt, context: context)
        }
        context.trace.info("getFileInfo autoDecrypt:\(autoDecrypt)")
        let base = try resolveFileBase(for: file, context: context)
        do {
            var localAttributes =  try LSFileSystem.attributesOfItem(atPath: base.filePath)
            if !autoDecrypt {
                return localAttributes
            }
            //获取解密后的size
            let fileSize = FSCrypto.fileSize(atPath: base.filePath)
            localAttributes[FileAttributeKey.size] = fileSize
            return localAttributes
        } catch {
            throw FileSystemError.system(error)
        }
    }
    
    func getFileInfoOld(_ file: FileObject, autoDecrypt: Bool, context: FileSystem.Context) throws -> [FileAttributeKey : Any] {
        context.trace.info("getFileInfoOld autoDecrypt:\(autoDecrypt)")
        let base = try resolveFileBase(for: file, context: context)
        do {
            if !autoDecrypt {
                let localAttributes =  try LSFileSystem.attributesOfItem(atPath: base.filePath)
                return localAttributes
            }
            let filePath = try FSCrypto.manualApiDecryptFile(with: base.filePath, context: context)
            //这里先读取加密数据的除size外的key，size解密后获取
            let dAttributes = try LSFileSystem.attributesOfItem(atPath: filePath)
            if base.filePath == filePath {
                return dAttributes
            }else {
                var localAttributes =  try LSFileSystem.attributesOfItem(atPath: base.filePath)
                localAttributes[FileAttributeKey.size] = dAttributes[FileAttributeKey.size]
                return localAttributes
            }
        } catch {
            throw FileSystemError.system(error)
        }
    }

    /// 拷贝文件，这里默认认为 src 与 dest 都是本文件系统。
    func copy(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        assert(isSameTTFile(src: srcFile, dest: destFile))
        let srcBase = try resolveFileBase(for: srcFile, context: context)
        let destBase = try resolveFileBase(for: destFile, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.copyItem(atPath: srcBase.filePath, toPath: destBase.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    /// 移动文件，这里默认认为 src 与 dest 都是本文件系统。
    func move(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        assert(isSameTTFile(src: srcFile, dest: destFile))
        let srcBase = try resolveFileBase(for: srcFile, context: context)
        let destBase = try resolveFileBase(for: destFile, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.moveItem(atPath: srcBase.filePath, toPath: destBase.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func createDirectory(_ file: FileObject, recursive: Bool, attributes: [FileAttributeKey : Any], context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            try LSFileSystem.main.createDirectory(atPath: base.filePath, withIntermediateDirectories: recursive, attributes: attributes)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func remove(_ file: FileObject, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            try LSFileSystem.main.removeItem(atPath: base.filePath)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func getSystemFilePath(_ file: FileObject, context: FileSystem.Context) throws -> String {
        let base = try resolveFileBase(for: file, context: context)
        let filePath = try FSCrypto.manualApiDecryptFile(with: base.filePath, context: context)
        return filePath
    }

    func copySystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.copyItem(atPath: systemFilePath, toPath: base.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func moveSystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.moveItem(atPath: systemFilePath, toPath: base.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }

    func writeSystemData(_ data: Data, to file: FileObject, context: FileSystem.Context) throws {
        let base = try resolveFileBase(for: file, context: context)
        if FileSystemUtils.writeSystemDataCreateEnable(), file.isInTempDir {
            let module = BDPModuleManager(of: context.uniqueId.appType).resolveModule(with: BDPStorageModuleProtocol.self)
            if let storageModule = module as? BDPStorageModuleProtocol,
               let sandbox = storageModule.sandbox(for: context.uniqueId),
                let tmpPath = sandbox.tmpPath() {
                context.trace.info("writeSystemData start create dir")
                if !LSFileSystem.fileExists(filePath: tmpPath) {
                    do {
                        try LSFileSystem.main.createDirectory(atPath: tmpPath, withIntermediateDirectories: true)
                    } catch {
                        context.trace.error("writeSystemData createFolder fail")
                    }
                }
            }
        }
        do {
            let encryptEnable = FSCrypto.encryptEnable()
            try LSFileSystem.main.write(data: data, to: base.filePath, useEncrypt: encryptEnable)
        } catch {
            throw FileSystemError.system(error)
        }
    }
}

