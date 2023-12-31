//
//  MicroAppPath.swift
//  TTMicroApp
//
//  Created by ByteDance on 2023/1/18.
//

import Foundation
import LarkStorage
// lint:disable lark_storage_migrate_check
public enum MicroAppIsoPath {
    case old(String)
    case new(IsoPath)
    
    var description: String {
        switch self {
        case .old(_):
            return "old"
        case .new:
            return "new"
        }
    }
}

extension MicroAppIsoPath {
    
    public func write(data: Data) throws {
        switch self {
        case .old(let strPath):
            try data.write(to: URL(fileURLWithPath: strPath), options: .atomic)
        case .new(let isoPath):
            try data.write(to: isoPath)
        }
    }
    
    public func write(str: String, encoding: String.Encoding) throws {
        switch self {
        case .old(let strPath):
            try str.write(toFile: strPath, atomically: true, encoding: encoding)
        case .new(let isoPath):
            try str.write(to: isoPath, atomically: true, encoding: encoding)
        }
    }

    public func write(dict: NSDictionary) -> Bool {
        switch self {
        case .old(let strPath):
            return dict.write(toFile: strPath, atomically: true)
        case .new(let isoPath):
            do {
                try dict.write(to: isoPath, atomically: true)
                return true
            } catch  {
                return false
            }
        }
    }
        
    public func fileWritingHandle() throws -> FileHandle {
        let fileHandle:FileHandle
        switch self {
        case .old(let strPath):
            fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: strPath))
        case .new(let isoPath):
            fileHandle = try isoPath.fileWritingHandle()
        }
        return fileHandle
    }
    
    public func fileWritingHandleV2(append shouldAppend: Bool) throws -> SBFileHandle {
        let fileHandle:SBFileHandle
        switch self {
        case .old(let strPath):
            fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: strPath)).sb
        case .new(let isoPath):
            fileHandle = try isoPath.fileHandleForWriting(append: shouldAppend)
        }
        return fileHandle
    }
    
    public func fileUpdatingHandle() throws -> FileHandle {
        let fileHandle:FileHandle
        switch self {
        case .old(let strPath):
            fileHandle = try FileHandle(forUpdating: URL(fileURLWithPath: strPath))
        case .new(let isoPath):
            fileHandle = try isoPath.fileUpdatingHandle()
        }
        return fileHandle
    }
    
    public func readData() throws -> Data {
        switch self {
        case .old(let strPath):
            return try Data(contentsOf: URL(fileURLWithPath: strPath))
        case .new(let isoPath):
            return try Data.read(from: isoPath)
        }
     }
     
     public func readString() throws -> String {
         switch self {
         case .old(let strPath):
             return try String(contentsOf: URL(fileURLWithPath: strPath))
         case .new(let isoPath):
             return try String.read(from: isoPath)
         }
     }
     
     public func readDict() -> NSDictionary? {
         switch self {
         case .old(let strPath):
             return NSDictionary(contentsOfFile: strPath)
         case .new(let isoPath):
            return try? NSDictionary.read(from: isoPath)
         }
     }
     
     public func fileReadingHandle() throws -> FileHandle {
         let fileHandle:FileHandle
         switch self {
         case .old(let strPath):
             fileHandle = try FileHandle(forReadingFrom: URL(fileURLWithPath: strPath))
         case .new(let isoPath):
             fileHandle = try isoPath.fileReadingHandle()
         }
         return fileHandle
     }
    
    public func copyItem(fromPath: String) throws {
        switch self {
        case .old(let toStrPath):
            try FileManager.default.copyItem(atPath: fromPath, toPath: toStrPath)
        case .new(let toIsoPath):
            try toIsoPath.copyItem(from: AbsPath(fromPath))
        }
    }
    
    public func moveItem(fromPath: String) throws {
        switch self {
        case .old(let toStrPath):
            try FileManager.default.moveItem(atPath: fromPath, toPath: toStrPath)
        case .new(let toIsoPath):
            try toIsoPath.notStrictly.moveItem(from: AbsPath(fromPath))
        }
    }
    
    public func removeItem() throws {
        switch self {
        case .old(let strPath):
            try FileManager.default.removeItem(atPath: strPath)
        case .new(let isoPath):
            try isoPath.removeItem()
        }
    }
    
    public func createDirectory(withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        switch self {
        case .old(let strPath):
            try FileManager.default.createDirectory(atPath: strPath, withIntermediateDirectories: createIntermediates, attributes: attributes)
        case .new(let isoPath):
            try isoPath.createDirectory(withIntermediateDirectories: createIntermediates, attributes: attributes)
        }
    }
    
    public func createFile(contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        switch self {
        case .old(let strPath):
            return FileManager.default.createFile(atPath: strPath, contents: data, attributes: attr)
        case .new(let isoPath):
            do {
                try isoPath.createFile(with: data, attributes: attr)
                return true
            } catch {
                return false
            }
        }
    }
    
}

///旧实现基于BDPFileSystemHelper
extension MicroAppIsoPath {
    public func contents() -> Data? {
        switch self {
        case .old(let strPath):
            return FileManager.default.contents(atPath: strPath)
        case .new(let isoPath):
            do {
                let data = try Data.read(from: isoPath)
                return data
            } catch {
                return nil
            }
        }
    }
    
    public func removeFolderIfNeed() -> Bool{
        switch self {
        case .old(let strPath):
            return BDPFileSystemHelper.removeFolderIfNeed(strPath)
        case .new(let isoPath):
            if isoPath.fileExists(isDirectory: nil){
                do {
                    try isoPath.removeItem()
                    return true
                } catch  {
                    return false
                }
            }
            return true
        }
    }
    
    public func createFolderIfNeed() -> Bool{
        switch self {
        case .old(let strPath):
            return BDPFileSystemHelper.createFolderIfNeed(strPath)
        case .new(let isoPath):
            if !isoPath.fileExists(isDirectory: nil){
                do {
                    try isoPath.createDirectory(withIntermediateDirectories: true, attributes: nil)
                    return true
                } catch  {
                    return false
                }
            }
            return true
        }
    }
}
// lint:enable lark_storage_migrate_check
