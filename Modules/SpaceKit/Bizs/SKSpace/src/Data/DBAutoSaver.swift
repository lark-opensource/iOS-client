//
//  DBAutoSaver.swift
//  SpaceKit
//
//  Created by guotenghu on 2019/7/11.
//  
// 数据库自动保存的逻辑

import Foundation
import ReSwift
import SKFoundation
import SKCommon

final class DBAutoSaver {
    let fileResource: FileResource
    let tableManger: TablesManager
    private var hasSubscribed = false
    private var dbDataDiff = DBDataDiff()
    typealias TokenToObjTokenData = [TokenStruct: FileListDefine.ObjToken]
    typealias TokenMapData = [FileListDefine.NodeToken: [TokenStruct]]

    init(fileResource: FileResource, tableManger: TablesManager) {
        self.fileResource = fileResource
        self.tableManger = tableManger
    }

    func subscribeMainStore() {
        DocsLogger.info("subscribe for db save", component: LogComponents.db)
        assertMainThread()
        if hasSubscribed { return }
//        spaceAssert(!hasSubscribed)
        hasSubscribed = true
        self.fileResource.subscribe(self) { (state) in
            state.select { $0 }.skipRepeats({ (old, new) -> Bool in
                self.dbDataDiff = self.getDBDiffBetween(old, new)
//                DocsLogger.info("action: \(type(of: new.currentAction)), get dbDataDiff is \(self.dbDataDiff)")
//                DocsLogger.info("action: \(new.currentAction), get dbDataDiff is \(self.dbDataDiff)", component: LogComponents.db)

                return self.dbDataDiff.isAllEmpty
            })
        }
    }

    func clear() {
        DocsLogger.info("unsubscribe for db save", component: LogComponents.db)
        guard hasSubscribed else { return }
        hasSubscribed = false
        self.fileResource.unsubscribe(self)
    }

    private func assertMainThread() {
        spaceAssertMainThread()
    }

    private func getDBDiffBetween(_ oldState: ResourceState, _ newState: ResourceState) -> DBDataDiff {
        var diff = DBDataDiff()
        diff.specialTokensDiff = getSpecialTokensDiff(oldState.specialTokens, new: newState.specialTokens)
        (diff.users, diff.deleteUsers) = getUsersDiff(oldState.allUsers, new: newState.allUsers)

        var oldAllFileEntries: [FileListDefine.ObjToken: SpaceEntry] = [:]
        var newAllFileEntries: [FileListDefine.ObjToken: SpaceEntry] = [:]
        var oldShortCutAllFileEntries: [FileListDefine.NodeToken: SpaceEntry] = [:]
        var newShortCutAllFileEntries: [FileListDefine.NodeToken: SpaceEntry] = [:]
        for (_, entry) in oldState.allFileEntries {
            if entry.isShortCut {
                oldShortCutAllFileEntries[entry.nodeToken] = entry
            } else {
                oldAllFileEntries[entry.objToken] = entry
            }
        }
        for (_, entry) in newState.allFileEntries {
            if entry.isShortCut {
                newShortCutAllFileEntries[entry.nodeToken] = entry
            } else {
                newAllFileEntries[entry.objToken] = entry
            }
        }
        (diff.fileEntry, diff.deleteFileEntry) = getFileEntryDiff(oldAllFileEntries, new: newAllFileEntries)
        (diff.shortCutFileEntry, diff.shortCutDeleteFileEntry) = getFileEntryDiff(oldShortCutAllFileEntries, new: newShortCutAllFileEntries)

        (diff.nodeToObjTokenMap, diff.deleteNodeToObjTokenMap) = getNodeTokenToObjTokenDiff(oldState.nodeTokenToObjTokenMap, new: newState.nodeTokenToObjTokenMap)
        (diff.nodeTokensMap, diff.deleteNodeTokensMap) = getNodeTokenMapDiff(oldState.nodeTokenMap, new: newState.nodeTokenMap)
        return diff
    }

    private func getSpecialTokensDiff(_ old: SpecialTokens, new: SpecialTokens) -> SpecialTokensDiff {
        var diff = SpecialTokensDiff()
        DocFolderKey.allCases.forEach { folderKey in
            let oldTokens = old[folderKey]
            let newTokens = new[folderKey]
            if !oldTokens.elementsEqual(newTokens) {
                diff[folderKey] = newTokens
            }
        }
        return diff
    }

    private func getUsersDiff(_ old: [FileListDefine.UserID: UserInfo], new: [FileListDefine.UserID: UserInfo]) -> ([UserInfo], [UserInfo]) {
        var inCreaseOrChanges = [UserInfo]()
        var deletes = [UserInfo]()
        for (key, value) in new where old[key] !== value {
            inCreaseOrChanges.append(value)
        }
        if new.count < old.count {
            for (key, value) in old where new[key] == nil {
                DocsLogger.info("【DBAutoSaver】getUsersDiff delete", component: LogComponents.db)
                deletes.append(value)
            }
        }
        return (inCreaseOrChanges, deletes)
    }

    private func getFileEntryDiff(_ old: [FileListDefine.ObjToken: SpaceEntry], new: [FileListDefine.ObjToken: SpaceEntry]) -> ([SpaceEntry], [SpaceEntry]) {
        var inCreaseOrChanges = [SpaceEntry]()
        var deletes = [SpaceEntry]()
        for (key, value) in new where old[key] !== value {
            inCreaseOrChanges.append(value)
        }
        if new.count < old.count {
            for (key, value) in old where new[key] == nil {
                DocsLogger.info("【DBAutoSaver】getFileEntryDiff delete", component: LogComponents.db)
                deletes.append(value)
            }
        }
        return (inCreaseOrChanges, deletes)
    }

    private func getNodeTokenToObjTokenDiff(_ old: TokenToObjTokenData, new: TokenToObjTokenData) -> (TokenToObjTokenData, TokenToObjTokenData) {
        var inCreaseOrChanges = [TokenStruct: FileListDefine.ObjToken]()
        var deletes = [TokenStruct: FileListDefine.ObjToken]()
        for (key, value) in new where old[key] != value {
            inCreaseOrChanges[key] = value
        }
        if new.count < old.count {
            for (key, value) in old where new[key] == nil {
                DocsLogger.info("【DBAutoSaver】getNodeTokenToObjTokenDiff delete", component: LogComponents.db)
                deletes[key] = value
            }
        }
        return (inCreaseOrChanges, deletes)
    }

    private func getNodeTokenMapDiff(_ old: TokenMapData, new: TokenMapData) -> (TokenMapData, TokenMapData) {
        var inCreaseOrChanges = [FileListDefine.NodeToken: [TokenStruct]]()
        var deletes = [FileListDefine.NodeToken: [TokenStruct]]()
        for (key, value) in new where old[key] != value {
            inCreaseOrChanges[key] = value
        }
        if new.count < old.count {
            for (key, value) in old where new[key] == nil {
                DocsLogger.info("【DBAutoSaver】getNodeTokenMapDiff delete", component: LogComponents.db)
                deletes[key] = value
            }
        }
        return (inCreaseOrChanges, deletes)
    }
}

extension DBAutoSaver: StoreSubscriber {
    func newState(state: ResourceState) {
//        guard !dbDataDiff.isAllEmpty else {
//            spaceAssertionFailure("dbDataDiff is empty, but called new state!!")
//            return
//        }
        DocsLogger.info("save dbDataDiff to DB", component: LogComponents.db)
//        dbDataDiff.logInfo()
        dbDataDiff.checkStatus()
        tableManger.updateDB(dbDataDiff)
    }
}
