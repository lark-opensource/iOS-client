//
//  FileSystem+MicroAppAbsPath.swift
//  OPFoundation
//
//  Created by ByteDance on 2023/2/8.
//

import Foundation
import LarkStorage
// lint:disable lark_storage_migrate_check
public enum MicroAppAbsPath {
    case old(String)
    case new(AbsPath)
    
    var description: String {
        switch self {
        case .old(_):
            return "old"
        case .new:
            return "new"
        }
    }
}

extension MicroAppAbsPath {
    public func fileExists(isDirectory: UnsafeMutablePointer<Bool>?) -> Bool {
       switch self {
       case .old(let strPath):
           var b: ObjCBool = false
           let ret = FileManager.default.fileExists(atPath: strPath, isDirectory: &b)
           isDirectory?.pointee = b.boolValue
           return ret
       case .new(let absPath):
           return absPath.fileExists(isDirectory: isDirectory)
       }
   }
    
    
    public func isDirectory() -> Bool {
        switch self {
        case .old(let strPath):
            var isDirObjc: ObjCBool = ObjCBool(false)
            let exists = FileManager.default.fileExists(atPath: strPath, isDirectory: &isDirObjc)
            return exists && isDirObjc.boolValue
        case .new(let absPath):
            return absPath.isDirectory
        }
    }
    
    public func attributesOfItem() throws -> [FileAttributeKey: Any] {
        switch self {
        case .old(let strPath):
            return try FileManager.default.attributesOfItem(atPath: strPath)
        case .new(let absPath):
            return try absPath.attributesOfItem()
        }
    }
    
    public func attributesOfFileSystem() throws -> [FileAttributeKey: Any] {
        switch self {
        case .old(let strPath):
            return try FileManager.default.attributesOfFileSystem(forPath: strPath)
        case .new(let absPath):
            return try absPath.attributesOfFileSystem()
        }
    }
    
    public func contentsOfDirectory()throws -> [String] {
        switch self {
        case .old(let strPath):
            return try FileManager.default.contentsOfDirectory(atPath: strPath)
        case .new(let absPath):
            return try absPath.contentsOfDirectory_()
        }
    }

    public func enumerator() -> FileManager.DirectoryEnumerator? {
        switch self {
        case .old(let strPath):
            return  FileManager.default.enumerator(atPath: strPath)
        case .new(let absPath):
            return absPath.enumerator()?.base
        }
    }
}

///基于BDPFileSystemHelper封装
extension MicroAppAbsPath{
    
    public func fileSize() -> Int64 {
        switch self {
        case .old(let strPath):
            return BDPFileSystemHelper.size(withPath: strPath)
        case .new(let absPath):
            var isDir = false
            guard absPath.fileExists(isDirectory: &isDir) else{
                return 0
            }
            if isDir {
                var folderSize:Int64 = 0
                guard let childs = try? absPath.childrenOfDirectory(recursive: true) else{
                    return folderSize
                }
                for child in childs {
                    folderSize += Int64(child.fileSize ?? 0)
                }
                return folderSize
            }else {
                return Int64(absPath.fileSize ?? 0)
            }
        }
    }
    
}
// lint:enable lark_storage_migrate_check
