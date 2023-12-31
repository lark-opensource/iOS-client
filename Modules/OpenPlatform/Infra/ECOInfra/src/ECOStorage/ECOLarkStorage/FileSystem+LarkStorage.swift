//
//  FileSystem+LarkStorage.swift
//  TTMicroApp
//
//  Created by ByteDance on 2023/1/18.
//

import Foundation
import LarkStorage
import LarkAccountInterface
import LarkContainer
import LKCommonsLogging
import ECOProbe

@objcMembers
public final class LSFileSystem: NSObject {
    private static let logger = Logger.oplog(LSFileSystem.self, category: "LSFileSystem")

    public static let main = LSFileSystem(domain: Domain.biz.microApp)
    public static let openBusiness = LSFileSystem(domain: Domain.biz.microApp.child("openBusiness"))
    public static let fileLog = LSFileSystem(domain: Domain.biz.microApp.child("fileLog"))
    private let domain: DomainType
    private var isUserSpace: Bool = true

    private init(domain: DomainType) {
        self.domain = domain
        super.init()
    }

    //LarkStorage FileSystem fg
    public static var isoPathEnable: Bool = {
        return EMAFeatureGating.boolValue(forKey: "openplatform.filesystem.larkstorage.enable") || EMAFeatureGating.boolValue(forKey: "openplatform.filesystem.larkstorage.enable.new")
    }()
    
    public func global() -> LSFileSystem {
        self.isUserSpace = false
        return self
    }
    
    private func microAppIsoPath(filePath: String, useEncrypt: Bool = false, function: String = #function) -> MicroAppIsoPath {
        let microAppPath: MicroAppIsoPath
        if Self.isoPathEnable {
            do {
                // TODOZJX
                let parsed = try IsoPath.parse(from: filePath,
                                               space: isUserSpace ? .user(id: AccountServiceAdapter.shared.currentChatterId) : .global,
                                               domain: self.domain)
                if useEncrypt {
                    Self.logger.info("LSFileSystem encrypt file:\(filePath),function:\(function)")
                    microAppPath = .new(parsed.usingCipher())
                }else {
                    microAppPath = .new(parsed)
                }
            } catch {
                assertionFailure("parse isoPath fail")
                microAppPath = .old(filePath)
                OPMonitor(EPMClientOpenPlatformInfraFileLarkstorageCode.openplatform_larkstorage_info)
                    .addCategoryValue("parse_fail_path", filePath)
                    .addCategoryValue("function", function)
                    .flush()
            }
        }else {
            microAppPath = .old(filePath)
        }
        return microAppPath
    }
    
    private static func microAppAbsPath(filePath: String, function: String = #function) -> MicroAppAbsPath {
        let microAppPath: MicroAppAbsPath
        if Self.isoPathEnable {
            microAppPath = .new(AbsPath(filePath))
        }else {
            microAppPath = .old(filePath)
        }
        return microAppPath
    }
}

//abs path
extension LSFileSystem {
    /// 指定路径文件&目录是否存在
    /// - Parameters:
    ///   - filePath: 文件路径
    public static func fileExists(filePath: String, isDirectory: UnsafeMutablePointer<Bool>? = nil) -> Bool {
        let path = self.microAppAbsPath(filePath: filePath)
        return path.fileExists(isDirectory: isDirectory)
    }
    
    /// 是否是dir
    /// - Parameters:
    ///   - filePath: 文件路径
    public static func isDirectory(filePath: String) -> Bool {
        let path = self.microAppAbsPath(filePath: filePath)
        return path.isDirectory()
    }
    
    /// 指定路径的attributes
    /// - Parameters:
    ///   - filePath: 文件路径
    public static func attributesOfItem(atPath: String) throws -> [FileAttributeKey: Any] {
        let path = self.microAppAbsPath(filePath: atPath)
        return try path.attributesOfItem()
    }
    
    public static func attributesOfFileSystem(atPath: String) throws -> [FileAttributeKey: Any] {
        let path = self.microAppAbsPath(filePath: atPath)
        return try path.attributesOfFileSystem()
    }
    
    /// 指定目录的items
    /// - Parameters:
    ///   - filePath: 文件路径
    public static func contentsOfDirectory(dirPath: String) throws -> [String] {
        let path = self.microAppAbsPath(filePath: dirPath)
        return try path.contentsOfDirectory()
    }
    
    /// 指定path的enumerator
    /// - Parameters:
    ///   - path: 文件路径
    public static func enumerator(atPath path: String) -> FileManager.DirectoryEnumerator? {
        let path = self.microAppAbsPath(filePath: path)
        return path.enumerator()
    }
    
    /// 原BDPFileSystemHelper.fileSize
    /// - Parameters:
    ///   - filePath: 文件/目录路径
    public static func fileSize(path: String) -> Int64 {
        let absPath = self.microAppAbsPath(filePath: path)
        return absPath.fileSize()
    }

    
}

//iso path
extension LSFileSystem {
     /// 写入data到指定路径
     /// - Parameters:
     ///   - data: 写入的data数据
     ///   - filePath: 文件路径
     public func write(data: Data, to filePath: String) throws {
         try self.write(data: data, to: filePath, useEncrypt: false)
     }
    
    /// 写入data到指定路径
    /// - Parameters:
    ///   - data: 写入的data数据
    ///   - filePath: 文件路径
    ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
    public func write(data: Data, to filePath: String, useEncrypt: Bool) throws {
        let path = self.microAppIsoPath(filePath: filePath, useEncrypt: useEncrypt)
        try path.write(data: data)
    }
    
     /// 写入string到指定路径
     /// - Parameters:
     ///   - data: 写入的string数据
     ///   - filePath: 文件路径
    public func write(str: String, to filePath: String, encoding: String.Encoding) throws {
        try self.write(str: str, to: filePath, encoding: encoding, useEncrypt: false)
     }
    
    /// 写入string到指定路径
    /// - Parameters:
    ///   - data: 写入的string数据
    ///   - filePath: 文件路径
    ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
   public func write(str: String, to filePath: String, encoding: String.Encoding, useEncrypt: Bool) throws {
       let path = self.microAppIsoPath(filePath: filePath, useEncrypt: useEncrypt)
        try path.write(str: str, encoding: encoding)
    }
    
   
     /// 写入字典到指定路径
     /// - Parameters:
     ///   - dict: 写入的dict数据
     ///   - filePath: 文件路径
    @discardableResult
    public func write(dict: NSDictionary, to filePath: String) -> Bool {
        self.write(dict: dict, to: filePath, useEncrypt: false)
     }
    
    /// 写入字典到指定路径
    /// - Parameters:
    ///   - dict: 写入的dict数据
    ///   - filePath: 文件路径
    ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
    @discardableResult
    public func write(dict: NSDictionary, to filePath: String, useEncrypt: Bool = false) -> Bool {
        let path = self.microAppIsoPath(filePath: filePath, useEncrypt: useEncrypt)
        return path.write(dict: dict)
    }

     /// 获取writingFileHandle
     /// - Parameters:
     ///   - filePath: 文件路径
     public func fileWritingHandle(filePath: String) throws -> FileHandle {
         let path = self.microAppIsoPath(filePath: filePath)
         return try path.fileWritingHandle()
     }
    
    /// 获取writingFileHandle
    /// - Parameters:
    ///   - filePath: 文件路径
    ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
    public func fileWritingHandleV2(filePath: String, append shouldAppend: Bool, useEncrypt: Bool = false) throws -> SBFileHandle {
        let path = self.microAppIsoPath(filePath: filePath, useEncrypt: useEncrypt)
        return try path.fileWritingHandleV2(append: shouldAppend)
    }
         
     /// 获取updatingFileHandle
     /// - Parameters:
     ///   - filePath: 文件路径
     public func fileUpdatingHandle(filePath: String) throws -> FileHandle {
         let path = self.microAppIsoPath(filePath: filePath)
         return try path.fileUpdatingHandle()
     }
    
    /// 读指定路径的数据
    /// - Parameters:
    ///   - filePath: 文件路径
    public func readData(from filePath: String) throws -> Data {
        let path = self.microAppIsoPath(filePath: filePath)
        return try path.readData()
    }
    
    /// 读指定路径的数据
    /// - Parameters:
    ///   - filePath: 文件路径
    public func readString(from filePath: String) throws -> String {
        let path = self.microAppIsoPath(filePath: filePath)
        return try path.readString()
    }
    
    /// 读指定路径的数据
    /// - Parameters:
    ///   - filePath: 文件路径
    public func readDict(from filePath: String) -> NSDictionary?{
        let path = self.microAppIsoPath(filePath: filePath)
        return path.readDict()
    }
    
    /// 获取readingFileHandle
    /// - Parameters:
    ///   - filePath: 文件路径
    public func fileReadingHandle(filePath: String) throws -> FileHandle {
        let path = self.microAppIsoPath(filePath: filePath)
        return try path.fileReadingHandle()
    }
    
     /// 复制文件到指定路径
     /// - Parameters:
     ///   - srcPath: 源文件路径
     ///   - dstPath: 目标路径
     public func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
         try self.copyItem(atPath: srcPath, toPath: dstPath, useEncrypt: false)
     }
    
     /// 复制文件到指定路径
     /// - Parameters:
     ///   - srcPath: 源文件路径
     ///   - dstPath: 目标路径
     ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
     public func copyItem(atPath srcPath: String, toPath dstPath: String, useEncrypt: Bool = false) throws {
         let path = self.microAppIsoPath(filePath: dstPath, useEncrypt: useEncrypt)
         try path.copyItem(fromPath: srcPath)
     }
     
     /// 移动文件到指定路径
     /// - Parameters:
     ///   - srcPath: 源文件路径
     ///   - dstPath: 目标路径
     public func moveItem(atPath srcPath: String, toPath dstPath: String) throws {
         try self.moveItem(atPath: srcPath, toPath: dstPath, useEncrypt: false)
     }
    
    /// 移动文件到指定路径
    /// - Parameters:
    ///   - srcPath: 源文件路径
    ///   - dstPath: 目标路径
    ///   - useEncrypt: 是否加密（加密只在MicroAppIsoPath为new生效）
    public func moveItem(atPath srcPath: String, toPath dstPath: String, useEncrypt: Bool = false) throws {
        let path = self.microAppIsoPath(filePath: dstPath, useEncrypt: useEncrypt)
        try path.moveItem(fromPath: srcPath)
    }
     
     /// 移除指定路径文件/目录
     /// - Parameters:
     ///   - atPath: 文件/目录路径
     public func removeItem(atPath: String) throws {
         let path = self.microAppIsoPath(filePath: atPath)
         try path.removeItem()
     }
     
     /// 创建目录
     /// - Parameters:
     ///   - srcPath: 目录路径
     public func createDirectory(atPath srcPath: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
         let path = self.microAppIsoPath(filePath: srcPath)
         try path.createDirectory(withIntermediateDirectories: createIntermediates, attributes: attributes)
     }
       
     /// 创建文件
     /// - Parameters:
     ///   - atPath: 目录路径
     public func createFile(atPath: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
         let path = self.microAppIsoPath(filePath: atPath)
         return path.createFile(contents: data, attributes: attr)
     }
    
    /// 原BDPFileSystemHelper.removeFolderIfNeed
    /// - Parameters:
    ///   - folderPath: 目标路径
    public func removeFolderIfNeed(folderPath: String) -> Bool{
        let path = self.microAppIsoPath(filePath: folderPath)
        return path.removeFolderIfNeed()
    }
    
    /// 原BDPFileSystemHelper.createFolderIfNeed
    /// - Parameters:
    ///   - folderPath: 目标路径
    public func createFolderIfNeed(folderPath: String) -> Bool{
        let path = self.microAppIsoPath(filePath: folderPath)
        return path.createFolderIfNeed()
    }
}

extension LSFileSystem {
    public func contents(filePath: String) -> Data? {
        let path = self.microAppIsoPath(filePath: filePath)
        return path.contents()
    }
}
