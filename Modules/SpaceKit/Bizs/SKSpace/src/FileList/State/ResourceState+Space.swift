//
//  ResourceState+Space.swift
//  SKECM
//
//  Created by guoqp on 2020/7/1.
// swiftlint:disable file_length

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SpaceInterface

// MARK: - 列表全量/增量更新
extension ResourceState {
    mutating func resetPersonalFiles(_ data: FileDataDiff, folderKey: DocFolderKey) {
        expectOnQueue()
        // 刷新列表时先取出未同步完成的文档Token，等列表刷新结束后将文档插到最后一个文件夹下
        let fakeTokens = specialTokens[folderKey].filter { $0.token.isFakeToken }
        specialTokens[folderKey].removeAll()
        updatePersonalFiles(data, folderKey: folderKey)
        // 列表网络数据更新结束后将fakeToken插入到文件夹下
        let inserIndex = specialTokens[folderKey].firstIndex { tokenStruct in
            let entry: SpaceEntry
            if folderKey.mixUsingObjTokenAndNodeToken {
                // 针对混合使用的列表，在离线插入时要区分下 objToken 和 nodeToken
                guard let objToken = nodeTokenToObjTokenMap[tokenStruct],
                      let fileEntry = allFileEntries[objToken] else {
                    return false
                }
                entry = fileEntry
            } else {
                guard let fileEntry = allFileEntries[tokenStruct.token] else {
                    return false
                }
                entry = fileEntry
            }
            return entry.type != .folder
        } ?? 0
        specialTokens[folderKey].insert(contentsOf: fakeTokens, at: inserIndex)
    }

    mutating func appendPersonalFiles(_ data: FileDataDiff, folderKey: DocFolderKey) {
        expectOnQueue()
        updatePersonalFiles(data, folderKey: folderKey)
    }

    private mutating func updatePersonalFiles(_ data: FileDataDiff, folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].append(contentsOf: data.personalFileObjs)
        specialListPagingInfo[folderKey] = data.personalFilesPagingInfo
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        updateAllFileEntriesByNodes(data.objsInfos)
        updateUserFile()
    }

    mutating func resetShareFolder(_ data: FileDataDiff) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        specialTokens[.shareFolder] = data.shareFoldersObjs
        specialListPagingInfo[.shareFolder] = data.shareFolderPagingInfo
        updateUserFile()
    }
    
    mutating func resetShareFolderV2(_ data: FileDataDiff) {
        expectOnQueue()
        specialTokens[.shareFolderV2].removeAll(keepingCapacity: true)
        appendShareFolderV2(data)
    }
    
    mutating func appendShareFolderV2(_ data: FileDataDiff) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        specialTokens[.shareFolderV2].append(contentsOf: data.shareFoldersObjs)
        specialListPagingInfo[.shareFolderV2] = data.shareFolderPagingInfo
        updateUserFile()
    }
    
    mutating func resetHiddenFolderV2(_ data: FileDataDiff) {
        expectOnQueue()
        specialTokens[.hiddenFolder].removeAll(keepingCapacity: true)
        appendHiddenFolderV2(data)
    }
    
    mutating func appendHiddenFolderV2(_ data: FileDataDiff) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        specialTokens[.hiddenFolder].append(contentsOf: data.shareFoldersObjs)
        specialListPagingInfo[.hiddenFolder] = data.shareFolderPagingInfo
        updateUserFile()
    }

    mutating func updateHiddenStatus(of nodeToken: FileListDefine.NodeToken, to hidden: Bool) {
        expectOnQueue()
        guard
            let objToken = nodeTokenToObjTokenMap[TokenStruct(token: nodeToken)],
            let fileEntry = fileEntryToModify(key: objToken) else {
                DocsLogger.info("can not get fileEntry for \(DocsTracker.encrypt(id: nodeToken))")
                updateUserFileCount += 1
                return
        }

        fileEntry.updateHiddenStatus(hidden)
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }
    
    mutating func updateHiddenStatusV2(of nodeToken: FileListDefine.NodeToken, to hidden: Bool) {
        expectOnQueue()
        guard let objToken = nodeTokenToObjTokenMap[TokenStruct(token: nodeToken)],
              let fileEntry = fileEntryToModify(key: objToken) else {
                  DocsLogger.info("can not get fileEntry for \(DocsTracker.encrypt(id: nodeToken))")
                  updateUserFileCount += 1
                  return
        }
        
        fileEntry.updateHiddenStatus(hidden)
        allFileEntries[objToken] = fileEntry
        if !hidden {
            specialTokens[.hiddenFolder].removeAll { $0.token == objToken }
        } else {
            specialTokens[.shareFolderV2].removeAll { $0.token == objToken }
        }
        updateUserFile()
    }

    mutating func resetShareFiles(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].removeAll(keepingCapacity: true)
        appendShareFiles(data, folderKey)
    }

    mutating func appendShareFiles(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodes(data.objsInfos)
        specialTokens[folderKey].append(contentsOf: data.shareObjs)
        specialListPagingInfo[folderKey] = data.sharePagingInfo
        updateUserFile()
    }

    mutating func resetPins(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].removeAll(keepingCapacity: true)
        updatePins(data, folderKey)
    }

    mutating func updatePins(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        updateUsersByDict(data.users)
        specialTokens[folderKey] = data.pinObjs
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        updateAllFileEntriesByNodes(data.objsInfos)
        let nodesFileToken = Array(data.nodes.keys)
        add(folders: [FileData.pinFilesPathKey: nodesFileToken])
        updateUserFile()
    }

    mutating func resetFavorites(_ data: FileDataDiff, folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].removeAll()
        appendFavorites(data, folderKey: folderKey)
    }

    mutating func appendFavorites(_ data: FileDataDiff, folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].append(contentsOf: data.starObjs)
        specialListPagingInfo[folderKey] = data.starPagingInfo
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodes(data.objsInfos)
        updateUserFile()
    }

    mutating func resetFilesForOneFolder(_ data: FileDataDiff) {
        expectOnQueue()
        update(pagingInfos: data.filePaingInfos)
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        add(folders: data.folders)
        updateUserFile()
        userFile.folderInfoMap.error = nil
    }

    /// 把若干fileEntry加到某个文件夹文件列表末尾
    mutating func appendFilesToFolder(_ data: FileDataDiff) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodeTokenInfo(nodes: data.nodes)
        append(folders: data.folders)
        update(pagingInfos: data.filePaingInfos)
        updateUserFile()
    }

    // MARK: Recent files
    mutating func resetRecentFilesOld(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].removeAll { !$0.token.isFakeToken }
        updateRecentFilesOld(data, folderKey)
    }

    mutating func updateRecentFilesOld(_ data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        specialTokens[folderKey].append(contentsOf: data.recentObjs)
        specialListPagingInfo[folderKey] = data.recentPagingInfo
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodes(data.objsInfos)
        updateUserFile()
    }

    mutating func resetRecentFiles(tokens: [String], _ folderKey: DocFolderKey) {
        expectOnQueue()
        let nodes = tokens.compactMap({ TokenStruct(token: $0) })
        specialTokens[folderKey] = nodes
        specialListPagingInfo[folderKey] = PagingInfo(hasMore: false, total: nodes.count, pageTitle: nil, lastLabel: nil)
        updateUserFile()
    }

    mutating func mergeRecentFiles(data: FileDataDiff, _ folderKey: DocFolderKey) {
        expectOnQueue()
        updateUsersByDict(data.users)
        updateAllFileEntriesByNodes(data.objsInfos)
        var set = Set(data.recentObjs)
        var mergedCurrentTokens = data.recentObjs
        // 过滤掉重复的 tokens
        let currentTokens: [TokenStruct] = specialTokens[folderKey].filter { set.insert($0).inserted }
        mergedCurrentTokens.append(contentsOf: currentTokens)
        specialTokens[folderKey] = mergedCurrentTokens
        updateUserFile()
    }

    mutating func updateFileEntryExternal(info: [FileListDefine.ObjToken: Bool]) {
        expectOnQueue()
        guard !info.isEmpty else {
            DocsLogger.info("info is empty")
            updateUserFileCount += 1
            return
        }
        for (objToken, externals) in info {
            if let fileEntry = fileEntryToModify(key: objToken) {
                fileEntry.externalSwitch = externals
                allFileEntries[objToken] = fileEntry
            }
        }
        updateUserFile()
    }
}


// MARK: - 本地列表的增删
extension ResourceState {
    mutating func deleteRecentFile(_ objTokens: [FileListDefine.ObjToken]) {
        expectOnQueue()
        let tokenSet = Set(objTokens)
        DocFolderKey.recentListKeys.forEach { folderKey in
            specialTokens[folderKey].removeAll { tokenSet.contains($0.token) }
        }
        updateUserFile()
    }

    mutating func deleteShareFile(_ token: FileListDefine.ObjToken) {
        expectOnQueue()
        DocFolderKey.shareFileListKeys.forEach { folderKey in
            specialTokens[folderKey].removeAll { $0.token == token }
        }
        updateUserFile()
    }

    mutating func deletePersonalFile(_ objToken: FileListDefine.ObjToken) {
        expectOnQueue()
        DocFolderKey.personalListKeys.forEach { folderKey in
            specialTokens[folderKey].removeAll { $0.token == objToken }
        }
        updateUserFile()
    }
}

// MARK: 内部逻辑
extension ResourceState {

    private mutating func updateAllFileEntriesByNodeTokenInfo(nodes: [TokenStruct: [FileListDefine.Key: Any]]) {
        expectOnQueue()
        var objInfos = [TokenStruct: FileListDefine.Node]()
        var newNodeToObjtokenMap = [TokenStruct: FileListDefine.ObjToken]()
        for (nodeToken, node) in nodes {
            guard let objToken = node[FileListServerKeys.objToken.rawValue] as? FileListDefine.ObjToken else {
                DocsLogger.info("can not get objToken from nodeToken")
                spaceAssertionFailure()
                continue
            }
            newNodeToObjtokenMap[nodeToken] = objToken
            objInfos[nodeToken] = node
        }
        updateAllFileEntriesByNodes(objInfos)
        nodeTokenToObjTokenMap.merge(newNodeToObjtokenMap) { (_, new) in new }
    }
    private mutating func updateAllFileEntriesByNodes(_ nodes: [TokenStruct: FileListDefine.Node]) {
        nodes.forEach { (_, node) in
            guard let objToken = node["obj_token"] as? String else {
                spaceAssertionFailure("objToken is nil")
                DocsLogger.warning("objToken is nil")
                return
            }
            if let nodeType = node["node_type"] as? Int, nodeType == 1 {
                //快捷方式
                if let token = node["token"] as? String {
                    updateShortCut(objToken: objToken, nodeToken: token, with: node)
                } else {
                    spaceAssertionFailure("token is nil")
                    DocsLogger.warning("token is nil")
                }
            } else {
                //本体
                update(objToken: objToken, with: node)
            }
        }
    }

    private mutating func update(objToken: String, with node: FileListDefine.Node, verify: Bool = true, needCover: Bool = true) {

        func updateFileEntryFrom(objInfo: FileListDefine.ObjInfo,
                                         users: [FileListDefine.UserID: UserInfo],
                                         file: SpaceEntry,
                                         verify: Bool = true) {
            let json = JSON(objInfo)
            if verify {
                guard let objToken = json["obj_token"].string,
                    objToken == file.objToken else {
                        DocsLogger.error("objToken mismatch when updating properties")
                        return
                }
            }
            file.updatePropertiesFrom(json, needCover: needCover)
            guard let ownerId = json["owner_id"].string else {
                DocsLogger.debug("can not finde ownerid", component: LogComponents.dataModel)
                return
            }
            if let user = users[ownerId] {
                file.update(ownerInfo: user)
            }
        }

        var nodeToken = node["token"] as? String
        //新的共享空间列表，返回的文件夹节点没有token字段。
        if nodeToken == nil, let type = node["type"] as? Int, type == DocsType.folder.rawValue {
            nodeToken = objToken
        }
        guard let fileEntry = fileEntryToModify(key: objToken, newNodeToken: nodeToken) else {
            // 逻辑走到此分支时，需要额外设置一下 nodeToken，否则会导致新共享空间列表 nodeToken 不正确
            let fileEntry = DataBuilder.parseNoNodeTokenFileEntryFor(objInfo: node, users: self.allUsers)
            if let nodeToken {
                allFileEntries[objToken] = fileEntry?.makeCopy(newNodeToken: nodeToken)
            } else {
                allFileEntries[objToken] = fileEntry
            }
            return
        }

        // 解决pin列表缩略图为空，导致网格视图缩略图拿不到cache，cell错乱问题
        let lastThumbnail = fileEntry.thumbnailUrl
        var newThumbnail = node["thumbnail"] as? String
        if newThumbnail == nil {
            newThumbnail = lastThumbnail
        } else if let newThumbnail1 = newThumbnail, newThumbnail1.isEmpty {
            newThumbnail = lastThumbnail
        }
        var entryInfo = node
        entryInfo["thumbnail"] = newThumbnail

        updateFileEntryFrom(objInfo: entryInfo, users: self.allUsers, file: fileEntry, verify: verify)

        if let parent = getFolderTokenForNodeToken(fileEntry.nodeToken) {
            fileEntry.updateParent(parent)
        } else {
            fileEntry.updateParent(nil)
        }
        allFileEntries[objToken] = fileEntry
    }


    private mutating func updateShortCut(objToken: String, nodeToken: String, with node: FileListDefine.Node) {

        func updateFileEntryFrom(objInfo: FileListDefine.ObjInfo,
                                         users: [FileListDefine.UserID: UserInfo],
                                         file: SpaceEntry) {
            let json = JSON(objInfo)
            guard let objToken = json["obj_token"].string,
                objToken == file.objToken else {
                    DocsLogger.error("objToken mismatch when updating properties")
                    return
            }
            file.updatePropertiesFrom(json)
            guard let ownerId = json["owner_id"].string else {
                DocsLogger.debug("can not finde ownerid", component: LogComponents.dataModel)
                return
            }
            if let user = users[ownerId] {
                file.update(ownerInfo: user)
            }
        }

        guard let fileEntry = fileEntryToModify(key: nodeToken, newNodeToken: nodeToken) else {
            let fileEntry = DataBuilder.parseNoNodeTokenFileEntryFor(objInfo: node, users: self.allUsers)
            allFileEntries[nodeToken] = fileEntry
            return
        }

        // 解决pin列表缩略图为空，导致网格视图缩略图拿不到cache，cell错乱问题
        let lastThumbnail = fileEntry.thumbnailUrl
        var newThumbnail = node["thumbnail"] as? String
        if newThumbnail == nil {
            newThumbnail = lastThumbnail
        } else if let newThumbnail1 = newThumbnail, newThumbnail1.isEmpty {
            newThumbnail = lastThumbnail
        }
        var entryInfo = node
        entryInfo["thumbnail"] = newThumbnail

        updateFileEntryFrom(objInfo: entryInfo, users: self.allUsers, file: fileEntry)
        allFileEntries[nodeToken] = fileEntry
    }

}

// MARK: - Offline stuff
extension ResourceState {

    
}

// MARK: - 其他业务逻辑
extension ResourceState {

    private mutating func changeObjTokenPosition(_ curToken: FileListDefine.ObjToken, frontToken: FileListDefine.ObjToken?, isTop: Bool,
                                                 in targetTokens: [FileListDefine.ObjToken]) -> [FileListDefine.ObjToken] {
        expectOnQueue()
        guard !targetTokens.isEmpty, let oriIndex = targetTokens.firstIndex(of: curToken), oriIndex >= 0 else { return targetTokens }

        var newTokens = targetTokens
        let placeHolderToken = Date().sk.dateString(in: .long) + "\(#function)\(#line)"

        newTokens[oriIndex] = placeHolderToken
        var targetIndex = 0
        if let frontToken = frontToken, let frontIndex = targetTokens.firstIndex(of: frontToken) {
            targetIndex = frontIndex + 1
        }
        newTokens.insert(curToken, at: targetIndex)
        let placeHolderIndex = newTokens.firstIndex(of: placeHolderToken)
        newTokens.remove(at: placeHolderIndex!)
        if let fileEntry = fileEntryToModify(key: curToken) {
            fileEntry.updateTopStatus(isTop)
            allFileEntries[curToken] = fileEntry
        }
        return newTokens
    }

    mutating func changePinsStatus(objToken: FileListDefine.ObjToken, isPined: Bool) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken)else {
            DocsLogger.info("can not find objToken")
            //有可能把不在列表里的加到 Pin
            updateUserFileCount += 1
            return
        }
        let copy = fileEntry.makeCopy()
        allFileEntries[objToken] = copy
        allFileEntries.forEach({ (_, entry) in
            if entry.objToken == objToken {
                entry.updatePinedStatus(isPined)
                entry.updateTopStatus(isPined)
            }
        })
        updateUserFile()
    }


    mutating func changeStarStatus(_ objToken: FileListDefine.ObjToken, isStared: Bool) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            DocsLogger.info("can not get fileEntry for \(DocsTracker.encrypt(id: objToken))")
            updateUserFileCount += 1
            return
        }
        if isStared {
            fileEntry.updateFavoriteTime(Date().timeIntervalSince1970)
            DocFolderKey.favoritesListKeys.forEach { folderKey in
                if !specialTokens[folderKey].contain(objToken: objToken) {
                    specialTokens[folderKey].insert(TokenStruct(token: objToken), at: 0)
                }
            }
        } else {
            DocFolderKey.favoritesListKeys.forEach { folderKey in
                specialTokens[folderKey].removeAll { $0.token == objToken }
            }
        }
        allFileEntries[objToken] = fileEntry
        allFileEntries.forEach({ (_, entry) in
            if entry.objToken == objToken {
                entry.updateStaredStatus(isStared)
            }
        })
        updateUserFile()
    }
}

// MARK: - 手动离线
extension ResourceState {

    /// 标记一个文件，为手动离线文档，或删除，不再是手动离线
    mutating func resetManualOfflineTag(of objToken: FileListDefine.ObjToken, to isSetManuOffline: Bool) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            DocsLogger.info("resetManualOfflineTag can not get fileEntry for \(DocsTracker.encrypt(id: objToken))", component: LogComponents.manuOffline)
            updateUserFileCount += 1
            return
        }
        DocsLogger.info("resetManualOfflineTag from :\(fileEntry.isSetManuOffline) to: \(isSetManuOffline), file type: \(fileEntry.type)", component: LogComponents.manuOffline)

        if isSetManuOffline {
            if !specialTokens[.manuOffline].contain(objToken: objToken) {
                specialTokens[.manuOffline].insert(TokenStruct(token: objToken), at: 0)
                /// 记录当下时间，缺点是用户改了系统时间就不准了
                fileEntry.addManuOfflineTime = Date().timeIntervalSince1970
            }
        } else {
            specialTokens[.manuOffline].removeAll { $0.token == objToken }
            // 同时重置同步状态显示
            fileEntry.hadShownManuStatus = false
            fileEntry.addManuOfflineTime = nil
        }
        fileEntry.isSetManuOffline = isSetManuOffline
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }
    
    mutating func resetMOFileFromDetailPage(of entry: SpaceEntry, to isSetManuOffline: Bool) {
        if fileEntryToModify(key: entry.objToken) != nil {
            /// 列表DB中已经有当前打开文档的数据，不需要插入假数据
            resetManualOfflineTag(of: entry.objToken, to: isSetManuOffline)
            return
        }
        /// 列表DB没有当前操作的打开文档的数据，插入一个假数据进实体表，真实引用Token到离线列表引用表
        let entry = entry.makeCopy()
        entry.isSetManuOffline = isSetManuOffline
        allFileEntries[entry.objToken] = entry
        
        resetManualOfflineTag(of: entry.objToken, to: isSetManuOffline)
    }
 
    mutating func updateFileSize(of objToken: FileListDefine.ObjToken, fileSize: UInt64) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            DocsLogger.info("can not get fileEntry for \(DocsTracker.encrypt(id: objToken))")
            updateUserFileCount += 1
            return
        }

        fileEntry.fileSize = fileSize
        allFileEntries[objToken] = fileEntry
        /// 先简单粗暴的更新，防止有的地方需要使用到最新数据
        updateUserFile()
    }
}
// MARK: - Rust Push Event Handler
extension ResourceState {
    // 因为 Rust 推送时可能包含多种事件，为了降低数据更新的频率，处理 Rust 推送的所有方法中都不应该修改 updateUserFileCount 的值，包括提前return时直接修改、调用 updateUserFile()，而是在处理完所有事件后统一进行更新

    mutating func deleteRecentForPush(objToken: FileListDefine.ObjToken) {
        expectOnQueue()
        DocFolderKey.recentListKeys.forEach { folderKey in
            specialTokens[folderKey].removeAll { $0.token == objToken }
        }
    }

    mutating func updateEntryForPush(objToken: FileListDefine.ObjToken, data: FileListDefine.ObjInfo, users: FileListDefine.Users) {
        expectOnQueue()
        updateUsersByDict(users)
        update(objToken: objToken, with: data, verify: false, needCover: false)
        allFileEntries[objToken]?.updateExtra()
    }

    mutating func addRecentEntryForPush(objToken: FileListDefine.ObjToken, data: FileListDefine.ObjInfo, users: FileListDefine.Users) {
        updateEntryForPush(objToken: objToken, data: data, users: users)
        if !specialTokens[.recent].contain(objToken: objToken) {
            specialTokens[.recent].insert(TokenStruct(token: objToken), at: 0)
            DocsLogger.info("insert file to recent")
        }
    }
}
