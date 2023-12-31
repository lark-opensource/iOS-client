//
//  SKFilePath+ReadWrite.swift
//  SKFoundation
//
//  Created by huangzhikai on 2022/11/16.
//

import Foundation
import LarkStorage
import LarkFileKit

extension UIImage {
    
    public static func read(from: SKFilePath) throws -> Self {

        switch from {
        case .isoPath(let isoPath):
            return try self.read(from: isoPath)
        case .absPath(let absPath):
            return try self.read(from: absPath)
        }
    }

    public func write(to: SKFilePath, atomically: Bool = true) throws {
        switch to {
        case .isoPath(let isoPath):
            try self.write(to: isoPath, atomically: atomically)
        case .absPath(let absPath):
            assertionFailure("absPath without image write to path：\(absPath.absoluteString)")
            return
        }
    }
}

extension String {
    public static func read(from: SKFilePath, encoding: Encoding = .utf8) throws -> Self {
        switch from {
        case .isoPath(let path):
            return try String.read(from: path, encoding: encoding)
        case .absPath(let path):
            return try String.read(from: path, encoding: encoding)
        }
    }

    public func write(to: SKFilePath, atomically: Bool = true, encoding: Encoding = .utf8) throws {
        switch to {
        case .isoPath(let path):
            return try self.write(to: path, atomically: atomically, encoding: encoding)
        case .absPath(let path):
            assertionFailure("absPath without string write to path：\(path.absoluteString)")
            return
        }
    }
    
}

extension Data {
    public func write(to: SKFilePath, options: Data.WritingOptions = []) throws {
        
        //有些同学调用写入数据方法，但文件路径没有创建，会导致写入失败，需要自己创建好路径，再调用写入方法
        //或者使用封装的SKFilePath writeFile(with contents: Data, mode: WriteFileMode) -> Bool 方法
        //非DEBUG包进行兜底创建路径
        let writeDataPath = to.deletingLastPathComponent
        if !writeDataPath.exists {
#if DEBUG
            assertionFailure("path is not exist, please createDirectory")
#else
            try writeDataPath.createDirectory(withIntermediateDirectories: true)
#endif
        }
        
        switch to {
        case .isoPath(let path):
            try self.write(to: path)
        case .absPath(let path):
            //写数据到bundle里面的时候，bundle是abspath
            //不允许使用absPath写数据，这里暂时线上走兜底处理
#if DEBUG
            assertionFailure("absPath disable to write，please use isoPath")
#else
            // lint:disable:next lark_storage_check
            try write(to: URL(fileURLWithPath: path.absoluteString), options: .atomic)
#endif
        }
    }
    
    public static func read(from: SKFilePath, options: Data.ReadingOptions = []) throws -> Self {
        switch from {
        case .isoPath(let path):
            return try Data.read(from: path, options: options)
        case .absPath(let path):
            return try Data.read(from: path, options: options)
        }
    }
    
}

extension FileHandle {
    
    public static func getHandle(forWritingAtPath: SKFilePath) throws -> FileHandle? {
        switch forWritingAtPath {
        case .isoPath(let path):
            return try? path.fileWritingHandle()
        case .absPath(let absPath):
            #if DEBUG
                assertionFailure("path is not exist, plesas createDirectory")
                return nil
            #else
            // 线上包做个兜底处理，Debug环境跑出异常
                return FileHandle(forWritingAtPath: absPath.absoluteString)   // lint:disable:this lark_storage_migrate_check
            #endif
        }
    }

}



