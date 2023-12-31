//
//  FileObject.swift
//  TTMicroApp
//
//  Created by Meng on 2021/8/3.
//

import Foundation
import LKCommonsLogging

/// 标准文件对象
public struct FileObject {
    private static let logger = Logger.oplog(FileObject.self, category: "FileObject")

    /// 原始值
    public var rawValue: String {
        return url.absoluteString.removingPercentEncoding ?? url.absoluteString
    }

    internal let url: URL

    public init(rawValue: String) throws {
        /// 判空
        guard !rawValue.isEmpty else {
//            throw FileSystemError.biz(.invalidTTFile(rawValue))
            FileObject.logger.info("FileObject rawValue isEmpty")
            throw FileSystemError.invalidFilePath(rawValue)
        }

        /// URL 编码
        let allowedChatacters = FileObject.allowedCharacters
        guard let encodeRawValue = rawValue.addingPercentEncoding(withAllowedCharacters: allowedChatacters) else {
            FileObject.logger.info("FileObject addingPercentEncoding fail:\(rawValue)")
//            throw FileSystemError.biz(.constructFileObjectFailed(rawValue))
            throw FileSystemError.invalidFilePath(rawValue)
        }

        /// 生成 URL
        guard let url = URL(string: encodeRawValue) else {
            FileObject.logger.info("FileObject URL initializer fail:\(rawValue)")
//            throw FileSystemError.biz(.constructFileObjectFailed(rawValue))
            throw FileSystemError.invalidFilePath(rawValue)
        }

        self.url = url

        // 检查 sandbox filepath 有效性
        guard isValidSandboxFilePath() else {
//            throw FileSystemError.biz(.invalidTTFile(rawValue))
            FileObject.logger.info("FileObject isValidSandboxFilePath false:\(rawValue)")
            throw FileSystemError.invalidFilePath(rawValue)
        }
    }

    fileprivate init(url: URL) {
        self.url = url
    }

    private static var allowedCharacters: CharacterSet {
        return CharacterSet.urlHostAllowed
            .union(.urlUserAllowed)
            .union(.urlPasswordAllowed)
            .union(.urlPathAllowed)
            .union(.urlQueryAllowed)
            .union(.urlFragmentAllowed)
    }
}

extension FileObject {
    public var lastPathComponent: String {
        return url.lastPathComponent.removingPercentEncoding ?? url.lastPathComponent
    }

    public var deletingLastPathComponent: FileObject {
        let newURL = url.deletingLastPathComponent()
        return FileObject(url: newURL)
    }

    public var pathExtension: String {
        return url.pathExtension.removingPercentEncoding ?? url.pathExtension
    }

    public func appendingPathComponent(_ component: String) -> FileObject {
        let newURL = url.appendingPathComponent(component) // 系统默认会对 path component 进行 url encode
        return FileObject(url: newURL)
    }

    /// base64RawValue for debug
    public var base64RawValue: String {
        return rawValue.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

/// TTFile Utils function, 长期需要与 FileObject 定义拆分
extension FileObject {

    /// Sandbox 允许的格式
    ///
    /// ttfile://user/xxx
    /// ttfile://temp/xxx
    /// /a/b/c
    func isValidSandboxFilePath() -> Bool {
        if let scheme = url.scheme, let host = url.host { // scheme 和 host 同时存在时，scheme 必须为 ttfile，host 必须为 user/temp
            return scheme == BDP_TTFILE_SCHEME && (host == APP_USER_DIR_NAME || host == APP_TEMP_DIR_NAME)
        } else {                                          // scheme 和 host 都不存在时才认为是合法的 package path
            return url.scheme == .none && url.host == .none
        }
    }

    public func isValidTTFile() -> Bool {
        guard let scheme = url.scheme, let host = url.host else {
            return false
        }
        return scheme == BDP_TTFILE_SCHEME && (host == APP_USER_DIR_NAME || host == APP_TEMP_DIR_NAME)
    }

    public func isValidPackageFile() -> Bool {
        return isValidSandboxFilePath() && !isValidTTFile() // 是 sandbox file 但不是 ttfile 的
    }

    /// 是否是 temp 文件夹内的文件，不包含 temp 目录本身
    ///
    /// ttfile://temp -> false
    /// ttfile://temp/ -> false
    /// ttfile://temp/foo -> true
    /// ttfile://temp/foo/ -> true
    ///
    public var isInTempDir: Bool {
        var path = rawValue

        if rawValue.hasSuffix("/") {
            path.removeLast(1)
        }
        return path != APP_FILE_TEMP_PREFIX() && (path.hasPrefix(APP_FILE_TEMP_PREFIX()))
    }

    /// 是否是 user 文件夹内的文件，不包含 user 目录本身
    ///
    /// ttfile://user -> false
    /// ttfile://user/ -> false
    /// ttfile://user/foo -> true
    /// ttfile://user/foo/ -> true
    ///
    public var isInUserDir: Bool {
        var path = rawValue

        if rawValue.hasSuffix("/") {
            path.removeLast(1)
        }

        return path != APP_FILE_USER_PREFIX() && (path.hasPrefix(APP_FILE_USER_PREFIX()))
    }

    /// ttfile user 目录
    public static let user: FileObject = {
        return try! FileObject(rawValue: APP_FILE_USER_PREFIX())
    }()

    /// ttfile temp 目录
    public static let temp: FileObject = {
        return try! FileObject(rawValue: APP_FILE_TEMP_PREFIX())
    }()

    /// ttfile package 目录
    public static let package: FileObject = {
        return try! FileObject(rawValue: APP_PKG_DIR)
    }()

    /// ttfile 随机路径
    public static func generateRandomTTFile(type: BDPFolderPathType, fileExtension: String? = nil) -> FileObject {
        var randomPath = BDPRandomString(15)
        if let ext = fileExtension, !ext.isEmpty {
            randomPath += ".\(ext)"
        }

        switch type {
        case .temp:
            return temp.appendingPathComponent(randomPath)
        case .user:
            return user.appendingPathComponent(randomPath)
        case .pkg:
            return package.appendingPathComponent(randomPath)
        @unknown default:
            assertionFailure("random folder type must handle!")
            return temp.appendingPathComponent(randomPath)
        }
    }

    public static func generateSpecificTTFile(type: BDPFolderPathType, pathComponment: String) -> FileObject {
        switch type {
        case .temp:
            return temp.appendingPathComponent(pathComponment)
        case .user:
            return user.appendingPathComponent(pathComponment)
        case .pkg:
            return package.appendingPathComponent(pathComponment)
        @unknown default:
            assertionFailure("specific folder type must handle!")
            return temp.appendingPathComponent(pathComponment)
        }
    }
}
