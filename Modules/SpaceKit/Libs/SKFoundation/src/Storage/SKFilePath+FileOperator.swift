//
//  SKFilePath+FileOperator.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/23.
//

import Foundation
import AVFoundation
import LarkStorage

//迁移 FileOperator 文件下的方法
extension SKFilePath {
    // Path URL
    public var pathURL: URL {
        switch self {
        case let .isoPath(path):
            return path.url
        case let .absPath(path):
            return path.url
        }
    }
    
    // 当前路径下的所有文件或子路径
    public func fileListInDirectory(recursive: Bool = false) -> [String]? {
        let paths = try? (recursive ? contentsOfDirectory() : contentsOfDirectory())
        return paths
    }
    
    // 删除当前路径下的所有文件
    public func cleanDir() throws {
        let paths = fileListInDirectory() ?? []
        try paths.forEach { path in
            try self.appendingRelativePath(path).removeItem()
        }
    }
    
    // 将当前文件copy到目标路径
    // overwrite 为ture， 重写目标路径文件
    @discardableResult
    public func copyItem(to targetPath: SKFilePath, overwrite: Bool = true) -> Bool {
        guard exists else {
            assertionFailure("Source path is not exist.")
            return false
        }
        
        let targetDirPath = targetPath.deletingLastPathComponent
        if !targetDirPath.exists {
            do {
                try targetDirPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                DocsLogger.error("create directory failed", error: error)
                return false
            }
        }
        if overwrite, targetPath.exists {
            do {
                try targetPath.removeItem()
            } catch {
                DocsLogger.error("remove target path item failed", error: error)
                return false
            }
        }
        
        do {
            try copyItem(to: targetPath)
            return true
        } catch {
            DocsLogger.error("copy item to target path failed", error: error)
            return false
        }
        
    }
    
    @discardableResult
    public func moveItem(to targetPath: SKFilePath, overwrite: Bool = true) -> Bool {
        guard self != targetPath else {
            return true
        }
        guard exists else {
            assertionFailure("Source path is not exist.")
            return false
        }
        
        let targetDirPath = targetPath.deletingLastPathComponent
        if !targetDirPath.exists {
            do {
                try targetDirPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                DocsLogger.error("create directory failed", error: error)
                return false
            }
        }
        if targetPath.exists {
            if overwrite {
                do {
                    try targetPath.removeItem()
                } catch {
                    DocsLogger.error("move item overwrite failed", error: error)
                    return false
                }
            } else {
                DocsLogger.info("move item failed because target item exist and not overwrite")
                return false
            }
        }
        
        do {
            try moveItem(to: targetPath)
            return true
        } catch {
            DocsLogger.error("move item to target path failed", error: error)
            return false
        }
        
    }
    
    public enum WriteFileMode {
        case over
        case append
        case none
    }
    public func writeFile(with contents: Data, mode: WriteFileMode) -> Bool {
        if exists {
            switch mode {
            case .over:
                do {
                    try removeItem()
                } catch {
                    DocsLogger.error("write file failed", error: error)
                    return false
                }
                
            case .append:
                let fileHandler = try? FileHandle.getHandle(forWritingAtPath: self)
                fileHandler?.seekToEndOfFile()
                fileHandler?.write(contents)
                fileHandler?.closeFile()
                return true
            case .none: return false
            }
        }
        
        let targetDirPath = deletingLastPathComponent
        if !targetDirPath.exists {
            do {
                try targetDirPath.createDirectory(withIntermediateDirectories: true)
            } catch {
                DocsLogger.error("create dir failed", error: error)
                return false
            }
        }
        
        do {
            try contents.write(to: self)
            return true
        } catch {
            DocsLogger.error("write data failed", error: error)
            return false
        }
    }
    
    public static func getFreeDiskSpace() -> Int64? {
        let docDir: SKFilePath = SKFilePath.absPath(AbsPath.home)
        guard let attrDict = docDir.systemAttributes,
              let freeSize = attrDict[.systemFreeSize] as? NSNumber else {
            return nil
        }
        return freeSize.int64Value
    }
    
    // 返回是否是文件
    // 如果之前是Url判断isFile，可以把url转成 AbsPath再使用这个方法
    public func isFile() -> Bool {
        guard let attributes = self.attributes, let fileType = attributes[.type] as? FileAttributeType,
            fileType == .typeRegular else { return false }
        return true
    }
    
    // 是否是文件夹
    public func isDirectoryType() -> Bool {
        guard let attributes = self.attributes, let fileType = attributes[.type] as? FileAttributeType,
            fileType == .typeDirectory else { return false }
        return true
    }
    
    //递归查找文件下所有文件加起来的大小
    public func sizeExt() -> UInt64? {
        guard self.exists else {
            return nil
        }
        if self.isFile() {
            return self.fileSize
        } else if self.isDirectoryType() {
            return self.sizeOfDirectory()
        } else {
            return nil
        }
    }

    public func sizeOfDirectory() -> UInt64? {
        guard self.isDirectoryType(), self.exists, let paths = self.fileListInDirectory(recursive: true) else {
            return nil
        }
        let fullPaths = paths.map { self.appendingRelativePath($0) }
        let foldSize = fullPaths.reduce(0) { (result, path) -> UInt64 in
            return result + (path.fileSize ?? 0)
        }
        return foldSize
    }
    
    public func getFileName() -> String {
        return pathURL.lastPathComponent
    }
    
    public func getVideoCodecType() -> String? {
        let asset = AVURLAsset(url: self.pathURL)
        let videoTracks = asset.tracks(withMediaType: .video)
        guard let description = videoTracks.first?.formatDescriptions.first else {
            return nil
        }
        let desc = CMFormatDescriptionGetMediaSubType(description as! CMFormatDescription)
        return desc.toString()
    }
}

// nolint: magic_number
extension FourCharCode {
    func toString() -> String {
        let n = Int(self)
        guard let char1 = UnicodeScalar((n >> 24) & 255) else { return "" }
        var s: String = String(char1)
        if let char2 = UnicodeScalar((n >> 16) & 255) {
            s.unicodeScalars.append(char2)
        }
        if let char3 = UnicodeScalar((n >> 8) & 255) {
            s.unicodeScalars.append(char3)
        }
        if let char4 = UnicodeScalar(n & 255) {
            s.unicodeScalars.append(char4)
        }
        return s.trimmingCharacters(in: NSCharacterSet.whitespaces)
    }
}
