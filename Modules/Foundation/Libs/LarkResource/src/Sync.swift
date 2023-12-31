//
//  Sync.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/21.
//

import Foundation

/// 同步封装接口
final class SyncResouceManager: ResouceAPI {

    var manager: ResourceManager

    init(manager: ResourceManager) {
        self.manager = manager
    }

    var defaultIndexTables: [IndexTable] {
        return self.manager.lock.rdSync(action: { self.manager.defaultIndexTables })
    }

    var indexTables: [IndexTable] {
        return self.manager.lock.rdSync(action: { self.manager.indexTables })
    }

    func reloadDefaultIndexTables(
        _ info: [DefaultIndexTable.TypeEnum: DefaultIndexTable.Value]
    ) {
        self.manager.lock.wrSync {
            self.manager.reloadDefaultIndexTables(info)
        }
    }

    func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResource? {
        return self.manager.lock.rdSync { () -> MetaResource? in
            self.manager.metaResource(key: key, options: options)
        }
    }

    func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResourceResult {
        return self.manager.lock.rdSync { () -> MetaResourceResult in
            self.manager.metaResource(key: key, options: options)
        }
    }

    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> ResourceResult<T> {
        return self.manager.lock.rdSync { () -> ResourceResult<T> in
            self.manager.resource(key: key, options: options)
        }
    }

    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> T? {
        return self.manager.lock.rdSync { () -> T? in
            self.manager.resource(key: key, options: options)
        }
    }

    func setup(indexTables: [IndexTable]) {
        self.manager.lock.wrSync {
            self.manager.setup(indexTables: indexTables)
        }
    }

    func insertOrUpdate(indexTables: [IndexTable]) {
        self.manager.lock.wrSync {
            self.manager.insertOrUpdate(indexTables: indexTables)
        }
    }

    func remove(indexTableIDs: [String]) {
        self.manager.lock.wrSync {
            self.manager.remove(indexTableIDs: indexTableIDs)
        }
    }
}
