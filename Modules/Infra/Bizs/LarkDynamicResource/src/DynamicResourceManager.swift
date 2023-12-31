//
//  LarkDynamicResourceManager.swift
//  LarkDynamicResource
//
//  Created by Aslan on 2021/3/23.
//

import Foundation
import LKCommonsLogging
import IESGeckoKit
import LarkResource
import OpenCombine
import OpenCombineDispatch

typealias UnderlyingManager = IESGurdKit

public final class DynamicResourceManager {
    static let logger = Logger.log(DynamicResourceManager.self, category: "Module.LarkDynamicResource")

    var bizConfigs: [DRBizConfig]
    var channels: [String]
    var featureConfig: [String: Any]
    var currentIndexTable: ResourceIndexTable?
    var ready: Bool = false
    var cancelBag = Set<AnyCancellable>()
    private let serialQueue = DispatchQueue(label: "com.DynamicResourceManager.workQueue")

    private var accessKey: String?

    public static let shared = DynamicResourceManager()

    public init() {
        self.bizConfigs = []
        self.channels = []
        self.featureConfig = [String: Any]()
    }

    func register(bizconfigs: [DRBizConfig]) {
        self.bizConfigs = bizconfigs
        bizConfigs.forEach { (item) in
            self.channels.append(item.bizID)
        }
        DynamicResourceManager.shared.registerBiz(biz: self.bizConfigs)
        guard let accessKey = self.bizConfigs.first?.bizKey else {
            Self.logger.info("dynamic resource: invalid accessKey")
            return
        }
        // ka的资源指定不能被sdk的策略清除掉
        UnderlyingManager.addChannelsWhitelist(self.channels, forAccessKey: accessKey)
    }

    func versionOfResource(by identifier: String, accessKey: String) -> UInt64 {
        UnderlyingManager.packageVersion(forAccessKey: accessKey, channel: identifier)
    }

    func triggerFetchResource(by identifier: String, accessKey: String) {
        let manager = DynamicResourceManager.shared
        manager.fetchResource(by: identifier) { (isSuccess, status) in
            DispatchQueue.global().async {
                let status = manager.resourceStatus(for: identifier)
                Self.logger.info("dynamic resource: status: \(status), success:\(isSuccess)")
                if isSuccess && status == .ready, let _ = manager.resourceRootFolderPath(identifier: identifier) {
                    // 下载成功，拷贝到备份目录，资源查找从备份目录中获取，避免升级过程中，资源被清除
                    self.handle(accessKey, by: identifier)
                }
            }
        }
    }

    func fetchResource(id: String) {
        // todo zhaoxiangyu
        // 原来是同步逻辑，后走 setting，这里逻辑很乱，后边梳理重构。
        serialQueue.async { [unowned self] in
            DynamicResourceHelper.accessKey()
                .receive(on: serialQueue.ocombine)
                .sink { _ in

            } receiveValue: { [weak self] accessKey in
                let bizConfig = DRBizConfig(bizID: id, bizKey: accessKey, subBizKey: id)
                self?.register(bizconfigs: [bizConfig])
                self?.triggerFetchResource(by: bizConfig.bizID, accessKey: accessKey)
            }.store(in: &self.cancelBag)
        }
    }

    func syncBackupIfNeed(by identifier: String) {
        // todo zhaoxiangyu
        // 原来是同步逻辑，后走 setting，这里逻辑很乱，后边梳理重构。
        serialQueue.async { [unowned self] in
            DynamicResourceHelper.accessKey()
                .receive(on: serialQueue.ocombine)
                .sink { _ in
                    
            } receiveValue: { [weak self] temp in
                self?.handle(temp, by: identifier)
            }.store(in: &self.cancelBag)
        }
    }

    func handle(_ accessKey: String, by identifier: String) {
        let manager = DynamicResourceManager.shared
        let version = manager.versionOfResource(by: identifier, accessKey: accessKey)
        let latestVersion = manager.latestVersion(for: accessKey, channel: identifier)
        Self.logger.info("dynamic resource: resource version: \(version), latest version:\(latestVersion)")
        if latestVersion == nil || version != latestVersion {
            let status = manager.resourceStatus(for: identifier)
            let targetPath = DynamicResourceManager.Folder.backupFolderPath(accessKey: accessKey, channel: identifier, version: version)
            if status == .ready, let path = manager.resourceRootFolderPath(identifier: identifier) {
                let copySuccess = DynamicResourceManager.Folder.copyItem(at: path, to: targetPath, overwrite: true)
                if copySuccess {
                    // 更新拷贝后的版本号
                    DynamicResourceManager.shared.updateLatestVersion(for: accessKey, channel: identifier, latestVersion: version)
                } else {
                    Self.logger.info("dynamic resource: backup failed, source path:\(path), target path:\(targetPath)")
                }
            }
        }
    }

    func fetchValidResourceIfNeed(by identifier: String) {
        guard let key = DynamicResourceHelper.syncAccessKey() else{
            return
        }
        self.accessKey = key
        guard let path = fetchValidResourcePath(by: identifier) else {
            return
        }
        updateValidResource(accesssKey: key, path: path, identifier: identifier)
    }

    func updateValidResource(accesssKey: String, path: String, identifier: String) {
        Self.logger.info("dynamic resource: invalid resource path:\(path)")
        // 更新查找索引
        let indexFilePath = path.appending("/res-index.plist")
        if let indexTable = ResourceIndexTable(name: identifier, indexFilePath: indexFilePath, bundlePath: path) {
            DynamicResourceManager.shared.currentIndexTable = indexTable
            ResourceManager.insertOrUpdate(indexTables: [indexTable])
            DynamicResourceManager.shared.readFeatureConfig(by: path)
            DynamicResourceManager.shared.ready = true
            Self.logger.info("dynamic resource: current index table:\(indexTable.identifier)")
        }
    }

    func fetchValidResourcePath(by identifier: String) -> String? {
        var path: String?
        let manager = DynamicResourceManager.shared
        guard let accessKey = accessKey else {
            Self.logger.info("dynamic resource: can not find access key, need fix")
            return nil
        }
        if let map = readVersionInfo(for: accessKey, channel: identifier) {
            let currentVersion = map["current_version"]
            let latestVersion = map["latest_version"]
            Self.logger.info("dynamic resource: current_version:\(currentVersion), latest_version:\(latestVersion)")
            if let latestVer = latestVersion, let vInt = UInt64(latestVer) {
                // 使用最新资源
                path = DynamicResourceManager.Folder.backupFolderPath(accessKey: accessKey, channel: identifier, version: vInt)

                DispatchQueue.global().async {
                    // 删除老版本数据，放异步线程执行
                    if let curVer = currentVersion, let cvInt = UInt64(curVer) {
                        if vInt != cvInt {
                            // remove old folder
                            let oldpath = DynamicResourceManager.Folder.backupFolderPath(accessKey: accessKey, channel: identifier, version: cvInt)
                            DynamicResourceManager.Folder.removeItem(at: oldpath)
                        }
                    }
                    manager.updateCurrentVersion(for: accessKey, channel: identifier, currentVersion: vInt)
                }
            }
        }
        return path
    }

    func readFeatureConfig(by path: String) {
        let filePath = DynamicResourceManager.Folder.featureConfigFilePath(path: path)
        if DynamicResourceManager.Folder.isExist(at: filePath) {
            // lint:disable:next lark_storage_check - 即将下线，不处理
            if let data = NSData(contentsOfFile: filePath) {
                if let dict = try? JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String: Any] {
                    self.featureConfig = dict
                } else {
                    Self.logger.info("dynamic resource: json serialize error!")
                }
             }
        }
    }

    func revert() {
        // 状态初始化，切换租户都会走这里逻辑
        featureConfig = [String: Any]()
        ready = false
        if let currentIndexTable = DynamicResourceManager.shared.currentIndexTable {
            // 移除上一个租户的资源索引表
            Self.logger.info("dynamic resource: remove last index table:\(currentIndexTable.identifier)")
            ResourceManager.remove(indexTableIDs: [currentIndexTable.identifier])
        }

        let backupResourcePath = Bundle.main.bundleURL.appendingPathComponent("dynamic_resource.bundle").path
        let indexFilePath = backupResourcePath.appending("/res-index.plist")
        if let backupResourceIndexTable = ResourceIndexTable(name: "backupdResouce", indexFilePath: indexFilePath, bundlePath: backupResourcePath) {
            currentIndexTable = backupResourceIndexTable
            ResourceManager.insertOrUpdate(indexTables: [backupResourceIndexTable])
            readFeatureConfig(by: indexFilePath)
            ready = true
        }
    }
}
