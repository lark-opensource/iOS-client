//
//  FileSystem+OpenAppIO.swift
//  TTMicroApp
//
//  Created by Meng on 2021/10/25.
//

import Foundation

/// 开放应用沙箱 FileSystem 操作
/// - Note: 包含 package 路径，ttfile://user, ttfile://temp 。
class OpenAppFileSystemIO: FileSystemIO {
    private let ttfileSystem: FileSystemIO
    private let packageFileSystem: FileSystemIO

    init(ttfileSystem: FileSystemIO, packageFileSystem: FileSystemIO) {
        self.ttfileSystem = ttfileSystem
        self.packageFileSystem = packageFileSystem
    }

    private func isTTFile(_ file: FileObject) -> Bool {
        return file.url.scheme == BDP_TTFILE_SCHEME
    }

    private func resolveFileSystem(for file: FileObject) -> FileSystemIO {
        if isTTFile(file) {
            return ttfileSystem
        } else {
            return packageFileSystem
        }
    }

    private func isSameFileSystem(src: FileObject, dest: FileObject) -> Bool {
        let srcFS = resolveFileSystem(for: src)
        let destFS = resolveFileSystem(for: dest)
        return srcFS === destFS
    }

    /// 读权限按照 file 所在 FileSystem 权限。
    func canRead(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let fs = resolveFileSystem(for: file)
        return try fs.canRead(file, context: context)
    }

    /// 写权限按照 file 所在 FileSystem 权限。
    func canWrite(_ file: FileObject, isRemove: Bool, context: FileSystem.Context) throws -> Bool {
        let fs = resolveFileSystem(for: file)
        return try fs.canWrite(file, isRemove: isRemove, context: context)
    }

    /// 写入大小判断:
    ///     1. 如果 src 与 dest 文件系统相同，则按照 destFileSystem 行为判断。
    ///     2. 如果 src 与 dest 文件系统不相同，则先从源系统读取文件 size， 然后在目标系统判断是否可以写入。
    func isWriteFileOverSizeLimit(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        if isSameFileSystem(src: srcFile, dest: destFile) {
            let destFS = resolveFileSystem(for: destFile)
            return try destFS.isWriteFileOverSizeLimit(from: srcFile, to: destFile, context: context)
        } else {
            let srcFS = resolveFileSystem(for: srcFile)
            let destFS = resolveFileSystem(for: destFile)

            /// 跨文件系统操作，需要先从源系统读取文件 size， 然后在目标系统判断是否可以写入。
            /// 如果 package 为 dest，则依赖 PackageFS 本身的 error。
            /// FIXME: 现在 package 应该是读取不出来 dir size 的，不过 src 在包路径一般传递的也是文件，将来完整支持 dir 时需要考虑。
            let attributes = try srcFS.getFileInfo(srcFile, autoDecrypt: true, context: context) as NSDictionary
            return try destFS.isWriteDataOverSizeLimit(from: Int64(attributes.fileSize()), to: destFile, context: context)
        }
    }

    /// 写入大小判断，按照目标 file 所在 FileSystem 行为判断。
    func isWriteDataOverSizeLimit(from dataSize: Int64, to destFile: FileObject, context: FileSystem.Context) throws -> Bool {
        let fs = resolveFileSystem(for: destFile)
        return try fs.isWriteDataOverSizeLimit(from: dataSize, to: destFile, context: context)
    }

    /// 文件是否存在，按照 file 所在 FileSystem 行为判断。
    func fileExists(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let fs = resolveFileSystem(for: file)
        return try fs.fileExists(file, context: context)
    }

    /// 是否是文件夹，按照 file 所在 FileSystem 行为判断。
    func isDirectory(_ file: FileObject, context: FileSystem.Context) throws -> Bool {
        let fs = resolveFileSystem(for: file)
        return try fs.isDirectory(file, context: context)
    }

    /// 获取文件夹内容，按照 file 所在 FileSystem 行为获取。
    func getDirectoryContents(_ file: FileObject, context: FileSystem.Context) throws -> [String] {
        let fs = resolveFileSystem(for: file)
        return try fs.getDirectoryContents(file, context: context)
    }

    /// 读取文件数据，按照 file 所在 FileSystem 行为读取。
    func readFileContents(_ file: FileObject, position: Int64, length: Int64, context: FileSystem.Context) throws -> Data {
        let fs = resolveFileSystem(for: file)
        return try fs.readFileContents(file, position: position, length: length, context: context)
    }

    /// 读取文件数据，按照 file 所在 FileSystem 行为读取。
    func readFileContents(_ file: FileObject, context: FileSystem.Context) throws -> Data {
        let fs = resolveFileSystem(for: file)
        return try fs.readFileContents(file, context: context)
    }

    /// 写入文件数据，按照 file 所在 FileSystem 行为写入。
    func writeFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.writeFileContents(file, data: data, context: context)
    }
    
    /// 文件结尾追加数据，按照 file 所在 FileSystem 行为写入。
    func appendFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.appendFileContents(file, data: data, context: context)
    }
    
    /// 获取文件属性，按照 file 所在 FileSystem 行为返回。
    func getFileInfo(_ file: FileObject, autoDecrypt: Bool, context: FileSystem.Context) throws -> [FileAttributeKey : Any] {
        let fs = resolveFileSystem(for: file)
        return try fs.getFileInfo(file, autoDecrypt: autoDecrypt, context: context)
    }

    /// 复制文件：
    ///     1. 如果 src 与 dest 文件系统相同，则按照 destFileSystem 行为复制。
    ///     2. 如果 src 与 dest 文件系统不同，则会先读取 src 文件系统数据，再写入到 dest 文件系统。
    func copy(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        if isSameFileSystem(src: srcFile, dest: destFile) {
            let destFS = resolveFileSystem(for: destFile)
            try destFS.copy(from: srcFile, to: destFile, context: context)
        } else {
            // cross file system
            let srcFS = resolveFileSystem(for: srcFile)
            let destFS = resolveFileSystem(for: destFile)

            // 跨文件系统操作，先从源系统读数据，再写入目标系统。
            // FIXME: 原子性, 性能问题
            let data = try srcFS.readFileContents(srcFile, context: context)
            try destFS.writeFileContents(destFile, data: data, context: context)
        }
    }

    /// 移动文件：
    ///     1. 如果 src 与 dest 文件系统相同，则按照 destFileSystem 行为复制。
    ///     2. 如果 src 与 dest 文件系统不同，则会先读取 src 文件系统数据，再写入到 dest 文件系统，最后删除源文件系统数据。
    func move(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws {
        if isSameFileSystem(src: srcFile, dest: destFile) {
            let destFS = resolveFileSystem(for: destFile)
            try destFS.move(from: srcFile, to: destFile, context: context)
        } else {
            // cross file system
            let srcFS = resolveFileSystem(for: srcFile)
            let destFS = resolveFileSystem(for: destFile)

            // 跨文件系统操作，先从源系统读数据，再写入目标系统，最后删除源系统数据。
            // FIXME: 原子性, 性能问题
            let data = try srcFS.readFileContents(srcFile, context: context)
            try destFS.writeFileContents(destFile, data: data, context: context)
            try srcFS.remove(srcFile, context: context)
        }
    }

    /// 创建文件夹，按照 file 所在 FileSystem 行为创建。
    func createDirectory(_ file: FileObject, recursive: Bool, attributes: [FileAttributeKey : Any], context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.createDirectory(file, recursive: recursive, attributes: attributes, context: context)
    }

    /// 删除文件，按照 file 所在 FileSystem 行为删除。
    func remove(_ file: FileObject, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.remove(file, context: context)
    }

    /// 获取系统文件路径，按照 file 所在 FileSystem 获取。
    func getSystemFilePath(_ file: FileObject, context: FileSystem.Context) throws -> String {
        let fs = resolveFileSystem(for: file)
        return try fs.getSystemFilePath(file, context: context)
    }

    /// 复制系统文件到目标路径，按照 file 所在 FileSystem 复制。
    func copySystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.copySystemFile(systemFilePath, to: file, context: context)
    }

    /// 移动系统文件到目标路径，按照 file 所在 FileSystem 移动。
    func moveSystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.moveSystemFile(systemFilePath, to: file, context: context)
    }

    /// 移动系统数据到目标路径，按照 file 所在 FileSystem 写入。
    func writeSystemData(_ data: Data, to file: FileObject, context: FileSystem.Context) throws {
        let fs = resolveFileSystem(for: file)
        try fs.writeSystemData(data, to: file, context: context)
    }
}
