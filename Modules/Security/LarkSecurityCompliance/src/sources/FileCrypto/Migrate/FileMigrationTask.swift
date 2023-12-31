//
//  FileMigrationTask.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/24.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra
import LarkAccountInterface

final class FileMigrationTask {
    
    enum State: Int {
        case preparing
        case migrating
        case done
    }
    
    static let dirPath = NSTemporaryDirectory() + "security_temp/security_migration_dir/"
    
    @SafeWrapper var state: State = .preparing {
        didSet {
            if state == .done {
                try? file.close()
            }
        }
    }
    
    /// 文件迁移任务唯一 ID
    let migrationID: String
    /// 原始文件路径
    let path: String
  
    // 迁移后的文件路径，临时的
    let migratedPath: String

    // 原始文件最后更新时间点，使用密文覆盖原始文件路径时会先判断更新时间，如果时间落后则不进行覆盖
    let updatedTime: Date
    let size: Double
    
    let record = FileIORecord()
    
    let userResolver: UserResolver
    
    let file: AESFile
    
    let start = CACurrentMediaTime()
    
    init(userResolver: UserResolver, path: String, migrationID: String) throws {
        self.userResolver = userResolver
        self.path = path
        self.migrationID = migrationID
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let date = attrs[.modificationDate] as? Date
        self.updatedTime = date ?? Date()
        self.size = (attrs[.size] as? NSNumber)?.doubleValue ?? 0
        migratedPath = Self.dirPath + migrationID
        
        Self.createDirectoryIfNeeded()
        
        let userService = try userResolver.resolve(type: PassportUserService.self)
        let service = try userResolver.resolve(type: FileCryptoService.self)
        @Provider var passportService: PassportService
        
        let did = Int64(passportService.deviceID) ?? 0
        let uid = Int64(userService.user.userID) ?? 0
        let key = try service.deviceKey(did: did)
        let header = AESHeader(key: key, uid: uid, did: did)
        
        self.file = try AESFileFactory.createFile(deviceKey: key, header: header, filePath: migratedPath, option: .write)
    }
    
    // 数据迁移逻辑，将明文 data 转换成密文 data，然后存到临时目录中
    func migrateData(_ data: Data) throws {
        guard state == .migrating else { return }
        _ = try self.file.write(data: data, position: nil)
    }
    
    var canWriteBackward: Bool {
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: path)
            let date = attrs[.modificationDate] as? Date
            let size = (attrs[.size] as? NSNumber)?.doubleValue ?? 0
            let migratedAttr = try FileManager.default.attributesOfItem(atPath: migratedPath)
            let migratedSize = (migratedAttr[.size] as? NSNumber)?.doubleValue ?? 0
            return date == self.updatedTime && abs(migratedSize - size - Double(AESHeader.size)) <= 0.0001
        } catch {
            return false
        }
    }

    // 将密文文件迁移到原始文件路径
    func writeBackward() throws {
        let from = URL(fileURLWithPath: migratedPath)
        let to = URL(fileURLWithPath: path)
        _ = try FileManager.default.replaceItemAt(to, withItemAt: from, backupItemName: migrationID)
        let cost = CACurrentMediaTime() - start
        FileMigrationPoolImp.logger.info("write backward finished, path: \(path), cost: \(cost) size: \(size)byte")
        FileCryptoMonitor.migrationTask([
            "is_success": true,
            "cost": cost,
            "size": size,
            "file_extension": to.pathExtension
        ])
    }
    
    /// 迁移的数据不合法，删除掉
    func trashMigrateFile() throws {
        try FileManager.default.removeItem(atPath: migratedPath)
        let cost = CACurrentMediaTime() - start
        FileMigrationPoolImp.logger.info("trash migrated file finished, path: \(migratedPath), cost: \(cost) size: \(size)byte")
        FileCryptoMonitor.migrationTask([
            "is_success": false,
            "cost": cost,
            "size": size,
            "file_extension": URL(fileURLWithPath: path).pathExtension
        ])
    }
    
    private static func createDirectoryIfNeeded() {
        var isDirectory = ObjCBool(false)
        let fileExisted = FileManager.default.fileExists(atPath: Self.dirPath, isDirectory: &isDirectory)
        if !fileExisted || !isDirectory.boolValue {
            do {
                try FileManager.default.createDirectory(atPath: Self.dirPath, withIntermediateDirectories: true)
            } catch {
                FileMigrationPoolImp.logger.error("create migration directory failed: \(error)")
            }
        }
    }
}
