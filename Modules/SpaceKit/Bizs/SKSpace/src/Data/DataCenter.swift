//  Created by weidong fu on 13/12/2017.

import Foundation
import SQLiteMigrationManager
import SQLite
import ReSwift
import SwiftyJSON
import RxRelay
import SKFoundation
import SKCommon
import LarkContainer

//public extension CCMExtension where Base == UserResolver {
//
//    var dataCenter: DataCenter {
//        if CCMUserScope.spaceEnabled {
//            if let obj = try? base.resolve(type: DataCenter.self) {
//                return obj
//            } else {
//                return .shared
//            }
//        } else {
//            return .shared
//        }
//    }
//}

public final class DataCenter: NSObject {

//    @available(*, deprecated, message: "new code should use `userResolver.docs.dataCenter`")
    static let shared = DataCenter()

    private var tablesManager: TablesManager?
    private var dbAutoSaver: DBAutoSaver?

    let docConnection: DocsDBConnectionProvidor


    private static func expectOnDataQueue() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(dataQueue))
        #endif
    }


    public init(docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
        super.init()
    }

    public func loadDB(_ userID: String, fileResource: FileResource, _ completion: (Bool) -> Void) {
        Self.expectOnDataQueue()
        guard self.docConnection.file == nil else {
            DocsLogger.warning("docConnection file is exist")
            completion(false)
            return
        }
        if self.docConnection.setup(userID: userID) {
            self.tablesManager = TablesManager(self.docConnection)
            self.dbAutoSaver = DBAutoSaver(fileResource: fileResource, tableManger: self.tablesManager!)
            completion(true)
        }
    }

    func reset() {
        Self.expectOnDataQueue()

        DispatchQueue.dataQueueAsyn {
            self.docConnection.reset()
            self.dbAutoSaver?.clear()
            self.dbAutoSaver = nil
            self.tablesManager = nil
        }
    }

    func getdbData() -> DBData? {
        Self.expectOnDataQueue()
        guard let tablesMgr = self.tablesManager else {
            DocsLogger.warning("connection not ready when reload Data from DB", component: LogComponents.db)
            return nil
        }
        DocsLogger.info("get data from DB start", component: LogComponents.db)
        let dbData = tablesMgr.getdbData()
        dbData.logInfo()
        DocsLogger.info("get data from DB OK", component: LogComponents.db)
        return dbData
    }

    func subscribeMainStore() {
        dbAutoSaver?.subscribeMainStore()
    }
}

extension DataCenter {
//    func getFileEntryFromDB(by objToken: FileListDefine.ObjToken, completion: @escaping (SpaceEntry?) -> Void) {
//        Self.expectOnDataQueue()
//        guard let tablesMgr = tablesManager else {
//            spaceAssertionFailure("tablesManager is nil")
//            completion(nil)
//            return
//        }
//        guard let entry = tablesMgr.getFileEntry(by: objToken) else {
//            completion(nil)
//            return
//        }
//        completion(entry)
//    }

    public func getFileEntries(by tokens: [FileListDefine.ObjToken], completion: @escaping ([SpaceEntry]) -> Void) {
        Self.expectOnDataQueue()
        guard let tablesManager = tablesManager else {
            spaceAssertionFailure("tablesManager is nil")
            completion([])
            return
        }
        let entries = tablesManager.getFileEntries(by: tokens)
        completion(entries)
    }

//    func getShortCutFileEntryFromDB(by objToken: FileListDefine.NodeToken, completion: @escaping (SpaceEntry?) -> Void) {
//        Self.expectOnDataQueue()
//        guard let tablesMgr = tablesManager else {
//            spaceAssertionFailure("tablesManager is nil")
//            completion(nil)
//            return
//        }
//        guard let entry = tablesMgr.getShortCutFileEntry(by: objToken) else {
//            completion(nil)
//            return
//        }
//        completion(entry)
//    }

    public func getShortCutFileEntries(by tokens: [FileListDefine.NodeToken], completion: @escaping ([SpaceEntry]) -> Void) {
        Self.expectOnDataQueue()
        guard let tablesManager = tablesManager else {
            spaceAssertionFailure("tablesManager is nil")
            completion([])
            return
        }
        let entries = tablesManager.getShortCutFileEntries(by: tokens)
        completion(entries)
    }
}


public extension DataCenter {
    func getFilterCacheTokens(listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool, completion: @escaping ([String]?) -> Void) {
        Self.expectOnDataQueue()
        guard let tablesManager = tablesManager else {
            DocsLogger.error("get cache tokens failed, tables manager is nil")
            completion(nil)
            return
        }
        let tokens = tablesManager.getFilterCacheTokens(listID: listID,
                                                        filterType: filterType,
                                                        sortType: sortType,
                                                        isAscending: isAscending)
        completion(tokens)
    }

    func save(filterCacheTokens tokens: [String], listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool) {
        Self.expectOnDataQueue()
        guard let tablesManager = tablesManager else {
            DocsLogger.error("save cache tokens failed, tables manager is nil")
            return
        }
        tablesManager.save(filterCacheTokens: tokens,
                           listID: listID,
                           filterType: filterType,
                               sortType: sortType,
                               isAscending: isAscending)
    }
}

// MARK: - Deprecated Sync Functions
extension DataCenter {

    @available(*, deprecated, message: "Space opt: Use block style API instead. TODO: Space Refactor")
    func getFileEntryFromDB(by objToken: FileListDefine.ObjToken) -> SpaceEntry? {
        guard let tablesMgr = tablesManager else {
            spaceAssertionFailure("connection not ready when reload Data from DB")
            return nil
        }
        guard let file = tablesMgr.getFileEntry(by: objToken) else {
            return nil
        }
        return file
    }

    @available(*, deprecated, message: "Space opt: Use block style API instead. TODO: Space Refactor")
    public func getFileEntries(by tokens: [FileListDefine.ObjToken]) -> [SpaceEntry] {
        guard let tablesMgr = tablesManager else {
            spaceAssertionFailure("connection not ready when reload Data from DB")
            return []
        }
        return tablesMgr.getFileEntries(by: tokens)
    }

//    @available(*, deprecated, message: "Space opt: Use block style API instead. TODO: Space Refactor")
//    func getShortCutFileEntryFromDB(by objToken: FileListDefine.NodeToken) -> SpaceEntry? {
//        guard let tablesMgr = tablesManager else {
//            spaceAssertionFailure("connection not ready when reload Data from DB")
//            return nil
//        }
//        guard let file = tablesMgr.getShortCutFileEntry(by: objToken) else {
//            return nil
//        }
//        return file
//    }

    @available(*, deprecated, message: "Space opt: Use block style API instead. TODO: Space Refactor")
    public func getShortCutFileEntries(by tokens: [FileListDefine.NodeToken]) -> [SpaceEntry] {
        guard let tablesMgr = tablesManager else {
            spaceAssertionFailure("connection not ready when reload Data from DB")
            return []
        }
        return tablesMgr.getShortCutFileEntries(by: tokens)
    }

}

let dataQueue = DispatchQueue(label: "com.skspace.dbQueue", qos: DispatchQoS.userInitiated)
extension DispatchQueue {
    static var dataQueueToken: DispatchSpecificKey<()> = {
        let key = DispatchSpecificKey<()>()
        dataQueue.setSpecific(key: key, value: ())
        return key
    }()

    static var isDataQueue: Bool {
        return DispatchQueue.getSpecific(key: dataQueueToken) != nil
    }

    static func dataQueueSyn<Result>(task: () throws -> Result) rethrows -> Result {
        if isDataQueue {
            return try task()
        } else {
            return try dataQueue.sync {
                try task()
            }
        }
    }

    static func dataQueueAsyn(actionBlock: @escaping () -> Void) {
        dataQueue.async {
            actionBlock()
        }
    }
}
