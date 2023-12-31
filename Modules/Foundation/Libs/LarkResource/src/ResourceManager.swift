//
//  ResourceManager.swift
//  LarkResource
//
//  Created by 李晨 on 2020/2/20.
//

import Foundation
import LKCommonsLogging
import EEAtomic

// lint:disable lark_storage_check - bundle 资源相关，不做存储检查

/*
 Document: https://bytedance.feishu.cn/docs/doccnlxCrgzcRUCCpmaLqoFv4ff
 */
public final class ResourceManager: NSObject {

    static var logger: Log = Logger.log(ResourceManager.self, category: "resource.manager")

    /// 索引文件名
    public static let indexFileName = "res-index.plist"

    /// app 默认索引表名称
    public static let appDefaultIndexName = "resource.app.default.index"

    /// 沙盒默认索引表名称
    public static let sanboxDefaultIndexName = "resource.sandbox.default.index"

    /// app 索引文件在 Bundle.main 的路径
    public static let appDefaultPath = indexFileName

    /// 沙盒索引文件文件夹路径
    public static let sandboxFolderPath = NSHomeDirectory() + "/Library/resources"

    /// 沙盒索引文件路径
    public static let sandboxDefaultPath = sandboxFolderPath + "/" + indexFileName

    /// 非主线程单例
    static var shared = ResourceManager()
    /// 主线程单例
    static var mainThreadShared = ResourceManager()

    /// 所有 moduleNameAuto.bundle 索引
    static var autoModuleIndexs: [String: IndexTable] = [:]

    private static var once: AtomicOnce = AtomicOnce()

    /// 自动加载过 auto bundle 索引
    static var autoLoadedBundleIndex: Bool = {
        once.once {
            loadAutoModuleIndexes()
            reloadDefaultIndexTables(.all, setup: true)
        }
        return true
    }()

    /// 读写锁
    var lock: RWLock = RWLock()

    /// 默认 app 索引表
    private var appIndexTable: IndexTable?
    /// 默认沙盒索引表
    private var sanboxIndexTable: IndexTable?

    /// 默认索引表
    var defaultIndexTables: [IndexTable] {
        var tables: [IndexTable] = []
        if let sanboxIndexTable = self.sanboxIndexTable {
            tables.append(sanboxIndexTable)
        }
        if let appIndexTable = self.appIndexTable {
            tables.append(appIndexTable)
        }
        return tables
    }

    /// 全局索引表
    private(set) var indexTables: [IndexTable] = []

    var sync: SyncResouceManager {
        return SyncResouceManager(manager: self)
    }
}

// MARK: - ResouceAPI
extension ResourceManager: ResouceAPI {

    func reloadDefaultIndexTables(
        _ info: [DefaultIndexTable.TypeEnum: DefaultIndexTable.Value]
    ) {
        if let value = info[.app] {
            self.appIndexTable = value.indexTable
        }
        if let value = info[.sandbox] {
            self.sanboxIndexTable = value.indexTable
        }
    }

    func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResource? {
        let result: MetaResourceResult = self.metaResource(key: key, options: options)
        return result.value
    }

    func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResourceResult {
        let optionSet = OptionsInfoSet(options: options)

        let indexTables = self.getIndexTables(env: key.env, options: optionSet)
        if indexTables.isEmpty {
            return MetaResourceResult.failure(.noIndexTable)
        }
        for indexTable in indexTables {
            if let result = indexTable.resourceIndex(key: key) {
                return MetaResourceResult.success(result)
            }
        }
        return MetaResourceResult.failure(.noResource)
    }

    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> ResourceResult<T> {

        let optionSet = OptionsInfoSet(options: options)

        let convertKey = ConvertKey(resourceType: T.self)
        let convertEntry: ConvertibleEntryProtocol = optionSet.converts[convertKey] ?? T.convertEntry

        let metaResult: MetaResourceResult = self.metaResource(key: key, options: options)

        guard let metaResource = metaResult.value else {
            return ResourceResult<T>.failure(metaResult.error ?? .unknow)
        }

        do {
            let resourceValue: T = try convertEntry.convert(result: metaResource, options: optionSet)
            let resource = Resource(
                key: key,
                index: metaResource.index,
                value: resourceValue
            )
            return ResourceResult<T>.success(resource)
        } catch {
            if let err = error as? ResourceError {
                return ResourceResult<T>.failure(err)
            }
            return ResourceResult<T>.failure(.custom(error))
        }
    }

    func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> T? {
        let result: ResourceResult<T> = self.resource(key: key, options: options)
        return result.value?.value
    }
}

// MARK: - Index Table
extension ResourceManager {

    func setup(indexTables: [IndexTable]) {
        self.indexTables = indexTables
    }

    func insertOrUpdate(indexTables: [IndexTable]) {
        let insertOrUpdate: ([IndexTable], [IndexTable]) -> [IndexTable] = { (origin: [IndexTable], new: [IndexTable]) -> [IndexTable] in
            var result = origin
            new.reversed().forEach { (indexTable) in
                if let index = origin.firstIndex(where: { (item) -> Bool in
                    return item.identifier == indexTable.identifier
                }) {
                    result[index] = indexTable
                } else {
                    result.insert(indexTable, at: 0)
                }
            }
            return result
        }

        self.indexTables = insertOrUpdate(self.indexTables, indexTables)
    }

    func remove(indexTableIDs: [String]) {
        self.indexTables = self.indexTables.filter({ (item) -> Bool in
            return !indexTableIDs.contains(item.identifier)
        })
    }

    func getIndexTables(env: Env, options: OptionsInfoSet) -> [IndexTable] {
        _ = ResourceManager.autoLoadedBundleIndex
        let moduleIndexes = ResourceManager.autoModuleIndexs
        var tables: [IndexTable] = options.extraIndexTables
        tables += self.indexTables
        tables += self.defaultIndexTables
        if !env.moduleName.isEmpty,
            let moduleIndex = moduleIndexes[env.moduleName + "Auto"] ??
                moduleIndexes[env.moduleName] {
            tables += [moduleIndex]
        }
        tables += options.baseIndexTables
        return tables
    }
}

// MARK: - public static function
extension ResourceManager {

    public struct IndexReloadType: OptionSet {
        public let rawValue: Int

        public static let app = IndexReloadType(rawValue: 1 << 0)
        public static let sandbox = IndexReloadType(rawValue: 1 << 1)
        public static let all: IndexReloadType = [IndexReloadType.app, IndexReloadType.sandbox]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    public static var defaultIndexTables: [IndexTable] {
        if Thread.isMainThread {
            return self.mainThreadShared.defaultIndexTables
        } else {
            return self.shared.sync.defaultIndexTables
        }
    }

    public static var globalIndexTables: [IndexTable] {
        if Thread.isMainThread {
            return self.mainThreadShared.indexTables
        } else {
            return self.shared.sync.indexTables
        }
    }

    public static func setupResourceModule() {
        _ = autoLoadedBundleIndex
    }

    static func loadAutoModuleIndexes() {
        let bundlePaths = Bundle.main.paths(
            forResourcesOfType: "bundle",
            inDirectory: nil
        )
        /// 加载所有 Auto.bundle
        for path in bundlePaths {
            /// 优先判断后缀. 减少字符串操作
            if path.hasSuffix(Module.autoBundleSuffix),
                let bundleFullName = path.split(separator: "/").last,
                let bundleName = bundleFullName.split(separator: ".").first,
                let bundleURL = URL(string: path) {
                let name = String(bundleName)
                autoModuleIndexs[name] = Module.indexTable(name, bundleURL)
            }
        }
    }

    /// 刷新框架默认索引表
    public static func reloadAllDefaultIndexTables() {
        self.reloadDefaultIndexTables(.all)
    }

    /// 根据指定 type 刷新框架默认索引表
    public static func reloadDefaultIndexTables(_ type: IndexReloadType, setup: Bool = false) {
        logger.info("reload default index table, type \(type.rawValue)")
        var reloadInfo: [DefaultIndexTable.TypeEnum: DefaultIndexTable.Value] = [:]
        /// 判断是否需要更新 app 索引
        if type.contains(.app) {
            if let indexPath = Bundle.main.path(
                forResource: ResourceManager.appDefaultPath,
                ofType: nil),
                let appIndexTable = ResourceIndexTable(
                    name: ResourceManager.appDefaultIndexName,
                    indexFilePath: indexPath,
                    bundlePath: Bundle.main.bundlePath) {
                logger.info("reload default app index file")
                reloadInfo[.app] = DefaultIndexTable.Value(appIndexTable)
            } else {
                logger.info("reset default app index file")
                /// 本地不存在索引文件，清空当前数据
                reloadInfo[.app] = DefaultIndexTable.Value(nil)
            }
        }
        /// 判断是否需要更新沙盒索引
        if type.contains(.sandbox) {
            /// 判断目录是否存在
            checkSandboxFolderExists()
            if let indexPath = Bundle.main.path(
                forResource: ResourceManager.sandboxDefaultPath,
                ofType: nil),
                let sandboxIndexTable = ResourceIndexTable(
                    name: ResourceManager.sanboxDefaultIndexName,
                    indexFilePath: indexPath,
                    bundlePath: ResourceManager.sandboxFolderPath) {
                logger.info("reload default sandbox index file")
                reloadInfo[.sandbox] = DefaultIndexTable.Value(sandboxIndexTable)
            } else {
                logger.info("reset default sandbox index file")
                /// 本地不存在索引文件，清空当前数据
                reloadInfo[.sandbox] = DefaultIndexTable.Value(nil)
            }
        }
        /// 判断是否是初始化，初始化不发通知，不需要异步执行
        if setup {
            /// setup 不添加 lock，是由于 setup 是由 autoLoadedBundleIndex 触发
            /// autoLoadedBundleIndex 触发时，内部逻辑都是包在一个 once 中，不存在多线程问题
            self.shared.reloadDefaultIndexTables(reloadInfo)
            self.mainThreadShared.reloadDefaultIndexTables(reloadInfo)
        } else {
            self.shared.sync.reloadDefaultIndexTables(reloadInfo)
            doInMainThread {
                self.mainThreadShared.reloadDefaultIndexTables(reloadInfo)
                NotificationCenter.default.post(name: .DefaultIndexDidChange, object: nil)
            }
        }
    }

    public static func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResourceResult {
        if Thread.isMainThread {
            return self.mainThreadShared.metaResource(key: key, options: options)
        } else {
            return self.shared.sync.metaResource(key: key, options: options)
        }
    }

    public static func metaResource(key: ResourceKey, options: OptionsInfo = []) -> MetaResource? {
        if Thread.isMainThread {
            return self.mainThreadShared.metaResource(key: key, options: options)
        } else {
            return self.shared.sync.metaResource(key: key, options: options)
        }
    }

    public static func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> ResourceResult<T> {
        if Thread.isMainThread {
            return self.mainThreadShared.resource(key: key, options: options)
        } else {
            return self.shared.sync.resource(key: key, options: options)
        }
    }

    public static func resource<T: ResourceConvertible>(key: ResourceKey, options: OptionsInfo = []) -> T? {
        if Thread.isMainThread {
            return self.mainThreadShared.resource(key: key, options: options)
        } else {
            return self.shared.sync.resource(key: key, options: options)
        }
    }

    public static func get<T: ResourceConvertible>(
        key: String,
        type: String,
        env: Env = Env(),
        options: OptionsInfo = []) -> T? {
        let resourceKey = ResourceKey.key(key, type: type, env: env)
        return resource(key: resourceKey, options: options)
    }

    public static func setup(indexTables: [IndexTable]) {
        logger.info("setup indexTables", additionalData: [
            "id": indexTables.map { $0.identifier }
                .reduce("") { $0 + " " + $1 }
        ])

        self.shared.sync.setup(indexTables: indexTables)
        doInMainThread {
            self.mainThreadShared.setup(indexTables: indexTables)
            NotificationCenter.default.post(name: .GlobalIndexDidChange, object: nil)
        }
    }

    public static func insertOrUpdate(indexTables: [IndexTable]) {
        logger.info("insert indexTables", additionalData: [
            "id": indexTables.map { $0.identifier }
                .reduce("") { $0 + " " + $1 }
        ])

        self.shared.sync.insertOrUpdate(indexTables: indexTables)
        doInMainThread {
            self.mainThreadShared.insertOrUpdate(indexTables: indexTables)
            NotificationCenter.default.post(name: .GlobalIndexDidChange, object: nil)
        }
    }

    public static func remove(indexTableIDs: [String]) {
        logger.info("remove indexTables", additionalData: [
            "id": indexTableIDs.reduce("") { $0 + " " + $1 }
        ])

        self.shared.sync.remove(indexTableIDs: indexTableIDs)
        doInMainThread {
            self.mainThreadShared.remove(indexTableIDs: indexTableIDs)
            NotificationCenter.default.post(name: .GlobalIndexDidChange, object: nil)
        }
    }

    static func doInMainThread(_ block: @escaping () -> Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }

    /// 检测默认资源沙盒路径
    static func checkSandboxFolderExists() {
        var isDirectory: ObjCBool = false
        if !FileManager.default.fileExists(
            atPath: self.sandboxFolderPath,
            isDirectory: &isDirectory
        ) || !isDirectory.boolValue {
            logger.info("create resource folder in \(self.sandboxFolderPath)")
            try? FileManager.default.removeItem(atPath: self.sandboxFolderPath)
            try? FileManager.default.createDirectory(
                atPath: self.sandboxFolderPath,
                withIntermediateDirectories: true,
                attributes: nil)
        }
    }
}
