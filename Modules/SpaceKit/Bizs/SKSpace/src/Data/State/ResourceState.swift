//
//  ResourceState.swift
//  FileResource
//
//  Created by weidong fu on 22/1/2018.
// swiftlint:disable file_length

import Foundation
import ReSwift
import SwiftyJSON
import SQLite
import SKFoundation
import SKCommon
import SpaceInterface
import SKInfra
import LarkContainer

public struct ResourceState: StateType {
    // MARK: - debug Info
    /// 当前正在处理的 Action，用于追查问题
    public var currentAction: Action?
    public var stateUpdateCount = 0
    //updateUser 被调用的次数。理论上，每个action都要调用一次这个。
    // 如果不调用是正常情况，要手动把这个+1
    public var updateUserFileCount = 0
    public func expectOnQueue() {
        #if DEBUG
        dispatchPrecondition(condition: .onQueue(dataQueue))
        #endif
    }

    public init () {
        
    }

    public func checkStatus() {
        expectOnQueue()
        specialTokens.checkStatus()
    }
    // MARK: - 原始数据
    var allUsers = [FileListDefine.UserID: UserInfo]()
    //本体以objtoken作为key,快捷方式以token作为key
    var allFileEntries = [FileListDefine.Key: SpaceEntry]()
    public var nodeTokenToObjTokenMap = [TokenStruct: FileListDefine.ObjToken]()
    /// 文件夹下面有什么子文件
    public var nodeTokenMap = [FileListDefine.NodeToken: [TokenStruct]]()
    public var specialTokens = SpecialTokens()

    /// [foler token: PaingInfos]
    public var filePaingInfos = [FileListDefine.NodeToken: PagingInfo]()
    public var specialListPagingInfo: [DocFolderKey: PagingInfo] = [:]
    // MARK: 结构化的数据
    public var userFile = UserFile()
}

// MARK: - 列表全量/增量更新
extension ResourceState {
    /// 用于 手动添加 SpaceEntry 到内存中，作为列表页接口请求回来之前，比如弱网络等兜底用，一般业务请勿使用，目前仅用于文档打开，如果allFileEntries中没有才添加
    mutating func addFileEntries(_ files: [SpaceEntry]) {
        expectOnQueue()
        for entry in files where allFileEntries[entry.objToken] == nil {
            allFileEntries[entry.objToken] = entry
        }
        updateUserFile()
    }
    
    /// 从数据库加载nodeToken对应的目录下的列表数据到内存中
    mutating func loadSubFolderFileEntries(by nodeToken: String) {
        expectOnQueue()
        guard let subNodeTokens = self.nodeTokenMap[nodeToken] else {
            DocsLogger.info("找不到nodeToken对应的子nodeToken列表")
            updateUserFileCount += 1
            return
        }
        _ = self.getFileEntries(by: subNodeTokens, limit: Int.max)
        updateUserFile()
    }

    /// 从数据库中删除 nodeToken 对应的目录下的列表数据
    mutating func deleteSubFolderFileEntries(by nodeToken: String) {
        expectOnQueue()
        guard let children = nodeTokenMap[nodeToken] else {
            updateUserFileCount += 1
            return
        }
        let localNodeTokens = children.filter { nodeToken in
            nodeTokenToObjTokenMap[nodeToken]?.isFakeToken ?? false
        }
        nodeTokenMap[nodeToken] = localNodeTokens.isEmpty ? nil : localNodeTokens
        updateUserFile()
    }
    
    /// 从数据库加载特殊列表数据到内存中，包括：最近列表、pin列表、共享列表、收藏列表、我的空间等
    mutating func loadFolderEntries(folderKey: DocFolderKey, limit: Int) {
        expectOnQueue()
        guard limit >= 0 else {
            DocsLogger.info("limit must greater or equal to zero")
            updateUserFileCount += 1
            return
        }
        let tokens = specialTokens.tokens(by: folderKey)
        _ = self.getFileEntries(by: tokens, limit: limit)
        updateUserFile()
    }

    private func getFileEntries(allTokens: [TokenStruct], limit: Int) -> [SpaceEntry] {
        //取前limit个
        let tokens = Array(allTokens.prefix(limit))

        if tokens.isEmpty {
            DocsLogger.info("tokens is nil")
            return []
        }
        var entries = [SpaceEntry]()

        //区分本体和快捷方式
        var tokensForQuery = [FileListDefine.Key]()
        var shortCutTokensForQuery = [FileListDefine.Key]()
        for tokenStruct in tokens {
            if tokenStruct.isShortCut {
                shortCutTokensForQuery.append(tokenStruct.token)
            } else {
                tokensForQuery.append(tokenStruct.token)
            }
        }

        //查内存中本体
        var tokensForQueryDB = [FileListDefine.Key]()
        let entriesInRAM = tokensForQuery.compactMap { (token) -> SpaceEntry? in
            guard let entry = self.allFileEntries[token] else {
                tokensForQueryDB.append(token)
                return nil
            }
            return entry
        }
        entries.append(contentsOf: entriesInRAM)

        //查内存中快捷方式
        var shortCutTokensForQueryDB = [FileListDefine.Key]()
        let shortCutEntriesInRAM = shortCutTokensForQuery.compactMap { (token) -> SpaceEntry? in
            guard let entry = self.allFileEntries[token] else {
                shortCutTokensForQueryDB.append(token)
                return nil
            }
            return entry
        }
        entries.append(contentsOf: shortCutEntriesInRAM)

        if tokensForQueryDB.isEmpty, shortCutTokensForQueryDB.isEmpty {
            DocsLogger.info("tokensNeedQueryDB is nil")
            return entries
        }

        //查DB - 本体表
        var temp = [SpaceEntry]()
        let userResolver = Container.shared.getCurrentUserResolver(compatibleMode: CCMUserScope.compatibleMode)
        let entriesInDB = DataCenter.shared.getFileEntries(by: tokensForQueryDB) ?? []
        temp.append(contentsOf: entriesInDB)

        //查DB - 快捷方式表
        let shortCutEntriesInDB = DataCenter.shared.getShortCutFileEntries(by: shortCutTokensForQueryDB) ?? []
        temp.append(contentsOf: shortCutEntriesInDB)
        entries.append(contentsOf: temp)
        return entries
    }


    private mutating func getFileEntries(by allTokens: [TokenStruct], limit: Int) -> [SpaceEntry] {
        let temp = getFileEntries(allTokens: allTokens, limit: limit)
        for entry in temp {
            entry.updateExtra()
            let key = entry.isShortCut ? entry.nodeToken : entry.objToken
            if allFileEntries[key] == nil {
                allFileEntries[key] = entry
            }
        }
        return temp
    }
    
}

// MARK: - 本地列表的增删
extension ResourceState {
    mutating func deleteByToken(_ tokenStruct: TokenStruct) {
        expectOnQueue()
        deleteByTokenInner(tokenStruct)
        updateUserFile()
    }

    // 完全删除内存中fileEntry
    private mutating func deleteByTokenInner(_ tokenStruct: TokenStruct) {
        expectOnQueue()
        specialTokens.deleteFromAllByToken(tokenStruct)
        let nodeTokensToDelete = allNodeTokenFor(tokenStruct: tokenStruct)
        nodeTokensToDelete.forEach { nodeToken in
            nodeTokenMap.forEach({ (arg0) in
                var (parent, childNodeTokens) = arg0
                childNodeTokens.removeAll { $0.token == nodeToken }
                nodeTokenMap[parent] = childNodeTokens
            })
        }
        let token = tokenStruct.token
        if tokenStruct.isShortCut {
            DocsLogger.info("delete shortcut token: \(DocsTracker.encrypt(id: token))")
        } else {
            DocsLogger.info("get \(nodeTokensToDelete.count) nodeTokens for delete objToken: \(DocsTracker.encrypt(id: token))")
        }
        allFileEntries.removeValue(forKey: tokenStruct.token)
    }


    mutating func resetManuOfflineStatus(by objToken: FileListDefine.ObjToken) {
        expectOnQueue()
        if let file = fileEntryToModify(key: objToken) {
            file.hadShownManuStatus = false
            let key = file.isShortCut ? file.nodeToken : file.objToken
            allFileEntries[key] = file
        }
        updateUserFile()
    }

    mutating func deleteFilesInSimpleMode(_ files: [SimpleModeWillDeleteFile]) {
        expectOnQueue()

        files.forEach { (file) in
            let objToken = file.objToken
            if file.isSetManuOffline {
                resetManuOfflineStatus(by: objToken)
            } else {
                deleteByTokenInner(TokenStruct(token: objToken))
            }
        }
        updateUserFile()
    }

    mutating func delete(_ nodeToken: FileListDefine.NodeToken, in folder: FileListDefine.NodeToken) {
        expectOnQueue()
        guard !nodeToken.isEmpty else {
            DocsLogger.info("Invalid file params")
            spaceAssertionFailure()
            return
        }
        remove(nodeToken, from: folder)
        updateUserFile()
    }

    mutating func move(_ nodeToken: FileListDefine.NodeToken, from folderToDelete: FileListDefine.NodeToken, to folderToAdd: FileListDefine.NodeToken) {
        expectOnQueue()
        if !nodeToken.isEmpty {
            remove(nodeToken, from: folderToDelete)
        }
        if !nodeToken.isEmpty, !folderToAdd.isEmpty {
            add(nodeToken, to: folderToAdd)
        }
        updateUserFile()
    }

    private mutating func remove(_ nodeToken: FileListDefine.NodeToken, from folderNodeToken: FileListDefine.NodeToken) {
        var orignalNodeTokens = nodeTokenMap[folderNodeToken]
        orignalNodeTokens?.removeAll { $0.token == nodeToken }
        nodeTokenMap[folderNodeToken] = orignalNodeTokens
    }

    private mutating func add(_ fileNodeToken: FileListDefine.NodeToken, to folderNodeToken: FileListDefine.NodeToken, needSortAfterFolder: Bool = false) {
        guard !folderNodeToken.isEmpty, !fileNodeToken.isEmpty else {
            DocsLogger.warning("folderNodeToken or fileNodeToken is empty")
            return
        }
        var childNodeTokens = nodeTokenMap[folderNodeToken] ?? []
        var idx = 0
        if needSortAfterFolder {
            idx = childNodeTokens.firstIndex { (nodeToken) -> Bool in
                guard let objToken = nodeTokenToObjTokenMap[nodeToken],
                    let fileEntry = allFileEntries[objToken] else {
                        DocsLogger.info("can not find file Entry")
                        return false
                }
                return fileEntry.type != .folder
            } ?? 0
        }
        let tokenStruct = TokenStruct(token: fileNodeToken)
        childNodeTokens.insert(tokenStruct, at: idx)
        nodeTokenMap[folderNodeToken] = childNodeTokens
    }

   public mutating func addAFileToAllEntries(_ file: SpaceEntry) {
        expectOnQueue()
        let key = file.isShortCut ? file.nodeToken : file.objToken
        allFileEntries[key] = file
        updateUserFileCount += 1
    }

}

// MARK: - Offline stuff
extension ResourceState {
   public mutating func replaceOldFileEntry(fileEntry: SpaceEntry, newObjToken: FileListDefine.ObjToken, newNodeToken: FileListDefine.NodeToken) {
       expectOnQueue()
       let fakeObjToken = fileEntry.objToken
       let fakeNodeToken = TokenStruct(token: fileEntry.nodeToken)
       allFileEntries[fakeObjToken] = nil
       let newEntry = fileEntry.makeCopy(newNodeToken: newNodeToken, newObjToken: newObjToken)
       let fakeShareURL = DocsUrlUtil.url(type: newEntry.type, token: newObjToken)
       newEntry.updateShareURL(fakeShareURL.absoluteString)
       newEntry.updateOriginURL(fakeShareURL.absoluteString)
       allFileEntries[newObjToken] = newEntry
       let nodeTokens = nodeTokenToObjTokenMap.keys.filter { nodeTokenToObjTokenMap[$0] == fakeObjToken }
       nodeTokens.forEach { nodeTokenToObjTokenMap[$0] = newObjToken }
       nodeTokenToObjTokenMap[TokenStruct(token: newNodeToken)] = newObjToken
       specialTokens.replaceObjToken(old: TokenStruct(token: fakeObjToken),
                                     objToken: TokenStruct(token: newObjToken),
                                     nodeToken: TokenStruct(token: newNodeToken))
       let newNodeTokenMap = nodeTokenMap.mapValues { tokens in
           tokens.map { $0 == fakeNodeToken ? TokenStruct(token: newNodeToken) : $0 }
       }
       nodeTokenMap = newNodeTokenMap
       updateUserFile()
    }

    public mutating func insertFakeFileEntry(_ fakeFileEntry: SpaceEntry, to folder: FileListDefine.NodeToken) {
        let nodeToken = fakeFileEntry.nodeToken
        let nodeTokenStruct = TokenStruct(token: nodeToken)
        expectOnQueue()
        guard !nodeToken.isEmpty, fakeFileEntry.objToken.isFakeToken else {
            spaceAssertionFailure("Invalid params")
            return
        }
        nodeTokenToObjTokenMap[nodeTokenStruct] = fakeFileEntry.objToken
        allFileEntries[fakeFileEntry.objToken] = fakeFileEntry.makeCopy()
        add(nodeToken, to: folder, needSortAfterFolder: true)
        if let objToken = nodeTokenToObjTokenMap[nodeTokenStruct] {
            let tokenStruct = TokenStruct(token: objToken)
            let specialFolders = DocFolderKey.getAffectByLocalFakeEntriesKeys(isWiki: fakeFileEntry.type == .wiki)
            specialFolders.forEach { folderKey in
                var tokens = specialTokens[folderKey]
                let tokenToInsert = folderKey.mixUsingObjTokenAndNodeToken ? nodeTokenStruct : tokenStruct
                if !tokens.contains(tokenToInsert) {
                    let index: Int
                    if folderKey.mixShowFolderAndFiles {
                        index = tokens.firstIndex { nodeToken -> Bool in
                            let entry: SpaceEntry
                            if folderKey.mixUsingObjTokenAndNodeToken {
                                // 针对混合使用的列表，在离线插入时要区分下 objToken 和 nodeToken
                                guard let objToken = nodeTokenToObjTokenMap[nodeToken],
                                      let fileEntry = allFileEntries[objToken] else {
                                    return false
                                }
                                entry = fileEntry
                            } else {
                                guard let fileEntry = allFileEntries[nodeToken.token] else {
                                    return false
                                }
                                entry = fileEntry
                            }
                            return entry.type != .folder
                        } ?? 0
                    } else {
                        index = 0
                    }
                    tokens.insert(tokenToInsert, at: index)
                    specialTokens[folderKey] = tokens
                    DocsLogger.info("insert fake entry to list: \(folderKey.name)")
                }
            }
        }
        updateUserFile()
    }

    mutating func insertUploadFileEntry(fileEntry: SpaceEntry, folderToken: FileListDefine.NodeToken) {
        expectOnQueue()
        let nodeToken = fileEntry.nodeToken
        let nodeTokenStruct = TokenStruct(token: nodeToken)
        guard !nodeToken.isEmpty else {
            spaceAssertionFailure("Invalid params")
            return
        }
        nodeTokenToObjTokenMap[nodeTokenStruct] = fileEntry.objToken
        // 这里校准一下 ownerType
        if !folderToken.isEmpty, let parentFolder = allFileEntries[folderToken] {
            fileEntry.updateOwnerType(parentFolder.ownerType)
        } else {
            fileEntry.updateOwnerType(SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType)
        }
        allFileEntries[fileEntry.objToken] = fileEntry.makeCopy()
        add(nodeToken, to: folderToken, needSortAfterFolder: true)
        let tokenStruct = TokenStruct(token: fileEntry.objToken)
        let specialFolders = DocFolderKey.getAffectByLocalFakeEntriesKeys(isWiki: false)
        specialFolders.forEach { folderKey in
            var tokens = specialTokens[folderKey]
            if !tokens.contains(tokenStruct) {
                tokens.insert(tokenStruct, at: 0)
                specialTokens[folderKey] = tokens
                DocsLogger.info("insert fake uploaded entry to list: \(folderKey.name)")
            }
        }
        updateUserFile()
    }

    mutating func insertUploadWikiEntry(fileEntry: SpaceEntry) {
        expectOnQueue()
        allFileEntries[fileEntry.objToken] = fileEntry.makeCopy()
        let tokenStruct = TokenStruct(token: fileEntry.objToken)
        let specialFolders = DocFolderKey.getAffectByLocalFakeEntriesKeys(isWiki: true)
        specialFolders.forEach { folderKey in
            var tokens = specialTokens[folderKey]
            if !tokens.contains(tokenStruct) {
                tokens.insert(tokenStruct, at: 0)
                specialTokens[folderKey] = tokens
                DocsLogger.info("insert fake uploaded wiki entry to list: \(folderKey.name)")
            }
        }
        updateUserFile()
    }

   public mutating func set(needSync: Bool, objToken: FileListDefine.ObjToken, type: DocsType) {
        expectOnQueue()

        var fileEntry = fileEntryToModify(key: objToken)
        if fileEntry != nil, fileEntry!.isSyncing == needSync {
            updateUserFileCount += 1
            return
        }
        DocsLogger.verbose("\(DocsTracker.encrypt(id: objToken)), needsync \(needSync)", component: LogComponents.offlineSyncDoc)
        if fileEntry == nil, needSync {
            fileEntry = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
        }

        fileEntry?.isSyncing = needSync
        allFileEntries[objToken] = fileEntry

        updateUserFile()
    }

   public  mutating func updateSyncStatus(tokenInfos: [FileListDefine.ObjToken: SyncStatus]) {
        expectOnQueue()
        for (objToken, syncStatus) in tokenInfos {
            let fileEntry = fileEntryToModify(key: objToken)
            if fileEntry?.syncStatus != syncStatus {
                fileEntry?.syncStatus = syncStatus
                if syncStatus.downloadStatus == .successOver2s {
                    /// 需要做个标记，后续downloading过程中，UI上不再显示转圈圈
                    /// 从手动离线列表remove这个file时，重置成false
                    fileEntry?.hadShownManuStatus = true
                }
                allFileEntries[objToken] = fileEntry
            }
        }
        updateUserFile()
    }
}

// MARK: - 其他业务逻辑
extension ResourceState {
    public mutating func onDummyAction() {
        updateUserFileCount += 1
    }
    public mutating func appendUsers(users: FileListDefine.Users) {
        expectOnQueue()
        updateUsersByDict(users)
        updateUserFile()
    }

    public mutating func updateMyEditTime(_ myEditTime: TimeInterval, for objToken: FileListDefine.ObjToken) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            updateUserFileCount += 1
            return
        }
        fileEntry.updateMyEditTime(myEditTime)
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }



    ///变成非共享文件夹
    public mutating func removeShareFolderInfo(folderNodeToken: FileListDefine.NodeToken) {
        expectOnQueue()
        let node = TokenStruct(token: folderNodeToken)
        guard let objToken = nodeTokenToObjTokenMap[node],
            let fileEntry = fileEntryToModify(key: objToken) else {
                DocsLogger.info("can not find file")
                return
        }
        var extra = fileEntry.extra
        extra?[FileListServerKeys.isShareRoot] = nil
        extra?[FileListServerKeys.spaceId] = nil
        fileEntry.updateExtraValue(extra)
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }

    public mutating func rename(key: FileListDefine.Key, with newName: String) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: key) else {
            DocsLogger.info("can not find fileEntry")
            updateUserFileCount += 1
            return
        }
        fileEntry.updateName(newName)
        fileEntry.updateEditTime(Date().timeIntervalSince1970)
        /// 如果修改了文件扩展名，修改对应的 subtype 字段
        if fileEntry.type == .file {
            var extra = fileEntry.extra ?? [:]
            extra["subtype"] = (newName as NSString).pathExtension
            fileEntry.updateExtraValue(extra)
        }
        allFileEntries[key] = fileEntry
        updateUserFile()
    }

    public mutating func updateSecret(key: FileListDefine.Key, with newName: String) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: key) else {
            DocsLogger.info("can not find fileEntry")
            updateUserFileCount += 1
            return
        }
        fileEntry.update(secureLabelName: newName)
        allFileEntries[key] = fileEntry
        updateUserFile()
    }


    public mutating func transfer(_ objToken: FileListDefine.ObjToken, to newOwner: FileListDefine.UserID) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            DocsLogger.info("can not find fileEntry")
            updateUserFileCount += 1
            return
        }
        fileEntry.updateOwnerID(newOwner)
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }

    public mutating func updateIconInfoWith(_ objToken: FileListDefine.ObjToken, customIcon: CustomIcon) {
        expectOnQueue()
        guard let fileEntry = fileEntryToModify(key: objToken) else {
            DocsLogger.info("can not get fileEntry for \(DocsTracker.encrypt(id: objToken))")
            updateUserFileCount += 1
            return
        }
        fileEntry.updateCustomIcon(customIcon)
        allFileEntries[objToken] = fileEntry
        updateUserFile()
    }
}

// MARK: - Getters
extension ResourceState {
    /// 根据objToken获取fileEntry
    ///
    /// - Parameter objToken: objtoken
    /// - Returns: 如果可以，返回fileEntry。不要修改这个变量！！
    public func getFileEntry(tokenNode: TokenStruct) -> SpaceEntry? {
        expectOnQueue()
        return self.getFileEntries(allTokens: [tokenNode], limit: Int.max).first?.makeCopy()
    }


    // 有可能找错！！！因为一个文档，可能出现在多处。其他人不要调用
    public func getNodeTokenForObjToken(_ objToken: FileListDefine.ObjToken) -> FileListDefine.NodeToken? {
        expectOnQueue()
        return self.nodeTokenToObjTokenMap.first { $0.value == objToken }?.key.token
    }

    public func getFolderTokenForNodeToken(_ nodeToken: FileListDefine.NodeToken) -> FileListDefine.NodeToken? {
        expectOnQueue()
        return nodeTokenMap.first(where: { $0.value.contain(nodeToken: nodeToken) })?.key
    }

    public func userInfoFor(_ userid: FileListDefine.UserID) -> UserInfo? {
        expectOnQueue()
        return self.allUsers[userid]
    }
}

// MARK: - About DB
extension ResourceState {

    public func clear() {
        expectOnQueue()
    }

    mutating func udpateFromDBData(_ dbData: DBData) {
        expectOnQueue()
        DocsLogger.info("new update fileData userFile and userfeed start")
        userFile = UserFile()
        allFileEntries.removeAll()
        dbData.fileEntry.forEach { (fileEntry) in
            allFileEntries[fileEntry.objToken] = fileEntry
        }
        allUsers.removeAll()
        dbData.users.forEach { (userInfo) in
            allUsers[userInfo.userID] = userInfo
        }
        nodeTokenMap = dbData.nodeTokensMap
        nodeTokenToObjTokenMap = dbData.nodeToObjTokenMap
        specialTokens = dbData.specialTokens

        allFileEntries.values.forEach { (fileEntry) in
            fileEntry.updateExtra()
        }
        self.updateUserFile()
        DocsLogger.info("new update fileData userFile and userfeed ok")
    }
}

// MARK: - 内部逻辑
extension ResourceState {
    public mutating func updateUserFile() {
        expectOnQueue()
        DocFolderKey.allCases.forEach { folderKey in
            userFile.specialListMap[folderKey] = generateSpecialFolderInfo(folderKey: folderKey)
        }
        userFile.folderInfoMap = generateFolderInfoMap()
        addUpateUserFileDebugLog()
        checkStatus()
        updateUserFileCount += 1
    }

    private func queryKeyWith(tokenNode: TokenStruct,
                              checkNode needCheckNode: Bool) -> String? {
        //非shortCut，且需要转成objToken。
        if !tokenNode.isShortCut && needCheckNode {
            return nodeTokenToObjTokenMap[tokenNode]
        }
        //shortcut
        return tokenNode.token
    }

    private struct FolderInfoRequest {
        let specialTokens: [TokenStruct]
        let needCheckNode: Bool
        let folderKey: DocFolderKey
        let pagingInfo: PagingInfo
    }

    private mutating func generateFolderInfo(request: FolderInfoRequest,
                                             fileHanlder: (_ file: SpaceEntry) -> Bool,
                                             folderInfoHander: ((_ folderInfo: FolderInfo, _ page: inout PagingInfo) -> Void)) -> FolderInfo {
        let folderInfo = FolderInfo()
        guard !request.specialTokens.isEmpty else {
            DocsLogger.debug("\(request.folderKey) is empty", component: LogComponents.dataModel)
            return folderInfo
        }
        _ = getFileEntries(by: request.specialTokens, limit: Int.max)

        for tokenNode in request.specialTokens {
            guard let token = queryKeyWith(tokenNode: tokenNode, checkNode: request.needCheckNode) else {
                continue
            }
            guard let fileEntry = fileEntryToModify(key: token) else {
                continue
            }
            guard fileEntry.isEnableShowInList else {
                continue
            }
            guard fileHanlder(fileEntry) else { continue }
            folderInfo.files.append(fileEntry)
        }
        var mutaPagingInfo = request.pagingInfo
        folderInfoHander(folderInfo, &mutaPagingInfo)
        return folderInfo
    }

    private mutating func generateSpecialFolderInfo(folderKey: DocFolderKey) -> FolderInfo {
        let tokens = specialTokens[folderKey]
        let pagingInfo = specialListPagingInfo[folderKey] ?? PagingInfo(hasMore: false, total: 0, pageTitle: nil, lastLabel: nil)
        let fileFilter: (SpaceEntry) -> Bool = folderKey.affectByLeanMode
        ? { $0.judgeIsNeedShowInSimpleMode(oriShow: true) }
        : { _ in return true }
        let request = FolderInfoRequest(specialTokens: tokens,
                                        needCheckNode: folderKey.mixUsingObjTokenAndNodeToken,
                                        folderKey: folderKey,
                                        pagingInfo: pagingInfo)
        return generateFolderInfo(request: request, fileHanlder: fileFilter, folderInfoHander: { _, _ in })
    }

    public mutating func generateFolderInfoMap() -> FolderInfoMap {
        var folderInfoMap = FolderInfoMap()
        nodeTokenMap.forEach { (folderNodeToken, _) in
            let folderInfo = self.getNewFolderInfo(folderNodeToken: folderNodeToken)
            folderInfoMap.folders[folderNodeToken] = folderInfo
        }
        return folderInfoMap
    }

    public mutating func getNewFolderInfo(folderNodeToken: FileListDefine.NodeToken) -> FolderInfo {
        let folderInfo = FolderInfo()
        folderInfo.folderNodeToken = folderNodeToken
        guard let nodeTokens = nodeTokenMap[folderNodeToken] else { return folderInfo }
        _ = getFileEntries(by: nodeTokens, limit: Int.max)

        let entries = nodeTokens.compactMap { tokenNode -> SpaceEntry? in
            guard let token = queryKeyWith(tokenNode: tokenNode, checkNode: true) else {
                return nil
            }
            guard let fileEntry = fileEntryToModify(key: token, newNodeToken: tokenNode.token) else {
                return nil
            }
            guard fileEntry.isEnableShowInList else {
                return nil
            }
            fileEntry.updateParent(folderNodeToken)
            return fileEntry
        }

        folderInfo.files.append(contentsOf: entries)

        if let fileEntry = allFileEntries[folderNodeToken] {
            folderInfo.name = fileEntry.name
        }
        return folderInfo
    }

    public mutating func updateUsersByDict(_ userDict: [FileListDefine.UserID: FileListDefine.User]) {
        for (userid, rawUserInfo) in userDict {
            let userInfo = (allUsers[userid]?.makeCopy()) ?? UserInfo(userid)
            userInfo.updatePropertiesFrom(JSON(rawUserInfo))
            allUsers[userid] = userInfo
        }
    }



    public mutating func update(pagingInfos: [FileListDefine.NodeToken: PagingInfo]) {
        expectOnQueue()
        pagingInfos.forEach { (folderNodeToken, pagingInfo) in
            filePaingInfos[folderNodeToken] = pagingInfo
        }
    }

    public mutating func add(folders: [FileListDefine.NodeToken: [TokenStruct]]) {
        expectOnQueue()
        for (parentNodeToken, childNodeTokens) in folders {
            let folderNodeTokens = nodeTokenMap[parentNodeToken] ?? []
            // 保留本地的fake_token的node的fakeNodeToken
            let localNodeTokens = folderNodeTokens.filter { currentNodeToken in
                nodeTokenToObjTokenMap[currentNodeToken]?.isFakeToken ?? false
            }
            var remainingTokens = childNodeTokens.filter { !localNodeTokens.contains($0) }
            let firstNonFolderIndex = remainingTokens.firstIndex { token in
                guard let objToken = nodeTokenToObjTokenMap[token],
                let entry = allFileEntries[objToken] else {
                    return false
                }
                return entry.type != .folder
            } ?? 0
            remainingTokens.insert(contentsOf: localNodeTokens, at: firstNonFolderIndex)
            nodeTokenMap[parentNodeToken] = remainingTokens
        }
    }

    public mutating func append(folders: [FileListDefine.NodeToken: [TokenStruct]]) {
        expectOnQueue()
        for (parentNodeToken, childNodeTokens) in folders {
            let localNodeTokens = nodeTokenMap[parentNodeToken] ?? [TokenStruct]()
            let remainingTokens = childNodeTokens.filter { !localNodeTokens.contains($0) }
            nodeTokenMap[parentNodeToken]?.append(contentsOf: remainingTokens)
        }
    }



    public func allNodeTokenFor(tokenStruct: TokenStruct) -> [FileListDefine.ObjToken] {
        expectOnQueue()
        var deleteToken = [String]()
        if tokenStruct.isShortCut {
            deleteToken.append(tokenStruct.token)
        } else {
            let objToken = tokenStruct.token
            for (key, value) in nodeTokenToObjTokenMap where (!key.isShortCut && value == objToken) {
                deleteToken.append(key.token)
            }
        }
        return deleteToken
    }

    /// 根据 objtoken 获取fileEntry。可以对返回值进行修改，然后更新到allFileEntries字典里
    ///
    /// - Parameter objToken: objToken
    /// - Returns: 如果可以，返回SpaceEntry
    public func fileEntryToModify(key: String, newNodeToken: String? = nil) -> SpaceEntry? {
        guard let fileEntry = allFileEntries[key]?.makeCopy(newNodeToken: newNodeToken) else {
            return nil
        }
        return fileEntry
    }
}

// MARK: - log
extension ResourceState {
    public func addUpateUserFileDebugLog() {
        specialTokens.storages.forEach { folderKey, tokens in
            addUserFileDebugLog(tag: folderKey, objTokenCount: tokens.count, filesCount: userFile.specialListMap[folderKey]?.files.count ?? 0)
        }
    }

    public func addUserFileDebugLog(tag: DocFolderKey, objTokenCount: Int, filesCount: Int) {
        DocsLogger.debugFileList(tag: tag, desc: "更新UserFile，objTokens:\(objTokenCount), fileEntry: \(filesCount)")
    }
}
