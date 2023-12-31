//
//  FileSystem+IO.swift
//  TTMicroApp
//
//  Created by Meng on 2021/9/22.
//

import Foundation

extension FileSystem {
    internal static let io: FileSystemIO = OpenAppFileSystemIO(
        ttfileSystem: LcoalTTFileSystemIO(),
        packageFileSystem: PackageFileSystemIO()
    )
}

/// 抽象的 file system 操作接口。
///
/// FileSystemIO 协议主要用于业务实现自己的文件操作定义，对外提供一组统一的文件操作。
/// 除此之外，也可以用于构建一些特殊的文件系统，如 InMemoryFileSystem 等。
///
/// - Note: 所有 API 目前都是同步接口。
/// - Note: 本层实现目标是提供基础的操作能力，只做操作必要性校验，不做完整校验，如读写权限等不在本层判断，所有操作默认都会尝试执行。
public protocol FileSystemIO: AnyObject {
    /// 是否有读权限
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func canRead(_ file: FileObject, context: FileSystem.Context) throws -> Bool

    /// 是否有写权限
    /// - Parameters:
    ///   - file: 目标文件
    ///   - isRemove: 是否是删除操作
    ///   - context: 操作上下文
    func canWrite(_ file: FileObject, isRemove: Bool, context: FileSystem.Context) throws -> Bool

    /// 文件是否超出写入大小
    /// - Parameters:
    ///   - srcFile: 源文件
    ///   - destFile: 目标文件
    ///   - context: 操作上下文
    func isWriteFileOverSizeLimit(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws -> Bool

    /// 是否超出写入大小
    /// - Parameters:
    ///   - dataSize: 写入数据大小
    ///   - destFile: 目标文件
    ///   - context: 操作上下文
    func isWriteDataOverSizeLimit(from dataSize: Int64, to destFile: FileObject, context: FileSystem.Context) throws -> Bool

    /// 文件是否存在
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func fileExists(_ file: FileObject, context: FileSystem.Context) throws -> Bool

    /// 是否是文件夹
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func isDirectory(_ file: FileObject, context: FileSystem.Context) throws -> Bool

    /// 获取文件夹内容
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func getDirectoryContents(_ file: FileObject, context: FileSystem.Context) throws -> [String]

    /// 读取文件数据
    /// - Parameters:
    ///   - file: 目标文件
    ///   - positon: 开始读取位置
    ///   - length: 读取数据长度
    ///   - context: 操作上下文
    ///
    /// - Note: 默认不校验 postion 与 length 的值，信任传入结果，业务需要在外部做好处理
    func readFileContents(_ file: FileObject, position: Int64, length: Int64, context: FileSystem.Context) throws -> Data

    /// 读取文件数据
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func readFileContents(_ file: FileObject, context: FileSystem.Context) throws -> Data

    /// 写入文件数据
    /// - Parameters:
    ///   - file: 目标文件
    ///   - data: 写入数据
    ///   - context: 操作上下文
    func writeFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws

    /// 在文件结尾追加数据
    /// - Parameters:
    ///   - file: 目标文件
    ///   - data: 追加写入数据
    ///   - context: 操作上下文
    func appendFileContents(_ file: FileObject, data: Data, context: FileSystem.Context) throws
    
    /// 获取文件属性
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func getFileInfo(_ file: FileObject, autoDecrypt: Bool, context: FileSystem.Context) throws -> [FileAttributeKey: Any]

    /// 复制文件
    /// - Parameters:
    ///   - srcFile: 源文件
    ///   - destFile: 目标文件
    ///   - context: 操作上下文
    func copy(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws

    /// 移动文件
    /// - Parameters:
    ///   - srcFile: 源文件
    ///   - destFile: 目标文件
    ///   - context: 操作上下文
    func move(from srcFile: FileObject, to destFile: FileObject, context: FileSystem.Context) throws

    /// 创建文件夹
    /// - Parameters:
    ///   - file: 目标文件
    ///   - recursive: 是否递归创建
    ///   - attributes: 文件属性
    ///   - context: 操作上下文
    func createDirectory(_ file: FileObject, recursive: Bool, attributes: [FileAttributeKey: Any], context: FileSystem.Context) throws

    /// 删除文件
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func remove(_ file: FileObject, context: FileSystem.Context) throws

    /// 获取系统文件真实路径
    /// - Parameters:
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func getSystemFilePath(_ file: FileObject, context: FileSystem.Context) throws -> String

    /// 拷贝系统文件到目标路径
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func copySystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws

    /// 移动系统文件到目标路径
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func moveSystemFile(_ systemFilePath: String, to file: FileObject, context: FileSystem.Context) throws

    /// 写入系统数据到目标路径
    /// - Parameters:
    ///   - systemFilePath: 系统文件路径
    ///   - file: 目标文件
    ///   - context: 操作上下文
    func writeSystemData(_ data: Data, to file: FileObject, context: FileSystem.Context) throws
}
