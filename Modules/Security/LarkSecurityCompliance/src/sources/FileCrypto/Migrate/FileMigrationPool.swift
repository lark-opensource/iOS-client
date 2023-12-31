//
//  FileMigrationPool.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2023/11/24.
//

import Foundation
import LarkContainer
import LarkSecurityComplianceInfra

// 文件处理的顺序是：enter -> start read/write -> leave -> stop read/write

protocol FileMigrationRecord {
    func startReadFile(withHandle handle: FileRecordHandle)
    func stopReadFile(withHandle handle: FileRecordHandle)
    func startWriteFile(withHandle handle: FileRecordHandle)
    func stopWriteFile(withHandle handle: FileRecordHandle)
}

protocol FileMigrationPool: FileMigrationRecord {
    func enter(handle: FileMigrationHandle)
    func migrateData(_ data: Data, forHandle handle: FileMigrationHandle)
    func leave(handle: FileMigrationHandle)
    
    func cleanExpiredMigrationFiles()
}

final class FileMigrationPoolEmpty: FileMigrationPool {
    init() {
        FileMigrationPoolImp.logger.info("init empty file migration pool")
    }
    func enter(handle: FileMigrationHandle) { }
    func migrateData(_ data: Data, forHandle handle: FileMigrationHandle) { }
    func leave(handle: FileMigrationHandle) { }
    
    func startReadFile(withHandle handle: FileRecordHandle) { }
    func stopReadFile(withHandle handle: FileRecordHandle) { }
    func startWriteFile(withHandle handle: FileRecordHandle) { }
    func stopWriteFile(withHandle handle: FileRecordHandle) { }
    
    func cleanExpiredMigrationFiles() { }
}

final class FileMigrationPoolImp: FileMigrationPool {
    
    let taskQueue = DispatchQueue(label: "file.migration.task.queue")
    
    @SafeWrapper private var tasks: [String: FileMigrationTask] = [:]
    @SafeWrapper private var filePaths = [String]()
    
    static let logger = Logger(tag: "[file_crypto][file_migration]")
    
    let userResolver: UserResolver
    
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        Self.logger.info("init file migration pool")
    }

    func enter(handle: FileMigrationHandle) {
        let path = handle.filePath
        let migrationID = handle.migrationID
        guard !filePaths.contains(path) else { return }
        filePaths.append(path)
        taskQueue.async { [weak self] in
            guard let self, tasks[path] == nil else { return }
            do {
                Self.logger.info("will create task path: \(path)  \(migrationID)")
                let task = try FileMigrationTask(userResolver: userResolver, path: path, migrationID: migrationID)
                if tasks[path] == nil {
                    tasks[path] = task
                }
                Self.logger.info("did create task : \(task.migratedPath)  \(migrationID)")
            } catch {
                Self.logger.error("create task failed with : \(error)")
            }
        }
    }
    
    func leave(handle: FileMigrationHandle) {
        let path = handle.filePath
        let migrationID = handle.migrationID
        taskQueue.async { [weak self] in
            guard let self,
                    let task = tasks[path],
                  task.migrationID == migrationID else { return }
            task.state = .done
            Self.logger.info("did leave task  \(migrationID)")
        }
    }
    
    func migrateData(_ data: Data, forHandle handle: FileMigrationHandle) {
        let path = handle.filePath
        let migrationID = handle.migrationID
        taskQueue.async { [weak self] in
            guard let self,
                  let task = tasks[path],
                  task.migrationID == migrationID else { return }
            do {
                if task.state == .preparing {
                    task.state = .migrating
                }
                try task.migrateData(data)
                Self.logger.info("did migrate data \(migrationID)")
            } catch {
                Self.logger.error("migrate data with error: \(error) path: \(path)")
            }
        }
    }
    
    func cleanExpiredMigrationFiles() {
        let start = CACurrentMediaTime()
        let dir = FileMigrationTask.dirPath
        let subpaths = FileManager.default.subpaths(atPath: dir) ?? []
        subpaths.forEach { path in
            let isTask = self.tasks.contains { task in
                path == task.value.migrationID
            }
            if !isTask {
                do {
                    try FileManager.default.removeItem(atPath: dir + "/" + path)
                    Self.logger.info("clean expired migration file: \(path)")
                } catch {
                    Self.logger.error("clean expired migration file failed: \(path), error: \(error)")
                }
                
            }
        }
        let now = CACurrentMediaTime()
        Self.logger.info("clean expired migration files done, cost: \(now - start)s")
    }
    
    // MARK: - FileMigrationRecord
    
    func startReadFile(withHandle handle: FileRecordHandle) {
        let path = handle.filePath
        taskQueue.async { [weak self] in
            guard let self, let task = tasks[path] else { return }
            task.record.record(from: .read, method: .open)
        }
    }
    
    func stopReadFile(withHandle handle: FileRecordHandle) {
        let path = handle.filePath
        taskQueue.async { [weak self] in
            guard let self, let task = tasks[path] else { return }
            task.record.record(from: .read, method: .close)
            taskWriteBackwardIfNeeded(with: task)
        }
    }
    
    func startWriteFile(withHandle handle: FileRecordHandle) {
        let path = handle.filePath
        taskQueue.async { [weak self] in
            guard let self, let task = tasks[path] else { return }
            task.record.record(from: .write, method: .open)
        }
    }
    
    func stopWriteFile(withHandle handle: FileRecordHandle) {
        let path = handle.filePath
        taskQueue.async { [weak self] in
            guard let self, let task = tasks[path] else { return }
            task.record.record(from: .write, method: .close)
            taskWriteBackwardIfNeeded(with: task)
        }
    }
    
    private func taskWriteBackwardIfNeeded(with task: FileMigrationTask) {
        Self.logger.info("task write backward with read: \(task.record.readCount), write: \(task.record.writeCount) state: \(task.state) \(task.migrationID)")
        guard task.record.readCount <= 0, task.record.writeCount <= 0, task.state == .done else { return }
        do {
            if task.canWriteBackward {
                try task.writeBackward()
            } else {
                try task.trashMigrateFile()
            }
        } catch {
            Self.logger.error("task write backward with error: \(error), path: \(task.path)")
        }
        tasks.removeValue(forKey: task.path)
        filePaths.removeAll(where: { $0 == task.path })
    }
}
