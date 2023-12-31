//
//  FileSystem+PackageIO.swift
//  TTMicroApp
//
//  Created by Meng on 2021/10/25.
//

import Foundation
import ECOInfra

/// Package 文件系统
class PackageFileSystemIO: FileSystemIO {
    // FIXME: 兼容逻辑，将来逐步迁移掉 localfFileManager，reader，packagePath
    private struct FileBase {
        let filePath: String
        let packagePath: String
        let localFileManager: BDPLocalFileManagerProtocol
        let reader: BDPPkgFileReader
    }

    private func resolveFileBase(_ file: FileObject, context: FileSystem.Context) throws -> FileBase {
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

        /// resolve package path
        guard let pkgPath = info.pkgPath else {
            throw FileSystemError.biz(.resolvePkgPathFailed(file, context))
        }

        /// resove reader
        guard let reader = BDPCommonManager.shared()?.getCommonWith(context.uniqueId)?.reader else {
            throw FileSystemError.biz(.resolvePkgReaderFailed(context))
        }

        return FileBase(filePath: filePath, packagePath: pkgPath, localFileManager: localFileManager, reader: reader)
    }

    /// 获取包文件路径
    ///
    /// 1. 如果是资源文件(isAuxiliary == true), 则返回包资源缓存真实路径
    /// 2. 如果不是资源文件(isAuxiliary == false), 则返回包路径，同 getPackagePath
    ///
    private func getPackagePathWithAuxiliary(file: FileObject, context: FileSystem.Context) throws -> String {
        let base = try resolveFileBase(file, context: context)
        if context.isAuxiliary {
            do {
                let urlObjc = try base.reader.urlOfData(withFilePath: base.packagePath)
                if let url = OPUnsafeObject(urlObjc) {
                    return url.path
                } else {
                    throw FileSystemError.biz(.resolveAuxiliaryFileFailed(nil, file, context))
                }
            } catch {
                throw FileSystemError.biz(.resolveAuxiliaryFileFailed(error, file, context))
            }
        } else {
            return base.packagePath
        }
    }

    /// 包路径默认可读。
    func canRead(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        return true
    }

    /// 包路径默认不可写。
    func canWrite(_ file: FileObject, isRemove: Bool, context: FileSystem.Context) throws -> Bool {
        return false
    }

    /// 不应该产生此判断，如果走到这里，说明上层判断权限有误。
    func isWriteFileOverSizeLimit(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        assert(false, "try write to package path, isWriteFileOverSizeLimit src: \(srcFile.rawValue), dest: \(destFile.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(destFile, context))
    }

    /// 不应该产生此判断，如果走到这里，说明上层判断权限有误。
    func isWriteDataOverSizeLimit(from dataSize: Int64, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        assert(false, "try write to package path, isWriteDataOverSizeLimit dest: \(destFile.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(destFile, context))
    }

    func fileExists(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let base = try resolveFileBase(file, context: context)
        return base.reader.fileExistsInPkg(atPath: base.packagePath)
    }

    func isDirectory(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let base = try resolveFileBase(file, context: context)
        return (base.packagePath as NSString).pathExtension == "" // TODO: 历史逻辑如此实现，应当改造
    }

    func getDirectoryContents(_ file: FileObject, context: FileSystem.Context) throws -> [String] {
        let base = try resolveFileBase(file, context: context)
        if let contents = base.reader.contentsOfPkgDir(atPath: base.packagePath) {
            return contents
        } else {
            throw FileSystemError.biz(.listPackageContentsFailed(file, context))
        }
    }

    func readFileContents(_ file: FileObject, position: Int64, length: Int64, context: FileSystem.Context) throws -> Data {
        // 如果 length 为 0，直接返回空数据
        if length == 0 {
            return Data()
        }

        let base = try resolveFileBase(file, context: context)
        let realPackagePath = try getPackagePathWithAuxiliary(file: file, context: context)
        if context.isAuxiliary {
            let pos = UInt64(truncatingIfNeeded: position)
            let len = Int(truncatingIfNeeded: length)

            let fileHandle = try LSFileSystem.main.fileReadingHandle(filePath: realPackagePath)
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
        } else {
            do {
                /// 包文件数据，直接读取出来做切割了
                if let data = try OPUnsafeObject(base.reader.readData(withFilePath: realPackagePath)) {
                    let start = Data.Index(truncatingIfNeeded: position)
                    let end = Data.Index(truncatingIfNeeded: length)
                    return data.subdata(in: start..<end)
                } else {
                    throw FileSystemError.biz(.readPkgDataFailed(realPackagePath, nil, context))
                }
            } catch {
                throw FileSystemError.biz(.readPkgDataFailed(realPackagePath, error, context))
            }
        }
    }

    func readFileContents(_ file: FileObject, context: FileSystem.Context) throws -> Data {
        let base = try resolveFileBase(file, context: context)
        let realPackagePath = try getPackagePathWithAuxiliary(file: file, context: context)
        if context.isAuxiliary {
            do {
                return try LSFileSystem.main.readData(from: realPackagePath)
            } catch {
                throw FileSystemError.system(error)
            }
        } else {
            do {
                if let data = try OPUnsafeObject(base.reader.readData(withFilePath: realPackagePath)) {
                    return data
                } else {
                    throw FileSystemError.biz(.readPkgDataFailed(realPackagePath, nil, context))
                }
            } catch {
                throw FileSystemError.biz(.readPkgDataFailed(realPackagePath, error, context))
            }
        }
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func writeFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }
    
    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func appendFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }
    
    func getFileInfo(_ file: FileObject, autoDecrypt: Bool, context: FileSystem.Context) throws -> [FileAttributeKey : Any] {
        let base = try resolveFileBase(file, context: context)
        var attributes: [FileAttributeKey: Any] = [:]
        /* FIXME: 先注释掉这段，因为包路径是相对路径，这段代码稳定抛 system error, 后续完成包路径文件操作完整性改造后再考虑开放。
        do {
            // FIXME: no package path attributes to get
            attributes = try FileManager.default.attributesOfItem(atPath: base.packagePath)
        } catch {
            throw FileSystemError.system(error)
        }
         */

        let size = UInt64(base.reader.fileSizeInPkg(atPath: base.packagePath))
        attributes[.size] = size
        return attributes
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func copy(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, copy src: \(srcFile.rawValue), dest: \(destFile.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(destFile, context))
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func move(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, move src: \(srcFile.rawValue), dest: \(destFile.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(srcFile, context))
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func createDirectory(_ file: FileObject, recursive: Bool, attributes: [FileAttributeKey : Any], context: FileSystem.Context) throws {
        assert(false, "try write to package path, createDirectory file: \(file.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func remove(_ file: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, remove file: \(file.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }

    func getSystemFilePath(_ file: FileObject, context: FileSystem.Context) throws -> String {
        return try getPackagePathWithAuxiliary(file: file, context: context)
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func copySystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, copySystemFile file: \(file.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func moveSystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, moveSystemFile file: \(file.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }

    /// 不应执行此操作，如果走到这里，说明上层判断权限有误。
    func writeSystemData(_ data: Data, to file: FileObject, context: FileSystem.Context) throws {
        assert(false, "try write to package path, writeSystemData file: \(file.rawValue)")
        throw FileSystemError.biz(.tryWriteToPackagePath(file, context))
    }
}
