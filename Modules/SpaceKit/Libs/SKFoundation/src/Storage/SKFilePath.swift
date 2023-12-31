//
//  SKFilePath.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/16.
//

import Foundation
import LarkStorage

// lint:disable lark_storage_migrate_check

public enum SKFilePath {
    case isoPath(IsoPath)
    case absPath(AbsPath)
    
    // 只用来初始化 absPath
    // MARK: ⚠️ 使用 absPath 需要特别注意，传入的absPath 需要带有/前缀
    // eg： /a/b/c 通过 absPath 包装后还是：/a/b/c
    //      a/b/c 通过 absPath 包装后，可能会变成 FileManager.default.currentDirectoryPath + /a/b/c
    //  currentDirectoryPath 正常是当前包的bundle路径，也可能只有一个/ ，这里是统一存储做的事情
    public init(absPath: String) {
        let path = AbsPath(absPath)
        self = .absPath(path)
    }
    
    // 只用来初始化 absPath
    public init(absUrl: URL) {
        let path = AbsPath(url: absUrl)
        self = .absPath(path ?? AbsPath(""))
    }
}

public extension SKFilePath {
    
    // 路径
    var pathString: String {
        switch self {
        case .isoPath(let sandbox):
            return sandbox.absoluteString
        case .absPath(let absPath):
            return absPath.absoluteString
        }
    }
    
    // 是否存在
    var exists: Bool {
        switch self {
        case .isoPath(let path):
            return path.exists
        case .absPath(let absPath):
            return absPath.exists
        }
    }
    
    var isDirectory: Bool {
        switch self {
        case .isoPath(let path):
            return path.isDirectory
        case .absPath(let absPath):
            return absPath.isDirectory
        }
    }
    
    // 文件大小
    var fileSize: UInt64? {
        let sizeNumber = fileAttribites[FileAttributeKey.size] as? NSNumber
        return sizeNumber?.uint64Value
    }
    
    var fileAttribites: [FileAttributeKey: Any] {
        switch self {
        case let .isoPath(path):
            return path.attributes
        case let .absPath(path):
            return path.attributes
        }
    }

    func set(fileAttributes: [FileAttributeKey: Any]) throws {
        switch self {
        case let .isoPath(path):
            try path.setAttributes(fileAttributes)
            return
        case let .absPath(path):
            assertionFailure("absPath without setFileAttributes：\(path.absoluteString)")
            try FileManager.default.setAttributes(fileAttributes, ofItemAtPath: path.absoluteString)
        }
    }
    
    // 文件属性
    var attributes: FileAttributes? {
        switch self {
        case .isoPath(let path):
            return path.attributes
        case .absPath(let path):
            return path.attributes
        }
    }
    
    // 系统属性
    var systemAttributes: FileAttributes? {
        switch self {
        case .isoPath(let path):
            return try? path.attributesOfFileSystem()
        case .absPath(let path):
            return try? path.attributesOfFileSystem()

        }
    }
    
    //文件路径是否为空
    var isEmpty: Bool {
        return self.pathString.isEmpty
    }
    
    // 拼接路径
    func appendingRelativePath(_ relativePath: String) -> Self {
        switch self {
        case .isoPath(let path):
            return .isoPath(path.appendingRelativePath(relativePath))
        case .absPath(let path):
            return .absPath(path.appendingRelativePath(relativePath))
        }
    }
    
    // 返回上级目录
    var deletingLastPathComponent: Self {
        switch self {
        case .isoPath(let path):
            return .isoPath(path.deletingLastPathComponent)
        case .absPath(let path):
            return .absPath(path.deletingLastPathComponent)
        }
    }
    
    // 最后路径
    var lastPathComponent: String {
        switch self {
        case .isoPath(let path):
            return path.lastPathComponent
        case .absPath(let path):
            return path.lastPathComponent
        }
    }
    
    // 返回文件的本地显示名字
    var displayName: String {
        switch self {
        case .isoPath(let path):
            return path.displayName
        case .absPath(let path):
            return path.displayName
        }
    }
    
    // 返回FileHandle
    func fileReadingHandle() throws -> FileHandle {
        switch self {
        case .isoPath(let path):
            return try path.fileReadingHandle()
        case .absPath(let path):
            return try path.fileReadingHandle()
        }
    }
    
    //创建文件
    func createFile(with data: Data?) -> Bool {
        switch self {
        case .isoPath(let path):
            do {
                try path.createFile(with: data)
                return true
            } catch {
                DocsLogger.error("Failed to create file", extraInfo: ["path": path.absoluteString, "error": error.localizedDescription])
                return false
            }
        case .absPath(let path):
            assertionFailure("absPath without createFile：\(path.absoluteString)")
            // 兜底逻辑，走到这里需要关注
            FileManager.default.createFile(atPath: path.absoluteString, contents: data)
            return true
        }
    }
    
    func createFileIfNeeded(with data: Data?) -> Bool {
        switch self {
        case .isoPath(let path):
            do {
                try path.createFileIfNeeded(with: data)
                return true
            } catch {
                DocsLogger.error("Failed to create file", extraInfo: ["path": path.absoluteString, "error": error.localizedDescription])
                return false
            }
        case .absPath(let path):
            assertionFailure("absPath without createFileIfNeeded：\(path.absoluteString)")
            if !FileManager.default.fileExists(atPath: path.absoluteString) {
                return FileManager.default.createFile(atPath: path.absoluteString, contents: data)
            }
            return true
        }
  
    }
    
    // 创建文件路径
    func createDirectory(withIntermediateDirectories createIntermediates: Bool) throws {
        switch self {
        case .isoPath(let path):
            return try path.createDirectory(withIntermediateDirectories: createIntermediates)
        case .absPath(let path):
            assertionFailure("absPath without createDirectory：\(path.absoluteString)")
            return try FileManager.default.createDirectory(atPath: path.absoluteString, withIntermediateDirectories: createIntermediates, attributes: nil)
        }
    }
    
    @discardableResult
    func createDirectory() -> Bool {
        do {
            try self.createDirectory(withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }
    
    func createDirectoryIfNeeded(withIntermediateDirectories createIntermediates: Bool) throws {
        switch self {
        case .isoPath(let path):
            try path.createDirectoryIfNeeded(withIntermediateDirectories: createIntermediates)
        case .absPath(let path):
            assertionFailure("absPath without createDirectoryIfNeeded：\(path.absoluteString)")
            var b: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: path.absoluteString, isDirectory: &b)
            guard !exists else { return }
            try FileManager.default.createDirectory(atPath: path.absoluteString, withIntermediateDirectories: createIntermediates, attributes: nil)
        }
    }
    
    @discardableResult
    func createDirectoryIfNeeded() -> Bool {
        do {
            try self.createDirectoryIfNeeded(withIntermediateDirectories: true)
            return true
        } catch {
            return false
        }
    }
    
    //移动文件
    func moveItem(to toPath: SKFilePath) throws {
        switch self {
        case .isoPath(let path):
            // 取出 toPath
            switch toPath {
            case .isoPath(let isoPath):
                try path.moveItem(to: isoPath)
            case .absPath(let absPath):
                assertionFailure("should not be abs path \(absPath)")
                try FileManager.default.moveItem(atPath: path.absoluteString, toPath: absPath.absoluteString)
            }
            
        case .absPath(let path):
            // 取出 toPath
            switch toPath {
            case .isoPath(let isoPath):
                try isoPath.notStrictly.moveItem(from: path)
            case .absPath(let absPath):
                assertionFailure("should not be abs path \(absPath)")
                try FileManager.default.moveItem(atPath: path.absoluteString, toPath: absPath.absoluteString)
            }

        }
    }
    
    // 复制item
    func copyItem(to toPath: SKFilePath) throws {
        switch self {
        case .isoPath(let path):
            // 取出 toPath
            switch toPath {
            case .isoPath(let isoPath):
                try path.copyItem(to: isoPath)
            case .absPath(let absPath):
                assertionFailure("should not be absPath \(absPath)")
                try FileManager.default.copyItem(atPath: path.absoluteString, toPath: absPath.absoluteString)
            }
        case .absPath(let path):
            try toPath.copyItemFromUrl(from: path.url)
            return
        }
    }
    
    // 删除item
    func removeItem() throws {
        switch self {
        case .isoPath(let path):
            return try path.removeItem()
        case .absPath(let path):
            //因为absPath，没有copy方法，所以构建个isoPath，然后调用 copyItemFromUrl
            assertionFailure("absPath without removeItem：\(path.absoluteString)")
            try FileManager.default.removeItem(atPath: path.absoluteString)
            return
        }
    }
    
    // 返回当前文件夹下的路径
    func contentsOfDirectory() throws -> [String] {
        var result = [String]()
        switch self {
        case .isoPath(let path):
            path.eachChildren { iPath in
                if let relativePath = iPath.relativePath(to: path) {
                    result.append(relativePath)
                }
            }
            return result
        case .absPath(let path):
            path.eachChildren { iPath in
                if let relativePath = iPath.relativePath(to: path) {
                    result.append(relativePath)
                }
            }
            return result
        }
    }
    
    // 递归返回当前文件夹的路径
    func subpathsOfDirectory() throws -> [String] {
        var result = [String]()
        switch self {
        case .isoPath(let path):
            path.eachChildren(recursive: true) { iPath in
                if let relativePath = iPath.relativePath(to: path) {
                    result.append(relativePath)
                }
            }
            return result
        case .absPath(let path):
            path.eachChildren(recursive: true) { iPath in
                if let relativePath = iPath.relativePath(to: path) {
                    result.append(relativePath)
                }
            }
            return result
        }
    }
    
    // 文件列表,绝对路径
    func enumerator() -> [SKFilePath] {
        var result = [SKFilePath]()
        switch self {
        case .isoPath(let path):
            guard let pathArr = path.enumerator() else {
                return []
            }
            for file in pathArr {
                result.append(.isoPath(file))
            }
            return result
        case .absPath(let path):
            guard let pathArr = path.enumerator() else {
                return []
            }
            for file in pathArr {
                result.append(.absPath(file))
            }
            return result
        }
    }
    
    // 文件列表，相对路径
    func subpaths() -> [String] {
        var result = [String]()
        switch self {
        case .isoPath(let path):
            guard let pathArr = path.enumerator() else {
                return []
            }
            for file in pathArr {
                guard let relativePath = file.relativePath(to: path) else { continue }
                result.append(relativePath)
            }
            return result
        case .absPath(let path):
            guard let pathArr = path.enumerator() else {
                return []
            }
            for file in pathArr {
                guard let relativePath = file.relativePath(to: path) else { continue }
                result.append(relativePath)
            }
            return result
        }
    }
    
    // 读取data
    func contentsAtPath() -> Data? {
        switch self {
        case .isoPath(let path):
            do {
                let data = try Data.read(from: path)
                return data
            } catch {
                DocsLogger.error("contentsAtPath Failed", extraInfo: ["path": path.absoluteString, "error": error.localizedDescription])
                return nil
            }
        case .absPath(let path):
            do {
                let data = try Data.read(from: path)
                return data
            } catch {
                DocsLogger.error("contentsAtPath Failed", extraInfo: ["path": path.absoluteString, "error": error.localizedDescription])
                return nil
            }
        }
    }
}

// lint:enable lark_storage_migrate_check
