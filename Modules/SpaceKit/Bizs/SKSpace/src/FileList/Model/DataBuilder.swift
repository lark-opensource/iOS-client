//
//  DataBuilder+Space.swift
//  SKECM
//
//  Created by guoqp on 2020/6/28.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation
import SKResource
import SpaceInterface
import SKWorkspace

public struct DataBuilder {
    /// 解析Pin接口返回的数据
    public static func getPinsFileData(from data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        fileData.pinObjs = dataParser.getObjTokenList() ?? []
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.objsInfos = dataParser.getObjInfos() ?? [:]
        fileData.nodes = dataParser.getChildrenNodes() ?? [:]
        return fileData
    }

    /// 解析收藏接口返回的数据
    public static func getFavoritesFileData(from data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        fileData.objsInfos = dataParser.getObjInfos() ?? [:]
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.starObjs = dataParser.getObjTokenList() ?? []
        fileData.starPagingInfo = dataParser.getPageInfo()
        return fileData
    }

    /// 解析共享文件夹接口返回的数据
    public static func getShareFoldersData(data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        guard let nodes = dataParser.getNodes() else { return fileData }
        guard let users = dataParser.getUsers() else { return fileData }
        guard let files = dataParser.getFileNodeTokenList() else { return fileData }
        fileData.nodes = nodes
        fileData.users = users
        fileData.shareFoldersObjs = files
        fileData.shareFolderPagingInfo = dataParser.getPageInfo()
        return fileData
    }

    public static func addHiddenStatusMark(_ isHidden: Bool, to data: FileDataDiff) -> FileDataDiff {
        var newData = data
        var newNodes = [TokenStruct: [FileListDefine.Key: Any]]()
        for node in data.nodes {
            let nodeToken = node.key
            var nodeInfo = node.value
            nodeInfo[FileListServerKeys.isHiddenStatus.rawValue] = isHidden
            newNodes[nodeToken] = nodeInfo
        }
        newData.nodes = newNodes
        return newData
    }
    public static func mergeShareFolderData(_ showingData: FileDataDiff, _ hiddenData: FileDataDiff) -> FileDataDiff {
        let newShowingData = addHiddenStatusMark(false, to: showingData)

        let newHiddenData = addHiddenStatusMark(true, to: hiddenData)

        var fileData = newShowingData

        newHiddenData.nodes.forEach { (nodeToken, nodeInfo) in
            fileData.nodes[nodeToken] = nodeInfo
        }
        newHiddenData.users.forEach { (userID, userInfo) in
            fileData.users[userID] = userInfo
        }
        newHiddenData.shareFoldersObjs.forEach { (nodeToken) in
            fileData.shareFoldersObjs.append(nodeToken)
        }

        fileData.shareFolderPagingInfo.hasMore = newHiddenData.shareFolderPagingInfo.hasMore
        fileData.shareFolderPagingInfo.lastLabel = newHiddenData.shareFolderPagingInfo.lastLabel
        if let hiddenTotal = newHiddenData.shareFolderPagingInfo.total,
            let showingTotal = fileData.shareFolderPagingInfo.total {
            fileData.shareFolderPagingInfo.total = hiddenTotal + showingTotal
        }
        return fileData
    }
    /// 解析最近浏览接口返回的数据
    public static func getRecentFileData(from data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        fileData.objsInfos = dataParser.getObjInfos() ?? [:]
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.recentObjs = dataParser.getObjTokenList() ?? []
        fileData.recentPagingInfo = dataParser.getPageInfo()
        DocsLogger.info("getRecentFileData \(fileData.recentPagingInfo)")
        return fileData
    }

    /// 解析最近浏览接口返回的数据
    public static func getSubordinateRecentData(from data: JSON, subordinateID: String) -> (FileDataDiff, UserInfo) {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        let objTokenList = dataParser.getObjTokenList() ?? []
        fileData.folders = [subordinateID : objTokenList]
        fileData.nodes = dataParser.getObjInfos() ?? [:]
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.filePaingInfos = [subordinateID : dataParser.getPageInfo()]
        DocsLogger.info("getSubordinateRecentData \(fileData.filePaingInfos)")
        let user = fileData.users[subordinateID] ?? [:]
        let userInfo = UserInfo(subordinateID)
        userInfo.updatePropertiesFromV2(user)
        return (fileData, userInfo)
    }

    /// 解析my space personalFiles 接口返回的数据
    public static func getPersonalFileData(from data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        fileData.objsInfos = dataParser.getObjInfos() ?? [:]
        fileData.nodes = dataParser.getNodes() ?? [:]
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.personalFileObjs = dataParser.getObjTokenList() ?? []
        fileData.personalFilesPagingInfo = dataParser.getPageInfo()
        return fileData
    }

    /// 解析与我共享接口返回的数据
    public static func getShareFileData(from data: JSON) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        fileData.objsInfos = dataParser.getObjInfos() ?? [:]
        fileData.users = dataParser.getUsers() ?? [:]
        fileData.shareObjs = dataParser.getObjTokenList() ?? []
        fileData.sharePagingInfo = dataParser.getPageInfo()
        return fileData
    }

    public static func mergeV2ShareFileData(folderData: FileDataDiff, filesData: FileDataDiff) -> FileDataDiff {
        // 文件夹数据在前
        var finalData = folderData
        filesData.objsInfos.forEach { (token, objInfo) in
            finalData.objsInfos[token] = objInfo
        }
        filesData.users.forEach { (userID, userInfo) in
            finalData.users[userID] = userInfo
        }
        finalData.shareObjs.append(contentsOf: filesData.shareObjs)
        // hasMore, lastLabel 使用 filesData 的值
        finalData.sharePagingInfo = filesData.sharePagingInfo

        // total 计算总和
        if let folderTotal = folderData.sharePagingInfo.total,
           let filesTotal = filesData.sharePagingInfo.total {
            finalData.sharePagingInfo.total = folderTotal + filesTotal
        }

        return finalData
    }

    // 解析文件夹列表返回的数据
    public static func getFolderData(from data: JSON, parent: String) -> FileDataDiff {
        var fileData = FileDataDiff()
        let dataParser = DataParser(json: data)
        let users = dataParser.getUsers() ?? [:]
        var nodes = dataParser.getNodes() ?? [:]
        var childNodeTokens = dataParser.getFileNodeTokenList() ?? []
        if let offlines = dataParser.getOffline() {
            offlines.forEach { node in
                if let nodeToken = node.value[FileListServerKeys.token.rawValue] as? String,
                   let index = childNodeTokens.firstIndex(where: { $0.token == nodeToken }) {
                    childNodeTokens.remove(at: index)
                    nodes[TokenStruct(token: nodeToken)] = nil
                }
            }
        }
        let pagingInfo = dataParser.getPageInfo()
        fileData.nodes = nodes
        fileData.users = users
        fileData.folders = [parent: childNodeTokens]
        fileData.filePaingInfos = [parent: pagingInfo]
        return fileData
    }
}

// MARK: - Support
extension DataBuilder {
    /// 生成fileEntry，用于基础数据，不包括parent/nodeToken
    ///
    /// - Parameters:
    ///   - objInfo: 元数据，字典形式
    ///   - users: 所有的User，包括这个fileEntry的创建/拥有着
    /// - Returns: 一个fileEntry
    static func parseNoNodeTokenFileEntryFor(objInfo: FileListDefine.ObjInfo?, users: [FileListDefine.UserID: UserInfo]) -> SpaceEntry? {
        guard let objInfo = objInfo else {
            DocsLogger.debug("objInfo is nil", component: LogComponents.dataModel)
            return nil
        }
        let json = JSON(objInfo)
        guard let typeRaw = json["type"].int,
            let objToken = json["obj_token"].string else {
                DocsLogger.info("objInfo not valid", component: LogComponents.dataModel)
                return nil
        }
        let nodeToken = json["token"].string ?? ""
        let entity = SpaceEntryFactory.createEntry(type: DocsType(rawValue: typeRaw), nodeToken: nodeToken, objToken: objToken)
        entity.updatePropertiesFrom(json)
        guard let ownerId = json["owner_id"].string else {
            DocsLogger.info("can not find ownerid", component: LogComponents.dataModel)
            return nil
        }
        if let user = users[ownerId] {
            entity.update(ownerInfo: user)
        }

        if entity.isShortCut || entity.type == .folder {
            if entity.nodeToken.isEmpty {
                DocsLogger.warning("nodeToken is nil")
            }
        }
        return entity
    }
}

// MARK: - 添加至、移动至  最近访问的文件夹
extension DataBuilder {
    static func getRecentFolders(from json: JSON) -> [SpaceEntry] {
        let dataParser = DataParser(foderPathJson: json)
        /// 文件夹 tokens 集合
        guard let fileTokens = dataParser.getRecentFolderToken() else {
            return []
        }
        /// 文件夹 folderinfo 集合
        guard let fileNodes = dataParser.getNodes() else {
            return []
        }
        var users: [String: UserInfo] = [:]
        if let fileUser = dataParser.getUsers() {
            for (userid, rawUserInfo) in fileUser {
                let userInfo = UserInfo(userid)
                userInfo.updatePropertiesFrom(JSON(rawUserInfo))
                users[userid] = userInfo
            }
        }

        var folders: [SpaceEntry] = []
        for token in fileTokens {
            guard let folderDic = fileNodes[TokenStruct(token: token)] else { continue }
            guard let recentObjDic = JSON(folderDic).dictionaryObject else { continue }
            guard let typeRaw = recentObjDic["type"] as? Int, !DocsType(rawValue: typeRaw).isUnknownType,
                let token = recentObjDic["token"] as? String, let objToken = recentObjDic["obj_token"] as? String else {
                    continue
            }
            let folder = SpaceEntryFactory.createEntry(type: DocsType(rawValue: typeRaw), nodeToken: token, objToken: objToken)
            folder.updatePropertiesFrom(JSON(folderDic))
            if let extraDic = recentObjDic["extra"] as? [String: Any] {
                folder.updateExtraValue(extraDic)
            }

            if let ownerId = json["owner_id"].string {
                if let user = users[ownerId] {
                    folder.update(ownerInfo: user)
                }
            }

            folders.append(folder)
        }
        return folders
    }
}

extension DataParser {
    public func getEntries() -> [SpaceEntry] {
        //解析user
        var allUsers: [FileListDefine.UserID: UserInfo] = [:]
        if let userDict = self.getUsers() {
            for (userid, rawUserInfo) in userDict {
                let userInfo = UserInfo(userid)
                userInfo.updatePropertiesFrom(JSON(rawUserInfo))
                allUsers[userid] = userInfo
            }
        }
        //解析node
        var allFileEntries: [SpaceEntry] = []
        if let objInfos = self.getObjInfos() {
            for (_, objInfo) in objInfos {
                if let fileEntry = DataBuilder.parseNoNodeTokenFileEntryFor(objInfo: objInfo, users: allUsers) {
                    allFileEntries.append(fileEntry)
                }
            }
        }
        return allFileEntries
    }
}
