//
//  FileSystem+Compatible.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/22.
//

import Foundation
import SSZipArchive

public protocol OPFileSystemZipArhiveDelegate: NSObject, SSZipArchiveDelegate { }

/// 标准 API 兼容接口，用于业务封装一些 第三方库/大型业务模块 的文件操作
///
/// 由于直接与系统文件操作，相关文件的权限限制，数据处理，完全交给业务，因此:
/// 1. 业务诉求如果可以用标准 API 满足，则应当使用 FileSystem 标准 API
/// 2. 如果业务有超出沙箱的边界诉求，则可使用此 API，后续对文件的增删改查操作，均需要业务自行负责。
///
/// 哪些场景会用到下述 API，举例：
/// 1. 第三方播放器需要播放文件，入参需要系统文件路径，此时可以使用 getSystemFile 获取。
/// 2. 文件选择器需要将选择好的系统文件复制到沙箱，可以使用 copySystemFile。
///
public final class FileSystemCompatible {
    /// 获取文件的系统文件路径
    ///
    /// 如果是包文件路径，需要确认是否正确传入了的参数，默认情况下，返回的是虚拟包路径。
    /// 如果你的文件是被包管理解析缓存的资源文件，则需要在 Context 中传递 isAuxiliary 为 true
    ///
    /// 1. 检查文件是否存在
    /// 2. 检查是否是文件
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文
    /// - Throws: FileSystemError
    /// - Returns: 系统文件路径
    public static func getSystemFile(from file: FileObject, context: FileSystem.Context) throws -> String {
        return try FileSystem.monitorWrapper(primitiveAPI: .getSystemFile, dest: file, context: context, monitorOptimize: true) {
            /// 文件是否存在
            guard try FileSystem.fileExist(file, context: context.taggingAPI(.getSystemFile)) else {
                throw FileSystemError.fileNotExists(file, context)
            }

            /// 是否是文件
            guard try !FileSystem.isDirectory(file, context: context.taggingAPI(.getSystemFile)) else {
                throw FileSystemError.isNotFile(file, context)
            }

            return try FileSystem.io.getSystemFilePath(file, context: context)
        }
    }

    /// 将系统文件 copy 到沙箱
    ///
    /// 1. 检查目标文件是否有写权限，这里的写权限包括 user/temp 目录的写权限，与面向外部业务不同，需要谨慎操作。
    /// 2. 检查目标文件是否已存在。
    /// 3. 如果是 user 目录，检查写入大小
    /// 4. 复制文件
    ///
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 文件对象
    ///   - context: 上下文
    /// - Throws: FileSystemError
    public static func copySystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        try FileSystem.monitorWrapper(primitiveAPI: .copySystemFile, dest: file, context: context) {
            var isDir = false
            let systemFileExists = LSFileSystem.fileExists(filePath: systemFilePath, isDirectory: &isDir)
            context.trace.info("copy system file", additionalData: [
                "exists": "\(systemFileExists)",
                "isDir": "\(isDir)"
            ])

            /// 是否有写权限，对内部业务来说 temp 目录也可以写
            guard try FileSystem.canWrite(file, isRemove: false, context: context.taggingAPI(.copySystemFile)) || file.isInTempDir else {
                throw FileSystemError.writePermissionDenied(file, context)
            }

            /// 目标文件是否已存在
            guard try !FileSystem.fileExist(file, context: context.taggingAPI(.copySystemFile)) else {
                throw FileSystemError.fileAlreadyExists(file, context)
            }

            /// User 目录校验写入大小，待完成 FileSystemIO 改造后统一考虑接入
            if file.isInUserDir {
                var attributes: NSDictionary
                do {
                    attributes = try LSFileSystem.attributesOfItem(atPath: systemFilePath) as NSDictionary
                } catch {
                    throw FileSystemError.system(error)
                }
                let size = attributes.fileSize()
                if try FileSystem.io.isWriteDataOverSizeLimit(from: Int64(size), to: file, context: context) {
                    throw FileSystemError.writeSizeLimit(nil, file, context)
                }
            }

            /// 复制文件
            try FileSystem.io.copySystemFile(systemFilePath, to: file, context: context)
        }
    }

    /// 将系统文件 move 到沙箱
    ///
    /// 1. 检查目标文件是否有写权限，这里的写权限包括 user/temp 目录的写权限，与面向外部业务不同，需要谨慎操作。
    /// 2. 检查目标文件是否已存在。
    /// 3. 如果是 user 目录，检查写入大小
    /// 4. 移动文件
    ///
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 文件对象
    ///   - context: 上下文
    /// - Throws: FileSystemError
    public static func moveSystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        try FileSystem.monitorWrapper(primitiveAPI: .moveSystemFile, dest: file, context: context) {
            var isDir = false
            let systemFileExists = LSFileSystem.fileExists(filePath: systemFilePath, isDirectory: &isDir)
            context.trace.info("move system file", additionalData: [
                "exists": "\(systemFileExists)",
                "isDir": "\(isDir)"
            ])

            /// 是否有写权限，对内部业务来说 temp 目录也可以写
            guard try FileSystem.canWrite(file, isRemove: false, context: context.taggingAPI(.copySystemFile)) || file.isInTempDir else {
                throw FileSystemError.writePermissionDenied(file, context)
            }
            
            ///文件名长度限制
            guard file.lastPathComponent.count < FileSystem.Constant.maxFileNameLength else{
                throw FileSystemError.fileNameTooLong(file.rawValue)
            }
            
            /// 目标文件是否已存在
            guard try !FileSystem.fileExist(file, context: context.taggingAPI(.copySystemFile)) else {
                throw FileSystemError.fileAlreadyExists(file, context)
            }

            /// User 目录校验写入大小，待完成 FileSystemIO 改造后统一考虑接入
            if file.isInUserDir {
                var attributes: NSDictionary
                do {
                    attributes = try LSFileSystem.attributesOfItem(atPath: systemFilePath) as NSDictionary
                } catch {
                    throw FileSystemError.system(error)
                }
                let size = attributes.fileSize()
                if try FileSystem.io.isWriteDataOverSizeLimit(from: Int64(size), to: file, context: context) {
                    throw FileSystemError.writeSizeLimit(nil, file, context)
                }
            }

            /// 移动文件
            try FileSystem.io.moveSystemFile(systemFilePath, to: file, context: context)
        }
    }

    /// 将系统数据 write 到沙箱
    ///
    /// 1. 检查目标文件是否有写权限，这里的写权限包括 user/temp 目录的写权限，与面向外部业务不同，需要谨慎操作。
    /// 2. 检查目标文件是否已存在。
    /// 3. 如果是 user 目录，检查写入大小
    /// 4. 写入文件
    ///
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 文件对象
    ///   - context: 上下文
    /// - Throws: FileSystemError
    public static func writeSystemData(_ data: Data, to file: FileObject, context: FileSystem.Context) throws {
        try FileSystem.monitorWrapper(primitiveAPI: .writeSystemData, dest: file, context: context) {
            /// 是否有写权限，对内部业务来说 temp 目录也可以写
            guard try FileSystem.canWrite(file, isRemove: false, context: context.taggingAPI(.copySystemFile)) || file.isInTempDir else {
                throw FileSystemError.writePermissionDenied(file, context)
            }

            /// 目标文件是否已存在
            guard try !FileSystem.fileExist(file, context: context.taggingAPI(.copySystemFile)) else {
                throw FileSystemError.fileAlreadyExists(file, context)
            }

            /// User 目录校验写入大小，待完成 FileSystemIO 改造后统一考虑接入
            if file.isInUserDir {
                if try FileSystem.io.isWriteDataOverSizeLimit(from: Int64(data.count), to: file, context: context) {
                    throw FileSystemError.writeSizeLimit(nil, file, context)
                }
            }

            /// 写入文件
            try FileSystem.io.writeSystemData(data, to: file, context: context)
        }
    }

    /// 解压缩文件
    ///
    /// 1. 检查源文件读权限
    /// 2. 检查目标文件写权限
    /// 3. 检查源文件是否存在
    /// 4. 检查目标文件父目录是否存在
    /// 5. 检查源文件写入大小
    /// 6. 解压缩
    ///
    /// 解压缩能力本身还有较多历史遗留问题，暂作为兼容接口实现。
    /// 已知潜在问题:
    /// 1. 使用解压前文件判断写入大小
    /// 2. 解压第三方接口未确认路径穿越问题
    /// 3. 加解密场景下的性能问题
    ///
    /// - Parameters:
    ///   - src: 源文件
    ///   - dest: 目标文件
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func unzip(src: FileObject, dest: FileObject, context: FileSystem.Context, delegate: OPFileSystemZipArhiveDelegate?) throws {
        try FileSystem.monitorWrapper(primitiveAPI: .unzip, src: src, dest: dest, context: context) {
            context.trace.info("unzip", additionalData: ["src": "\(src.rawValue)", "dest": "\(dest.rawValue)"])
            /// 检查源文件读权限
            guard try FileSystem.canRead(src, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.readPermissionDenied(src, context)
            }

            /// 检查目标文件写权限
            guard try FileSystem.canWrite(dest, isRemove: false, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.writePermissionDenied(dest, context)
            }

            /// 检查源文件是否存在
            guard try FileSystem.fileExist(src, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.fileNotExists(src, context)
            }

            /// 检查源文件是否是文件
            guard try !FileSystem.isDirectory(src, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.isNotFile(src, context)
            }

            /// 检查目标文件父目录是否存在
            let destFolder = dest.deletingLastPathComponent
            guard try FileSystem.fileExist(destFolder, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.fileNotExists(destFolder, context)
            }

            /// 检查源文件写入大小
            guard try !FileSystem.isOverSizeLimit(src: src, dest: dest, context: context.taggingAPI(.unzip)) else {
                throw FileSystemError.writeSizeLimit(src, dest, context)
            }

            let srcPath = try FileSystem.io.getSystemFilePath(src, context: context)
            let destPath = try FileSystem.io.getSystemFilePath(dest, context: context)

            /// 解压缩
            guard SSZipArchive.unzipFile(atPath: srcPath, toDestination: destPath, delegate: delegate) else {
                throw FileSystemError.biz(.unzipFailed(src, dest, context))
            }

            func encryptPath(_ targetPath: String) throws {
                let isDir = LSFileSystem.isDirectory(filePath: targetPath)
                if isDir {
                    let subFileNames = try LSFileSystem.contentsOfDirectory(dirPath: targetPath).filter { fileName in
                        fileName != ".DS_Store"
                    }
                    try subFileNames.forEach({
                        let targetURL = URL(fileURLWithPath: targetPath)
                        try encryptPath(targetURL.appendingPathComponent($0).path)
                    })
                } else {
                    try FSCrypto.encryptFile(with: targetPath, context: context)
                }
            }

            /// 递归加密, 如果未开启加解密则不进行默认加密操作，节省一次递归操作
            if FSCrypto.encryptEnable() {
                try encryptPath(destPath)
            }

        }
    }

    /// 解密文件到指定路径
    /// 解密接口只做为兜底的兼容接口存在，目的是为了解决极端情况下开发者的加密数据恢复问题。
    ///
    /// - Parameters:
    ///   - src: 源文件路径
    ///   - dest: 目标文件路径
    ///   - context: 上下文
    public static func decryptFile(src: FileObject, dest: FileObject, context: FileSystem.Context) throws {
        try FileSystem.monitorWrapper(primitiveAPI: .decryptFile, src: src, dest: dest, context: context) {
            let systemFilePath = try FileSystem.io.getSystemFilePath(src, context: context)
            let destFilePath = try FileSystem.io.getSystemFilePath(dest, context: context)

            let decryptSystemFile = try FSCrypto.decryptFile(with: systemFilePath, context: context)
            do {
                try LSFileSystem.main.moveItem(atPath: decryptSystemFile, toPath: destFilePath)
            } catch {
                throw FileSystemError.system(error)
            }
        }
    }
}
