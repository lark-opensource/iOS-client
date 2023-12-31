//
//  IsoPath+Zip.swift
//  LarkStorage
//
//  Created by 7Up on 2023/1/4.
//

import Foundation

extension IsoPath {
    enum ZipError: Error {
        /// 缺少 archiver
        case missingArchiver
        /// 创建压缩文件失败
        case createFailure(Error)
        /// 解压文件失败
        case unzipFailure(Error)
    }

    /// 基于多个文件创建压缩文件
    public func createZipFile(withFilesAtPaths paths: [AbsPath], password: String? = nil) throws {
        guard let archiver = Dependencies.zipArchiver else {
            throw ZipError.missingArchiver
        }
        do {
            try archiver.createZipFile(
                atPath: absoluteString,
                withFilesAtPaths: paths.map(\.absoluteString),
                password: password
            )
        } catch {
            throw ZipError.createFailure(error)
        }
    }

    /// 基于目录创建压缩文件
    public func createZipFile(withContentsOfDirectory directoryPath: AbsPathConvertiable, password: String? = nil) throws {
        guard let archiver = Dependencies.zipArchiver else {
            throw ZipError.missingArchiver
        }
        do {
            try archiver.createZipFile(
                atPath: absoluteString,
                withContentsOfDirectory: directoryPath.asAbsPath().absoluteString,
                password: password
            )
        } catch {
            throw ZipError.createFailure(error)
        }
    }

    /// 解压文件到当前路径
    public func unzipFile(fromPath: AbsPathConvertiable, overwrite: Bool = true, password: String? = nil) throws {
        guard let archiver = Dependencies.zipArchiver else {
            throw ZipError.missingArchiver
        }
        do {
            try archiver.unzipFile(
                atPath: fromPath.asAbsPath().absoluteString,
                toPath: absoluteString,
                overwrite: overwrite,
                password: password
            )
        } catch {
            throw ZipError.unzipFailure(error)
        }
    }
}
