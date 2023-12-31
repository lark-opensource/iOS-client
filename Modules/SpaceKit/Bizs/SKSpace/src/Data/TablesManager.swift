//
//  TablesManager.swift
//
//  Created by weidong fu on 27/1/2018.
//

import Foundation
import SQLite
import SKFoundation
import SKCommon

class TablesManager {
    // MARK: - New table
    private lazy var fileEntryTable: NewFileEntrisTable = {
        return NewFileEntrisTable(docConnection)
    }()

    private lazy var shortCutFileEntryTable: ShortCutFileEntriesTable = {
        return ShortCutFileEntriesTable(docConnection)
    }()

    private lazy var newUserTable: NewUsersTable = {
        return NewUsersTable(docConnection)
    }()

    private lazy var newFolderMapTable: NewFolderMapTable = {
        return NewFolderMapTable(docConnection)
    }()

    private lazy var nodeToObjTokenMapTable: NodeToObjTokenMapTable = {
        return NodeToObjTokenMapTable(docConnection)
    }()

    private lazy var specialFolderTable: SpecialFolderTable = {
        return SpecialFolderTable(docConnection)
    }()

    private lazy var spaceFilterSortListCacheTable: SpaceListCacheTable? = {
        return SpaceListCacheTable(connectionProvider: docConnection)
    }()

    // MARK: - New table end

    private let docConnection: DocsDBConnectionProvidor

    init(_ docConnection: DocsDBConnectionProvidor = Connection.docs) {
        self.docConnection = docConnection
    }

    deinit {
        DocsLogger.info("TablesManager deinit")
    }
}

extension TablesManager {

    func updateDB(_ dbDataDiff: DBDataDiff) {
        do {
            try docConnection.file?.transaction {
                fileEntryTable.delete(dbDataDiff.deleteFileEntry)
                fileEntryTable.update(dbDataDiff.fileEntry)
                shortCutFileEntryTable.delete(dbDataDiff.shortCutDeleteFileEntry)
                shortCutFileEntryTable.update(dbDataDiff.shortCutFileEntry)
                newFolderMapTable.delete(dbDataDiff.deleteNodeTokensMap)
                newFolderMapTable.update(dbDataDiff.nodeTokensMap)
                newUserTable.delete(dbDataDiff.deleteUsers)
                newUserTable.update(dbDataDiff.users)
                nodeToObjTokenMapTable.delete(dbDataDiff.deleteNodeToObjTokenMap)
                nodeToObjTokenMapTable.update(dbDataDiff.nodeToObjTokenMap)
                specialFolderTable.update(specialTokensDiff: dbDataDiff.specialTokensDiff)
            }
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
        }
    }

    func getdbData() -> DBData {
        DocsTracker.startRecordTimeConsuming(eventType: .databaseInit, parameters: nil)
        var dbData = DBData()
        do {
            try docConnection.file?.transaction {
                let beforeOptTime: TimeInterval = NSDate().timeIntervalSince1970
                dbData.users = newUserTable.getAllUsers()
                dbData.specialTokens = specialFolderTable.getSpecialTokens()
                dbData.nodeToObjTokenMap = nodeToObjTokenMapTable.getNodeObjTokenMap()
                dbData.nodeTokensMap = newFolderMapTable.getFolderMap()
                let afterOptTime: TimeInterval = NSDate().timeIntervalSince1970
                DocsLogger.info("[db test] getdbData fileEntryCont\(dbData.fileEntry.count)- \(afterOptTime - beforeOptTime)", component: LogComponents.db)
            }
        } catch {
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
        }
        DocsTracker.endRecordTimeConsuming(eventType: .databaseInit, parameters: nil)
        return dbData
    }

//    func getShortCutFileEntry(by nodeToken: String) -> SpaceEntry? {
//        DocsLogger.info("getShortCutFileEntryFromDb", component: LogComponents.db)
//        var fileEntry: SpaceEntry?
//        do {
//            try docConnection.file?.transaction {
//                fileEntry = shortCutFileEntryTable.getFileEntry(by: nodeToken)
//            }
//        } catch {
//            spaceAssertionFailure()
//            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
//        }
//        return fileEntry
//    }

    func getShortCutFileEntries(by tokens: [String]) -> [SpaceEntry] {
        var fileEntries: [SpaceEntry] = []
        do {
            try docConnection.file?.transaction {
                fileEntries = shortCutFileEntryTable.getFileEntries(tokens)
            }
        } catch {
            spaceAssertionFailure()
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
        }
        return fileEntries
    }

    func getFileEntry(by objToken: FileListDefine.ObjToken) -> SpaceEntry? {
        var fileEntry: SpaceEntry?
        do {
            try docConnection.file?.transaction {
                fileEntry = fileEntryTable.getFileEntry(by: objToken)
            }
        } catch {
            spaceAssertionFailure()
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
        }
        return fileEntry
    }

    func getFileEntries(by tokens: [FileListDefine.ObjToken]) -> [SpaceEntry] {
        var fileEntries: [SpaceEntry] = []
        do {
            try docConnection.file?.transaction {
                fileEntries = fileEntryTable.getFileEntries(tokens)
            }
        } catch {
            spaceAssertionFailure()
            DocsLogger.error("数据库相关", error: error, component: LogComponents.db)
        }
        return fileEntries
    }
}

extension TablesManager {

    func getFilterCacheTokens(listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool) -> [String]? {
        guard let cacheTable = spaceFilterSortListCacheTable else {
            DocsLogger.error("failed to get filter cache tokens, spaceFilterSortListCacheTable is nil")
            return nil
        }
        return cacheTable.getTokens(listID: listID, filterType: String(filterType.rawValue),
                                    sortType: sortType.rawValue, isAscending: isAscending)
    }

    func save(filterCacheTokens tokens: [String], listID: String, filterType: FilterItem.FilterType, sortType: SortItem.SortType, isAscending: Bool) {
        guard let cacheTable = spaceFilterSortListCacheTable else {
            DocsLogger.error("failed to save filter cache tokens, spaceFilterSortListCacheTable is nil")
            return
        }
        cacheTable.save(tokens: tokens, listID: listID, filterType: String(filterType.rawValue), sortType: sortType.rawValue, isAscending: isAscending)
    }
}

extension SQLite.Result: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case let .error(message, errorCode, statement):
            if let statement = statement {
                return "\(message) (\(statement)) (code: \(errorCode))"
            } else {
                return "\(message) (code: \(errorCode))"
            }
        @unknown default:
            return description
        }
    }
}
