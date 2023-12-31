//
//  WikiStorage.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/9/23.
//
// swiftlint:disable file_length
// disable-lint: magic number

import RxSwift
import RxRelay
import SwiftyJSON
import SQLite
import SKCommon
import SKFoundation
import SpaceInterface
import SKInfra
import LarkContainer

public extension CCMExtension where Base == UserResolver {

    var wikiStorage: WikiStorage? {
        if CCMUserScope.wikiEnabled {
            if let instance = try? base.resolve(type: WikiStorage.self) {
                return instance
            }
            DocsLogger.error("wiki.storage --can not resolver WikiStorage")
            spaceAssertionFailure("wiki.storage --can not resolver WikiStorage, please contact zenghao.howie")
            return nil
        } else {
            return WikiStorage.singleInstance
        }
    }
}

public final class WikiStorage: NSObject {
    
    private static let legacyDBName = "wiki_cache.sqlite"
    private static let encryptDBName = "wiki-encrypt.sqlite"
    
    fileprivate static let singleInstance = WikiStorage(userResolver: nil) //TODO.chensi 用户态迁移完成后删除旧的单例代码
    
    @available(*, deprecated, message: "new code should use `userResolver.docs.wikiStorage`")
    public static var shared: WikiStorage {
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: true)
        if let obj = userResolver.docs.wikiStorage {
            return obj
        }
        DocsLogger.error("wiki.storage -- basically impossible, contact chensi.123")
        spaceAssertionFailure("wiki.storage -- basically impossible, contact chensi.123")
        return singleInstance

    }
    
    private let workQueue = DispatchQueue(label: "wiki.storage.db", attributes: [.concurrent])
    private let networkQueue = DispatchQueue(label: "wiki.storage.network")
    private var database: Connection?
    
    private(set) var spacesTable: WikiSpaceTable?
    private let starSpacesRelay = BehaviorRelay<[WikiSpace]>(value: [])
    private let recentEntitiesRequest = WikiMultiRequest<Int, JSON>(onConflict: .resend)
    private let spaceListRelay = BehaviorRelay<[WikiSpace]>(value: [])
    private var initialPreloadSucceed = false
    
    public var starSpacesUpdated: Observable<[WikiSpace]> {
        return starSpacesRelay.asObservable()
    }
    
    public var wikiSpaceListUpdate: Observable<[WikiSpace]> {
        return spaceListRelay.asObservable()
    }

    private let bag = DisposeBag()

    private var wikiNodeMetaTable: WikiNodeMetaTable?
    private(set) var wikiTreeDBNodeTable: WikiTreeDBNodeTable?
    
    private(set) var wikiSpaceQuoteListTable: WikiSpaceQuoteListTable?

    public var isStorageReady = false
    
    let userResolver: UserResolver? // 为nil表示是单例对象
        
    public init(userResolver: UserResolver?) {
        self.userResolver = userResolver
        super.init()
        
        DocsLogger.info("wiki.storage -- addObserver for user life cycle events")
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userDidLogin),
                                               name: NSNotification.Name.Docs.userDidLogin,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userWillLogout),
                                               name: NSNotification.Name.Docs.userWillLogout,
                                               object: nil)

        
        DocsLogger.info("wiki.storage -- init with userResovler: \(userResolver != nil), object: \(ObjectIdentifier(self))")
        
        if userResolver != nil { // 用户态实例, 立即执行登录后的逻辑
            handleUserLogin()
        }
    }
    
    deinit {
        if let ur = self.userResolver { // 用户态实例
            DocsLogger.info("wiki.storage -- deinit with userResovler")
        }
        DocsLogger.info("wiki.storage -- deinit: \(ObjectIdentifier(self))")
    }


    @objc
    private func userDidLogin(_ noti: NSNotification) {
        let userValid: Bool
        if let userID1 = noti.userInfo?["userID"] as? String, let userID2 = self.userResolver?.userID {
            userValid = userID1 == userID2
        } else if self.userResolver == nil {
            userValid = true
        } else {
            userValid = false
        }
        guard userValid else { return } // 避免预期外的用户执行
        handleUserLogin()
    }
    
    private func handleUserLogin() {
        
        DocsLogger.info("wiki.storage --- prepare to setup storage for user did login notification,  \(ObjectIdentifier(self))")
        guard let delaySecond = WikiFeatureGate.preloadDelay else {
            DocsLogger.info("wiki.storage --- failed to get wiki preload delay value, lazy load instand")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(delaySecond)) {
            self.reloadFromDB { error in
                if let wikiError = error as? WikiError,
                    case .storageAlreadyInitialized = wikiError {
                    DocsLogger.info("wiki.storage --- wiki storage is already ready, skip preload")
                }
            }
        }
    }

    @objc
    private func userWillLogout() {
        DocsLogger.info("wiki.storage --- cleaning up user storage for user will logout notification,  \(ObjectIdentifier(self))")
        cleanUp()
    }

    public func resetDB() {
        cleanUp()
        workQueue.async(flags: [.barrier]) {
            let dbFolderPath = SKFilePath.userSandboxWithLibrary(User.current.info?.userID ?? "default")
                .appendingRelativePath("wiki")
                .appendingRelativePath("database")
            dbFolderPath.createDirectoryIfNeeded()
            let dbPath = dbFolderPath.appendingRelativePath(Self.encryptDBName)
            do {
                try dbPath.removeItem()
            } catch {
                DocsLogger.error("reset wiki DB failed with error", error: error)
            }
        }
        reloadFromDB()
    }

    public func cleanUpDB() {
        cleanUp()
    }

    private func cleanUp() {
        workQueue.async(flags: [.barrier]) {
            NotificationCenter.default.removeObserver(self,
                                                      name: Notification.Name.Docs.wikiTitleUpdated,
                                                      object: nil)
            NotificationCenter.default.removeObserver(self,
                                                      name: Notification.Name.Docs.wikiTreeNodeTitleUpdated,
                                                      object: nil)
            self.starSpacesRelay.accept([])
            self.spaceListRelay.accept([])
            self.spacesTable = nil
            self.wikiNodeMetaTable = nil
            self.wikiTreeDBNodeTable = nil
            self.wikiSpaceQuoteListTable = nil
            self.database = nil
            self.isStorageReady = false
            DocsLogger.info("wiki.storage --- storage clean up complete")
        }
    }

    public func loadStorageIfNeed(completion: (() -> Void)? = nil) {
        workQueue.async(flags: [.barrier]) {
            guard !self.isStorageReady else {
                DocsLogger.info("wiki.storage --- storage is already ready!")
                DispatchQueue.main.async {
                    completion?()
                }
                return
            }
            self.unsafeReloadDB()
            DispatchQueue.main.async {
                completion?()
            }
        }

    }

    private func reloadFromDB(completion: ((Error?) -> Void)? = nil) {
        workQueue.async(flags: [.barrier]) {
            guard !self.isStorageReady else {
                DocsLogger.info("wiki.storage --- storage is already ready!")
                completion?(WikiError.storageAlreadyInitialized)
                return
            }
            self.unsafeReloadDB(completion: completion)
        }
    }

    private func unsafeReloadDB(completion: ((Error?) -> Void)? = nil) {
        let dbFolderPath = SKFilePath.userSandboxWithLibrary(User.current.info?.userID ?? "default")
            .appendingRelativePath("wiki")
            .appendingRelativePath("database")
        dbFolderPath.createDirectoryIfNeeded()
        let legacyDBPath = dbFolderPath.appendingRelativePath(Self.legacyDBName)
        let encryptDBPath = dbFolderPath.appendingRelativePath(Self.encryptDBName)
        let (useEncrypt, connection) = Connection.getEncryptDatabase(unEncryptPath: legacyDBPath, encryptPath: encryptDBPath, readonly: false, fromsource: .wikiList)
        var dbError: Error?
        if let db = connection {
            do {
                try setup(database: db)
            } catch {
                DocsLogger.error("wiki.storage --- db error when reload data", error: error)
                spacesTable = nil
                wikiNodeMetaTable = nil
                wikiTreeDBNodeTable = nil
                wikiSpaceQuoteListTable = nil
                database = nil
                try? encryptDBPath.removeItem()
                spaceAssertionFailure("wiki.storage --- db error when reload data: \(error)")
                dbError = error
            }
        } else {
            DocsLogger.error("wiki.storage --- db error when get encrypt database")
            try? encryptDBPath.removeItem()
            spaceAssertionFailure("wiki.storage --- db error when get encrypt database")
        }
        isStorageReady = true
        completion?(dbError)
        DocsLogger.info("wiki.storage --- storage setup complete.")
    }

    private func setup(database: Connection) throws {

        self.database = database
        try checkDBVersion(db: database)

        let spacesTable = WikiSpaceTable(connection: database, tableName: "wiki_space_v2")
        try spacesTable.setup()
        self.spacesTable = spacesTable

        let wikiNodeMetaTable = WikiNodeMetaTable(connection: database, tableName: "wike_node_meta_v2")
        try wikiNodeMetaTable.setup()
        self.wikiNodeMetaTable = wikiNodeMetaTable

        let wikiTreeDBNodeTable = WikiTreeDBNodeTable(connection: database)
        try wikiTreeDBNodeTable.setup()
        self.wikiTreeDBNodeTable = wikiTreeDBNodeTable
        
        let wikiSpaceQuoteListTable = WikiSpaceQuoteListTable(connection: database)
        try wikiSpaceQuoteListTable.setup()
        self.wikiSpaceQuoteListTable = wikiSpaceQuoteListTable
    }

    public func update(spaces: [WikiSpace]) {
        workQueue.async(flags: [.barrier]) {
            self.unsafeUpdate(spaces: spaces)
        }
    }

    public func update(wikiNodeMeta: WikiNodeMeta) {
        loadStorageIfNeed()
        workQueue.async(flags: [.barrier]) {
            self.wikiNodeMetaTable?.insert(node: wikiNodeMeta)
        }
    }
    
    public func updateWikiSpaceList(spaces: [WikiSpace]) {
        workQueue.async(flags: [.barrier]) {
            self.spacesTable?.insert(spaces: spaces)
        }
    }
    
    public func updateWikiSpaceQuote(with quote: [WikiSpaceQuote]) {
        workQueue.async(flags: [.barrier]) {
            self.wikiSpaceQuoteListTable?.insert(with: quote)
        }
    }
    
    public func updateWikiSpaceQuote(spaceIds: [String], type: SpaceType, classType: SpaceClassType) {
        workQueue.async(flags: [.barrier]) {
            let quotes: [WikiSpaceQuote] = spaceIds.map {
                WikiSpaceQuote(spaceID: $0, spaceType: type, spaceClassType: classType)
            }
            if quotes.isEmpty {
                self.wikiSpaceQuoteListTable?.deleteQuoto(type: type, classType: classType)
            }
            self.wikiSpaceQuoteListTable?.insert(with: quotes)
        }
    }
    
    public func getWikiSpaceList(spaceType: SpaceType, classType: SpaceClassType, completion: (() -> Void)? = nil) {
        workQueue.sync {
            let spaceIds = wikiSpaceQuoteListTable?.getAllSpaceIdOfCurrentClass(spaceType: spaceType, spaceClassId: classType)
            let spaceList = spacesTable?.getAllSpacesOfCurrentClass(with: spaceIds ?? []) ?? []
            spaceListRelay.accept(spaceList)
            
            let starSpaceIds = wikiSpaceQuoteListTable?.getAllSpaceIdOfCurrentClass(spaceType: .star, spaceClassId: .star)
            let starSpaces = spacesTable?.getAllSpacesOfCurrentClass(with: starSpaceIds ?? []) ?? []
            starSpacesRelay.accept(starSpaces)
            DispatchQueue.main.async {
                completion?()
            }
        }
    }
    
    public func cleanWikiSpaceList() {
        loadStorageIfNeed()
        workQueue.sync {
            wikiSpaceQuoteListTable?.deleteAllQuote()
        }
    }

    public func getWikiNodeMeta(_ wikiToken: String) -> WikiNodeMeta? {
        // TODO: 是否改异步
        loadStorageIfNeed()
        return workQueue.sync {
            self.wikiNodeMetaTable?.getNodeMeta(wikiToken)
        }
    }

    public func cleanWikiNodeMeta(wikiToken: String) {
        loadStorageIfNeed()
        workQueue.sync { [weak self] in
            self?.wikiNodeMetaTable?.delete(for: wikiToken)
        }
    }

    private func unsafeUpdate(spaces: [WikiSpace]) {
        guard isStorageReady else {
            DocsLogger.warning("wiki.storage --- failed to update spaces, storage is not ready!")
            return
        }
        // 手动构建置顶列表索引
        let starQuotes = spaces.map {
            WikiSpaceQuote(spaceID: $0.spaceID, spaceType: .star, spaceClassType: .star)
        }
        wikiSpaceQuoteListTable?.insert(with: starQuotes)
        
        if spaces.isEmpty {
            wikiSpaceQuoteListTable?.deleteQuoto(type: .star, classType: .star)
        }
        spacesTable?.insert(spaces: spaces)
        self.starSpacesRelay.accept(spaces)
    }
}

extension WikiStorage {
    private func checkDBVersion(db: Connection) throws {
        if db.dbVersion == 0 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            db.dbVersion = 1
        }

        if db.dbVersion == 1 {
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 2
        }

        if db.dbVersion == 2 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            db.dbVersion = 3
        }
        
        if db.dbVersion == 3 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 4
        }

        if db.dbVersion == 4 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 5
        }

        // 补偿 version 4 和 version 5 曾经因版本冲突导致的 DB 异常
        if db.dbVersion == 5 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 6
        }

        // 新增 space 收藏状态
        if db.dbVersion == 6 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 7
        }

        // 新增 space tenantID 属性
        if db.dbVersion == 7 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 8
        }

        // space tenantID 属性改为可选
        if db.dbVersion == 8 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("recent_wiki_entity_v2").drop(ifExists: true))
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 9
        }

        // wiki tree node 新增 origin_is_external 字段
        if db.dbVersion == 9 {
            try db.run(Table("wiki_tree_node").drop(ifExists: true))
            db.dbVersion = 10
        }
        
        // wiki tree node 新增 origin_deleted_flag 字段
        if db.dbVersion == 10 {
            try db.run(Table("wiki_tree_db_node").drop(ifExists: true))
            db.dbVersion = 11
        }

        if db.dbVersion == 11 {
            try db.run(Table("wiki_space_list").drop(ifExists: true))
            db.dbVersion = 12
        }
        
        // wiki space 新增 space_type & create_uid 字段
        if db.dbVersion == 12 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            db.dbVersion = 13
        }
        
        if db.dbVersion == 13 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("wiki_space_list").drop(ifExists: true))
            db.dbVersion = 14
        }

        // 新增 display_tag
        if db.dbVersion == 14 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            try db.run(Table("wiki_space_list").drop(ifExists: true))
            db.dbVersion = 15
        }
        
        // 新增 is_explorer_pin
        if db.dbVersion == 15 {
            try db.run(Table("wiki_tree_db_node").drop(ifExists: true))
            db.dbVersion = 16
        }
        
        // wiki space 新增 root_token字段
        if db.dbVersion == 16 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            db.dbVersion = 17
        }
        
        // wiki node 新增 isSpaceLocation字段
        if db.dbVersion == 17 {
            try db.run(Table("wiki_tree_db_node").drop(ifExists: true))
            db.dbVersion = 18
        }
        
        // wiki 新增icon_info
        if db.dbVersion == 18 {
            try db.run(Table("wiki_tree_db_node").drop(ifExists: true))
            db.dbVersion = 19
        }
        
        // wiki space 新增 icon_info字段
        if db.dbVersion == 19 {
            try db.run(Table("wiki_space_v2").drop(ifExists: true))
            db.dbVersion = 20
        }
        
        // wiki node 新增 url字段
        if db.dbVersion == 20 {
            try db.run(Table("wiki_tree_db_node").drop(ifExists: true))
            db.dbVersion = 21
        }

        // 数据库版本降低
        if db.dbVersion > 21 {
            db.dbVersion = 0
            try checkDBVersion(db: db)
        }
    }
}

extension Connection {
    public var dbVersion: Int32 {
        get {
            do {
                return Int32(try scalar("PRAGMA user_version") as? Int64 ?? 0)
            } catch {
                DocsLogger.error("wiki.storage --- get db version error", error: error)
                return 0
            }
        }
        set {
            do {
                try run("PRAGMA user_version = \(newValue)")
            } catch {
                DocsLogger.error("wiki.storage --- set db version error", error: error)
            }
        }
    }
}

// MARK: - simple mode 精简模式接口
extension WikiStorage: WikiStorageBase {
    public func deleteDB() {
        wikiTreeDBNodeTable?.deleteAll()
        cleanWikiSpaceList()
    }

    public func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile], completion: (() -> Void)?) {
        DocsLogger.info("\(self.tkClassName) start to clear data in simple mode", component: LogComponents.simpleMode)
        cleanUp()
        workQueue.async(flags: [.barrier]) {
            DispatchQueue.main.async {
                completion?()
            }
        }
    }

    public func setWikiMeta(wikiToken: String, completion: @escaping (WikiInfo?, Error?) -> Void) {
        let metaHandler = { [weak self] (nodeMeta: WikiNodeMeta) in
            self?.update(wikiNodeMeta: nodeMeta)
            completion(WikiInfo(wikiToken: nodeMeta.wikiToken,
                                objToken: nodeMeta.objToken,
                                docsType: nodeMeta.docsType,
                                spaceId: nodeMeta.spaceID), nil)
        }
        let errorHandler = { (error: Error) in
            DocsLogger.error("WikiStorageBase setWikiMeta error: \(error)")
            completion(nil, error)
        }
        WikiNetworkManager.shared.getWikiObjInfo(wikiToken: wikiToken)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { info, logID in
                switch info {
                case let .inWiki(meta):
                    metaHandler(meta)
                case let .inSpace(info):
                    DocsLogger.info("save preloaded redirect info",
                                    extraInfo: ["logID": logID],
                                    component: LogComponents.workspace)
                    let record = WorkspaceCrossRouteRecord(wikiToken: info.wikiToken, objToken: info.objToken, objType: info.docsType, inWiki: false, logID: logID)
                    DocsContainer.shared.resolve(WorkspaceCrossRouteStorage.self)?.set(record: record)
                    let wikiInfo = WikiInfo(wikiToken: info.wikiToken, objToken: info.objToken, docsType: info.docsType, spaceId: "")
                    // 保证预加载可以正常进行
                    completion(wikiInfo, nil)
                }
            }, onError: errorHandler)
            .disposed(by: bag)
    }

    public func setWikiMeta(wikiToken: String, objToken: String, objType: Int, spaceId: String) {
        let node = WikiNodeMeta(wikiToken: wikiToken,
                                objToken: objToken,
                                docsType: DocsType(rawValue: objType),
                                spaceID: spaceId)
        update(wikiNodeMeta: node)
    }

    public func getWikiInfo(by wikiToken: String) -> WikiInfo? {
        if let node = getWikiNodeMeta(wikiToken) {
            return WikiInfo(wikiToken: node.wikiToken,
                            objToken: node.objToken,
                            docsType: node.docsType,
                            spaceId: node.spaceID)
        } else {
            DocsLogger.info("no match wikiToken V2")
            return nil
        }
    }
    
    public func insertFakeNodeForLibrary(wikiNode: WikiNode) {
        loadStorageIfNeed { [weak self] in
            guard let libraryId = MyLibrarySpaceIdCache.get(),
                  let rootToken = self?.wikiTreeDBNodeTable?.getRootWikiToken(spaceID: libraryId, rootType: .mainRoot),
                  let rootNode = self?.wikiTreeDBNodeTable?.getNodes(spaceID: libraryId, wikiTokens: [rootToken]).first  else {
                return
            }
            // 相同节点先删除后插入
            self?.wikiTreeDBNodeTable?.delete(tokens: [wikiNode.wikiToken])
            // 构建新节点插入
            let newRootChildern: [String]? = (rootNode.children ?? []) + [wikiNode.wikiToken]
            let newRootNode = WikiTreeDBNode(meta: rootNode.meta, children: newRootChildern, parent: rootNode.parent, sortID: rootNode.sortID)
            let wikiMeta = WikiTreeNodeMeta(wikiToken: wikiNode.wikiToken, spaceId: libraryId, objToken: wikiNode.objToken, docsType: wikiNode.objType, title: wikiNode.title)
            let node = WikiTreeDBNode(meta: wikiMeta, children: nil, parent: rootToken, sortID: Double.greatestFiniteMagnitude)
            self?.wikiTreeDBNodeTable?.insert(nodes: [newRootNode, node])
        }
    }
    
    public func getMylibraryMainRootToken() -> String? {
        guard let libararyId = MyLibrarySpaceIdCache.get() else {
            return nil
        }
        return wikiTreeDBNodeTable?.getRootWikiToken(spaceID: libararyId, rootType: .mainRoot)
    }
}
