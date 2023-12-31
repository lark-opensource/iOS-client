//
//  AIFilePath.swift
//  LarkInlineAI
//
//  Created by GuoXinyi on 2023/5/16.
//

import LarkStorage

enum AIFilePath {
    case isoPath(IsoPath)
    
    // Path URL
    var pathURL: URL {
        switch self {
        case let .isoPath(path):
            return path.url
        }
    }
}

extension AIFilePath {
    // 路径
    var pathString: String {
        switch self {
        case .isoPath(let sandbox):
            return sandbox.absoluteString
        }
    }
    
    // 是否存在
    var exists: Bool {
        switch self {
        case .isoPath(let path):
            return path.exists
        }
    }
    
    var isDirectory: Bool {
        switch self {
        case .isoPath(let path):
            return path.isDirectory
        }
    }
    
    var fileAttribites: [FileAttributeKey: Any] {
        switch self {
        case let .isoPath(path):
            return path.attributes
        }
    }

    
    // 文件大小
    var fileSize: UInt64? {
        let sizeNumber = fileAttribites[FileAttributeKey.size] as? NSNumber
        return sizeNumber?.uint64Value
    }
    
    func set(fileAttributes: [FileAttributeKey: Any]) throws {
        switch self {
        case let .isoPath(path):
            try path.setAttributes(fileAttributes)
        }
    }
    
    // 文件属性
    var attributes: FileAttributes? {
        switch self {
        case .isoPath(let path):
            return path.attributes
        }
    }
    
    // 系统属性
    var systemAttributes: FileAttributes? {
        switch self {
        case .isoPath(let path):
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
                LarkInlineAILogger.error("Failed to create file, path:\(path.absoluteString) error:\(error.localizedDescription)")
                return false
            }
        }
    }
    
    func createFileIfNeeded(with data: Data?) -> Bool {
        switch self {
        case .isoPath(let path):
            do {
                try path.createFileIfNeeded(with: data)
                return true
            } catch {
                LarkInlineAILogger.error("Failed to create file, path:\(path.absoluteString) error:\(error.localizedDescription)")
                return false
            }
        }
  
    }
    
    // 创建文件路径
    func createDirectory(withIntermediateDirectories createIntermediates: Bool) throws {
        switch self {
        case .isoPath(let path):
            return try path.createDirectory(withIntermediateDirectories: createIntermediates)
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
    func moveItem(to toPath: AIFilePath) throws {
        switch self {
        case .isoPath(let path):
            // 取出 toPath
            switch toPath {
            case .isoPath(let isoPath):
                try path.moveItem(to: isoPath)
            }
        }
    }
    
    // 复制item
    func copyItem(to toPath: AIFilePath) throws {
        switch self {
        case .isoPath(let path):
            // 取出 toPath
            switch toPath {
            case .isoPath(let isoPath):
                try path.copyItem(to: isoPath)
            }
        }
    }
    
    // 删除item
    func removeItem() throws {
        switch self {
        case .isoPath(let path):
            return try path.removeItem()
        }
    }
    
    //适配move from是URL类型的
    func moveItemFromUrl(from: URL) throws {
        switch self {
        case .isoPath(let path):
            return try path.notStrictly.moveItem(from: AbsPath(from.path))
        }
    }
    //适配copy from是URL类型的
    func copyItemFromUrl(from: URL) throws {
        switch self {
        case .isoPath(let path):
            return try path.notStrictly.copyItem(from: AbsPath(from.path))
        }
    }
    
    // 当前路径下的所有文件或子路径
    func fileListInDirectory(recursive: Bool = false) -> [String]? {
        let paths = try? (recursive ? contentsOfDirectory() : contentsOfDirectory())
        return paths
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
        }
    }
    
}
