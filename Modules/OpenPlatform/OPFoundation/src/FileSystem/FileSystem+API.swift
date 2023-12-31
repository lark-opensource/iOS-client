//
//  FileSystem+API.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/3.
//

import Foundation

/// FileSystem 标准 API
extension FileSystem {
    /// 判断文件是否存在
    ///
    /// 1. 检查文件读权限。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否存在
    public static func fileExist(_ file: FileObject, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .fileExist, dest: file, context: context, monitorOptimize: true) {
            /// 检查读权限
            guard try canRead(file, context: context.taggingAPI(.fileExist)) else {
                throw FileSystemError.readPermissionDenied(file, context)
            }

            return try io.fileExists(file, context: context)
        }
    }

    /// 判断文件是否文件夹
    ///
    /// 1. 检查文件读权限。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否文件夹
    public static func isDirectory(_ file: FileObject, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .isDirectory, dest: file, context: context, monitorOptimize: true) {
            /// 检查读权限
            guard try canRead(file, context: context.taggingAPI(.isDirectory)) else {
                throw FileSystemError.readPermissionDenied(file, context)
            }

            return try io.isDirectory(file, context: context)
        }
    }

    /// 获取文件夹目录内容, 即获取下一层级
    ///
    /// 1. 检查文件读权限。
    /// 1. 检查文件是否存在。
    /// 2. 检查文件是否是目录。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 目录子文件对象
    public static func listContents(_ file: FileObject, context: Context) throws -> [String] {
        return try monitorWrapper(primitiveAPI: .listContents, dest: file, context: context, monitorOptimize: true) {
            /// 检查读权限
            guard try canRead(file, context: context.taggingAPI(.listContents)) else {
                throw FileSystemError.readPermissionDenied(file, context)
            }

            /// 存在性判断
            guard try fileExist(file, context: context.taggingAPI(.listContents)) else {
                throw FileSystemError.fileNotExists(file, context)
            }

            /// 是否文件目录
            guard try isDirectory(file, context: context.taggingAPI(.listContents)) else {
                throw FileSystemError.isNotDirectory(file, context)
            }

            return try io.getDirectoryContents(file, context: context)
        }
    }

    /// 获取文件属性信息
    ///
    /// 1. 检查文件读权限。
    /// 1. 检查文件是否存在。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 文件属性信息
    public static func attributesOfFile(_ file: FileObject, context: Context) throws -> [FileAttributeKey: Any] {
        return try monitorWrapper(primitiveAPI: .attributesOfFile, dest: file, context: context, monitorOptimize: true) {
            /// 检查读权限
            guard try canRead(file, context: context.taggingAPI(.attributesOfFile)) else {
                throw FileSystemError.readPermissionDenied(file, context)
            }

            /// 存在性判断
            guard try fileExist(file, context: context.taggingAPI(.attributesOfFile)) else {
                throw FileSystemError.fileNotExists(file, context)
            }

            return try io.getFileInfo(file, autoDecrypt: true, context: context)
        }
    }

    /// 读取文件数据
    ///
    /// 1. 检查文件读权限。
    /// 2. 检查文件是否存在。
    /// 3. 检查是否是文件。
    /// 4. 判断 postion 合法性。
    /// 5. 判断 length 合法性。
    /// 6. 判断 length 是否超出最大读取下限
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - position: 开始读取位置，空表示从 0 开始读取。default: nil
    ///   - length: 读取数据长度，空表示读取到文件末尾, 如果不传则认为默认读取到文件末尾。default: nil
    ///   - threshold: 分片读取时的最大限制大小, 如果不传则认为不使用分片读取。default: nil
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 文件数据
    public static func readFile(
        _ file: FileObject,
        position: Int64? = nil,
        length: Int64? = nil,
        threshold: Int64? = nil,
        context: Context
    ) throws -> Data {
        return try monitorWrapper(primitiveAPI: .readFile, dest: file, context: context, monitorOptimize: true) {
            context.trace.info("readFile", additionalData: ["params_position": "\(position ?? 0)","params_length":"\(length ?? 0)"])

            /// 检查读权限
            guard try canRead(file, context: context.taggingAPI(.readFile)) else {
                throw FileSystemError.readPermissionDenied(file, context)
            }

            /// 存在性判断
            guard try fileExist(file, context: context.taggingAPI(.readFile)) else {
                throw FileSystemError.fileNotExists(file, context)
            }

            /// 是否文件
            guard try !isDirectory(file, context: context.taggingAPI(.readFile)) else {
                throw FileSystemError.isNotFile(file, context)
            }

            /// 分片逻辑
            if let threshold = threshold {
                let attributes = try attributesOfFile(file, context: context.taggingAPI(.readFile)) as NSDictionary
                let fileSize = Int64(truncatingIfNeeded: attributes.fileSize())

                /// check nil or set default
                let pos = position ?? 0
                let len = length ?? (fileSize - pos)

                /// 判断 postion 合法性
                guard (0..<fileSize).contains(pos) else {
                    throw FileSystemError.invalidParam("position")
                }

                // 判断 length 合法性
                guard (0...fileSize).contains(len) else {
                    throw FileSystemError.invalidParam("length")
                }

                /// 判断 length 是否超出最大读取下限
                if (len > threshold) {
                    throw FileSystemError.overReadSizeThreshold(file, context)
                }

                /// 读取文件内容
                return try io.readFileContents(file, position: pos, length: len, context: context)
            /// 非分片逻辑
            } else {
                return try io.readFileContents(file, context: context)
            }
        }
    }

    /// 删除文件
    ///
    /// 1. 检查文件写权限。
    /// 2. 检查文件是否存在。
    /// 3. 检查是否是文件。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func removeFile(_ file: FileObject, context: Context) throws {
        try monitorWrapper(primitiveAPI: .removeFile, dest: file, context: context) {
            /// 检查写权限
            guard try canWrite(file, isRemove: true, context: context.taggingAPI(.removeFile)) else {
                throw FileSystemError.writePermissionDenied(file, context)
            }

            /// 文件存在性判断, 不存在直接返回，不报错
            if try !fileExist(file, context: context.taggingAPI(.removeFile)) {
                return
            }

            /// 文件夹判断
            guard try !isDirectory(file, context: context.taggingAPI(.removeFile)) else {
                throw FileSystemError.isNotFile(file, context)
            }

            try io.remove(file, context: context)
        }
    }

    /// 移动文件
    ///
    /// 1. 检查源文件写权限。
    /// 2. 检查目标文件写权限。
    /// 3. 检查源文件与目标文件是否是父子目录。
    /// 4. 检查源文件是否存在。
    /// 5. 检查目标文件是否已存在。
    /// 6. 检查目标文件父目录是否存在。
    /// 7. 检查源文件写入大小。
    ///
    /// - Parameters:
    ///   - src: 源文件对象
    ///   - dest: 目标文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func moveFile(src: FileObject, dest: FileObject, context: Context) throws {
        try monitorWrapper(primitiveAPI: .moveFile, src: src, dest: dest, context: context) {
            /// 检查源文件写权限
            guard try canWrite(src, isRemove: true, context: context.taggingAPI(.moveFile)) else {
                throw FileSystemError.writePermissionDenied(src, context)
            }

            /// 检查目标文件写权限
            guard try canWrite(dest, isRemove: false, context: context.taggingAPI(.moveFile)) else {
                throw FileSystemError.writePermissionDenied(dest, context)
            }
            
            ///文件名长度限制
            guard dest.lastPathComponent.count < FileSystem.Constant.maxFileNameLength else{
                throw FileSystemError.fileNameTooLong(dest.rawValue)
            }
            
            /// 父子目录判断
            guard !FileSystemUtils.isSubpath(src: src.rawValue, dest: dest.rawValue) else {
                throw FileSystemError.cannotOperatePathAndSubpathAtTheSameTime(src, dest, context)
            }

            /// 源文件存在性判断
            guard try fileExist(src, context: context.taggingAPI(.moveFile)) else {
                throw FileSystemError.fileNotExists(src, context)
            }

            /// 目标文件是否已存在
            guard try !fileExist(dest, context: context.taggingAPI(.moveFile)) else {
                throw FileSystemError.fileAlreadyExists(dest, context)
            }

            /// 目标文件目录存在性判断
            let destFolder = dest.deletingLastPathComponent
            guard try fileExist(destFolder, context: context.taggingAPI(.moveFile)) else {
                throw FileSystemError.parentNotExists(dest, context)
            }

            /// 写入大小判断
            guard try !isOverSizeLimit(src: src, dest: dest, context: context) else {
                throw FileSystemError.writeSizeLimit(src, dest, context)
            }

            try io.move(from: src, to: dest, context: context)
        }
    }

    /// 复制文件
    ///
    /// 1. 检查源文件读权限。
    /// 2. 检查目标文件写权限。
    /// 3. 检查源文件与目标文件是否是父子目录。
    /// 4. 检查源文件是否存在。
    /// 5. 检查目标文件是否已存在。
    /// 6. 检查目标文件父目录是否存在。
    /// 7. 检查源文件写入大小
    ///
    /// - Parameters:
    ///   - src: 源文件对象
    ///   - dest: 目标文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func copyFile(src: FileObject, dest: FileObject, context: Context) throws {
        try monitorWrapper(primitiveAPI: .copyFile, src: src, dest: dest, context: context) {
            /// 检查源文件读权限
            guard try canRead(src, context: context.taggingAPI(.copyFile)) else {
                throw FileSystemError.readPermissionDenied(src, context)
            }

            /// 检查目标文件写权限
            guard try canWrite(dest, isRemove: false, context: context.taggingAPI(.copyFile)) else {
                throw FileSystemError.writePermissionDenied(dest, context)
            }
            
            ///文件名长度限制
            guard dest.lastPathComponent.count < FileSystem.Constant.maxFileNameLength else{
                throw FileSystemError.fileNameTooLong(dest.rawValue)
            }
            
            /// 父子目录判断
            guard !FileSystemUtils.isSubpath(src: src.rawValue, dest: dest.rawValue) else {
                throw FileSystemError.cannotOperatePathAndSubpathAtTheSameTime(src, dest, context)
            }

            /// 源文件存在性判断
            guard try fileExist(src, context: context.taggingAPI(.copyFile)) else {
                throw FileSystemError.fileNotExists(src, context)
            }

            /// 目标文件是否已存在
            guard try !fileExist(dest, context: context.taggingAPI(.copyFile)) else {
                throw FileSystemError.fileAlreadyExists(dest, context)
            }

            /// 目标文件夹存在性判断
            let folder = dest.deletingLastPathComponent
            guard try fileExist(folder, context: context.taggingAPI(.copyFile)) else {
                throw FileSystemError.fileNotExists(folder, context)
            }

            /// 写入大小判断
            guard try !isOverSizeLimit(src: src, dest: dest, context: context) else {
                throw FileSystemError.writeSizeLimit(src, dest, context)
            }

            try io.copy(from: src, to: dest, context: context)
        }
    }

    /// 写入数据到文件
    ///
    /// 1. 检查文件写权限。
    /// 2. 检查文件是否已存在
    /// 3. 检查目标文件父目录是否存在。
    /// 4. 检查写入文件大小。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - data: 写入数据
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func writeFile(_ file: FileObject, data: Data, context: Context, internalSupportTemp: Bool = false) throws {
        try monitorWrapper(primitiveAPI: .writeFile, dest: file, context: context) {
            context.trace.info("writeFile", additionalData: ["params_data_length": "\(data.count)"])

            /// 检查写权限
            guard try canWrite(file, isRemove: false, context: context.taggingAPI(.writeFile)) || (internalSupportTemp && file.isInTempDir) else {
                throw FileSystemError.writePermissionDenied(file, context)
            }
            
            ///文件名长度限制
            guard file.lastPathComponent.count < FileSystem.Constant.maxFileNameLength else{
                throw FileSystemError.fileNameTooLong(file.rawValue)
            }
            
            /// 目标文件存在性判断
            guard try !fileExist(file, context: context.taggingAPI(.writeFile)) else {
                throw FileSystemError.fileAlreadyExists(file, context)
            }

            /// 父文件目录存在性判断
            let folder = file.deletingLastPathComponent
            guard try fileExist(folder, context: context.taggingAPI(.writeFile)) else {
                throw FileSystemError.parentNotExists(folder, context)
            }
            
            /// 单次写入大小判断
            let writeSizeThreshold = FileSystemUtils.writeSizeThreshold(uniqueId: context.uniqueId)
            context.trace.info("writeFile", additionalData: ["writeSizeThreshold": "\(writeSizeThreshold)"])
            
            guard data.count <= writeSizeThreshold || (internalSupportTemp && file.isInTempDir) else {
                throw FileSystemError.overWriteSizeThreshold(file, context)
            }
            
            /// 写入大小判断
            guard try !isOverSizeLimit(file, data: data, context: context) || (internalSupportTemp && file.isInTempDir) else {
                throw FileSystemError.writeSizeLimit(nil, file, context)
            }

            try io.writeFileContents(file, data: data, context: context)
        }
    }

    /// 在文件结尾追加内容
    ///
    /// 1. 检查文件写权限。
    /// 2. 检查文件是否存在
    /// 3. 检查写入文件大小。
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - data: 写入数据
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func appendFile(_ file: FileObject, data: Data, context: Context) throws {
        try monitorWrapper(primitiveAPI: .appendFile, dest: file, context: context) {
            context.trace.info("appendFile", additionalData: ["params_data_length": "\(data.count)"])
            
            /// 检查写权限
            guard try canWrite(file, isRemove: false, context: context.taggingAPI(.appendFile)) else {
                throw FileSystemError.writePermissionDenied(file, context)
            }

            /// 目标文件存在性判断
            guard try fileExist(file, context: context.taggingAPI(.appendFile)) else {
                throw FileSystemError.fileNotExists(file, context)
            }
            
            /// 单次写入大小判断
            let writeSizeThreshold = FileSystemUtils.writeSizeThreshold(uniqueId: context.uniqueId)
            context.trace.info("appendFile", additionalData: ["writeSizeThreshold": "\(writeSizeThreshold)"])
            guard data.count <= writeSizeThreshold else {
                throw FileSystemError.overWriteSizeThreshold(file, context)
            }
            
            /// 写入大小判断
            guard try !isOverSizeLimit(file, data: data, context: context) else {
                throw FileSystemError.writeSizeLimit(nil, file, context)
            }

            try io.appendFileContents(file, data: data, context: context)
        }
    }

    
    /// 创建文件夹
    ///
    /// 1. 检查文件写权限
    /// 2. 检查文件是否存在
    /// 3. 非递归情况下，如果目标文件父文件目录不存在则报错
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - recursive: 是否递归创建
    ///   - attributes: 文件属性
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func createDirectory(
        _ file: FileObject, recursive: Bool, attributes: [FileAttributeKey: Any] = [:], context: Context
    ) throws {
        try monitorWrapper(primitiveAPI: .createDirectory, dest: file, context: context) {
            context.trace.info("createDirectory", additionalData: ["params_recursive": "\(recursive)",
                                                                   "params_attributes_keys": "\(attributes.keys.map(\.rawValue))"])

            /// 检查写权限
            guard try canWrite(file, isRemove: false, context: context.taggingAPI(.createDirectory)) else {
                throw FileSystemError.writePermissionDenied(file, context)
            }
            
            ///文件名长度限制
            guard file.lastPathComponent.count < FileSystem.Constant.maxFileNameLength else{
                throw FileSystemError.fileNameTooLong(file.rawValue)
            }
            
            /// 文件存在性判断
            guard try !fileExist(file, context: context.taggingAPI(.createDirectory)) else {
                throw FileSystemError.fileAlreadyExists(file, context)
            }

            /// 非递归情况，文件父目录存在性判断
            if !recursive {
                let folder = file.deletingLastPathComponent
                guard try fileExist(folder, context: context.taggingAPI(.createDirectory)) else {
                    throw FileSystemError.parentNotExists(folder, context)
                }
            }

            try io.createDirectory(file, recursive: recursive, attributes: attributes, context: context)
        }
    }

    /// 删除文件夹
    ///
    /// 1. 检查文件写权限
    /// 2. 如果目标文件不存在则直接返回成功
    /// 3. 如果目标文件不是文件夹则报错
    /// 4. 如果非递归情况，目标文件夹非空则报错
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - recursive: 是否递归删除
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    public static func removeDirectory(_ file: FileObject, recursive: Bool, context: Context) throws {
        try monitorWrapper(primitiveAPI: .removeDirectory, dest: file, context: context) {
            context.trace.info("removeDirectory", additionalData: ["params_recursive": "\(recursive)"])

            /// 检查写权限
            guard try canWrite(file, isRemove: true, context: context.taggingAPI(.removeDirectory)) else {
                throw FileSystemError.writePermissionDenied(file, context)
            }

            /// 存在性判断, 如果不存在直接返回
            if try !fileExist(file, context: context.taggingAPI(.removeDirectory)) {
                return
            }

            /// 文件夹判断
            guard try isDirectory(file, context: context.taggingAPI(.removeDirectory)) else {
                throw FileSystemError.isNotDirectory(file, context)
            }

            /// 非递归情况，文件夹非空判断
            if try !recursive && !listContents(file, context: context.taggingAPI(.removeDirectory)).isEmpty {
                throw FileSystemError.directoryNotEmpty(file, context)
            }

            try io.remove(file, context: context)
        }
    }

    /// 是否有读权限
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否可读
    public static func canRead(_ file: FileObject, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .canRead, dest: file, context: context, monitorOptimize: true) {
            return try io.canRead(file, context: context)
        }
    }

    /// 是否有写权限
    ///
    /// - Parameters:
    ///   - file: 文件对象
    ///   - isRemove: 是否是删除操作
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否可写
    public static func canWrite(_ file: FileObject, isRemove: Bool, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .canWrite, dest: file, context: context, monitorOptimize: true) {
            context.trace.info("canWrite", additionalData: ["params_is_remove": "\(isRemove)"])
            return try io.canWrite(file, isRemove: isRemove, context: context)
        }
    }

    /// 目标文件写入是否超出限制大小
    ///
    /// 1. 如果源文件不存在，直接返回 false
    ///
    /// - Parameters:
    ///   - src: 源文件对象
    ///   - dest: 目标文件对象
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否允许写入
    public static func isOverSizeLimit(src: FileObject, dest: FileObject, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .isOverSizeLimit, src: src, dest: dest, context: context, monitorOptimize: true) {
            /// 文件不存在直接返回 false
            if try !fileExist(src, context: context.taggingAPI(.isOverSizeLimit)) {
                return false
            }

            return try io.isWriteFileOverSizeLimit(from: src, to: dest, context: context)
        }
    }

    /// 目标数据写入是否超出限制大小
    ///
    /// - Parameters:
    ///   - file: 写入的文件
    ///   - data: 写入数据
    ///   - context: 上下文信息
    /// - Throws: FileSystemError
    /// - Returns: 是否允许写入
    public static func isOverSizeLimit(_ file: FileObject, data: Data, context: Context) throws -> Bool {
        return try monitorWrapper(primitiveAPI: .isOverSizeLimit, dest: file, context: context, monitorOptimize: true) {
            context.trace.info("isOverSizeLimit", additionalData: ["params_data_length": "\(data.count)"])
            return try io.isWriteDataOverSizeLimit(from: Int64(data.bytes.count), to: file, context: context)
        }
    }
}
