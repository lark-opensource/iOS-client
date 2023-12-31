//
//  MigrateFile.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/7/5.
//

import Foundation
import LarkSecurityComplianceInfra
import LarkContainer

// ignoring lark storage check for SBCipher implementation
// lint:disable lark_storage_check

protocol MigrateFile {
    var info: AESMetaInfo { get }
}

extension MigrateFile {
    func calculateDividedGroups() throws -> [UInt64] {
        let attributes = try FileManager.default.attributesOfItem(atPath: info.filePath)
        let size = attributes[.size] as? NSNumber
        let fileSize = size?.uint64Value ?? 0
        let divider = UInt64(100_000_000)
        let count = fileSize / divider
        var result = Array(repeating: divider, count: Int(count))
        let other = fileSize % divider
        if other > 0 {
            result.append(other)
        }
        return result
    }
}

final class MigrateFileV2: MigrateFile {
    
    let info: AESMetaInfo
    let userResolver: UserResolver
    let enableReplaceFile: Bool

    init(userResolver: UserResolver, info: AESMetaInfo) {
        self.info = info
        self.userResolver = userResolver
        enableReplaceFile = SCSetting.staticBool(scKey: .enableFileReplaceItem, userResolver: userResolver)
    }
    
    func doProcess() throws -> AESHeader? {
        let filePath = info.filePath
        let version = info.encryptVersion ?? AESFileFactory.cryptoVersion(filePath)
        
        let fileURL = URL(fileURLWithPath: filePath)
        let directory = NSTemporaryDirectory() + "security_temp_file/"
        let tmpPath = directory + fileURL.lastPathComponent
        
        var isDirectory = ObjCBool(true)
        if !FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: false)
        }
        
        switch version {
        case .v1:
            return try autoreleasepool {
                SCLogger.info("start migrate file from v1: \(info.filePath) to v2")
                let pathStream = DecryptPathStream(userResolver: userResolver, atFilePath: info.filePath)
                try pathStream.open(shouldAppend: false)

                let data = try pathStream.readAll()
                
                let header = AESHeader(key: info.deviceKey, uid: Int64(info.uid) ?? 0, did: Int64(info.did) ?? 0)
                let file = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: header, filePath: tmpPath, option: .write)
                _ = try file.write(data: data, position: nil)
                
                try file.close()
                if enableReplaceFile {
                    _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: info.filePath), withItemAt: URL(fileURLWithPath: tmpPath), backupItemName: UUID().uuidString)
                    SCLogger.info("use replace file with: \(info.filePath), from: \(tmpPath)")
                } else {
                    try FileManager.default.removeItem(atPath: info.filePath)
                    try FileManager.default.moveItem(atPath: tmpPath, toPath: info.filePath)
                    SCLogger.info("use remove file with: \(info.filePath), from: \(tmpPath)")
                }
                
                SCLogger.info("end migrate file from v1: \(info.filePath) to v2")
                return header
            }
        
        case .regular:
            SCLogger.info("start migrate file from reguar: \(info.filePath) to v2")
            let readHandle = try SCFileHandle(path: info.filePath, option: .read)

            let header = AESHeader(key: info.deviceKey, uid: Int64(info.uid) ?? 0, did: Int64(info.did) ?? 0)
            let fileWrite = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: header, filePath: tmpPath, option: .write)
            let groups = try calculateDividedGroups()
            for group in groups {
                try autoreleasepool {
                    guard let data = try readHandle.read(upToCount: Int(group)) else { return }
                    _ = try fileWrite.write(data: data, position: nil)
                }
            }

            try fileWrite.close()
            try readHandle.close()
            
            if enableReplaceFile {
                _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: info.filePath), withItemAt: URL(fileURLWithPath: tmpPath), backupItemName: UUID().uuidString)
                SCLogger.info("use replace file with: \(info.filePath), from: \(tmpPath)")
            } else {
                try FileManager.default.removeItem(atPath: info.filePath)
                try FileManager.default.moveItem(atPath: tmpPath, toPath: info.filePath)
                SCLogger.info("use remove file with: \(info.filePath), from: \(tmpPath)")
            }
            SCLogger.info("end migrate file from reguar: \(info.filePath) to v2")
            return header
        
        case .v2:
            #if SECURITY_DEBUG
            SCMonitor.info(business: .file_stream, eventName: "read_api_mistaked", category: ["path": info.filePath, "method": "crypto"])
            Logger.error("file_read_api_mistaked with path: \(info.filePath)")
            #endif
            return nil
        }
    }
}

final class MigrateFileRaw: MigrateFile {
    let info: AESMetaInfo
    let userResolver: UserResolver
    lazy var cryptoPath = CryptoPath(userResolver: userResolver)
    let enableReplaceFile: Bool
    
    init(userResolver: UserResolver, info: AESMetaInfo) {
        self.info = info
        self.userResolver = userResolver
        let settings = try? userResolver.resolve(type: SCSetting.self)
        enableReplaceFile = SCSetting.staticBool(scKey: .enableFileReplaceItem, userResolver: userResolver)
    }
    
    func doProcess() throws {
        let filePath = info.filePath
        let version = info.encryptVersion ?? AESFileFactory.cryptoVersion(filePath)
        switch version {
        case .v1:
            SCLogger.info("start migrate file from v1: \(info.filePath) to regular")
            let decryptPath = try cryptoPath.decrypt(filePath)
            if enableReplaceFile {
                _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: filePath), withItemAt: URL(fileURLWithPath: decryptPath), backupItemName: UUID().uuidString)
                SCLogger.info("use replace file with: \(filePath), from: \(decryptPath)")
            } else {
                try FileManager.default.removeItem(atPath: filePath)
                try FileManager.default.moveItem(atPath: decryptPath, toPath: filePath)
                SCLogger.info("use remove file with: \(filePath), from: \(decryptPath)")
            }
            SCLogger.info("end migrate file from v1: \(info.filePath) to regular")
            
        case .v2:
            SCLogger.info("start migrate file from v2: \(info.filePath) to regular")
            let header = try AESHeader(filePath: filePath)
            try header.checkV2Header(did: info.did, uid: info.uid, deviceKey: info.deviceKey)
            let aesFile = try AESFileFactory.createFile(deviceKey: info.deviceKey, header: header, filePath: info.filePath, option: .read)
            
            let directory = NSTemporaryDirectory() + "security_temp_file/"
            let tmpPath = directory + UUID().uuidString
            
            var isDirectory = ObjCBool(true)
            if !FileManager.default.fileExists(atPath: directory, isDirectory: &isDirectory) {
                try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: false)
            }
            if FileManager.default.fileExists(atPath: tmpPath) {
                try FileManager.default.removeItem(atPath: tmpPath)
            }
            FileManager.default.createFile(atPath: tmpPath, contents: nil)
            
            let groups = try calculateDividedGroups()
            let fileWrite = try SCFileHandle(path: tmpPath, option: .write)
            for group in groups {
                try autoreleasepool {
                    let data = try aesFile.read(maxLength: UInt32(group), position: nil)
                    try fileWrite.write(contentsOf: data)
                }
            }
            try fileWrite.close()
            try aesFile.close()
            if enableReplaceFile {
                _ = try FileManager.default.replaceItemAt(URL(fileURLWithPath: filePath), withItemAt: URL(fileURLWithPath: tmpPath), backupItemName: UUID().uuidString)
                SCLogger.info("use replace file with: \(filePath), from: \(tmpPath)")
            } else {
                try FileManager.default.removeItem(atPath: filePath)
                try FileManager.default.moveItem(atPath: tmpPath, toPath: filePath)
                SCLogger.info("use remove file with: \(filePath), from: \(tmpPath)")
            }
            
            SCLogger.info("end migrate file from v2: \(info.filePath) to regular")
            
        case .regular:
            break
        }
    }
}
